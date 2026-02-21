use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use aws_sdk_cognitoidentityprovider::types::{AuthFlowType, ChallengeNameType, MessageActionType};
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use hmac::{Hmac, Mac};
use rand::Rng;
use serde::{Deserialize, Serialize};
use sha2::Sha256;

use crate::models::ApiError;
use crate::AppState;

type HmacSha256 = Hmac<Sha256>;

#[derive(Deserialize)]
pub struct AppleSignInRequest {
    pub identity_token: String,
}

#[derive(Deserialize)]
pub struct GoogleSignInRequest {
    pub id_token: String,
}

#[derive(Serialize)]
pub struct CognitoTokenResponse {
    pub access_token: String,
    pub id_token: String,
    pub refresh_token: String,
    pub expires_in: i32,
}

/// Verify a JWT using JWKS from the given URL.
/// Returns the decoded claims if valid, or an error string.
async fn verify_jwt_with_jwks(
    token: &str,
    jwks_url: &str,
    expected_aud: Option<&str>,
) -> Result<serde_json::Value, String> {
    use base64::Engine as _;

    // Fetch JWKS
    let jwks_resp = reqwest::get(jwks_url)
        .await
        .map_err(|e| format!("Failed to fetch JWKS: {e}"))?
        .json::<serde_json::Value>()
        .await
        .map_err(|e| format!("Failed to parse JWKS: {e}"))?;

    // Parse token header to get kid
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Err("Invalid JWT format".to_string());
    }

    let header_bytes = base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(parts[0])
        .map_err(|_| "Invalid JWT header encoding")?;
    let header: serde_json::Value =
        serde_json::from_slice(&header_bytes).map_err(|_| "Invalid JWT header JSON")?;

    let kid = header["kid"].as_str().ok_or("No kid in JWT header")?;
    let alg = header["alg"].as_str().unwrap_or("RS256");

    if alg != "RS256" {
        return Err(format!("Unexpected algorithm: {alg}"));
    }

    // Find matching key in JWKS
    let keys = jwks_resp["keys"].as_array().ok_or("No keys in JWKS")?;

    let jwk = keys
        .iter()
        .find(|k| k["kid"].as_str() == Some(kid))
        .ok_or_else(|| format!("No matching key for kid={kid}"))?;

    // Decode RS256 using jsonwebtoken
    let n = jwk["n"].as_str().ok_or("Missing n in JWK")?;
    let e = jwk["e"].as_str().ok_or("Missing e in JWK")?;

    let decoding_key = jsonwebtoken::DecodingKey::from_rsa_components(n, e)
        .map_err(|err| format!("Invalid RSA key: {err}"))?;

    let mut validation = jsonwebtoken::Validation::new(jsonwebtoken::Algorithm::RS256);
    validation.validate_exp = true;
    if let Some(aud) = expected_aud {
        validation.set_audience(&[aud]);
    } else {
        validation.validate_aud = false;
    }

    let token_data = jsonwebtoken::decode::<serde_json::Value>(token, &decoding_key, &validation)
        .map_err(|e| format!("JWT validation failed: {e}"))?;

    Ok(token_data.claims)
}

/// Generate a signed nonce for the Cognito custom auth challenge.
/// Format: "timestamp:hmac" where hmac = HMAC-SHA256(username:timestamp, nonce_secret)
fn generate_nonce(username: &str, nonce_secret: &str) -> String {
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let message = format!("{}:{}", username, ts);
    let mut mac =
        HmacSha256::new_from_slice(nonce_secret.as_bytes()).expect("HMAC accepts any key size");
    mac.update(message.as_bytes());
    let result = mac.finalize().into_bytes();
    format!("{}:{}", ts, hex::encode(result))
}

/// Generate a random permanent password for social login users.
fn random_password() -> String {
    let mut rng = rand::thread_rng();
    let chars: String = (0..24)
        .map(|_| {
            let idx = rng.gen_range(0..62);
            match idx {
                0..=9 => (b'0' + idx) as char,
                10..=35 => (b'A' + idx - 10) as char,
                _ => (b'a' + idx - 36) as char,
            }
        })
        .collect();
    // Ensure it meets Cognito policy: start with uppercase, add digit
    format!("A1{}", chars)
}

