use std::sync::Arc;

use aws_sdk_dynamodb::types::AttributeValue;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Extension, Json};
use serde::{Deserialize, Serialize};

use crate::models::{ApiError, Claims};
use crate::AppState;

#[derive(Serialize)]
pub struct UserProfile {
    pub user_id: String,
    pub email: String,
    pub name: String,
    pub created_at: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub currency: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notifications_enabled: Option<bool>,
}

#[derive(Deserialize)]
pub struct UpdateProfileRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub currency: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notifications_enabled: Option<bool>,
}

pub async fn get_profile(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .get_item()
        .table_name("ovaflus-users")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .send()
        .await;

    match result {
        Ok(output) => match output.item {
            Some(item) => {
                let profile = UserProfile {
                    user_id: item
                        .get("user_id")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    email: item
                        .get("email")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    name: item
                        .get("name")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    created_at: item
                        .get("created_at")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    currency: item.get("currency").and_then(|v| v.as_s().ok()).cloned(),
                    notifications_enabled: item
                        .get("notifications_enabled")
                        .and_then(|v| v.as_bool().ok())
                        .copied(),
                };
                (StatusCode::OK, Json(serde_json::to_value(profile).unwrap())).into_response()
            }
            None => (StatusCode::NOT_FOUND, Json(ApiError::new("User not found"))).into_response(),
        },
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Database error: {}", e))),
        )
            .into_response(),
    }
}

pub async fn update_profile(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<UpdateProfileRequest>,
) -> impl IntoResponse {
    let mut update_expr_parts: Vec<String> = Vec::new();
    let mut expr_attr_values: Vec<(String, AttributeValue)> = Vec::new();
    let mut expr_attr_names: Vec<(String, String)> = Vec::new();

    if let Some(ref name) = body.name {
        update_expr_parts.push("#n = :name".to_string());
        expr_attr_values.push((":name".to_string(), AttributeValue::S(name.clone())));
        expr_attr_names.push(("#n".to_string(), "name".to_string()));
    }

    if let Some(ref currency) = body.currency {
        update_expr_parts.push("currency = :currency".to_string());
        expr_attr_values.push((":currency".to_string(), AttributeValue::S(currency.clone())));
    }

    if let Some(notifications_enabled) = body.notifications_enabled {
        update_expr_parts.push("notifications_enabled = :notif".to_string());
        expr_attr_values.push((
            ":notif".to_string(),
            AttributeValue::Bool(notifications_enabled),
        ));
    }

    if update_expr_parts.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("No fields to update")),
        )
            .into_response();
    }

    let update_expr_parts_with_timestamp = {
        let mut parts = update_expr_parts;
        parts.push("updated_at = :updated_at".to_string());
        expr_attr_values.push((
            ":updated_at".to_string(),
            AttributeValue::S(chrono::Utc::now().to_rfc3339()),
        ));
        parts
    };

    let update_expression = format!("SET {}", update_expr_parts_with_timestamp.join(", "));

    let mut update = state
        .dynamo
        .update_item()
        .table_name("ovaflus-users")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .update_expression(&update_expression)
        .return_values(aws_sdk_dynamodb::types::ReturnValue::AllNew);

    for (k, v) in expr_attr_values {
        update = update.expression_attribute_values(k, v);
    }
    for (k, v) in expr_attr_names {
        update = update.expression_attribute_names(k, v);
    }

    match update.send().await {
        Ok(output) => {
            let item = output.attributes.unwrap_or_default();
            let profile = UserProfile {
                user_id: item
                    .get("user_id")
                    .and_then(|v| v.as_s().ok())
                    .cloned()
                    .unwrap_or_default(),
                email: item
                    .get("email")
                    .and_then(|v| v.as_s().ok())
                    .cloned()
                    .unwrap_or_default(),
                name: item
                    .get("name")
                    .and_then(|v| v.as_s().ok())
                    .cloned()
                    .unwrap_or_default(),
                created_at: item
                    .get("created_at")
                    .and_then(|v| v.as_s().ok())
                    .cloned()
                    .unwrap_or_default(),
                currency: item.get("currency").and_then(|v| v.as_s().ok()).cloned(),
                notifications_enabled: item
                    .get("notifications_enabled")
                    .and_then(|v| v.as_bool().ok())
                    .copied(),
            };
            (StatusCode::OK, Json(serde_json::to_value(profile).unwrap())).into_response()
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Update failed: {}", e))),
        )
            .into_response(),
    }
}
