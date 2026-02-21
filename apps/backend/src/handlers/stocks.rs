use std::sync::Arc;

use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde::Deserialize;

use crate::models::ApiError;
use crate::AppState;

#[derive(Deserialize)]
pub struct SearchQuery {
    pub q: String,
}

pub async fn get_stock(
    State(state): State<Arc<AppState>>,
    Path(symbol): Path<String>,
) -> impl IntoResponse {
    let client = reqwest::Client::new();

    // Fetch quote and profile in parallel
    let quote_fut = client
        .get("https://finnhub.io/api/v1/quote")
        .query(&[("symbol", &symbol), ("token", &state.finnhub_api_key)])
        .send();

    let profile_fut = client
        .get("https://finnhub.io/api/v1/stock/profile2")
        .query(&[("symbol", &symbol), ("token", &state.finnhub_api_key)])
        .send();

    let (quote_res, profile_res) = tokio::join!(quote_fut, profile_fut);

    let quote: serde_json::Value = match quote_res {
        Ok(resp) => match resp.json().await {
            Ok(v) => v,
            Err(e) => {
                return (
                    StatusCode::BAD_GATEWAY,
                    Json(ApiError::new(format!("Failed to parse quote: {}", e))),
                )
                    .into_response();
            }
        },
        Err(e) => {
            return (
                StatusCode::BAD_GATEWAY,
                Json(ApiError::new(format!("Failed to fetch quote: {}", e))),
            )
                .into_response();
        }
    };

    let profile: serde_json::Value = match profile_res {
        Ok(resp) => match resp.json().await {
            Ok(v) => v,
            Err(e) => {
                return (
                    StatusCode::BAD_GATEWAY,
                    Json(ApiError::new(format!("Failed to parse profile: {}", e))),
                )
                    .into_response();
            }
        },
        Err(e) => {
            return (
                StatusCode::BAD_GATEWAY,
                Json(ApiError::new(format!("Failed to fetch profile: {}", e))),
            )
                .into_response();
        }
    };

    // Merge quote and profile into a single object
    let mut merged = serde_json::Map::new();
    if let serde_json::Value::Object(q) = quote {
        merged.extend(q);
    }
    if let serde_json::Value::Object(p) = profile {
        merged.extend(p);
    }

    (StatusCode::OK, Json(serde_json::Value::Object(merged))).into_response()
}

pub async fn search_stocks(
    State(state): State<Arc<AppState>>,
    Query(params): Query<SearchQuery>,
) -> impl IntoResponse {
    let client = reqwest::Client::new();

    let result = client
        .get("https://finnhub.io/api/v1/search")
        .query(&[("q", &params.q), ("token", &state.finnhub_api_key)])
        .send()
        .await;

    match result {
        Ok(resp) => match resp.json::<serde_json::Value>().await {
            Ok(data) => (StatusCode::OK, Json(data)).into_response(),
            Err(e) => (
                StatusCode::BAD_GATEWAY,
                Json(ApiError::new(format!("Failed to parse response: {}", e))),
            )
                .into_response(),
        },
        Err(e) => (
            StatusCode::BAD_GATEWAY,
            Json(ApiError::new(format!("Finnhub request failed: {}", e))),
        )
            .into_response(),
    }
}

pub async fn get_stock_news(
    State(state): State<Arc<AppState>>,
    Path(symbol): Path<String>,
) -> impl IntoResponse {
    let client = reqwest::Client::new();

    let now = chrono::Utc::now();
    let from = (now - chrono::Duration::days(7))
        .format("%Y-%m-%d")
        .to_string();
    let to = now.format("%Y-%m-%d").to_string();

    let result = client
        .get("https://finnhub.io/api/v1/company-news")
        .query(&[
            ("symbol", symbol.as_str()),
            ("from", from.as_str()),
            ("to", to.as_str()),
            ("token", state.finnhub_api_key.as_str()),
        ])
        .send()
        .await;

    match result {
        Ok(resp) => match resp.json::<serde_json::Value>().await {
            Ok(data) => (StatusCode::OK, Json(data)).into_response(),
            Err(e) => (
                StatusCode::BAD_GATEWAY,
                Json(ApiError::new(format!("Failed to parse response: {}", e))),
            )
                .into_response(),
        },
        Err(e) => (
            StatusCode::BAD_GATEWAY,
            Json(ApiError::new(format!("Finnhub request failed: {}", e))),
        )
            .into_response(),
    }
}