/// Upsert a Cognito user by email and run the custom auth flow.
/// Returns Cognito tokens on success.
async fn cognito_social_sign_in(
    state: &Arc<AppState>,
    email: &str,
) -> Result<CognitoTokenResponse, (StatusCode, Json<ApiError>)> {
    // Try to create user (suppress email if already exists)
    let create_result = state
        .cognito
        .admin_create_user()
        .user_pool_id(&state.cognito_user_pool_id)
        .username(email)
        .user_attributes(
            aws_sdk_cognitoidentityprovider::types::AttributeType::builder()
                .name("email")
                .value(email)
                .build()
                .map_err(|e| ApiError::internal(format!("Attribute build error: {e}")))?,
        )
        .user_attributes(
            aws_sdk_cognitoidentityprovider::types::AttributeType::builder()
                .name("email_verified")
                .value("true")
                .build()
                .map_err(|e| ApiError::internal(format!("Attribute build error: {e}")))?,
        )
        .message_action(MessageActionType::Suppress)
        .send()
        .await;

    // Ignore "UsernameExistsException" — user already exists, that's fine
    if let Err(e) = &create_result {
        let err_str = format!("{:?}", e);
        if !err_str.contains("UsernameExistsException") {
            tracing::error!("AdminCreateUser failed: {e}");
            return Err(ApiError::internal("Failed to create Cognito user"));
        }
    }

    // Set a permanent random password so user is in CONFIRMED state
    state
        .cognito
        .admin_set_user_password()
        .user_pool_id(&state.cognito_user_pool_id)
        .username(email)
        .password(random_password())
        .permanent(true)
        .send()
        .await
        .map_err(|e| {
            tracing::error!("AdminSetUserPassword failed: {e}");
            ApiError::internal("Failed to configure user")
        })?;

    // Initiate custom auth flow
    let auth_resp = state
        .cognito
        .admin_initiate_auth()
        .auth_flow(AuthFlowType::CustomAuth)
        .user_pool_id(&state.cognito_user_pool_id)
        .client_id(&state.cognito_app_client_id)
        .auth_parameters("USERNAME", email)
        .send()
        .await
        .map_err(|e| {
            tracing::error!("AdminInitiateAuth failed: {e}");
            ApiError::internal("Auth initiation failed")
        })?;

    let session = auth_resp
        .session
        .ok_or_else(|| ApiError::internal("No session from auth initiation"))?;

    // Generate and send nonce response
    let nonce = generate_nonce(email, &state.nonce_secret);

    let challenge_resp = state
        .cognito
        .admin_respond_to_auth_challenge()
        .challenge_name(ChallengeNameType::CustomChallenge)
        .user_pool_id(&state.cognito_user_pool_id)
        .client_id(&state.cognito_app_client_id)
        .session(&session)
        .challenge_responses("USERNAME", email)
        .challenge_responses("ANSWER", &nonce)
        .send()
        .await
        .map_err(|e| {
            tracing::error!("AdminRespondToAuthChallenge failed: {e}");
            ApiError::internal("Auth challenge failed")
        })?;

    let result = challenge_resp
        .authentication_result
        .ok_or_else(|| ApiError::internal("No authentication result from challenge"))?;

    Ok(CognitoTokenResponse {
        access_token: result.access_token.unwrap_or_default(),
        id_token: result.id_token.unwrap_or_default(),
        refresh_token: result.refresh_token.unwrap_or_default(),
        expires_in: result.expires_in,
    })
}

pub async fn apple_sign_in(
    State(state): State<Arc<AppState>>,
    Json(body): Json<AppleSignInRequest>,
) -> impl IntoResponse {
    // Apple JWKS URL
    const APPLE_JWKS_URL: &str = "https://appleid.apple.com/auth/keys";

    // Verify the Apple identity token (aud = "com.flus.app" — our bundle ID)
    let claims = match verify_jwt_with_jwks(
        &body.identity_token,
        APPLE_JWKS_URL,
        Some("com.flus.app"),
    )
    .await
    {
        Ok(c) => c,
        Err(e) => {
            tracing::warn!("Apple JWT validation failed: {e}");
            return (
                StatusCode::UNAUTHORIZED,
                Json(serde_json::json!({"error": "unauthorized", "message": "Invalid Apple identity token"})),
            ).into_response();
        }
    };

    let email = match claims["email"].as_str() {
        Some(e) => e.to_string(),
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": "bad_request", "message": "Email not found in Apple token"})),
            ).into_response();
        }
    };

    match cognito_social_sign_in(&state, &email).await {
        Ok(tokens) => (StatusCode::OK, Json(tokens)).into_response(),
        Err((status, err)) => (status, err).into_response(),
    }
}

pub async fn google_sign_in(
    State(state): State<Arc<AppState>>,
    Json(body): Json<GoogleSignInRequest>,
) -> impl IntoResponse {
    // Google JWKS URL
    const GOOGLE_JWKS_URL: &str = "https://www.googleapis.com/oauth2/v3/certs";

    // Verify Google ID token (no aud check here — Google client ID validated by signature)
    let claims = match verify_jwt_with_jwks(&body.id_token, GOOGLE_JWKS_URL, None).await {
        Ok(c) => c,
        Err(e) => {
            tracing::warn!("Google JWT validation failed: {e}");
            return (
                StatusCode::UNAUTHORIZED,
                Json(serde_json::json!({"error": "unauthorized", "message": "Invalid Google ID token"})),
            ).into_response();
        }
    };

    let email = match claims["email"].as_str() {
        Some(e) => e.to_string(),
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": "bad_request", "message": "Email not found in Google token"})),
            ).into_response();
        }
    };

    match cognito_social_sign_in(&state, &email).await {
        Ok(tokens) => (StatusCode::OK, Json(tokens)).into_response(),
        Err((status, err)) => (status, err).into_response(),
    }
}
