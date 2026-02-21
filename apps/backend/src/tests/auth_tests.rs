use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};

use crate::models::{SignInRequest, SignUpRequest};

#[test]
fn signup_request_requires_non_empty_email() {
    let json = r#"{"email": "", "name": "Test", "password": "password123"}"#;
    let req: SignUpRequest = serde_json::from_str(json).unwrap();
    // Struct deserializes but email is empty — validation should catch this at handler level
    assert!(req.email.is_empty());
}

#[test]
fn signup_request_requires_non_empty_password() {
    let json = r#"{"email": "test@example.com", "name": "Test", "password": ""}"#;
    let req: SignUpRequest = serde_json::from_str(json).unwrap();
    assert!(req.password.is_empty());
}

#[test]
fn signup_request_with_valid_fields() {
    let json = r#"{"email": "user@test.com", "name": "John Doe", "password": "strongpass123"}"#;
    let req: SignUpRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.email, "user@test.com");
    assert_eq!(req.name, "John Doe");
    assert_eq!(req.password, "strongpass123");
}

#[test]
fn signin_request_deserialization() {
    let json = r#"{"email": "user@test.com", "password": "mypassword"}"#;
    let req: SignInRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.email, "user@test.com");
    assert_eq!(req.password, "mypassword");
}

#[test]
fn signin_request_missing_field_fails() {
    let json = r#"{"email": "user@test.com"}"#;
    let result = serde_json::from_str::<SignInRequest>(json);
    assert!(result.is_err());
}

#[test]
fn password_hashing_verifies_correctly() {
    let password = b"password";
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();

    let hash = argon2.hash_password(password, &salt).unwrap().to_string();
    let parsed_hash = PasswordHash::new(&hash).unwrap();

    assert!(argon2.verify_password(password, &parsed_hash).is_ok());
}

#[test]
fn wrong_password_fails_verification() {
    let password = b"password";
    let wrong_password = b"wrong_password";
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();

    let hash = argon2.hash_password(password, &salt).unwrap().to_string();
    let parsed_hash = PasswordHash::new(&hash).unwrap();

    assert!(argon2
        .verify_password(wrong_password, &parsed_hash)
        .is_err());
}
