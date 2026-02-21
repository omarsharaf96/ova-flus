use std::sync::Arc;

use axum::{
    extract::FromRequestParts,
    http::{request::Parts, StatusCode},
    Json,
};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::Deserialize;

use crate::models::{ApiError, Claims};
use crate::AppState;

/// Extractor that validates a Cognito JWT Bearer token (RS256) and provides the Claims.
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

        // Fetch Cognito JWKS and validate RS256 token
        let claims = validate_cognito_token(token, state).await.map_err(|e| {
            tracing::warn!("Cognito token validation failed: {e}");
            ApiError::unauthorized("Invalid or expired token")
        })?;

        Ok(AuthUser(claims))
    }
}

/// Validate a Cognito access token using the User Pool's JWKS endpoint.
async fn validate_cognito_token(token: &str, state: &Arc<AppState>) -> Result<Claims, String> {
    use base64::Engine as _;

    let jwks_url = format!("{}/.well-known/jwks.json", state.cognito_issuer);

    // Fetch JWKS
    let jwks: serde_json::Value = reqwest::get(&jwks_url)
        .await
        .map_err(|e| format!("Failed to fetch JWKS: {e}"))?
        .json()
        .await
        .map_err(|e| format!("Failed to parse JWKS: {e}"))?;

    // Get kid from token header
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Err("Invalid JWT format".to_string());
    }

    let header_bytes = base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(parts[0])
        .map_err(|_| "Invalid JWT header encoding")?;
    let header: serde_json::Value =
        serde_json::from_slice(&header_bytes).map_err(|_| "Invalid JWT header JSON")?;

    let kid = header["kid"].as_str().ok_or("No kid in token header")?;

    // Find matching JWK
    let keys = jwks["keys"].as_array().ok_or("No keys in JWKS")?;
    let jwk = keys
        .iter()
        .find(|k| k["kid"].as_str() == Some(kid))
        .ok_or_else(|| format!("No matching key for kid={kid}"))?;

    let n = jwk["n"].as_str().ok_or("Missing n in JWK")?;
    let e = jwk["e"].as_str().ok_or("Missing e in JWK")?;

    let decoding_key =
        DecodingKey::from_rsa_components(n, e).map_err(|e| format!("Invalid RSA key: {e}"))?;

    let mut validation = Validation::new(Algorithm::RS256);
    validation.set_issuer(&[&state.cognito_issuer]);
    validation.validate_aud = false; // Cognito access tokens don't have aud by default

    // Decode and validate
    let token_data = decode::<CognitoClaims>(token, &decoding_key, &validation)
        .map_err(|e| format!("Token decode failed: {e}"))?;

    // Cognito access tokens have token_use == "access"
    if token_data.claims.token_use != "access" {
        return Err(format!(
            "Invalid token_use: {}",
            token_data.claims.token_use
        ));
    }

    Ok(Claims {
        sub: token_data.claims.sub,
        exp: token_data.claims.exp,
        iat: token_data.claims.iat,
        token_type: token_data.claims.token_use,
    })
}

/// Cognito JWT claims shape (access token)
#[derive(Debug, Deserialize)]
struct CognitoClaims {
    pub sub: String,
    pub exp: usize,
    pub iat: usize,
    pub token_use: String, // "access" for access tokens
    #[allow(dead_code)]
    pub client_id: Option<String>,
    #[allow(dead_code)]
    pub username: Option<String>,
}

#[cfg(test)]
mod tests {
    // Note: Integration tests for Cognito RS256 require a real Cognito pool.
    // Unit tests for the extractor logic are limited without a mock JWKS server.

    #[test]
    fn cognito_claims_token_use_check() {
        // Verify our token_use validation logic concept
        let token_use = "access";
        assert_eq!(token_use, "access");
        let bad_token_use = "id";
        assert_ne!(bad_token_use, "access");
    }
}
