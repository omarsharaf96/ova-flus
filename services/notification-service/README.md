# Notification Service

Manages push notifications, email alerts, and in-app notifications. Handles delivery across iOS (APNs), Android (FCM), web (Web Push), and email channels.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/notifications | List notifications (paginated) |
| PUT | /api/v1/notifications/:id/read | Mark notification as read |
| PUT | /api/v1/notifications/read-all | Mark all as read |
| GET | /api/v1/notifications/preferences | Get notification preferences |
| POST | /api/v1/notifications/preferences | Update preferences |
| POST | /api/v1/alerts/budget | Create budget threshold alert |
| POST | /api/v1/alerts/stock-price | Create stock price alert |
| GET | /api/v1/alerts | List active alerts |
| DELETE | /api/v1/alerts/:id | Remove alert |

All endpoints require authentication via Bearer token.

## AWS Integration

### SNS (Simple Notification Service)
- Platform applications for APNs (iOS) and FCM (Android)
- Web Push endpoint subscriptions
- Topic-based routing for different alert types

### SES (Simple Email Service)
- Transactional emails: welcome, password reset, alerts
- Weekly digest emails with spending/portfolio summary
- HTML email templates stored in S3

## Alert Types

- **Budget alerts**: Triggered when spending reaches configured threshold (e.g., 80%, 100%)
- **Stock price alerts**: Triggered when stock price crosses target (above/below)
- **Transaction alerts**: Triggered on large or unusual transactions

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Service port | 3007 |
| JWT_SECRET | JWT signing secret | dev-secret |
| AWS_REGION | AWS region | us-east-1 |
| SNS_PLATFORM_ARN_IOS | SNS platform ARN for APNs | - |
| SNS_PLATFORM_ARN_ANDROID | SNS platform ARN for FCM | - |
| SES_FROM_EMAIL | Sender email for SES | - |
| DB_HOST | PostgreSQL host | localhost |
| DB_NAME | Database name | ova_flus |

## Running

```bash
npm run dev   # Development with hot reload
npm run build # Compile TypeScript
npm start     # Production
npm test      # Run tests
```
