use crate::models::{Budget, CreateBudgetRequest};

#[test]
fn create_budget_request_serialization_with_all_fields() {
    let req = CreateBudgetRequest {
        name: "Groceries".to_string(),
        category: "food".to_string(),
        amount: 500.0,
        period: "monthly".to_string(),
        start_date: Some("2026-01-01".to_string()),
        end_date: Some("2026-12-31".to_string()),
    };

    let json = serde_json::to_value(&req).unwrap();
    assert_eq!(json["name"], "Groceries");
    assert_eq!(json["category"], "food");
    assert_eq!(json["amount"], 500.0);
    assert_eq!(json["period"], "monthly");
    assert_eq!(json["start_date"], "2026-01-01");
    assert_eq!(json["end_date"], "2026-12-31");
}

#[test]
fn budget_deserialization_from_json() {
    let json = serde_json::json!({
        "budget_id": "budget-001",
        "user_id": "user-123",
        "name": "Entertainment",
        "category": "entertainment",
        "amount": 200.0,
        "spent": 50.0,
        "period": "monthly",
        "start_date": "2026-01-01",
        "end_date": "2026-06-30"
    });

    let budget: Budget = serde_json::from_value(json).unwrap();
    assert_eq!(budget.budget_id, "budget-001");
    assert_eq!(budget.user_id, "user-123");
    assert_eq!(budget.name, "Entertainment");
    assert_eq!(budget.category, "entertainment");
    assert!((budget.amount - 200.0).abs() < f64::EPSILON);
    assert!((budget.spent - 50.0).abs() < f64::EPSILON);
    assert_eq!(budget.period, "monthly");
}

#[test]
fn budget_optional_end_date_can_be_none() {
    let json = serde_json::json!({
        "budget_id": "budget-002",
        "user_id": "user-456",
        "name": "Savings",
        "category": "savings",
        "amount": 1000.0,
        "spent": 0.0,
        "period": "monthly",
        "start_date": "2026-01-01",
        "end_date": null
    });

    let budget: Budget = serde_json::from_value(json).unwrap();
    assert!(budget.end_date.is_none());
}

#[test]
fn budget_optional_fields_missing_from_json() {
    let json = serde_json::json!({
        "budget_id": "budget-003",
        "user_id": "user-789",
        "name": "Travel",
        "category": "travel",
        "amount": 2000.0,
        "period": "yearly"
    });

    let budget: Budget = serde_json::from_value(json).unwrap();
    assert!(budget.start_date.is_none());
    assert!(budget.end_date.is_none());
    // spent has #[serde(default)] so should default to 0.0
    assert!((budget.spent - 0.0).abs() < f64::EPSILON);
}

#[test]
fn create_budget_request_with_no_optional_dates() {
    let req = CreateBudgetRequest {
        name: "Rent".to_string(),
        category: "housing".to_string(),
        amount: 1500.0,
        period: "monthly".to_string(),
        start_date: None,
        end_date: None,
    };

    let json = serde_json::to_value(&req).unwrap();
    assert_eq!(json["name"], "Rent");
    // Optional None fields serialize as null
    assert!(json["start_date"].is_null());
    assert!(json["end_date"].is_null());
}
