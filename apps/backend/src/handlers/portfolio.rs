use std::sync::Arc;

use aws_sdk_dynamodb::types::AttributeValue;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::middleware::auth::AuthUser;
use crate::models::ApiError;
use crate::AppState;

#[derive(Serialize, Deserialize)]
pub struct Holding {
    pub holding_id: String,
    pub user_id: String,
    pub symbol: String,
    pub shares: f64,
    pub avg_cost: f64,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Deserialize)]
pub struct AddHoldingRequest {
    pub symbol: String,
    pub shares: f64,
    pub avg_cost: f64,
}

#[derive(Deserialize)]
pub struct UpdateHoldingRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub shares: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub avg_cost: Option<f64>,
}

fn item_to_holding(item: &std::collections::HashMap<String, AttributeValue>) -> Holding {
    Holding {
        holding_id: item
            .get("holding_id")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
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
        shares: item
            .get("shares")
            .and_then(|v| v.as_n().ok())
            .and_then(|n| n.parse::<f64>().ok())
            .unwrap_or(0.0),
        avg_cost: item
            .get("avg_cost")
            .and_then(|v| v.as_n().ok())
            .and_then(|n| n.parse::<f64>().ok())
            .unwrap_or(0.0),
        created_at: item
            .get("created_at")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        updated_at: item
            .get("updated_at")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
    }
}

pub async fn get_portfolio(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .query()
        .table_name("ovaflus-portfolio")
        .key_condition_expression("user_id = :uid")
        .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
        .send()
        .await;

    match result {
        Ok(output) => {
            let holdings: Vec<Holding> = output
                .items
                .unwrap_or_default()
                .iter()
                .map(item_to_holding)
                .collect();
            (
                StatusCode::OK,
                Json(serde_json::to_value(holdings).unwrap()),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Database error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn add_holding(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Json(body): Json<AddHoldingRequest>,
) -> impl IntoResponse {
    let holding_id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();

    let result = state
        .dynamo
        .put_item()
        .table_name("ovaflus-portfolio")
        .item("user_id", AttributeValue::S(claims.sub.clone()))
        .item("holding_id", AttributeValue::S(holding_id.clone()))
        .item("symbol", AttributeValue::S(body.symbol.clone()))
        .item("shares", AttributeValue::N(body.shares.to_string()))
        .item("avg_cost", AttributeValue::N(body.avg_cost.to_string()))
        .item("created_at", AttributeValue::S(now.clone()))
        .item("updated_at", AttributeValue::S(now.clone()))
        .send()
        .await;

    match result {
        Ok(_) => {
            let holding = Holding {
                holding_id,
                user_id: claims.sub,
                symbol: body.symbol,
                shares: body.shares,
                avg_cost: body.avg_cost,
                created_at: now.clone(),
                updated_at: now,
            };
            (
                StatusCode::CREATED,
                Json(serde_json::to_value(holding).unwrap()),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Failed to add holding: {}", e))),
        )
            .into_response(),
    }
}

pub async fn update_holding(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Path(holding_id): Path<String>,
    Json(body): Json<UpdateHoldingRequest>,
) -> impl IntoResponse {
    let mut update_parts: Vec<String> = Vec::new();
    let mut expr_values: Vec<(String, AttributeValue)> = Vec::new();

    if let Some(shares) = body.shares {
        update_parts.push("shares = :shares".to_string());
        expr_values.push((":shares".to_string(), AttributeValue::N(shares.to_string())));
    }
    if let Some(avg_cost) = body.avg_cost {
        update_parts.push("avg_cost = :avg_cost".to_string());
        expr_values.push((
            ":avg_cost".to_string(),
            AttributeValue::N(avg_cost.to_string()),
        ));
    }

    if update_parts.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("No fields to update")),
        )
            .into_response();
    }

    update_parts.push("updated_at = :updated_at".to_string());
    expr_values.push((
        ":updated_at".to_string(),
        AttributeValue::S(Utc::now().to_rfc3339()),
    ));

    let update_expression = format!("SET {}", update_parts.join(", "));

    let mut update = state
        .dynamo
        .update_item()
        .table_name("ovaflus-portfolio")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("holding_id", AttributeValue::S(holding_id))
        .update_expression(&update_expression)
        .return_values(aws_sdk_dynamodb::types::ReturnValue::AllNew);

    for (k, v) in expr_values {
        update = update.expression_attribute_values(k, v);
    }

    match update.send().await {
        Ok(output) => {
            let item = output.attributes.unwrap_or_default();
            let holding = item_to_holding(&item);
            (StatusCode::OK, Json(serde_json::to_value(holding).unwrap())).into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Update failed: {}", e))),
        )
            .into_response(),
    }
}

pub async fn delete_holding(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Path(holding_id): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .delete_item()
        .table_name("ovaflus-portfolio")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("holding_id", AttributeValue::S(holding_id))
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
