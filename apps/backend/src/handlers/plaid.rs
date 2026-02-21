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

use crate::models::{ApiError, Claims};
use crate::AppState;

fn plaid_base_url(env: &str) -> String {
    format!("https://{}.plaid.com", env)
}

#[derive(Serialize)]
#[allow(dead_code)]
struct PlaidAuth {
    client_id: String,
    secret: String,
}

// --- Create Link Token ---

#[derive(Serialize)]
struct CreateLinkTokenBody {
    client_id: String,
    secret: String,
    user: PlaidUser,
    client_name: String,
    products: Vec<String>,
    country_codes: Vec<String>,
    language: String,
}

#[derive(Serialize)]
struct PlaidUser {
    client_user_id: String,
}

#[derive(Serialize)]
pub struct LinkTokenResponse {
    pub link_token: String,
}

pub async fn create_link_token(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> impl IntoResponse {
    let client = reqwest::Client::new();
    let base = plaid_base_url(&state.plaid_env);

    let body = CreateLinkTokenBody {
        client_id: state.plaid_client_id.clone(),
        secret: state.plaid_secret.clone(),
        user: PlaidUser {
            client_user_id: claims.sub.clone(),
        },
        client_name: "Flus".to_string(),
        products: vec!["transactions".to_string()],
        country_codes: vec!["US".to_string()],
        language: "en".to_string(),
    };

    let result = client
        .post(format!("{}/link/token/create", base))
        .json(&body)
        .send()
        .await;

    match result {
        Ok(resp) => match resp.json::<serde_json::Value>().await {
            Ok(data) => {
                if let Some(link_token) = data.get("link_token").and_then(|v| v.as_str()) {
                    (
                        StatusCode::OK,
                        Json(LinkTokenResponse {
                            link_token: link_token.to_string(),
                        }),
                    )
                        .into_response()
                } else {
                    (
                        StatusCode::BAD_GATEWAY,
                        Json(ApiError::new(format!(
                            "Plaid error: {}",
                            serde_json::to_string(&data).unwrap_or_default()
                        ))),
                    )
                        .into_response()
                }
            }
            Err(e) => (
                StatusCode::BAD_GATEWAY,
                Json(ApiError::new(format!(
                    "Failed to parse Plaid response: {}",
                    e
                ))),
            )
                .into_response(),
        },
        Err(e) => (
            StatusCode::BAD_GATEWAY,
            Json(ApiError::new(format!("Plaid request failed: {}", e))),
        )
            .into_response(),
    }
}

// --- Exchange Token ---

#[derive(Deserialize)]
pub struct PlaidAccountInfo {
    pub id: String,
    pub name: String,
    pub subtype: String,
    pub mask: Option<String>,
}

#[derive(Deserialize)]
pub struct ExchangeTokenRequest {
    pub public_token: String,
    pub institution_id: String,
    pub institution_name: String,
    #[serde(default)]
    pub accounts: Vec<PlaidAccountInfo>,
}

#[derive(Serialize)]
struct ExchangeTokenBody {
    client_id: String,
    secret: String,
    public_token: String,
}

pub async fn exchange_token(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<ExchangeTokenRequest>,
) -> impl IntoResponse {
    let client = reqwest::Client::new();
    let base = plaid_base_url(&state.plaid_env);

    let exchange_body = ExchangeTokenBody {
        client_id: state.plaid_client_id.clone(),
        secret: state.plaid_secret.clone(),
        public_token: body.public_token.clone(),
    };

    let result = client
        .post(format!("{}/item/public_token/exchange", base))
        .json(&exchange_body)
        .send()
        .await;

    let plaid_resp = match result {
        Ok(resp) => match resp.json::<serde_json::Value>().await {
            Ok(data) => data,
            Err(e) => {
                return (
                    StatusCode::BAD_GATEWAY,
                    Json(ApiError::new(format!(
                        "Failed to parse Plaid response: {}",
                        e
                    ))),
                )
                    .into_response();
            }
        },
        Err(e) => {
            return (
                StatusCode::BAD_GATEWAY,
                Json(ApiError::new(format!("Plaid request failed: {}", e))),
            )
                .into_response();
        }
    };

    let access_token = match plaid_resp.get("access_token").and_then(|v| v.as_str()) {
        Some(t) => t.to_string(),
        None => {
            return (
                StatusCode::BAD_GATEWAY,
                Json(ApiError::new(format!(
                    "Plaid error: {}",
                    serde_json::to_string(&plaid_resp).unwrap_or_default()
                ))),
            )
                .into_response();
        }
    };

    let item_id = plaid_resp
        .get("item_id")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();

    let now = Utc::now().to_rfc3339();

    // Store Plaid item in DynamoDB (for access_token lookup)
    let put_result = state
        .dynamo
        .put_item()
        .table_name("ovaflus-plaid-items")
        .item("user_id", AttributeValue::S(claims.sub.clone()))
        .item("item_id", AttributeValue::S(item_id.clone()))
        .item("access_token", AttributeValue::S(access_token))
        .item(
            "institution_id",
            AttributeValue::S(body.institution_id.clone()),
        )
        .item(
            "institution_name",
            AttributeValue::S(body.institution_name.clone()),
        )
        .item("created_at", AttributeValue::S(now.clone()))
        .send()
        .await;

    if let Err(e) = put_result {
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Failed to store Plaid item: {}", e))),
        )
            .into_response();
    }

    // Store each account in ovaflus-plaid-accounts table
    let mut response_accounts: Vec<serde_json::Value> = Vec::new();
    for account in &body.accounts {
        let acct_put = state
            .dynamo
            .put_item()
            .table_name("ovaflus-plaid-accounts")
            .item("user_id", AttributeValue::S(claims.sub.clone()))
            .item("account_id", AttributeValue::S(account.id.clone()))
            .item("item_id", AttributeValue::S(item_id.clone()))
            .item(
                "institution_id",
                AttributeValue::S(body.institution_id.clone()),
            )
            .item(
                "institution_name",
                AttributeValue::S(body.institution_name.clone()),
            )
            .item("account_name", AttributeValue::S(account.name.clone()))
            .item("account_type", AttributeValue::S(account.subtype.clone()))
            .item(
                "mask",
                AttributeValue::S(account.mask.clone().unwrap_or_default()),
            )
            .item("linked_at", AttributeValue::S(now.clone()))
            .send()
            .await;

        if let Err(e) = acct_put {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new(format!(
                    "Failed to store Plaid account: {}",
                    e
                ))),
            )
                .into_response();
        }

        response_accounts.push(serde_json::json!({
            "id": account.id,
            "name": account.name,
            "type": account.subtype,
            "mask": account.mask,
        }));
    }

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "item_id": item_id,
            "institution_id": body.institution_id,
            "institution_name": body.institution_name,
            "accounts": response_accounts,
        })),
    )
        .into_response()
}

