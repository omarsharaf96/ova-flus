use std::sync::Arc;

use aws_sdk_dynamodb::types::AttributeValue;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Extension, Json,
};
use chrono::Utc;
use serde::Serialize;

use crate::models::{ApiError, Claims};
use crate::AppState;

#[derive(Serialize)]
pub struct WatchlistItem {
    pub user_id: String,
    pub symbol: String,
    pub added_at: String,
}

fn item_to_watchlist_item(
    item: &std::collections::HashMap<String, AttributeValue>,
) -> WatchlistItem {
    WatchlistItem {
        user_id: item
            .get("user_id")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        symbol: item
            .get("symbol")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        added_at: item
            .get("added_at")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
    }
}

pub async fn get_watchlist(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .query()
        .table_name("ovaflus-watchlist")
        .key_condition_expression("user_id = :uid")
        .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
        .send()
        .await;

    match result {
        Ok(output) => {
            let items: Vec<WatchlistItem> = output
                .items
                .unwrap_or_default()
                .iter()
                .map(item_to_watchlist_item)
                .collect();
            (StatusCode::OK, Json(serde_json::to_value(items).unwrap())).into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Database error: {}", e))),
        )
            .into_response(),
    }
}

#[derive(serde::Deserialize)]
pub struct AddToWatchlistRequest {
    pub symbol: String,
}

pub async fn add_to_watchlist(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<AddToWatchlistRequest>,
) -> impl IntoResponse {
    let now = Utc::now().to_rfc3339();

    let result = state
        .dynamo
        .put_item()
        .table_name("ovaflus-watchlist")
        .item("user_id", AttributeValue::S(claims.sub.clone()))
        .item("symbol", AttributeValue::S(body.symbol.clone()))
        .item("added_at", AttributeValue::S(now.clone()))
        .send()
        .await;

    match result {
        Ok(_) => {
            let item = WatchlistItem {
                user_id: claims.sub,
                symbol: body.symbol,
                added_at: now,
            };
            (
                StatusCode::CREATED,
                Json(serde_json::to_value(item).unwrap()),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Failed to add to watchlist: {}", e))),
        )
            .into_response(),
    }
}

pub async fn remove_from_watchlist(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(symbol): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .delete_item()
        .table_name("ovaflus-watchlist")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("symbol", AttributeValue::S(symbol))
        .send()
        .await;

    match result {
        Ok(_) => StatusCode::NO_CONTENT.into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Delete failed: {}", e))),
        )
            .into_response(),
    }
}
