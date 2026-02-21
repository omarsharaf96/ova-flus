# Testing Patterns

**Analysis Date:** 2026-02-20

## Current State

**No active test suite detected.** The codebase contains no XCTest files, no test targets, and no mocking frameworks. Testing infrastructure does not exist.

## Test Framework

**Runner:**
- None configured

**Assertion Library:**
- Not applicable

**Run Commands:**
```bash
cd apps/ios
xcodebuild -scheme OvaFlus -destination 'platform=iOS Simulator,name=iPhone 15' clean build
```

The CI workflow (`/.github/workflows/ci.yml`) currently only builds the app—it does not run tests. Test commands would need to be added.

## Test File Organization

**Location Pattern:**
- No test files exist
- Recommended pattern (if tests were added): Co-located with source
  - `BudgetListView.swift` would have `BudgetListViewTests.swift` in same directory
  - Or separate `Tests/` directory at `apps/ios/OvaFlusTests/`

**Naming Convention (if implemented):**
- Swift standard: `[TargetType]Tests.swift`
- Per-file tests: `BudgetViewModelTests.swift`, `APIClientTests.swift`

**File Structure (if implemented):**
```
apps/ios/
├── OvaFlus/                    # Source code
├── OvaFlusTests/               # Test target (would go here)
│   ├── Features/
│   │   ├── Budget/
│   │   │   ├── BudgetViewModelTests.swift
│   │   │   ├── BudgetListViewTests.swift
│   │   ├── Stocks/
│   │   ├── Profile/
│   ├── Core/
│   │   ├── Auth/
│   │   │   ├── AuthManagerTests.swift
│   │   ├── Network/
│   │   │   ├── APIClientTests.swift
│   │   ├── Persistence/
│   │   │   ├── LocalDataManagerTests.swift
```

## Test Structure

**No existing tests to analyze.**

If tests were to be implemented, the pattern would follow standard XCTest structure:

```swift
import XCTest
import SwiftData
@testable import OvaFlus

final class BudgetViewModelTests: XCTestCase {
    var sut: BudgetViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = BudgetViewModel()
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    func testBudgetSummary_WithMultipleBudgets_CalculatesCorrectTotals() {
        // Arrange
        let budgets = [
            BudgetModel(name: "Food", amount: 100, spent: 50),
            BudgetModel(name: "Transport", amount: 200, spent: 100)
        ]

        // Act
        let summary = sut.budgetSummary(from: budgets)

        // Assert
        XCTAssertEqual(summary.totalBudget, 300)
        XCTAssertEqual(summary.totalSpent, 150)
    }
}
```

## What Could Be Tested

### ViewModels

**Unit Test Candidates:**
- `BudgetViewModel.swift`:
  - `budgetSummary(from:)` - Calculate totals correctly
  - `categoryBreakdown(from:)` - Group and sort categories
- `StocksViewModel.swift`:
  - `fetchPortfolio()` - Handles API success/failure
  - `searchStocks(query:)` - Validates minimum query length (2 chars)
  - `generateChartData(baseValue:days:)` - Generates correct number of data points
- `DashboardViewModel.swift`:
  - `fetchDashboardData()` - Concurrent async task execution

### Models & Data

**Unit Test Candidates:**
- `SwiftDataModels.swift`:
  - `BudgetModel.progress` - Returns 0 when amount is 0, caps at 1.0
  - `BudgetModel.remaining` - Calculates max(amount - spent, 0)
  - `GoalModel.progress` - Similar calculation with target amount
  - `BudgetModel.categoryIcon` - Returns correct emoji/icon for category
- `Budget.swift`:
  - `categoryIcon` property - Maps category strings to icons
- Codable decoding - JSON date handling (ISO8601 format)

### Network & Services

**Integration Test Candidates:**
- `APIClient.request<T>()` - HTTP request building, JSON encoding/decoding
- `AuthManager.signIn()` - Token storage and retrieval
- `NotificationService.checkBudgetAlert()` - Notification generation when threshold exceeded
- `LocalDataManager.save/load()` - UserDefaults serialization

### Views

**Snapshot/UI Test Candidates:**
- `BudgetListView` - List rendering, sort order
- `AddTransactionView` - Form validation (amount required)
- `PortfolioView` - Chart rendering, watchlist display
- `LoginView` - Auth flow, dev bypass button visibility

## Mocking Strategy

**No mocking framework currently used.** If tests were to be implemented:

**Recommended approach:**
- Manual protocol-based mocks (no external dependencies)
- Create protocols for dependencies:
  ```swift
  protocol APIClientProtocol {
      func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
  }

  struct MockAPIClient: APIClientProtocol {
      var requestResult: Any?
      var requestError: Error?

      func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
          if let error = requestError { throw error }
          return requestResult as? T ?? T(from: JSONDecoder())
      }
  }
  ```
- Constructor injection for tests:
  ```swift
  class BudgetViewModel {
      let apiClient: APIClientProtocol

      init(apiClient: APIClientProtocol = APIClient.shared) {
          self.apiClient = apiClient
      }
  }
  ```