// --- Get Accounts ---

#[derive(Serialize)]
pub struct LinkedAccount {
    pub id: String,
    pub institution_id: String,
    pub institution_name: String,
    pub account_name: String,
    pub account_type: String,
    pub mask: String,
    pub linked_at: String,
}

pub async fn get_accounts(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> impl IntoResponse {
    let result = state
        .dynamo
        .query()
        .table_name("ovaflus-plaid-accounts")
        .key_condition_expression("user_id = :uid")
        .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
        .send()
        .await;

    match result {
        Ok(output) => {
            let accounts: Vec<LinkedAccount> = output
                .items
                .unwrap_or_default()
                .iter()
                .map(|item| LinkedAccount {
                    id: item
                        .get("account_id")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    institution_id: item
                        .get("institution_id")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    institution_name: item
                        .get("institution_name")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    account_name: item
                        .get("account_name")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    account_type: item
                        .get("account_type")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    mask: item
                        .get("mask")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                    linked_at: item
                        .get("linked_at")
                        .and_then(|v| v.as_s().ok())
                        .cloned()
                        .unwrap_or_default(),
                })
                .collect();
            (
                StatusCode::OK,
                Json(serde_json::to_value(accounts).unwrap()),
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

// --- Sync Transactions ---

#[derive(Serialize)]
struct TransactionsSyncBody {
    client_id: String,
    secret: String,
    access_token: String,
}

pub async fn sync_transactions(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> impl IntoResponse {
    let client = reqwest::Client::new();
    let base = plaid_base_url(&state.plaid_env);

    // Get all plaid items for this user
    let items_result = state
        .dynamo
        .query()
        .table_name("ovaflus-plaid-items")
        .key_condition_expression("user_id = :uid")
        .expression_attribute_values(":uid", AttributeValue::S(claims.sub.clone()))
        .send()
        .await;

    let items = match items_result {
        Ok(output) => output.items.unwrap_or_default(),
        Err(e) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new(format!("Database error: {}", e))),
            )
                .into_response();
        }
    };

    let mut all_transactions: Vec<serde_json::Value> = Vec::new();
    let mut total_added: usize = 0;
    let mut total_modified: usize = 0;

    for item in &items {
        let access_token = match item.get("access_token").and_then(|v| v.as_s().ok()) {
            Some(t) => t.clone(),
            None => continue,
        };

        let sync_body = TransactionsSyncBody {
            client_id: state.plaid_client_id.clone(),
            secret: state.plaid_secret.clone(),
            access_token,
        };

        let result = client
            .post(format!("{}/transactions/sync", base))
            .json(&sync_body)
            .send()
            .await;

        if let Ok(resp) = result {
            if let Ok(data) = resp.json::<serde_json::Value>().await {
                if let Some(added) = data.get("added").and_then(|v| v.as_array()) {
                    total_added += added.len();
                    for txn in added {
                        all_transactions.push(map_plaid_transaction(txn));
                    }
                }
                if let Some(modified) = data.get("modified").and_then(|v| v.as_array()) {
                    total_modified += modified.len();
                    for txn in modified {
                        all_transactions.push(map_plaid_transaction(txn));
                    }
                }
            }
        }
    }

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "transactions": all_transactions,
            "added": total_added,
            "modified": total_modified,
        })),
    )
        .into_response()
}

