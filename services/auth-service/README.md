# Auth Service

Handles user authentication, authorization, and session management. Integrates with AWS Cognito for identity management, supports MFA, and issues JWT tokens for service-to-service communication.

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /api/v1/auth/register | No | Register a new user |
| POST | /api/v1/auth/login | No | Login with email/password |
| POST | /api/v1/auth/refresh | No | Refresh access token |
| POST | /api/v1/auth/logout | Yes | Logout (invalidate tokens) |
| GET | /api/v1/auth/me | Yes | Get current user profile |
| PUT | /api/v1/auth/me | Yes | Update user profile |
| POST | /api/v1/auth/mfa/setup | Yes | Initialize MFA setup (TOTP) |
| POST | /api/v1/auth/mfa/verify | Yes | Verify MFA code |

## Architecture

### AWS Cognito Integration
- User Pool manages registration, authentication, and token lifecycle
- Cognito handles password hashing, account verification, and token signing
- TOTP-based MFA via Cognito Software Token

### JWT Flow
1. User registers/logs in via Cognito
2. Cognito returns access token, ID token, and refresh token
3. Access token is sent as `Authorization: Bearer <token>` on subsequent requests
4. Middleware validates JWT signature against Cognito JWKS
5. Refresh token is used to obtain new access tokens when expired

### MFA Flow
1. User calls `/auth/mfa/setup` to get a TOTP secret and QR code URL
2. User scans QR code with authenticator app
3. User calls `/auth/mfa/verify` with the 6-digit code to confirm setup
4. Subsequent logins require MFA code via Cognito challenge response

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Service port | 3001 |
| JWT_SECRET | JWT signing secret (dev only) | dev-secret |
| AWS_REGION | AWS region | us-east-1 |
| COGNITO_USER_POOL_ID | Cognito User Pool ID | - |
| COGNITO_CLIENT_ID | Cognito App Client ID | - |
| DB_HOST | PostgreSQL host | localhost |
| DB_NAME | Database name | ova_flus |

## Running

```bash
npm run dev   # Development with hot reload
npm run build # Compile TypeScript
npm start     # Production
npm test      # Run tests
```
