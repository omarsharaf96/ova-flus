use std::sync::Arc;

use aws_sdk_dynamodb::types::AttributeValue;
use axum::{
    extract::{Path, Query, State},
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
pub struct Transaction {
    pub transaction_id: String,
    pub user_id: String,
    pub budget_id: String,
    pub amount: f64,
    pub description: String,
    pub category: String,
    pub date: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub plaid_transaction_id: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Deserialize)]
pub struct CreateTransactionRequest {
    pub budget_id: String,
    pub amount: f64,
    pub description: String,
    pub category: String,
    pub date: String,
}

#[derive(Deserialize)]
pub struct UpdateTransactionRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub date: Option<String>,
}

#[derive(Deserialize)]
pub struct ListTransactionsQuery {
    pub budget_id: Option<String>,
}

fn item_to_transaction(item: &std::collections::HashMap<String, AttributeValue>) -> Transaction {
    Transaction {
        transaction_id: item
            .get("transaction_id")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        user_id: item
            .get("user_id")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        budget_id: item
            .get("budget_id")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        amount: item
            .get("amount")
            .and_then(|v| v.as_n().ok())
            .and_then(|n| n.parse::<f64>().ok())
            .unwrap_or(0.0),
        description: item
            .get("description")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        category: item
            .get("category")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        date: item
            .get("date")
            .and_then(|v| v.as_s().ok())
            .cloned()
            .unwrap_or_default(),
        plaid_transaction_id: item
            .get("plaid_transaction_id")
            .and_then(|v| v.as_s().ok())
            .cloned(),
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

pub async fn list_transactions(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Query(params): Query<ListTransactionsQuery>,
) -> impl IntoResponse {
    let result = if let Some(ref budget_id) = params.budget_id {
        state
            .dynamo
            .query()
            .table_name("ovaflus-transactions")
            .index_name("budget-index")
            .key_condition_expression("user_id = :uid AND budget_id = :bid")
            .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
            .expression_attribute_values(":bid", AttributeValue::S(budget_id.to_string()))
            .send()
            .await
    } else {
        state
            .dynamo
            .query()
            .table_name("ovaflus-transactions")
            .key_condition_expression("user_id = :uid")
            .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
            .send()
            .await
    };

    match result {
        Ok(output) => {
            let transactions: Vec<Transaction> = output
                .items
                .unwrap_or_default()
                .iter()
                .map(item_to_transaction)
                .collect();
            (
                StatusCode::OK,
                Json(serde_json::to_value(transactions).unwrap()),
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

pub async fn create_transaction(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Json(body): Json<CreateTransactionRequest>,
) -> impl IntoResponse {
    let transaction_id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();

    // Create transaction
    let put_result = state
        .dynamo
        .put_item()
        .table_name("ovaflus-transactions")
        .item("user_id", AttributeValue::S(claims.sub.clone()))
        .item("transaction_id", AttributeValue::S(transaction_id.clone()))
        .item("budget_id", AttributeValue::S(body.budget_id.clone()))
        .item("amount", AttributeValue::N(body.amount.to_string()))
        .item("description", AttributeValue::S(body.description.clone()))
        .item("category", AttributeValue::S(body.category.clone()))
        .item("date", AttributeValue::S(body.date.clone()))
        .item("created_at", AttributeValue::S(now.clone()))
        .item("updated_at", AttributeValue::S(now.clone()))
        .send()
        .await;

    if let Err(e) = put_result {
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!(
                "Failed to create transaction: {}",
                e
            ))),
        )
            .into_response();
    }

    // Update budget spent amount
    let _ = state
        .dynamo
        .update_item()
        .table_name("ovaflus-budgets")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("budget_id", AttributeValue::S(body.budget_id.clone()))
        .update_expression("SET spent = spent + :amount")
        .expression_attribute_values(":amount", AttributeValue::N(body.amount.to_string()))
        .send()
        .await;

    let transaction = Transaction {
        transaction_id,
        user_id: claims.sub,
        budget_id: body.budget_id,
        amount: body.amount,
        description: body.description,
        category: body.category,
        date: body.date,
        plaid_transaction_id: None,
        created_at: now.clone(),
        updated_at: now,
    };

    (
        StatusCode::CREATED,
        Json(serde_json::to_value(transaction).unwrap()),
    )
        .into_response()
}

pub async fn get_transaction(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Path(transaction_id): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .get_item()
        .table_name("ovaflus-transactions")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("transaction_id", AttributeValue::S(transaction_id))
        .send()
        .await;

    match result {
        Ok(output) => match output.item {
            Some(item) => {
                let transaction = item_to_transaction(&item);
                (
                    StatusCode::OK,
                    Json(serde_json::to_value(transaction).unwrap()),
                )
                    .into_response()
            }
            None => (
                StatusCode::NOT_FOUND,
                Json(ApiError::new("Transaction not found")),
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

pub async fn update_transaction(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Path(transaction_id): Path<String>,
    Json(body): Json<UpdateTransactionRequest>,
) -> impl IntoResponse {
    let mut update_parts: Vec<String> = Vec::new();
    let mut expr_values: Vec<(String, AttributeValue)> = Vec::new();

    if let Some(amount) = body.amount {
        update_parts.push("amount = :amount".to_string());
        expr_values.push((":amount".to_string(), AttributeValue::N(amount.to_string())));
    }
    if let Some(ref description) = body.description {
        update_parts.push("description = :desc".to_string());
        expr_values.push((":desc".to_string(), AttributeValue::S(description.clone())));
    }
    if let Some(ref category) = body.category {
        update_parts.push("category = :category".to_string());
        expr_values.push((":category".to_string(), AttributeValue::S(category.clone())));
    }
    if let Some(ref date) = body.date {
        update_parts.push("#d = :date".to_string());
        expr_values.push((":date".to_string(), AttributeValue::S(date.clone())));
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
        .table_name("ovaflus-transactions")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("transaction_id", AttributeValue::S(transaction_id))
        .update_expression(&update_expression)
        .return_values(aws_sdk_dynamodb::types::ReturnValue::AllNew);

    for (k, v) in expr_values {
        update = update.expression_attribute_values(k, v);
    }

    // Add expression attribute name for reserved word "date"
    if body.date.is_some() {
        update = update.expression_attribute_names("#d", "date");
    }

    match update.send().await {
        Ok(output) => {
            let item = output.attributes.unwrap_or_default();
            let transaction = item_to_transaction(&item);
            (
                StatusCode::OK,
                Json(serde_json::to_value(transaction).unwrap()),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Update failed: {}", e))),
        )
            .into_response(),
    }
}

pub async fn delete_transaction(
    State(state): State<Arc<AppState>>,
    AuthUser(claims): AuthUser,
    Path(transaction_id): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .delete_item()
        .table_name("ovaflus-transactions")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("transaction_id", AttributeValue::S(transaction_id))
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
