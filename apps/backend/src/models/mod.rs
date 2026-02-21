#![allow(dead_code)]

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::{Deserialize, Serialize};

// ── Auth ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignUpRequest {
    pub email: String,
    pub name: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignInRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String, // user_id
    pub exp: usize,
    pub iat: usize,
    pub token_type: String, // "access" or "refresh"
}

// ── User Profile ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserProfile {
    pub user_id: String,
    pub email: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub password_hash: Option<String>,
    #[serde(default)]
    pub settings: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateProfileRequest {
    pub name: Option<String>,
    pub settings: Option<serde_json::Value>,
}

// ── Budgets ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Budget {
    pub budget_id: String,
    pub user_id: String,
    pub name: String,
    pub category: String,
    pub amount: f64,
    #[serde(default)]
    pub spent: f64,
    pub period: String,
    pub start_date: Option<String>,
    pub end_date: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateBudgetRequest {
    pub name: String,
    pub category: String,
    pub amount: f64,
    pub period: String,
    pub start_date: Option<String>,
    pub end_date: Option<String>,
}

// ── Transactions ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub transaction_id: String,
    pub user_id: String,
    pub amount: f64,
    pub transaction_type: String,
    pub category: String,
    pub merchant_name: Option<String>,
    pub date: String,
    pub budget_id: Option<String>,
    pub plaid_transaction_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTransactionRequest {
    pub amount: f64,
    pub transaction_type: String,
    pub category: String,
    pub merchant_name: Option<String>,
    pub date: String,
    pub budget_id: Option<String>,
}

// ── Portfolio / Holdings ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Holding {
    pub holding_id: String,
    pub user_id: String,
    pub symbol: String,
    pub shares: f64,
    pub average_cost: f64,
    pub purchase_date: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateHoldingRequest {
    pub symbol: String,
    pub shares: f64,
    pub average_cost: f64,
    pub purchase_date: Option<String>,
}

// ── Watchlist ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WatchlistItem {
    pub user_id: String,
    pub symbol: String,
    pub added_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AddWatchlistRequest {
    pub symbol: String,
}

// ── Goals ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Goal {
    pub goal_id: String,
    pub user_id: String,
    pub name: String,
    pub target_amount: f64,
    #[serde(default)]
    pub current_amount: f64,
    pub deadline: Option<String>,
    pub category: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateGoalRequest {
    pub name: String,
    pub target_amount: f64,
    pub deadline: Option<String>,
    pub category: Option<String>,
}

// ── Plaid ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaidItem {
    pub user_id: String,
    pub item_id: String,
    pub access_token: String,
    pub institution_name: Option<String>,
    #[serde(default)]
    pub accounts: Vec<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaidLinkTokenRequest {
    pub user_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaidExchangeRequest {
    pub public_token: String,
    pub institution_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaidSyncRequest {
    pub item_id: String,
}

// ── Errors ──

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiError {
    pub error: String,
    pub message: String,
}

impl ApiError {
    pub fn new(message: impl Into<String>) -> Self {
        let msg = message.into();
        Self {
            error: "error".to_string(),
            message: msg,
        }
    }

    pub fn with_code(error: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            error: error.into(),
            message: message.into(),
        }
    }

    pub fn unauthorized(message: impl Into<String>) -> (StatusCode, Json<Self>) {
        (
            StatusCode::UNAUTHORIZED,
            Json(Self::with_code("unauthorized", message)),
        )
    }

    pub fn bad_request(message: impl Into<String>) -> (StatusCode, Json<Self>) {
        (
            StatusCode::BAD_REQUEST,
            Json(Self::with_code("bad_request", message)),
        )
    }

    pub fn not_found(message: impl Into<String>) -> (StatusCode, Json<Self>) {
        (
            StatusCode::NOT_FOUND,
            Json(Self::with_code("not_found", message)),
        )
    }

    pub fn internal(message: impl Into<String>) -> (StatusCode, Json<Self>) {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(Self::with_code("internal_error", message)),
        )
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let status = match self.error.as_str() {
            "unauthorized" => StatusCode::UNAUTHORIZED,
            "bad_request" => StatusCode::BAD_REQUEST,
            "not_found" => StatusCode::NOT_FOUND,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        };
        (status, Json(self)).into_response()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn signup_request_serializes_and_deserializes() {
        let req = SignUpRequest {
            email: "test@example.com".to_string(),
            name: "Test User".to_string(),
            password: "secret123".to_string(),
        };
        let json = serde_json::to_string(&req).unwrap();
        let deserialized: SignUpRequest = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.email, "test@example.com");
        assert_eq!(deserialized.name, "Test User");
        assert_eq!(deserialized.password, "secret123");
    }

    #[test]
    fn auth_response_round_trips_through_serde() {
        let resp = AuthResponse {
            access_token: "access-tok".to_string(),
            refresh_token: "refresh-tok".to_string(),
            user_id: "user-123".to_string(),
        };
        let json = serde_json::to_value(&resp).unwrap();
        let deserialized: AuthResponse = serde_json::from_value(json).unwrap();
        assert_eq!(deserialized.access_token, "access-tok");
        assert_eq!(deserialized.refresh_token, "refresh-tok");
        assert_eq!(deserialized.user_id, "user-123");
    }

    #[test]
    fn api_error_new_produces_correct_fields() {
        let err = ApiError::new("Missing field");
        assert_eq!(err.error, "error");
        assert_eq!(err.message, "Missing field");

        let json = serde_json::to_value(&err).unwrap();
        assert_eq!(json["error"], "error");
        assert_eq!(json["message"], "Missing field");
    }

    #[test]
    fn api_error_with_code_produces_correct_fields() {
        let err = ApiError::with_code("bad_request", "Invalid input");
        assert_eq!(err.error, "bad_request");
        assert_eq!(err.message, "Invalid input");
    }

    #[test]
    fn claims_serialization() {
        let claims = Claims {
            sub: "user-456".to_string(),
            exp: 9999999999,
            iat: 1000000000,
            token_type: "access".to_string(),
        };
        let json = serde_json::to_value(&claims).unwrap();
        assert_eq!(json["sub"], "user-456");
        assert_eq!(json["exp"], 9999999999u64);
        assert_eq!(json["iat"], 1000000000);
        assert_eq!(json["token_type"], "access");

        let deserialized: Claims = serde_json::from_value(json).unwrap();
        assert_eq!(deserialized.sub, claims.sub);
        assert_eq!(deserialized.token_type, claims.token_type);
    }
}
