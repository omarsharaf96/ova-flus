# OvaFlus

OvaFlus is a cross-platform personal finance management application that combines **budget tracking** and **stock portfolio management** into a single, unified experience. Available on iOS, Android, web, and macOS.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS | SwiftUI |
| Android | Kotlin + Jetpack Compose |
| Web | Next.js 14 (React) |
| macOS | SwiftUI |
| Backend | Node.js microservices on AWS ECS Fargate |
| Database | PostgreSQL (RDS), DynamoDB |
| Infrastructure | AWS CDK, CloudFront, API Gateway |
| Monorepo | Turborepo workspaces |

## Monorepo Structure

```
ova-flus/
├── apps/                  # Client applications
│   ├── ios/               # iOS app (SwiftUI)
│   ├── android/           # Android app (Kotlin + Compose)
│   ├── web/               # Web app (Next.js 14)
│   └── macos/             # macOS app (SwiftUI)
├── services/              # Backend microservices
│   ├── auth-service/      # Authentication and authorization
│   ├── budget-service/    # Budget tracking and management
│   ├── transaction-service/ # Transaction processing
│   ├── portfolio-service/ # Stock portfolio management
│   ├── market-data-service/ # Real-time market data
│   ├── analytics-service/ # Financial analytics and insights
│   └── notification-service/ # Push notifications and alerts
├── packages/              # Shared packages
│   ├── shared-types/      # TypeScript type definitions
│   ├── ui-components/     # Shared React UI components
│   └── utils/             # Common utility functions
├── infrastructure/        # Infrastructure as code
│   ├── aws-cdk/           # AWS CDK stacks
│   └── api-contracts/     # OpenAPI/gRPC contract definitions
└── .github/               # CI/CD workflows
    └── workflows/
```

## Getting Started

### Prerequisites

- Node.js >= 20
- npm >= 10
- Turborepo (`npm install -g turbo`)
- For iOS/macOS: Xcode 15+
- For Android: Android Studio + JDK 17

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/ova-flus.git
cd ova-flus

# Install dependencies
npm install

# Run all services in development mode
npm run dev

# Build all packages
npm run build

# Run tests
npm run test
```

### Running Individual Services

```bash
# Run a specific service
turbo run dev --filter=auth-service

# Run the web app
turbo run dev --filter=web
```

## Documentation

- [Architecture Overview](./ARCHITECTURE.md)
- [Apps](./apps/)
  - [iOS](./apps/ios/README.md)
  - [Android](./apps/android/README.md)
  - [Web](./apps/web/README.md)
  - [macOS](./apps/macos/README.md)
- [Services](./services/)
  - [Auth Service](./services/auth-service/README.md)
  - [Budget Service](./services/budget-service/README.md)
  - [Transaction Service](./services/transaction-service/README.md)
  - [Portfolio Service](./services/portfolio-service/README.md)
  - [Market Data Service](./services/market-data-service/README.md)
  - [Analytics Service](./services/analytics-service/README.md)
  - [Notification Service](./services/notification-service/README.md)
- [Shared Packages](./packages/)
  - [Shared Types](./packages/shared-types/README.md)
  - [UI Components](./packages/ui-components/README.md)
  - [Utils](./packages/utils/README.md)
- [Infrastructure](./infrastructure/)
  - [AWS CDK](./infrastructure/aws-cdk/README.md)
  - [API Contracts](./infrastructure/api-contracts/README.md)
