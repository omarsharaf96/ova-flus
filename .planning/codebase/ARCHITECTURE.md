# Architecture

**Analysis Date:** 2026-02-20

## Pattern Overview

**Overall:** MVVM (Model-View-ViewModel) with Layered Architecture

**Key Characteristics:**
- SwiftUI-based presentation layer with reactive state management
- SwiftData for local persistence with @Query for reactive reads
- Singleton-based service layer (AuthManager, APIClient, NotificationService, LocalDataManager)
- Feature-based code organization with Core utilities
- @MainActor isolation for UI-related classes and operations
- Environment-based dependency injection for runtime services

## Layers

**Presentation Layer (Views):**
- Purpose: SwiftUI views and UI composition, user interaction handling
- Location: `Features/` directory per feature + `ContentView.swift`
- Contains: SwiftUI View structs, @StateObject ViewModels, View extensions
- Depends on: ViewModels, Models, Core extensions
- Used by: App entry point

**ViewModel Layer:**
- Purpose: UI state management, business logic, data aggregation for views
- Location: `Features/{Feature}/{Feature}ViewModel.swift`
- Contains: @MainActor ObservableObject classes with @Published properties
- Depends on: APIClient, LocalDataManager, SwiftData models
- Used by: Views via @StateObject

**Model Layer:**
- Purpose: Data representation (both SwiftData persistent and Codable API structs)
- Location: `Models/` directory
- Contains: SwiftData @Model classes + Codable structs for API responses
- Depends on: Foundation, SwiftData
- Used by: ViewModels, APIClient for decoding

**Core/Service Layer:**
- Purpose: Cross-cutting concerns, external integrations, persistence
- Location: `Core/` subdirectories (Auth, Network, Notifications, Persistence)
- Contains: Singleton service classes
- Depends on: Foundation, APIClient (for network services)
- Used by: ViewModels and other services

**Data Persistence Layer:**
- Purpose: Local storage management via SwiftData and UserDefaults
- Location: `Models/SwiftDataModels.swift` + `Core/Persistence/`
- Contains: SwiftData models with @Model macro, LocalDataManager for cache/defaults
- Depends on: SwiftData, Foundation
- Used by: ViewModels via @Query and @Environment(\.modelContext)

## Data Flow

**User Authentication Flow:**

1. User enters credentials in LoginView (AuthManager injected via @EnvironmentObject)
2. LoginView calls authManager.signIn()
3. AuthManager.signIn() → APIClient.request(.signIn) → decode AuthTokens
4. AuthTokens stored via LocalDataManager.save() → UserDefaults
5. AuthManager.fetchProfile() fetches User data
6. OvaFlusApp observes authManager.isAuthenticated → switches to ContentView

**Budget Creation and Display:**

1. User taps "+" in BudgetListView
2. Shows AddBudgetView (Sheet)
3. User submits → creates BudgetModel via modelContext
4. BudgetListView observes via @Query(sort:) → automatically re-renders
5. BudgetDetailView reads related TransactionModel via relationship

**Dashboard Data Aggregation:**

1. DashboardView initializes DashboardViewModel
2. ViewModel calls APIClient.request() for portfolio, recent transactions
3. APIClient constructs request with Authorization header from AuthManager.accessToken
4. ViewModel aggregates data from BudgetModel @Query and API responses
5. View renders aggregated summary + charts

**State Management:**

- Local UI state: @State variables in Views
- Shared app state: @EnvironmentObject (AuthManager)
- Persistent models: SwiftData @Query (auto-syncs from modelContext)
- Transient data: ViewModel @Published properties
- Cache: LocalDataManager.cacheObject() for offline support

## Key Abstractions

**APIClient:**
- Purpose: Unified HTTP request handling with auth token injection
- Examples: `Core/Network/APIClient.swift`
- Pattern: Singleton with generic async request<T: Decodable>() method
- Uses APIEndpoint enum to build URL/method/body