fn map_plaid_transaction(txn: &serde_json::Value) -> serde_json::Value {
    let category = txn
        .get("category")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str().map(String::from))
                .collect::<Vec<String>>()
        })
        .unwrap_or_default();

    serde_json::json!({
        "id": txn.get("transaction_id").and_then(|v| v.as_str()).unwrap_or(""),
        "account_id": txn.get("account_id").and_then(|v| v.as_str()).unwrap_or(""),
        "name": txn.get("name").and_then(|v| v.as_str()).unwrap_or(""),
        "amount": txn.get("amount").and_then(|v| v.as_f64()).unwrap_or(0.0),
        "date": txn.get("date").and_then(|v| v.as_str()).unwrap_or(""),
        "category": category,
        "pending": txn.get("pending").and_then(|v| v.as_bool()).unwrap_or(false),
    })
}

// --- Unlink Account ---

#[derive(Serialize)]
struct ItemRemoveBody {
    client_id: String,
    secret: String,
    access_token: String,
}

pub async fn unlink_account(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(item_id): Path<String>,
) -> impl IntoResponse {
    let client = reqwest::Client::new();
    let base = plaid_base_url(&state.plaid_env);

    // Get the access token from DynamoDB
    let get_result = state
        .dynamo
        .get_item()
        .table_name("ovaflus-plaid-items")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("item_id", AttributeValue::S(item_id.clone()))
        .send()
        .await;

    let access_token = match get_result {
        Ok(output) => match output.item {
            Some(item) => match item.get("access_token").and_then(|v| v.as_s().ok()) {
                Some(t) => t.clone(),
                None => {
                    return (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(ApiError::new("Missing access token")),
                    )
                        .into_response();
                }
            },
            None => {
                return (
                    StatusCode::NOT_FOUND,
                    Json(ApiError::new("Plaid item not found")),
                )
                    .into_response();
            }
        },
        Err(e) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new(format!("Database error: {}", e))),
            )
                .into_response();
        }
    };

    // Remove from Plaid
    let remove_body = ItemRemoveBody {
        client_id: state.plaid_client_id.clone(),
        secret: state.plaid_secret.clone(),
        access_token,
    };

    let _ = client
        .post(format!("{}/item/remove", base))
        .json(&remove_body)
        .send()
        .await;

    // Delete from DynamoDB
    let delete_result = state
        .dynamo
        .delete_item()
        .table_name("ovaflus-plaid-items")
        .key("user_id", AttributeValue::S(claims.sub.clone()))
        .key("item_id", AttributeValue::S(item_id))
        .send()
        .await;

    match delete_result {
        Ok(_) => StatusCode::NO_CONTENT.into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new(format!("Failed to delete item: {}", e))),
        )
            .into_response(),
    }
}
