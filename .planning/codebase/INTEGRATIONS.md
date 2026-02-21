# External Integrations

**Analysis Date:** 2026-02-20

## APIs & External Services

**Finance API (Custom Backend):**
- Service: OvaFlus backend at `https://api.ova-flus.com/v1`
- What it's used for: Budgets, transactions, portfolio, stock quotes, watchlist, user profile
  - SDK/Client: Custom `APIClient` singleton in `apps/ios/OvaFlus/Core/Network/APIClient.swift`
  - Auth: Bearer token-based (JWT); tokens retrieved from AuthManager

**Stock Data:**
- Service: Backend proxy (actual provider abstracted)
- What it's used for: Stock quotes, stock search, portfolio data, stock news
  - Endpoints: `/stocks/{symbol}`, `/stocks/search`, `/portfolio`, `/stocks/{symbol}/news`
  - Consumed by: `StocksViewModel` in `apps/ios/OvaFlus/Features/Stocks/StocksViewModel.swift`

## Data Storage

**Databases:**
- Primary: None on client-side beyond local persistence
- Backend database: Assumed managed by OvaFlus backend (abstracted)
  - Connection: Via HTTPS API calls to `https://api.ova-flus.com/v1`
  - Client: SwiftData for local read/write caching; models in `apps/ios/OvaFlus/Models/SwiftDataModels.swift`

**Local Persistence:**
- SwiftData (offline-first): BudgetModel, TransactionModel, HoldingModel, GoalModel, WatchlistItemModel
- UserDefaults: Authentication tokens, biometric preference, notification settings
- File cache: Offline support via `LocalDataManager.cacheObject()` at `~/Library/Caches/OvaFlusCache/`

**File Storage:**
- Local filesystem only - No cloud file storage integration
- App uses device Documents/Caches directory for local cache via FileManager
- Image assets stored in `apps/ios/OvaFlus/Assets.xcassets`

**Caching:**
- LocalDataManager singleton (`apps/ios/OvaFlus/Core/Persistence/LocalDataManager.swift`) provides:
  - UserDefaults-based storage for structured data (tokens, settings)
  - File-based cache for offline support with arbitrary filenames
  - Cache location: `~/Library/Caches/OvaFlusCache/`
  - No external caching service (Redis, Memcached, etc.)

## Authentication & Identity

**Auth Provider:**
- Custom backend with JWT tokens
- Implementation: `AuthManager` class in `apps/ios/OvaFlus/Core/Auth/AuthManager.swift` (@MainActor ObservableObject)
  - Approach: Email/password sign-in and sign-up with JWT token response
  - Tokens stored: accessToken, refreshToken, expiresAt (AuthTokens struct)
  - Biometric secondary auth: Face ID/Touch ID via `BiometricAuth.shared` singleton
  - Token refresh: Automatic via refreshToken endpoint when expired
  - Persistent storage: Auth tokens cached in UserDefaults with key `auth_tokens`

**Auth Endpoints:**
- POST `/auth/signin` - Email/password login
- POST `/auth/signup` - User registration
- POST `/auth/refresh` - Token refresh
- GET `/profile` - User profile fetch

**Biometric Authentication:**
- Implementation: `BiometricAuth` class in `apps/ios/OvaFlus/Core/Auth/BiometricAuth.swift`
  - Uses LocalAuthentication framework
  - Supports Face ID and Touch ID (device-specific)
  - Stored preference: `biometric_enabled` UserDefaults flag
  - Works alongside password-based auth

**AWS Cognito (Configured but Not Used):**
- AWSCognitoAuthPlugin imported in project.yml
- Status: Available but not integrated in current codebase
- Custom JWT approach used instead via `AuthManager`

## Monitoring & Observability

**Error Tracking:**
- None detected - No Sentry, Crashlytics, or similar integration
- Error handling in APIClient: Catches URLError and HTTPURLResponse validation
- Errors propagated to ViewModels via async/await throws pattern