**APIEndpoint:**
- Purpose: Type-safe API endpoint definition and routing
- Examples: `Core/Network/APIEndpoints.swift`
- Pattern: Enum with associated values, computed properties for path/method/body
- Endpoints: auth (signIn, signUp, refreshToken), budgets, transactions, portfolio, stocks, profile

**AuthManager:**
- Purpose: Authentication state lifecycle and token management
- Examples: `Core/Auth/AuthManager.swift`
- Pattern: @MainActor ObservableObject with @Published state
- Responsibilities: signIn/signUp, token refresh, biometric setup, token persistence

**ViewModels:**
- Purpose: Extract presentation logic from Views, manage data fetching
- Examples: `Features/Budget/BudgetViewModel.swift`, `Features/Dashboard/DashboardViewModel.swift`
- Pattern: @MainActor class with @Published properties, async methods for data loading
- Scope: Per-view or per-feature (shared across related views)

**LocalDataManager:**
- Purpose: Abstraction over UserDefaults and file-based caching
- Examples: `Core/Persistence/LocalDataManager.swift`
- Pattern: Singleton with dual storage (UserDefaults for small objects, file cache for offline)
- Used for: Token storage, auth state persistence, offline data caching

**NotificationService:**
- Purpose: Local notification scheduling and permission management
- Examples: `Core/Notifications/NotificationService.swift`
- Pattern: Singleton with async requestAuthorization() and scheduleWeeklySummary()

## Entry Points

**App Entry:**
- Location: `OvaFlusApp.swift` (@main struct)
- Triggers: System launch
- Responsibilities:
  - Initializes ModelContainer with all SwiftData models
  - Creates AuthManager as @StateObject
  - Conditionally renders LoginView or ContentView based on authManager.isAuthenticated
  - Injects authManager and modelContainer to view hierarchy
  - Schedules notifications on successful auth

**Tab Navigation:**
- Location: `ContentView.swift`
- Triggers: Authenticated users entering app
- Responsibilities:
  - TabView with 5 tabs (Dashboard, Budget, Analytics, Stocks, Profile)
  - Manages selectedTab @State
  - Calls DataMigrationService.migrateIfNeeded() on appear
  - Central coordinator for feature access

**Feature Entry Points:**
- DashboardView: Portfolio overview, recent transactions
- BudgetListView: Budget management, category breakdown
- AnalyticsView: Spending trends and analysis
- PortfolioView: Stock holdings and watchlist
- ProfileView: User settings and account management

## Error Handling

**Strategy:** Try-catch with error display in UI

**Patterns:**

- APIClient errors: URLError types (badURL, badServerResponse) propagate as throws
- ViewModel catches and converts to UI state: errorMessage @Published property
- LoginView shows errorMessage in red text
- APIClient.request() validates HTTP status 200...299, throws on others
- Token refresh: AuthManager.refreshToken() catches expiration, calls signOut()
- File operations: LocalDataManager wraps FileManager in try? (silent fail for cache)

## Cross-Cutting Concerns

**Logging:** Not implemented; add via logging framework or print statements in service methods

**Validation:**
- Form validation in AddBudgetView, AddTransactionView (empty string checks)
- Model validation: computed properties (progress, remaining) with guard statements
- API response decoding validation: JSONDecoder auto-validates Codable compliance

**Authentication:**
- Bearer token in Authorization header: APIClient injects from AuthManager.accessToken
- Token refresh: AuthManager.refreshToken() endpoint called on expiration
- Biometric: BiometricAuth wraps LocalAuthentication framework (Face ID/Touch ID)
- Token storage: Encoded in UserDefaults via LocalDataManager

**Date Handling:**
- ISO8601 decoding in APIClient: decoder.dateDecodingStrategy = .iso8601
- Date formatting in views: Text(date, style: .date) for user display
- ISO8601DateFormatter in APIEndpoint.addHolding for request serialization

---

*Architecture analysis: 2026-02-20*
