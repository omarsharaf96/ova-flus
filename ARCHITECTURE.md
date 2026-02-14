# OvaFlus Architecture

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ iOS App  │  │ Android  │  │ Web App  │  │ macOS    │           │
│  │ SwiftUI  │  │ Kotlin+  │  │ Next.js  │  │ App      │           │
│  │          │  │ Compose  │  │ 14       │  │ SwiftUI  │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │              │              │              │                 │
└───────┼──────────────┼──────────────┼──────────────┼────────────────┘
        │              │              │              │
┌───────┼──────────────┼──────────────┼──────────────┼────────────────┐
│       ▼              ▼              ▼              ▼                 │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │                   CloudFront CDN                         │       │
│  └─────────────────────────┬───────────────────────────────┘       │
│                             │                                       │
│  ┌─────────────────────────▼───────────────────────────────┐       │
│  │              AWS WAF + Cognito + API Gateway             │       │
│  └─────────────────────────┬───────────────────────────────┘       │
│                             │                                       │
│  ┌──────────────────────────▼──────────────────────────────┐       │
│  │                  APPLICATION LOAD BALANCER                │       │
│  └──┬────┬────┬────┬────┬────┬────┬────────────────────────┘       │
│     │    │    │    │    │    │    │                                  │
│     ▼    ▼    ▼    ▼    ▼    ▼    ▼     AWS ECS Fargate             │
│  ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐                       │
│  │Auth││Budg││Txn ││Port││Mrkt││Anly││Noti│                       │
│  │Svc ││Svc ││Svc ││Svc ││Data││Svc ││Svc │                       │
│  └──┬─┘└──┬─┘└──┬─┘└──┬─┘└──┬─┘└──┬─┘└──┬─┘                       │
│     │     │     │     │     │     │     │                           │
│  ┌──▼─────▼─────▼─────▼─────▼─────▼─────▼──┐                       │
│  │          DATA LAYER                       │                       │
│  │  ┌──────────┐  ┌──────────┐  ┌────────┐  │                       │
│  │  │ RDS      │  │ DynamoDB │  │ Redis  │  │                       │
│  │  │ Postgres │  │          │  │ Cache  │  │                       │
│  │  └──────────┘  └──────────┘  └────────┘  │                       │
│  └──────────────────────────────────────────┘                       │
│                                                                      │
│  ┌──────────────────────────────────────────┐                       │
│  │          STORAGE & MESSAGING              │                       │
│  │  ┌──────┐  ┌──────┐  ┌───────────────┐  │                       │
│  │  │ S3   │  │ SQS  │  │ EventBridge   │  │                       │
│  │  └──────┘  └──────┘  └───────────────┘  │                       │
│  └──────────────────────────────────────────┘                       │
│                                                                      │
│  ┌──────────────────────────────────────────┐                       │
│  │          MONITORING                       │                       │
│  │  ┌───────────┐  ┌──────┐  ┌───────────┐ │                       │
│  │  │CloudWatch │  │X-Ray │  │ Sentry    │ │                       │
│  │  └───────────┘  └──────┘  └───────────┘ │                       │
│  └──────────────────────────────────────────┘                       │
│                         AWS CLOUD                                    │
└──────────────────────────────────────────────────────────────────────┘
```

## 2. Tech Stack Decisions

### Client Applications

| Platform | Technology | Rationale |
|----------|-----------|-----------|
| iOS | SwiftUI | Native performance, first-class Apple ecosystem integration, modern declarative UI |
| Android | Kotlin + Jetpack Compose | Native performance, modern declarative UI, strong typing with Kotlin |
| Web | Next.js 14 | SSR/SSG for SEO, React ecosystem, App Router for modern patterns |
| macOS | SwiftUI | Code sharing with iOS, native macOS experience, Catalyst alternative |

**Why native over cross-platform?** Finance apps demand peak performance, platform-specific security features (Face ID, biometrics), and native UX patterns that users trust with their financial data.

### Backend

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Runtime | Node.js (TypeScript) | Type safety, shared types with web frontend, large ecosystem |
| Container Orchestration | AWS ECS Fargate | Serverless containers, no cluster management, auto-scaling |
| API Layer | Express.js + API Gateway | Mature, well-understood, AWS-native API management |
| Database (relational) | PostgreSQL on RDS | ACID compliance for financial data, rich querying |
| Database (NoSQL) | DynamoDB | High-throughput for market data, session storage |
| Cache | ElastiCache (Redis) | Low-latency reads, session caching, rate limiting |
| Message Queue | SQS + EventBridge | Async processing, service decoupling, event-driven patterns |

### Infrastructure

| Tool | Purpose |
|------|---------|
| AWS CDK (TypeScript) | Infrastructure as code, type-safe cloud resource definitions |
| Turborepo | Monorepo build orchestration, caching, task pipelines |
| GitHub Actions | CI/CD pipelines |

## 3. Monorepo Structure

The project uses a **Turborepo-based monorepo** with npm workspaces. This approach provides:

- **Shared types**: TypeScript interfaces shared between web frontend and all backend services
- **Unified CI/CD**: Single pipeline for linting, testing, and deploying all services
- **Atomic changes**: Cross-service changes in a single PR
- **Consistent tooling**: Shared ESLint, Prettier, and TypeScript configs

### Workspace Layout

- `apps/*` - Client applications (iOS, Android, web, macOS)
- `services/*` - Backend microservices (each independently deployable)
- `packages/*` - Shared libraries consumed by services and web app
- `infrastructure/*` - AWS CDK stacks and API contract definitions

## 4. AWS Architecture Layers

### Layer 1: Client
Native and web applications communicating via HTTPS REST APIs.

### Layer 2: CDN (CloudFront)
- Static asset caching for the web app
- API response caching for read-heavy endpoints (market data)
- Global edge locations for low latency

### Layer 3: Security
- **AWS WAF**: Rate limiting, IP filtering, SQL injection prevention
- **Amazon Cognito**: User authentication, OAuth 2.0 / OIDC, MFA
- **API Gateway**: Request validation, throttling, API key management

### Layer 4: Application (ECS Fargate)
Seven microservices, each running in its own Fargate task:

| Service | Responsibility |
|---------|---------------|
| auth-service | User registration, login, token management, MFA |
| budget-service | Budget creation, category management, spending tracking |
| transaction-service | Transaction ingestion, categorization, reconciliation |
| portfolio-service | Stock holdings, buy/sell orders, portfolio performance |
| market-data-service | Real-time stock prices, historical data, market indices |
| analytics-service | Spending insights, portfolio analytics, financial reports |
| notification-service | Push notifications, email alerts, price alerts |

### Layer 5: Data
- **PostgreSQL (RDS)**: User accounts, budgets, transactions, portfolios
- **DynamoDB**: Market data cache, session tokens, real-time price feeds
- **Redis (ElastiCache)**: Application caching, rate limiting counters

### Layer 6: Storage & Messaging
- **S3**: Document storage, exports, backups
- **SQS**: Async task queues (transaction processing, notifications)
- **EventBridge**: Event-driven communication between services

### Layer 7: Monitoring
- **CloudWatch**: Metrics, logs, alarms
- **X-Ray**: Distributed tracing across microservices
- **Sentry**: Error tracking and performance monitoring in client apps

## 5. Data Synchronization Strategy

### Offline-First Architecture
All client apps implement an offline-first pattern:

1. **Local storage**: SQLite (mobile) / IndexedDB (web) for local data persistence
2. **Optimistic updates**: UI updates immediately, syncs with server in background
3. **Conflict resolution**: Last-write-wins with timestamp-based ordering; server is source of truth
4. **Sync protocol**: Delta sync using versioned records with `updatedAt` timestamps

### Real-Time Updates
- **WebSocket connections** via API Gateway for real-time stock prices
- **Server-Sent Events** for portfolio value changes and budget alerts
- **Push notifications** via APNs (iOS/macOS) and FCM (Android) for critical alerts

## 6. Security Approach

### Authentication & Authorization
- **Cognito User Pools** for identity management
- **JWT tokens** with short-lived access tokens (15 min) and refresh tokens (30 days)
- **Role-based access control (RBAC)** at the API Gateway level
- **Multi-factor authentication** for sensitive operations (transfers, portfolio trades)

### Data Protection
- **Encryption at rest**: RDS encryption, S3 server-side encryption, DynamoDB encryption
- **Encryption in transit**: TLS 1.3 everywhere
- **Field-level encryption** for sensitive financial data (account numbers, SSN)
- **Key management**: AWS KMS for encryption key rotation

### Application Security
- Input validation at API Gateway and service level
- SQL injection prevention via parameterized queries
- CORS policies restricting origins
- CSP headers for the web application
- Dependency scanning via GitHub Dependabot

## 7. Development Phases

### Phase 1: Foundation
- Monorepo setup and CI/CD pipeline
- Auth service with Cognito integration
- Database schema design and migrations
- Shared type definitions and API contracts

### Phase 2: Core Features
- Budget service (CRUD operations, categories)
- Transaction service (manual entry, categorization)
- Web app with budget dashboard
- iOS app with budget tracking

### Phase 3: Portfolio Management
- Portfolio service (holdings, performance tracking)
- Market data service (price feeds, historical data)
- Portfolio UI on web and iOS
- Android app development begins

### Phase 4: Intelligence & Alerts
- Analytics service (spending insights, portfolio analysis)
- Notification service (push, email, price alerts)
- macOS app development
- Advanced charting and reporting

### Phase 5: Polish & Scale
- Performance optimization and load testing
- Advanced features (bank integration, recurring transactions)
- App Store and Play Store submissions
- Production infrastructure hardening
