#![allow(dead_code)]

use std::collections::HashMap;

use aws_sdk_dynamodb::{types::AttributeValue, Client};

// ── Table Name Constants ──

pub const TABLE_USERS: &str = "ovaflus-users";
pub const TABLE_BUDGETS: &str = "ovaflus-budgets";
pub const TABLE_TRANSACTIONS: &str = "ovaflus-transactions";
pub const TABLE_PORTFOLIO: &str = "ovaflus-portfolio";
pub const TABLE_WATCHLIST: &str = "ovaflus-watchlist";
pub const TABLE_GOALS: &str = "ovaflus-goals";
pub const TABLE_PLAID_ITEMS: &str = "ovaflus-plaid-items";

// ── Helper: extract String from AttributeValue ──

pub fn attr_s(av: &AttributeValue) -> Option<&str> {
    av.as_s().ok().map(|s| s.as_str())
}

pub fn attr_n(av: &AttributeValue) -> Option<f64> {
    av.as_n().ok().and_then(|s| s.parse::<f64>().ok())
}

// ── Put Item ──

pub async fn put_item(
    client: &Client,
    table: &str,
    item: HashMap<String, AttributeValue>,
) -> Result<(), aws_sdk_dynamodb::Error> {
    client
        .put_item()
        .table_name(table)
        .set_item(Some(item))
        .send()
        .await?;
    Ok(())
}

// ── Get Item ──

pub async fn get_item(
    client: &Client,
    table: &str,
    pk: &str,
    pk_val: &str,
    sk: Option<(&str, &str)>,
) -> Result<Option<HashMap<String, AttributeValue>>, aws_sdk_dynamodb::Error> {
    let mut key = HashMap::new();
    key.insert(pk.to_string(), AttributeValue::S(pk_val.to_string()));
    if let Some((sk_name, sk_val)) = sk {
        key.insert(sk_name.to_string(), AttributeValue::S(sk_val.to_string()));
    }

    let result = client
        .get_item()
        .table_name(table)
        .set_key(Some(key))
        .send()
        .await?;

    Ok(result.item)
}

// ── Query by Partition Key ──

pub async fn query_by_pk(
    client: &Client,
    table: &str,
    pk: &str,
    pk_val: &str,
) -> Result<Vec<HashMap<String, AttributeValue>>, aws_sdk_dynamodb::Error> {
    let result = client
        .query()
        .table_name(table)
        .key_condition_expression("#pk = :pk_val")
        .expression_attribute_names("#pk", pk)
        .expression_attribute_values(":pk_val", AttributeValue::S(pk_val.to_string()))
        .send()
        .await?;

    Ok(result.items.unwrap_or_default())
}

// ── Delete Item ──

pub async fn delete_item(
    client: &Client,
    table: &str,
    pk: &str,
    pk_val: &str,
    sk: Option<(&str, &str)>,
) -> Result<(), aws_sdk_dynamodb::Error> {
    let mut key = HashMap::new();
    key.insert(pk.to_string(), AttributeValue::S(pk_val.to_string()));
    if let Some((sk_name, sk_val)) = sk {
        key.insert(sk_name.to_string(), AttributeValue::S(sk_val.to_string()));
    }

    client
        .delete_item()
        .table_name(table)
        .set_key(Some(key))
        .send()
        .await?;

    Ok(())
}

// ── Update Item ──

pub async fn update_item(
    client: &Client,
    table: &str,
    key: HashMap<String, AttributeValue>,
    updates: HashMap<String, AttributeValue>,
) -> Result<(), aws_sdk_dynamodb::Error> {
    if updates.is_empty() {
        return Ok(());
    }

    let mut expr_parts = Vec::new();
    let mut expr_names = HashMap::new();
    let mut expr_values = HashMap::new();

    for (i, (field, value)) in updates.iter().enumerate() {
        let name_placeholder = format!("#f{i}");
        let value_placeholder = format!(":v{i}");
        expr_parts.push(format!("{name_placeholder} = {value_placeholder}"));
        expr_names.insert(name_placeholder, field.clone());
        expr_values.insert(value_placeholder, value.clone());
    }

    let update_expression = format!("SET {}", expr_parts.join(", "));

    let mut req = client
        .update_item()
        .table_name(table)
        .set_key(Some(key))
        .update_expression(update_expression);

    for (k, v) in expr_names {
        req = req.expression_attribute_names(k, v);
    }
    for (k, v) in expr_values {
        req = req.expression_attribute_values(k, v);
    }

    req.send().await?;
    Ok(())
}

// ── Query with Index ──

pub async fn query_by_index(
    client: &Client,
    table: &str,
    index_name: &str,
    pk: &str,
    pk_val: &str,
) -> Result<Vec<HashMap<String, AttributeValue>>, aws_sdk_dynamodb::Error> {
    let result = client
        .query()
        .table_name(table)
        .index_name(index_name)
        .key_condition_expression("#pk = :pk_val")
        .expression_attribute_names("#pk", pk)
        .expression_attribute_values(":pk_val", AttributeValue::S(pk_val.to_string()))
        .send()
        .await?;

    Ok(result.items.unwrap_or_default())
}

#[cfg(test)]
mod tests {
    use super::*;
    use aws_sdk_dynamodb::types::AttributeValue;

    #[test]
    fn attr_s_returns_string_for_s_variant() {
        let av = AttributeValue::S("hello".to_string());
        assert_eq!(attr_s(&av), Some("hello"));
    }

    #[test]
    fn attr_s_returns_none_for_non_s_variant() {
        let av = AttributeValue::N("42".to_string());
        assert_eq!(attr_s(&av), None);

        let av_bool = AttributeValue::Bool(true);
        assert_eq!(attr_s(&av_bool), None);
    }

    #[test]
    fn attr_n_returns_f64_for_n_variant() {
        let av = AttributeValue::N("3.14".to_string());
        let result = attr_n(&av);
        assert!(result.is_some());
        assert!((result.unwrap() - 3.14).abs() < f64::EPSILON);
    }

    #[test]
    fn attr_n_returns_none_for_non_n_variant() {
        let av = AttributeValue::S("not a number".to_string());
        assert_eq!(attr_n(&av), None);
    }

    #[test]
    fn attr_n_returns_none_for_unparseable_number() {
        let av = AttributeValue::N("not_a_number".to_string());
        assert_eq!(attr_n(&av), None);
    }

    #[test]
    fn table_name_constants_have_correct_values() {
        assert_eq!(TABLE_USERS, "ovaflus-users");
        assert_eq!(TABLE_BUDGETS, "ovaflus-budgets");
        assert_eq!(TABLE_TRANSACTIONS, "ovaflus-transactions");
        assert_eq!(TABLE_PORTFOLIO, "ovaflus-portfolio");
        assert_eq!(TABLE_WATCHLIST, "ovaflus-watchlist");
        assert_eq!(TABLE_GOALS, "ovaflus-goals");
        assert_eq!(TABLE_PLAID_ITEMS, "ovaflus-plaid-items");
    }
}
