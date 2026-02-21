# Coding Conventions

**Analysis Date:** 2026-02-20

## Naming Patterns

**Files:**
- Model files use singular names: `Budget.swift`, `Transaction.swift`, `User.swift` for Codable API response types
- SwiftUI Views end with "View": `BudgetListView.swift`, `AddTransactionView.swift`, `ProfileView.swift`
- ViewModels end with "ViewModel": `BudgetViewModel.swift`, `StocksViewModel.swift`, `DashboardViewModel.swift`
- Service/Manager classes use "Service" or "Manager": `NotificationService.swift`, `AuthManager.swift`, `LocalDataManager.swift`
- Utility extensions named descriptively: `View+Helpers.swift`, `Color+Theme.swift`
- SwiftData model classes end with "Model": `BudgetModel.swift`, `TransactionModel.swift`, `HoldingModel.swift` (note: all 5 models are in single file `SwiftDataModels.swift`)

**Classes and Types:**
- SwiftUI Views: PascalCase, no prefix (e.g., `BudgetListView`, `AddTransactionView`)
- ViewModels: PascalCase with "ViewModel" suffix (e.g., `BudgetViewModel`, `StocksViewModel`)
- Models (both Codable and SwiftData): PascalCase, SwiftData models have "Model" suffix (e.g., `BudgetModel`, `Budget`)
- Services/Managers: PascalCase with suffix (e.g., `AuthManager`, `NotificationService`, `LocalDataManager`)
- Enums: PascalCase nested inside types (e.g., `BiometricAuth.BiometricType`, `RecurringTransaction.RecurringFrequency`)
- Structs (Codable): PascalCase for all response types and DTO objects

**Functions:**
- camelCase for all function/method names: `fetchPortfolio()`, `saveTransaction()`, `checkBudgetAlert()`
- Private functions prefixed with underscore in some cases, but most commonly just private keyword: `private func fetchBudgetSummary()`
- Async functions use `async` keyword: `func fetchPortfolio() async`
- Property accessors use camelCase: `var isBiometricAvailable`, `var categoryIcon`

**Variables:**
- camelCase for all variable names: `isAuthenticated`, `currentUser`, `totalBudget`
- Private properties use underscore prefix when needed in some contexts, but most use `private` keyword
- State properties in Views: `@State private var showAddBudget`, `@State private var selectedCategory`
- Published properties in ViewModels: `@Published var portfolio`, `@Published var watchlist`

**Constants:**
- camelCase in code, but use `UserDefaults.standard` for system keys with snake_case: `"auth_tokens"`, `"biometric_enabled"`, `"notificationsEnabled"`

**Types:**
- Enums: PascalCase, often nested
  - Example: `enum BudgetPeriod: String, Codable` (in `Budget.swift`)
  - Example: `enum SubscriptionTier: String, Codable` (in `User.swift`)
  - Example: `enum BiometricType` (in `BiometricAuth.swift`)
- Protocols: None explicitly observed in codebase
- Type aliases: None observed

## Code Style

**Formatting:**
- 4-space indentation (standard Swift)
- Curly braces on same line for all control structures
- Single spaces around operators
- Lines wrapped at reasonable length (visible code suggests ~120 char limit)

**Semicolons:**
- Not used (standard Swift practice)

**Property Declaration Order:**
- Published/State properties first
- Private stored properties
- Computed properties at end
- Methods after properties

**Access Control:**
- `private` used liberally for implementation details
- `private var` for State in Views
- `private let` for internal dependencies
- No explicit `public` or `internal` keywords (implicitly public at module level)

## Import Organization

**Order:**
1. Foundation imports first: `import Foundation`
2. Framework imports: `import SwiftUI`, `import SwiftData`, `import LocalAuthentication`
3. System frameworks: `import UserNotifications`
4. No third-party dependencies in current codebase

**Path Aliases:**
- None detected. All imports are fully qualified standard library/framework imports

**Examples:**
```swift
// OvaFlusApp.swift
import SwiftUI
import SwiftData

// AuthManager.swift
import Foundation
import SwiftUI

// NotificationService.swift
import Foundation
import UserNotifications
import SwiftUI
```

## Error Handling

**Patterns:**
- Async functions use `throws` keyword and propagate errors: `async throws -> T`
- try/catch blocks in calling code: `do { ... } catch { ... }`
- Silent error handling in some cases with comment explaining why:
  ```swift
  // StocksViewModel.swift
  func addToWatchlist(symbol: String) async {
      do {
          let _: StockQuote = try await apiClient.request(...)
          await fetchWatchlist()
      } catch {
          // silently fail - SwiftData already has the item
      }
  }
  ```
