use std::sync::Arc;

use aws_sdk_dynamodb::types::AttributeValue;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Extension, Json,
};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::{ApiError, Claims};
use crate::AppState;

#[derive(Serialize, Deserialize)]
pub struct Budget {
    pub budget_id: String,
    pub user_id: String,
    pub name: String,
    pub category: String,
    pub amount: f64,
    pub spent: f64,
    pub period: String,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Deserialize)]
pub struct CreateBudgetRequest {
    pub name: String,
    pub category: String,
    pub amount: f64,
    pub period: String,
}

#[derive(Deserialize)]
pub struct UpdateBudgetRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub period: Option<String>,
}

fn item_to_budget(item: &std::collections::HashMap<String, AttributeValue>) -> Budget {
    Budget {
        budget_id: item
            .get("budget_id")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        user_id: item
            .get("user_id")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        name: item
            .get("name")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        category: item
            .get("category")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        amount: item
            .get("amount")
            .and_then(|v| v.as_n().ok())
            .and_then(|n| n.parse::<f64>().ok())
            .unwrap_or(0.0),
        spent: item
            .get("spent")
            .and_then(|v| v.as_n().ok())
            .and_then(|n| n.parse::<f64>().ok())
            .unwrap_or(0.0),
        period: item
            .get("period")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
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

pub async fn list_budgets(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .query()
        .table_name("ovaflus-budgets")
        .key_condition_expression("user_id = :uid")
        .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
        .send()
        .await;

    match result {
        Ok(output) => {
            let budgets: Vec<Budget> = output
                .items
                .unwrap_or_default()
                .iter()
                .map(item_to_budget)
                .collect();
            (StatusCode::OK, Json(serde_json::to_value(budgets).unwrap())).into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Database error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn create_budget(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateBudgetRequest>,
) -> impl IntoResponse {
    let budget_id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();

    let result = state
        .dynamo
        .put_item()
        .table_name("ovaflus-budgets")
        .item("user_id", AttributeValue::S(claims.sub.clone()))
        .item("budget_id", AttributeValue::S(budget_id.clone()))
        .item("name", AttributeValue::S(body.name.clone()))
        .item("category", AttributeValue::S(body.category.clone()))
        .item("amount", AttributeValue::N(body.amount.to_string()))
        .item("spent", AttributeValue::N("0".to_string()))
        .item("period", AttributeValue::S(body.period.clone()))
        .item("created_at", AttributeValue::S(now.clone()))
        .item("updated_at", AttributeValue::S(now.clone()))
        .send()
        .await;

    match result {
        Ok(_) => {
            let budget = Budget {
                budget_id,
                user_id: claims.sub,
                name: body.name,
                category: body.category,
                amount: body.amount,
                spent: 0.0,
                period: body.period,
                created_at: now.clone(),
                updated_at: now,
            };
            (
                StatusCode::CREATED,
                Json(serde_json::to_value(budget).unwrap()),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Failed to create budget: {}", e))),
        )
            .into_response(),
    }
}

pub async fn get_budget(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(budget_id): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .get_item()
        .table_name("ovaflus-budgets")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("budget_id", AttributeValue::S(budget_id))
        .send()
        .await;

    match result {
        Ok(output) => match output.item {
            Some(item) => {
                let budget = item_to_budget(&item);
                (StatusCode::OK, Json(serde_json::to_value(budget).unwrap())).into_response()
            }
            None => (
                StatusCode::NOT_FOUND,
                Json(ApiError::new("Budget not found")),
            )
                .into_response(),
        },
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Database error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn update_budget(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(budget_id): Path<String>,
    Json(body): Json<UpdateBudgetRequest>,
) -> impl IntoResponse {
    let mut update_parts: Vec<String> = Vec::new();
    let mut expr_values: Vec<(String, AttributeValue)> = Vec::new();
    let mut expr_names: Vec<(String, String)> = Vec::new();

    if let Some(ref name) = body.name {
        update_parts.push("#n = :name".to_string());
        expr_values.push((":name".to_string(), AttributeValue::S(name.clone())));
        expr_names.push(("#n".to_string(), "name".to_string()));
    }
    if let Some(ref category) = body.category {
        update_parts.push("category = :category".to_string());
        expr_values.push((":category".to_string(), AttributeValue::S(category.clone())));
    }
    if let Some(amount) = body.amount {
        update_parts.push("amount = :amount".to_string());
        expr_values.push((":amount".to_string(), AttributeValue::N(amount.to_string())));
    }
    if let Some(ref period) = body.period {
        update_parts.push("period = :period".to_string());
        expr_values.push((":period".to_string(), AttributeValue::S(period.clone())));
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
        .table_name("ovaflus-budgets")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("budget_id", AttributeValue::S(budget_id))
        .update_expression(&update_expression)
        .return_values(aws_sdk_dynamodb::types::ReturnValue::AllNew);

    for (k, v) in expr_values {
        update = update.expression_attribute_values(k, v);
    }
    for (k, v) in expr_names {
        update = update.expression_attribute_names(k, v);
    }

    match update.send().await {
        Ok(output) => {
            let item = output.attributes.unwrap_or_default();
            let budget = item_to_budget(&item);
            (StatusCode::OK, Json(serde_json::to_value(budget).unwrap())).into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Update failed: {}", e))),
        )
            .into_response(),
    }
}

pub async fn delete_budget(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(budget_id): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .delete_item()
        .table_name("ovaflus-budgets")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("budget_id", AttributeValue::S(budget_id))
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
