# Codebase Structure

**Analysis Date:** 2026-02-20

## Directory Layout

```
apps/ios/OvaFlus/
├── OvaFlusApp.swift              # App entry point, ModelContainer setup
├── ContentView.swift             # Tab navigation root
├── Info.plist                    # App configuration (permissions, etc.)
├── Assets.xcassets/              # App images, icons, colors
│
├── Models/                       # Data layer
│   ├── SwiftDataModels.swift     # SwiftData @Model classes (BudgetModel, TransactionModel, HoldingModel, GoalModel, WatchlistItemModel)
│   ├── Budget.swift              # Codable struct for API responses
│   ├── Transaction.swift         # Codable struct for API responses
│   ├── Portfolio.swift           # Codable struct for API responses
│   └── User.swift                # Codable struct for API responses
│
├── Core/                         # Shared services and utilities
│   ├── Auth/
│   │   ├── AuthManager.swift     # Authentication lifecycle, token management, @MainActor ObservableObject
│   │   └── BiometricAuth.swift   # Face ID/Touch ID wrapper
│   │
│   ├── Network/
│   │   ├── APIClient.swift       # HTTP request handler, singleton
│   │   └── APIEndpoints.swift    # Type-safe endpoint definitions (auth, budgets, portfolio, stocks, profile)
│   │
│   ├── Persistence/
│   │   ├── LocalDataManager.swift         # UserDefaults + file cache abstraction
│   │   └── DataMigrationService.swift     # SwiftData schema migrations
│   │
│   ├── Notifications/
│   │   └── NotificationService.swift      # Local notification scheduling
│   │
│   └── Extensions/
│       ├── Color+Theme.swift    # Theme colors, named color set helpers
│       └── View+Helpers.swift   # SwiftUI view modifiers (cardStyle, shimmer, hideKeyboard, conditional)
│
├── Features/                     # Feature-based modules
│   │
│   ├── Dashboard/
│   │   ├── DashboardView.swift           # Portfolio value, budget summary, recent transactions
│   │   └── DashboardViewModel.swift      # Data aggregation from API + SwiftData
│   │
│   ├── Budget/
│   │   ├── BudgetListView.swift          # @Query-based budget list, edit/delete
│   │   ├── BudgetDetailView.swift        # Single budget with transaction details
│   │   ├── AddBudgetView.swift           # Create/edit budget form
│   │   ├── AddTransactionView.swift      # Transaction creation form
│   │   └── BudgetViewModel.swift         # Budget aggregation (summary, breakdown)
│   │
│   ├── Analytics/
│   │   ├── AnalyticsView.swift           # Charts, spending trends
│   │   └── AnalyticsViewModel.swift      # Analytics data calculations
│   │
│   ├── Stocks/
│   │   ├── PortfolioView.swift           # Holdings overview, performance
│   │   ├── StockDetailView.swift         # Individual stock data and news
│   │   ├── WatchlistView.swift           # Watched symbols
│   │   ├── StockSearchView.swift         # Search stocks by symbol/name
│   │   ├── AddHoldingView.swift          # Add/edit stock position
│   │   └── StocksViewModel.swift         # Portfolio, watchlist, stock quote fetching
│   │
│   ├── Goals/
│   │   ├── GoalsView.swift               # Goals list (savings, debt payoff, emergency fund, investment)
│   │   ├── GoalDetailView.swift          # Single goal progress
│   │   └── AddGoalView.swift             # Create/edit goal
│   │
│   └── Profile/
│       ├── ProfileView.swift             # User info, account settings link
│       └── SettingsView.swift            # App settings, logout
│
└── OvaFlusWidget/                # iOS widget (not detailed in main app)
```

## Directory Purposes

**Models/:**
- Purpose: Data representation for SwiftData persistence and API decoding
- Contains: @Model classes for database entities + Codable structs for network responses
- Key files: `SwiftDataModels.swift` (primary data source of truth)

**Core/Auth/:**
- Purpose: Authentication and identity management
- Contains: AuthManager for login/logout/token lifecycle, BiometricAuth for Face ID/Touch ID
- Key files: `AuthManager.swift`

**Core/Network/:**
- Purpose: HTTP communication with backend
- Contains: APIClient singleton for request handling, APIEndpoint enum for routing
- Key files: `APIClient.swift`, `APIEndpoints.swift`

**Core/Persistence/:**
- Purpose: Local storage abstraction and data migration
- Contains: LocalDataManager for UserDefaults/file cache, DataMigrationService for schema upgrades
- Key files: `LocalDataManager.swift`

**Core/Notifications/:**
- Purpose: Local notification management
- Contains: NotificationService for scheduling, permission requests
- Key files: `NotificationService.swift`

