mod db;
mod handlers;
mod middleware;
mod models;

#[cfg(test)]
mod tests;

use std::sync::Arc;

use aws_sdk_dynamodb::Client as DynamoClient;
use aws_sdk_ssm::Client as SsmClient;
use axum::{
    routing::{delete, get, post, put},
    Router,
};
use lambda_http::run;
use tracing_subscriber::EnvFilter;

#[derive(Clone)]
pub struct AppState {
    pub dynamo: DynamoClient,
    pub jwt_secret: String,
    pub plaid_client_id: String,
    pub plaid_secret: String,
    pub plaid_env: String,
    pub finnhub_api_key: String,
}

async fn load_ssm_param(ssm: &SsmClient, name: &str) -> String {
    ssm.get_parameter()
        .name(name)
        .with_decryption(true)
        .send()
        .await
        .unwrap_or_else(|e| panic!("Failed to load SSM param {name}: {e}"))
        .parameter
        .expect("SSM parameter missing")
        .value
        .expect("SSM parameter value missing")
}

#[tokio::main]
async fn main() -> Result<(), lambda_http::Error> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .json()
        .init();

    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let dynamo = DynamoClient::new(&config);
    let ssm = SsmClient::new(&config);

    let prefix = std::env::var("SSM_PREFIX").unwrap_or_else(|_| "/ovaflus/prod".to_string());

    let state = AppState {
        dynamo,
        jwt_secret: load_ssm_param(&ssm, &format!("{prefix}/jwt-secret")).await,
        plaid_client_id: load_ssm_param(&ssm, &format!("{prefix}/plaid-client-id")).await,
        plaid_secret: load_ssm_param(&ssm, &format!("{prefix}/plaid-secret")).await,
        plaid_env: load_ssm_param(&ssm, &format!("{prefix}/plaid-env")).await,
        finnhub_api_key: load_ssm_param(&ssm, &format!("{prefix}/finnhub-api-key")).await,
    };

    let state = Arc::new(state);

    let app = Router::new()
        // Auth (public)
        .route("/auth/signup", post(handlers::auth::sign_up))
        .route("/auth/signin", post(handlers::auth::sign_in))
        .route("/auth/refresh", post(handlers::auth::refresh_token))
        // Profile
        .route("/profile", get(handlers::profile::get_profile))
        .route("/profile", put(handlers::profile::update_profile))
        // Budgets
        .route("/budgets", get(handlers::budgets::list_budgets))
        .route("/budgets", post(handlers::budgets::create_budget))
        .route("/budgets/:id", get(handlers::budgets::get_budget))
        .route("/budgets/:id", put(handlers::budgets::update_budget))
        .route("/budgets/:id", delete(handlers::budgets::delete_budget))
        // Transactions
        .route(
            "/transactions",
            get(handlers::transactions::list_transactions),
        )
        .route(
            "/transactions",
            post(handlers::transactions::create_transaction),
        )
        .route(
            "/transactions/:id",
            get(handlers::transactions::get_transaction),
        )
        .route(
            "/transactions/:id",
            put(handlers::transactions::update_transaction),
        )
        .route(
            "/transactions/:id",
            delete(handlers::transactions::delete_transaction),
        )
        // Portfolio
        .route("/portfolio", get(handlers::portfolio::get_portfolio))
        .route(
            "/portfolio/holdings",
            post(handlers::portfolio::add_holding),
        )
        .route(
            "/portfolio/holdings/:id",
            put(handlers::portfolio::update_holding),
        )
        .route(
            "/portfolio/holdings/:id",
            delete(handlers::portfolio::delete_holding),
        )
        // Stocks
        .route("/stocks/search", get(handlers::stocks::search_stocks))
        .route("/stocks/:symbol", get(handlers::stocks::get_stock))
        .route(
            "/stocks/:symbol/news",
            get(handlers::stocks::get_stock_news),
        )
        // Watchlist
        .route("/watchlist", get(handlers::watchlist::get_watchlist))
        .route("/watchlist", post(handlers::watchlist::add_to_watchlist))
        .route(
            "/watchlist/:symbol",
            delete(handlers::watchlist::remove_from_watchlist),
        )
        // Goals
        .route("/goals", get(handlers::goals::list_goals))
        .route("/goals", post(handlers::goals::create_goal))
        .route("/goals/:id", get(handlers::goals::get_goal))
        .route("/goals/:id", put(handlers::goals::update_goal))
        .route("/goals/:id", delete(handlers::goals::delete_goal))
        // Plaid
        .route(
            "/plaid/link-token",
            post(handlers::plaid::create_link_token),
        )
        .route(
            "/plaid/exchange-token",
            post(handlers::plaid::exchange_token),
        )
        .route("/plaid/accounts", get(handlers::plaid::get_accounts))
        .route("/plaid/sync", post(handlers::plaid::sync_transactions))
        .route(
            "/plaid/accounts/:item_id",
            delete(handlers::plaid::unlink_account),
        )
        .with_state(state);

    run(app).await
}
