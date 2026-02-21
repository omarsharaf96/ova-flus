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
pub struct Goal {
    pub goal_id: String,
    pub user_id: String,
    pub name: String,
    pub target_amount: f64,
    pub current_amount: f64,
    pub deadline: Option<String>,
    pub category: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Deserialize)]
pub struct CreateGoalRequest {
    pub name: String,
    pub target_amount: f64,
    pub deadline: Option<String>,
    pub category: Option<String>,
}

#[derive(Deserialize)]
pub struct UpdateGoalRequest {
    pub name: Option<String>,
    pub target_amount: Option<f64>,
    pub current_amount: Option<f64>,
    pub deadline: Option<String>,
    pub category: Option<String>,
}

fn item_to_goal(item: &std::collections::HashMap<String, AttributeValue>) -> Goal {
    Goal {
        goal_id: item
            .get("goal_id")
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
        target_amount: item
            .get("target_amount")
            .and_then(|v| v.as_n().ok())
            .and_then(|n| n.parse::<f64>().ok())
            .unwrap_or(0.0),
        current_amount: item
            .get("current_amount")
            .and_then(|v| v.as_n().ok())
            .and_then(|n| n.parse::<f64>().ok())
            .unwrap_or(0.0),
        deadline: item.get("deadline").and_then(|v| v.as_s().ok()).cloned(),
        category: item.get("category").and_then(|v| v.as_s().ok()).cloned(),
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

pub async fn list_goals(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .query()
        .table_name("ovaflus-goals")
        .key_condition_expression("user_id = :uid")
        .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
        .send()
        .await;

    match result {
        Ok(output) => {
            let goals: Vec<Goal> = output
                .items
                .unwrap_or_default()
                .iter()
                .map(item_to_goal)
                .collect();
            (StatusCode::OK, Json(serde_json::to_value(goals).unwrap())).into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Database error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn create_goal(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateGoalRequest>,
) -> impl IntoResponse {
    let goal_id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();

    let mut put = state
        .dynamo
        .put_item()
        .table_name("ovaflus-goals")
        .item("user_id", AttributeValue::S(claims.sub.clone()))
        .item("goal_id", AttributeValue::S(goal_id.clone()))
        .item("name", AttributeValue::S(body.name.clone()))
        .item(
            "target_amount",
            AttributeValue::N(body.target_amount.to_string()),
        )
        .item("current_amount", AttributeValue::N("0".to_string()))
        .item("created_at", AttributeValue::S(now.clone()))
        .item("updated_at", AttributeValue::S(now.clone()));

    if let Some(ref deadline) = body.deadline {
        put = put.item("deadline", AttributeValue::S(deadline.clone()));
    }
    if let Some(ref category) = body.category {
        put = put.item("category", AttributeValue::S(category.clone()));
    }

    match put.send().await {
        Ok(_) => {
            let goal = Goal {
                goal_id,
                user_id: claims.sub,
                name: body.name,
                target_amount: body.target_amount,
                current_amount: 0.0,
                deadline: body.deadline,
                category: body.category,
                created_at: now.clone(),
                updated_at: now,
            };
            (
                StatusCode::CREATED,
                Json(serde_json::to_value(goal).unwrap()),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Failed to create goal: {}", e))),
        )
            .into_response(),
    }
}

pub async fn get_goal(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(goal_id): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .get_item()
        .table_name("ovaflus-goals")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("goal_id", AttributeValue::S(goal_id))
        .send()
        .await;

    match result {
        Ok(output) => match output.item {
            Some(item) => {
                let goal = item_to_goal(&item);
                (StatusCode::OK, Json(serde_json::to_value(goal).unwrap())).into_response()
            }
            None => (StatusCode::NOT_FOUND, Json(ApiError::new("Goal not found"))).into_response(),
        },
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Database error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn update_goal(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(goal_id): Path<String>,
    Json(body): Json<UpdateGoalRequest>,
) -> impl IntoResponse {
    let mut update_parts: Vec<String> = Vec::new();
    let mut expr_values: Vec<(String, AttributeValue)> = Vec::new();
    let mut expr_names: Vec<(String, String)> = Vec::new();

    if let Some(ref name) = body.name {
        update_parts.push("#n = :name".to_string());
        expr_values.push((":name".to_string(), AttributeValue::S(name.clone())));
        expr_names.push(("#n".to_string(), "name".to_string()));
    }
    if let Some(target_amount) = body.target_amount {
        update_parts.push("target_amount = :target".to_string());
        expr_values.push((
            ":target".to_string(),
            AttributeValue::N(target_amount.to_string()),
        ));
    }
    if let Some(current_amount) = body.current_amount {
        update_parts.push("current_amount = :current".to_string());
        expr_values.push((
            ":current".to_string(),
            AttributeValue::N(current_amount.to_string()),
        ));
    }
    if let Some(ref deadline) = body.deadline {
        update_parts.push("deadline = :deadline".to_string());
        expr_values.push((":deadline".to_string(), AttributeValue::S(deadline.clone())));
    }
    if let Some(ref category) = body.category {
        update_parts.push("category = :category".to_string());
        expr_values.push((":category".to_string(), AttributeValue::S(category.clone())));
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
        .table_name("ovaflus-goals")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("goal_id", AttributeValue::S(goal_id))
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
            let goal = item_to_goal(&item);
            (StatusCode::OK, Json(serde_json::to_value(goal).unwrap())).into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Update failed: {}", e))),
        )
            .into_response(),
    }
}

pub async fn delete_goal(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(goal_id): Path<String>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .delete_item()
        .table_name("ovaflus-goals")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("goal_id", AttributeValue::S(goal_id))
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
