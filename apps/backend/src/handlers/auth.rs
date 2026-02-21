use std::sync::Arc;

use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use aws_sdk_dynamodb::types::AttributeValue;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use rand::rngs::OsRng;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::{ApiError, Claims};
use crate::AppState;

#[derive(Deserialize)]
pub struct SignUpRequest {
    pub email: String,
    pub password: String,
    pub name: String,
}

#[derive(Deserialize)]
pub struct SignInRequest {
    pub email: String,
    pub password: String,
}

#[derive(Deserialize)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

#[derive(Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user_id: String,
}

fn generate_tokens(
    user_id: &str,
    jwt_secret: &str,
) -> Result<(String, String), jsonwebtoken::errors::Error> {
    let now = Utc::now().timestamp() as usize;

    let access_claims = Claims {
        sub: user_id.to_string(),
        exp: now + 3600, // 1 hour
        iat: now,
        token_type: "access".to_string(),
    };

    let refresh_claims = Claims {
        sub: user_id.to_string(),
        exp: now + 7 * 24 * 3600, // 7 days
        iat: now,
        token_type: "refresh".to_string(),
    };

    let key = EncodingKey::from_secret(jwt_secret.as_bytes());
    let header = Header::default(); // HS256

    let access_token = encode(&header, &access_claims, &key)?;
    let refresh_token = encode(&header, &refresh_claims, &key)?;

    Ok((access_token, refresh_token))
}

pub async fn sign_up(
    State(state): State<Arc<AppState>>,
    Json(body): Json<SignUpRequest>,
) -> impl IntoResponse {
    // Check if email already exists
    let query_result = state
        .dynamo
        .query()
        .table_name("ovaflus-users")
        .index_name("email-index")
        .key_condition_expression("email = :email")
        .expression_attribute_values(":email", AttributeValue::S(body.email.clone()))
        .send()
        .await;

    match query_result {
        Ok(output) => {
            if output.count() > 0 {
                return (
                    StatusCode::CONFLICT,
                    Json(serde_json::json!({"error": "Email already registered"})),
                )
                    .into_response();
            }
        }
        Err(e) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new(format!("Database error: {}", e))),
            )
                .into_response();
        }
    }

    // Hash password
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = match argon2.hash_password(body.password.as_bytes(), &salt) {
        Ok(hash) => hash.to_string(),
        Err(e) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new(format!("Password hashing error: {}", e))),
            )
                .into_response();
        }
    };

    let user_id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();

    // Store user in DynamoDB
    let put_result = state
        .dynamo
        .put_item()
        .table_name("ovaflus-users")
        .item("user_id", AttributeValue::S(user_id.clone()))
        .item("email", AttributeValue::S(body.email.clone()))
        .item("name", AttributeValue::S(body.name.clone()))
        .item("password_hash", AttributeValue::S(password_hash))
        .item("created_at", AttributeValue::S(now.clone()))
        .item("updated_at", AttributeValue::S(now))
        .send()
        .await;

    if let Err(e) = put_result {
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Failed to create user: {}", e))),
        )
            .into_response();
    }

    // Generate JWT tokens
    match generate_tokens(&user_id, &state.jwt_secret) {
        Ok((access_token, refresh_token)) => (
            StatusCode::CREATED,
            Json(AuthResponse {
                access_token,
                refresh_token,
                user_id,
            }),
        )
            .into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Token generation error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn sign_in(
    State(state): State<Arc<AppState>>,
    Json(body): Json<SignInRequest>,
) -> impl IntoResponse {
    // Query user by email
    let query_result = state
        .dynamo
        .query()
        .table_name("ovaflus-users")
        .index_name("email-index")
        .key_condition_expression("email = :email")
        .expression_attribute_values(":email", AttributeValue::S(body.email.clone()))
        .send()
        .await;

    let items = match query_result {
        Ok(output) => output.items.unwrap_or_default(),
        Err(e) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new(format!("Database error: {}", e))),
            )
                .into_response();
        }
    };

    let user = match items.first() {
        Some(item) => item,
        None => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Invalid email or password")),
            )
                .into_response();
        }
    };

    // Verify password
    let stored_hash = match user.get("password_hash").and_then(|v| v.as_s().ok()) {
        Some(h) => h,
        None => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Corrupted user record")),
            )
                .into_response();
        }
    };

    let parsed_hash = match PasswordHash::new(stored_hash) {
        Ok(h) => h,
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Password verification error")),
            )
                .into_response();
        }
    };

    if Argon2::default()
        .verify_password(body.password.as_bytes(), &parsed_hash)
        .is_err()
    {
        return (
            StatusCode::UNAUTHORIZED,
            Json(ApiError::new("Invalid email or password")),
        )
            .into_response();
    }

    let user_id = user
        .get("user_id")
        .and_then(|v| v.as_s().ok())
        .unwrap_or(&String::new())
        .clone();

    match generate_tokens(&user_id, &state.jwt_secret) {
        Ok((access_token, refresh_token)) => (
            StatusCode::OK,
            Json(AuthResponse {
                access_token,
                refresh_token,
                user_id,
            }),
        )
            .into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Token generation error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn refresh_token(
    State(state): State<Arc<AppState>>,
    Json(body): Json<RefreshRequest>,
) -> impl IntoResponse {
    use jsonwebtoken::{decode, DecodingKey, Validation};

    let key = DecodingKey::from_secret(state.jwt_secret.as_bytes());
    let mut validation = Validation::default();
    validation.set_required_spec_claims(&["exp", "sub", "iat"]);

    let token_data = match decode::<Claims>(&body.refresh_token, &key, &validation) {
        Ok(data) => data,
        Err(_) => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Invalid or expired refresh token")),
            )
                .into_response();
        }
    };

    if token_data.claims.token_type != "refresh" {
        return (
            StatusCode::UNAUTHORIZED,
            Json(ApiError::new("Invalid token type")),
        )
            .into_response();
    }

    match generate_tokens(&token_data.claims.sub, &state.jwt_secret) {
        Ok((access_token, refresh_token)) => (
            StatusCode::OK,
            Json(AuthResponse {
                access_token,
                refresh_token,
                user_id: token_data.claims.sub,
            }),
        )
            .into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Token generation error: {}", e))),
        )
            .into_response(),
    }
}