**Logs:**
- Approach: Console logging only (print statements not visible in production)
- No centralized logging service (Datadog, New Relic, etc.)
- Debug logging visible in Xcode console during development

**Analytics:**
- None detected - No Google Analytics, Mixpanel, or Amplitude integration
- AnalyticsViewModel exists (`apps/ios/OvaFlus/Features/Analytics/AnalyticsViewModel.swift`) but appears to be UI-only
- No event tracking or usage metrics collection

## CI/CD & Deployment

**Hosting:**
- Distribution: Apple TestFlight / App Store Connect
- Platform: iOS devices running iOS 17.0+
- Deployment method: Automated via GitHub Actions using altool

**CI Pipeline:**
- Service: GitHub Actions
- Config files: `.github/workflows/ci.yml` (test) and `.github/workflows/cd-ios.yml` (deploy)
- CI Steps (`.github/workflows/ci.yml`):
  - Runs on: macOS 15 runner
  - Triggers: Pull requests and pushes
  - Build command: `xcodebuild -scheme OvaFlus -destination 'platform=iOS Simulator,name=iPhone 15' clean build`

**CD Pipeline (`.github/workflows/cd-ios.yml`):**
- Triggers: Pushes to `apps/ios/**` paths
- Steps:
  1. Build and archive: `xcodebuild -scheme OvaFlus -configuration Release -archivePath OvaFlus.xcarchive archive`
  2. Export IPA: `xcodebuild -exportArchive` with ExportOptions.plist
  3. Upload to TestFlight: `xcrun altool --upload-app -f OvaFlus.ipa --username APPLE_ID --password APPLE_APP_PASSWORD`
- Secrets used: `APPLE_ID`, `APPLE_APP_PASSWORD` (GitHub repository secrets)
- Error handling: `continue-on-error: true` on TestFlight upload (allows workflow to continue if upload fails)

## Environment Configuration

**Required env vars (Build):**
- `API_BASE_URL` - Backend API endpoint (defaults to `https://api.ova-flus.com/v1`)
- `SWIFT_VERSION` - Swift compiler version (set to 5.9 in project.yml)
- `DEVELOPMENT_TEAM` - Apple team ID for code signing (empty in base config, requires setup)

**Required env vars (Runtime - iOS Settings):**
- None required to be set programmatically; settings stored in UserDefaults and Info.plist

**Secrets location:**
- GitHub repository secrets: `APPLE_ID`, `APPLE_APP_PASSWORD`
- Local dev: Managed via Xcode build settings or environment
- Info.plist contains user-facing descriptions, not secrets:
  - `NSFaceIDUsageDescription`: "Flus uses Face ID to securely sign you in and protect your financial data."
  - `NSCameraUsageDescription`: "Flus uses the camera to scan receipts for easy expense tracking."
  - `NSUserNotificationsUsageDescription`: "Flus sends notifications for budget alerts, goal milestones, and weekly financial summaries."

**.env files:**
- `.env` file status: Not used (not detected in codebase)
- Configuration via environment variables and Xcode build settings

## Webhooks & Callbacks

**Incoming:**
- None detected - App is client-only, does not expose webhook endpoints

**Outgoing:**
- None detected - App does not initiate outbound webhooks to external services
- Push notifications: Handled by Apple Push Notification service (not configured in visible codebase)
- Local notifications: Scheduled via `NotificationService.shared` using UNUserNotificationCenter

**Push Notifications (APNs):**
- Supported via Info.plist capability
- Registration: Not visible in code (typically handled by iOS runtime)
- Fallback: Local notifications via UserNotifications framework used instead

## Third-Party Libraries (via Amplify)

**Amplify Swift 2.0.0+:**
- Configured plugins (not actively used in current implementation):
  - AWSCognitoAuthPlugin - Authentication (alternative to current JWT approach)
  - AWSAPIPlugin - GraphQL/REST API client (alternative to current URLSession)
- Status: Available for future use but custom implementations currently preferred

---

*Integration audit: 2026-02-20*