**What to Mock:**
- Network calls (APIClient) - return canned responses or throw errors
- UserDefaults - use in-memory test doubles
- SwiftData model context - use in-memory containers for tests
- Notification center - verify requests without sending actual notifications

**What NOT to Mock:**
- Model value calculations (progress, remaining, categoryIcon) - test directly
- Codable encoding/decoding - test with real JSONEncoder/Decoder
- Local file operations - use temporary test directories

## Fixtures and Test Data

**No fixtures exist.** If implemented:

```swift
// In Tests/Fixtures/BudgetFixtures.swift
struct BudgetFixtures {
    static let sampleBudget = BudgetModel(
        id: UUID().uuidString,
        name: "Groceries",
        category: "Food",
        amount: 500,
        spent: 250,
        period: "monthly",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 30)
    )

    static let sampleBudgets = [
        BudgetFixtures.sampleBudget,
        BudgetModel(name: "Transport", category: "Transport", amount: 200, spent: 100, ...)
    ]
}

// Usage
let budgets = BudgetFixtures.sampleBudgets
let summary = viewModel.budgetSummary(from: budgets)
```

**Location:** Would go in `Tests/Fixtures/` or `Tests/Helpers/`

## Coverage

**Requirements:** None enforced

**Current state:** No code coverage reporting

**If implemented, recommended targets:**
- Core logic (ViewModels, Models): 80%+ coverage
- API client: 70%+ coverage
- UI views: 30%+ (snapshot tests sufficient)
- Services: 60%+ coverage

## Test Types

**Unit Tests (Would test):**
- ViewModel computation functions
- Model value calculations
- Enum cases and associated values
- Guard statements and early returns

**Integration Tests (Would test):**
- APIClient with URLSession mocks
- AuthManager token storage and retrieval
- SwiftData model persistence
- Notification scheduling logic

**UI/Snapshot Tests (Would test):**
- View layout with different data states
- Empty state, loading state, error state displays
- Accessibility labels and ordering
- Dark mode appearance

**Not applicable:**
- E2E tests - No web UI or multi-app scenarios

## Error Scenario Testing

**No error tests exist.** If implemented:

```swift
// APIClient error handling
func testFetchPortfolio_WithNetworkError_UpdatesErrorMessage() {
    // Arrange
    let mockClient = MockAPIClient(error: URLError(.networkConnectionLost))
    let sut = StocksViewModel(apiClient: mockClient)

    // Act
    await sut.fetchPortfolio()

    // Assert
    XCTAssertEqual(sut.errorMessage, "Failed to load portfolio")
}

// SwiftData query failure
func testAddBudget_WithInvalidAmount_DoesNotInsert() {
    // Arrange
    let modelContext = ModelContext(ModelContainer(for: BudgetModel.self, inMemory: true))

    // Act
    let budget = BudgetModel(amount: -50)  // Invalid
    // Should not insert

    // Assert
    // Query should return empty
}
```

## Async Testing

**Pattern (if implemented):**

```swift
// Using async/await syntax
func testFetchPortfolio_SuccessfulRequest_UpdatesPortfolio() async throws {
    // Arrange
    let expectedPortfolio = Portfolio(totalValue: 10000, dayChange: 150)
    let mockClient = MockAPIClient(result: expectedPortfolio)
    let sut = StocksViewModel(apiClient: mockClient)

    // Act
    await sut.fetchPortfolio()

    // Assert
    XCTAssertEqual(sut.portfolio?.totalValue, 10000)
}
```

## Recommended Testing Roadmap

**Phase 1 (Core Models):**
1. Add unit tests for model calculations
   - `BudgetModel.progress`, `BudgetModel.remaining`
   - `GoalModel.progress`, `GoalModel.daysRemaining`
   - `Budget.categoryIcon` property mapping

**Phase 2 (Business Logic):**
2. Add unit tests for ViewModels
   - `BudgetViewModel.budgetSummary()`
   - `StocksViewModel.searchStocks()` validation
   - `DashboardViewModel.fetchDashboardData()` concurrent execution

**Phase 3 (Network & Services):**
3. Add integration tests
   - `APIClient.request()` with mock URLSession
   - `AuthManager` token lifecycle
   - `LocalDataManager` persistence

**Phase 4 (UI):**
4. Add snapshot/UI tests for key views
   - `BudgetListView` rendering
   - `PortfolioView` chart display
   - Form validation in add views

## CI Integration

**Current workflow:** Only builds, doesn't test

**To enable testing, update `.github/workflows/ci.yml`:**

```yaml
- name: Build and Test iOS
  run: |
    cd apps/ios
    xcodebuild -scheme OvaFlus -destination 'platform=iOS Simulator,name=iPhone 15' clean build test
    xcodebuild -scheme OvaFlus -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath ./build -resultBundlePath ./build/test.xcresult test
```

---

*Testing analysis: 2026-02-20*