**Core/Extensions/:**
- Purpose: Shared SwiftUI and system extensions
- Contains: Color theme definitions, View modifiers
- Key files: `Color+Theme.swift`, `View+Helpers.swift`

**Features/{Feature}/:**
- Purpose: Isolated feature implementation (Dashboard, Budget, Analytics, Stocks, Goals, Profile)
- Contains: Views + corresponding ViewModels
- Structure: One view per file, ViewModel shared across related views or per-view

## Key File Locations

**Entry Points:**
- `OvaFlusApp.swift`: @main struct, initializes ModelContainer and AuthManager
- `ContentView.swift`: Tab navigation, hosts all features
- `Features/Dashboard/DashboardView.swift`: Default landing view
- `Core/Auth/AuthManager.swift` LoginView: Login/signup UI

**Configuration:**
- `Models/SwiftDataModels.swift`: Data model schema definitions
- `Core/Network/APIEndpoints.swift`: API endpoint URLs and HTTP methods
- `Core/Persistence/LocalDataManager.swift`: UserDefaults and cache directory configuration
- `Info.plist`: App metadata, permissions, URL schemes

**Core Logic:**
- `Core/Auth/AuthManager.swift`: Authentication state machine
- `Core/Network/APIClient.swift`: HTTP request/response handling
- `Features/*/ViewModel.swift`: Per-feature business logic

**Testing:**
- No test files present in current structure

## Naming Conventions

**Files:**
- Views: `{Feature}View.swift` (e.g., BudgetListView, DashboardView)
- ViewModels: `{Feature}ViewModel.swift` (e.g., BudgetViewModel, StocksViewModel)
- Models: `{Entity}.swift` or `SwiftDataModels.swift` (e.g., Budget.swift, User.swift)
- Services: `{Service}Service.swift` (e.g., NotificationService, DataMigrationService)
- Extensions: `{Type}+{Category}.swift` (e.g., Color+Theme, View+Helpers)

**Directories:**
- Features: PascalCase feature names (Dashboard, Budget, Analytics, Stocks, Goals, Profile)
- Core: lowercase service categories (Auth, Network, Persistence, Notifications, Extensions)

**SwiftData Models:**
- Classes: `{Entity}Model.swift` (BudgetModel, TransactionModel, HoldingModel, GoalModel, WatchlistItemModel)
- Pattern: @Model final class with UUID id, UUID.uuidString for primary key

**Codable API Models:**
- Structs: `{Entity}.swift` (Budget, Transaction, User, Portfolio)
- Pattern: struct conforming to Codable for API request/response bodies

## Where to Add New Code

**New Feature:**
- Create directory: `Features/{NewFeature}/`
- Add View file: `Features/{NewFeature}/{NewFeature}View.swift`
- Add ViewModel: `Features/{NewFeature}/{NewFeature}ViewModel.swift` (if business logic needed)
- Add route in `ContentView.swift` TabView enum and tab item
- Add model in `Models/` if new persistent data needed

**New ViewModel:**
- Location: `Features/{Feature}/{Feature}ViewModel.swift`
- Pattern: @MainActor class YourViewModel: ObservableObject { @Published var state; func fetchData() async { } }
- Inject APIClient.shared and/or @Query into init if needed

**New Component/Sub-View:**
- Location: Same file as parent view (struct YourComponentView: View { })
- Or: `Features/{Feature}/{Component}View.swift` if complex and reusable
- Pattern: Struct receiving data as properties, no @State (stateless presentation)

**New Model:**
- Persistent model: Add to `Models/SwiftDataModels.swift` with @Model macro
- Add to ModelContainer schema in `OvaFlusApp.swift`
- API struct: Create new file `Models/{Entity}.swift` with Codable conformance

**New Service:**
- Location: `Core/{Category}/{Service}Service.swift`
- Pattern: class {Service}: ObservableObject (if published state) with static let shared singleton
- Expose via dependency injection: pass to ViewModels or as @EnvironmentObject

**Utilities/Helpers:**
- Shared extensions: `Core/Extensions/{Type}+{Category}.swift`
- Feature-specific helpers: In same file as dependent view or separate file in Feature directory

**New API Endpoint:**
- Add case to `APIEndpoint` enum in `Core/Network/APIEndpoints.swift`
- Implement path, method, body computed properties
- Call via `APIClient.shared.request(.yourEndpoint)`

## Special Directories

**Assets.xcassets/:**
- Purpose: App images, icons, colors, launch screen
- Generated: Managed by Xcode project
- Committed: Yes, binary asset container

**OvaFlusWidget/:**
- Purpose: iOS 17+ widget extension
- Generated: No
- Committed: Yes, but minimal implementation

**.build/ (not in structure):**
- Generated: Yes, SPM build artifacts
- Committed: No, in .gitignore

---

*Structure analysis: 2026-02-20*
