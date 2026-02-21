# Technology Stack

**Analysis Date:** 2026-02-20

## Languages

**Primary:**
- Swift 5.9 - iOS app codebase; all source files located in `apps/ios/OvaFlus/`

**Secondary:**
- YAML - Project configuration in `apps/ios/project.yml`

## Runtime

**Environment:**
- iOS 17.0+ (minimum deployment target set in `apps/ios/project.yml`)
- Xcode 15.0+
- macOS 15 for CI/CD (runner configured in `.github/workflows/ci.yml`)

**Package Manager:**
- Swift Package Manager (SPM)
- Lockfile: Not detected (typical for Xcode projects; dependencies resolved via project.yml)

## Frameworks

**Core UI:**
- SwiftUI - Primary UI framework across all views; used in `apps/ios/OvaFlus/Features/` and `apps/ios/OvaFlus/Core/`
- UIKit - Implicit through iOS SwiftUI; no direct imports (prevents SourceKit false errors on macOS)

**Data Persistence:**
- SwiftData - ORM for local data storage; models defined in `apps/ios/OvaFlus/Models/SwiftDataModels.swift`
  - BudgetModel, TransactionModel, HoldingModel, GoalModel, WatchlistItemModel
  - ModelContainer configured in `apps/ios/OvaFlus/OvaFlusApp.swift` with schema of 5 models
  - Uses `@Query` for reading and `@Environment(\.modelContext)` for writing

**Notifications:**
- UserNotifications - Local notification scheduling; implementation in `apps/ios/OvaFlus/Core/Notifications/NotificationService.swift`
  - Budget alerts, weekly summaries, goal completion notifications
  - UNUserNotificationCenter for managing notifications

**Authentication:**
- LocalAuthentication - Biometric auth (Face ID/Touch ID); implementation in `apps/ios/OvaFlus/Core/Auth/BiometricAuth.swift`
  - LAContext for policy evaluation
  - Device owner authentication with biometrics

**Networking:**
- Foundation URLSession - HTTP client; implementation in `apps/ios/OvaFlus/Core/Network/APIClient.swift`
  - Custom API client singleton for making authenticated requests
  - JSONEncoder/JSONDecoder for serialization with ISO8601 date strategy

**AWS SDK:**
- Amplify Swift (v2.0.0+) - AWS integration framework
  - AWSCognitoAuthPlugin - Authentication backend (configured in project.yml but not actively used; custom auth impl in AuthManager)
  - AWSAPIPlugin - API gateway integration (configured but not actively used; custom URLSession impl used instead)
  - Package source: https://github.com/aws-amplify/amplify-swift.git

## Key Dependencies

**Critical:**
- Amplify 2.0.0+ - AWS backend integration; provides auth and API plugins
- SwiftUI (iOS 17+) - Modern declarative UI; required for all view implementations
- SwiftData (iOS 17+) - Type-safe data persistence; powers all local data models

**Infrastructure:**
- UserDefaults (Foundation) - Simple key-value storage; used for biometric preferences (`biometric_enabled` flag), notification preferences, and auth token caching
- FileManager (Foundation) - File system access; used for cache directory management in `apps/ios/OvaFlus/Core/Persistence/LocalDataManager.swift`

## Configuration

**Environment:**
- API Base URL: Environment variable `API_BASE_URL` with default `https://api.ova-flus.com/v1` (set in `apps/ios/OvaFlus/Core/Network/APIClient.swift`)
- Bundle ID: `com.flus.app` (configured in `apps/ios/project.yml`)
- Widget Bundle ID: `com.flus.app.widget` (for app extension)
- Development Team: Empty (requires manual configuration or CI environment)

**Build:**
- Project config: `apps/ios/project.yml` (XcodeGen format)
- Info.plist: `apps/ios/OvaFlus/Info.plist` with app metadata
- Assets: `apps/ios/OvaFlus/Assets.xcassets` with app icon, colors, images
- Code signing: Automatic in build configuration

**Runtime Configuration:**
- Notifications enabled: UserDefaults flag `notificationsEnabled`
- Biometric auth enabled: UserDefaults flag `biometric_enabled`
- Auth tokens: Cached in UserDefaults with key `auth_tokens` (AuthTokens Codable struct)
- Cache location: `~/Library/Caches/OvaFlusCache/` (managed by LocalDataManager)

## Platform Requirements

**Development:**
- Xcode 15.0 or later
- Swift 5.9
- iOS 17.0+ SDK
- macOS 12.6+ for development machine (to run Xcode)
- Apple Developer account (for provisioning profiles and signing)
- Ruby + xcodeproj gem (for programmatic Xcode project modifications; gem installs at `~/.gem/ruby/2.6.0/gems/xcodeproj-*/lib`)

**Production:**
- Deployment target: iOS 17.0+
- App Store distribution via TestFlight/App Store Connect
- TestFlight credentials required for automated uploads (GitHub secrets `APPLE_ID` and `APPLE_APP_PASSWORD`)
- No backend server required on client; API communication via HTTPS to `https://api.ova-flus.com/v1`

**CI/CD Environment:**
- Runner: macOS 15 (GitHub Actions)
- Available tools: xcodebuild, xcrun
- Deployment: altool (Application Loader) for TestFlight uploads

---

*Stack analysis: 2026-02-20*
