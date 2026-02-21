use std::sync::Arc;

use axum::{
    extract::FromRequestParts,
    http::{request::Parts, StatusCode},
    Json,
};
use jsonwebtoken::{decode, DecodingKey, Validation};

use crate::models::{ApiError, Claims};
use crate::AppState;

/// Extractor that validates a JWT Bearer token and provides the Claims.
///
/// Usage in handler: `AuthUser(claims): AuthUser`
#[allow(dead_code)]
pub struct AuthUser(pub Claims);

#[axum::async_trait]
impl FromRequestParts<Arc<AppState>> for AuthUser {
    type Rejection = (StatusCode, Json<ApiError>);

    async fn from_request_parts(
        parts: &mut Parts,
        state: &Arc<AppState>,
    ) -> Result<Self, Self::Rejection> {
        let header = parts
            .headers
            .get("authorization")
            .and_then(|v| v.to_str().ok())
            .ok_or_else(|| ApiError::unauthorized("Missing authorization header"))?;

        let token = header
            .strip_prefix("Bearer ")
            .ok_or_else(|| ApiError::unauthorized("Invalid authorization format"))?;

        let mut validation = Validation::new(jsonwebtoken::Algorithm::HS256);
        validation.set_required_spec_claims(&["exp", "sub", "iat"]);

        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(state.jwt_secret.as_bytes()),
            &validation,
        )
        .map_err(|e| {
            tracing::warn!("JWT validation failed: {e}");
            ApiError::unauthorized("Invalid or expired token")
        })?;

        if token_data.claims.token_type != "access" {
            return Err(ApiError::unauthorized("Invalid token type"));
        }

        Ok(AuthUser(token_data.claims))
    }
}

#[cfg(test)]
mod tests {
    use crate::models::Claims;
    use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};

    const TEST_SECRET: &str = "test-secret-32-chars-long-minimum!";
    const TEST_USER_ID: &str = "user-123";

    #[test]
    fn jwt_creation_and_validation_round_trip() {
        let now = chrono::Utc::now().timestamp() as usize;
        let claims = Claims {
            sub: TEST_USER_ID.to_string(),
            exp: now + 3600,
            iat: now,
            token_type: "access".to_string(),
        };

        let key = EncodingKey::from_secret(TEST_SECRET.as_bytes());
        let token = encode(&Header::default(), &claims, &key).unwrap();

        let mut validation = Validation::new(jsonwebtoken::Algorithm::HS256);
        validation.set_required_spec_claims(&["exp", "sub", "iat"]);

        let decoded = decode::<Claims>(
            &token,
            &DecodingKey::from_secret(TEST_SECRET.as_bytes()),
            &validation,
        )
        .unwrap();

        assert_eq!(decoded.claims.sub, TEST_USER_ID);
        assert_eq!(decoded.claims.token_type, "access");
        assert_eq!(decoded.claims.iat, now);
    }

    #[test]
    fn expired_token_fails_validation() {
        let claims = Claims {
            sub: TEST_USER_ID.to_string(),
            exp: 1000, // far in the past
            iat: 500,
            token_type: "access".to_string(),
        };

        let key = EncodingKey::from_secret(TEST_SECRET.as_bytes());
        let token = encode(&Header::default(), &claims, &key).unwrap();

        let mut validation = Validation::new(jsonwebtoken::Algorithm::HS256);
        validation.set_required_spec_claims(&["exp", "sub", "iat"]);

        let result = decode::<Claims>(
            &token,
            &DecodingKey::from_secret(TEST_SECRET.as_bytes()),
            &validation,
        );

        assert!(result.is_err());
    }

    #[test]
    fn wrong_secret_fails_validation() {
        let now = chrono::Utc::now().timestamp() as usize;
        let claims = Claims {
            sub: TEST_USER_ID.to_string(),
            exp: now + 3600,
            iat: now,
            token_type: "access".to_string(),
        };

        let key = EncodingKey::from_secret(TEST_SECRET.as_bytes());
        let token = encode(&Header::default(), &claims, &key).unwrap();

        let wrong_key = DecodingKey::from_secret(b"completely-wrong-secret-key!!!!!");
        let mut validation = Validation::new(jsonwebtoken::Algorithm::HS256);
        validation.set_required_spec_claims(&["exp", "sub", "iat"]);

        let result = decode::<Claims>(&token, &wrong_key, &validation);

        assert!(result.is_err());
    }
}