- Network errors caught and converted to user-friendly messages: `errorMessage = "Failed to load portfolio"`
- Guard statements for early returns: `guard let token = tokens?.accessToken else { return }`
- Force unwrap avoided except in initialization: `fatalError("Could not create ModelContainer: \(error)")` used only in critical setup

**No explicit Result type** - uses async/await with throws pattern instead

## Logging

**Framework:** `console` (standard `print` not observed; relies on system logging and UserDefaults flags)

**Patterns:**
- No explicit logging framework observed in codebase
- Errors stored in `@Published var errorMessage: String?` on ViewModels
- UserDefaults used for feature flags: `UserDefaults.standard.bool(forKey: "notificationsEnabled")`
- Dev-only code marked with comments:
  ```swift
  // Dev bypass
  VStack(spacing: 8) {
      HStack {
          Rectangle().frame(height: 1).foregroundStyle(.quaternary)
          Text("DEV ONLY").font(.caption2).foregroundStyle(.tertiary)
          ...
      }
  }
  ```

## Comments

**When to Comment:**
- Explain "why", not "what" - the what is clear from code
- Used for dev-specific code and workarounds
- Minimal use overall - code is largely self-documenting

**Example patterns:**
```swift
// Placeholder for LoginView referenced in OvaFlusApp
struct LoginView: View {

// silently fail - SwiftData already has the item
} catch {

// Dev bypass
VStack(spacing: 8) {
```

**No JSDoc/TSDoc** - Swift uses none by default. Documentation is minimal.

## Function Design

**Size:** Generally kept small and focused
- View computation bodies: 20-50 lines
- ViewModel methods: 10-30 lines
- Service methods: 10-20 lines

**Parameters:**
- Named parameters used for clarity: `func request<T: Decodable>(_ endpoint: APIEndpoint)`
- Trailing closures used where appropriate in SwiftUI builders
- No excessive parameters - complex data passed as objects

**Return Values:**
- Explicit types always specified: `-> T`, `-> Bool`, `-> [BudgetSummaryData]`
- Async functions return results or throw errors: `async throws -> T`
- Optional returns for potentially-nil values: `-> T?`

## Module Design

**Exports:**
- Struct `@main` used for app entry: `@main struct OvaFlusApp: App`
- No explicit exports - all types at module level are implicitly public
- Structs and classes not marked with access modifiers default to internal/public

**Barrel Files:**
- No barrel files (index.swift style) observed
- Each file contains one primary type + related types:
  - `Budget.swift`: Budget, BudgetPeriod, BudgetCategory, BudgetSummary
  - `Transaction.swift`: Transaction, TransactionType, RecurringTransaction, RecurringFrequency
  - `SwiftDataModels.swift`: All 5 SwiftData models (BudgetModel, TransactionModel, HoldingModel, GoalModel, WatchlistItemModel)

**Singletonsand Shared Instances:**
- Singleton pattern used extensively: `static let shared = AuthManager()`
- MainActor annotation on singletons: `@MainActor class AuthManager: ObservableObject`
- Shared instances: `APIClient.shared`, `AuthManager.shared`, `NotificationService.shared`, `LocalDataManager.shared`, `BiometricAuth.shared`

## SwiftUI Patterns

**View Composition:**
- Small, reusable subviews for complex layouts
- Example: `BudgetRowView` extracted from `BudgetListView`
- Preview blocks included: `#Preview { BudgetListView().modelContainer(...) }`

**State Management:**
- `@Query` for SwiftData reads: `@Query(sort: \BudgetModel.createdAt, order: .reverse) var budgets: [BudgetModel]`
- `@Environment(\.modelContext)` for writes: `@Environment(\.modelContext) private var modelContext`
- `@State` for local UI state: `@State private var showAddBudget = false`
- `@EnvironmentObject` for app-wide state: `@EnvironmentObject var authManager: AuthManager`
- `@Published` in ViewModels: `@Published var isLoading = false`

**MainActor Isolation:**
- All ViewModels: `@MainActor class ViewModel: ObservableObject`
- Notification service: `@MainActor final class NotificationService: NSObject`
- Auth manager: `@MainActor class AuthManager: ObservableObject`

**UIKit Integration:**
- Wrapped in `#if canImport(UIKit)` for Xcode compatibility on macOS:
  ```swift
  #if canImport(UIKit)
  UIImpactFeedbackGenerator(style: .light).impactOccurred()
  #endif
  ```
- View helpers access UIApplication: `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), ...)`

**Async/Await:**
- Used throughout for network calls and async operations
- `.task` modifier on Views: `.task { await NotificationService.shared.requestAuthorization() }`
- Deferred loading in functions: `defer { isLoading = false }`

---

*Convention analysis: 2026-02-20*
