# Codebase Concerns

**Analysis Date:** 2026-02-20

## Tech Debt

**Development Bypass in LoginView:**
- Issue: Hardcoded dev-only bypass button that directly sets `authManager.isAuthenticated = true` without token validation
- Files: `Core/Auth/AuthManager.swift` (lines 199-222)
- Impact: Allows unprotected access to entire app during development. Must be removed before production release. No authentication check occurs, bypassing security.
- Fix approach: Remove the "DEV ONLY" section entirely. Use environment flag or build configuration to conditionally include dev features, not string checks visible in compiled binary.

**Generic Error Handling with Silent Failures:**
- Issue: Multiple view models and services silently fail with try-catch blocks that only set generic error messages
- Files: `Features/Stocks/StocksViewModel.swift` (lines 39-41, 49-51, 63-65, 88-90), `Features/Budget/BudgetViewModel.swift`, `Core/Auth/AuthManager.swift` (lines 102-104)
- Impact: Users cannot diagnose issues (network vs server vs auth). Makes debugging difficult. No distinction between 404 vs 500 vs timeout errors.
- Fix approach: Create error enum with specific cases (networkError, authError, notFoundError, serverError). Log errors with context before silently failing. Provide meaningful error messages to users.

**Mock Chart Data Generation:**
- Issue: Stock portfolio and watchlist charts generate random synthetic data instead of using real data
- Files: `Features/Stocks/StocksViewModel.swift` (lines 102-110), `Features/Stocks/PortfolioView.swift`
- Impact: Charts are misleading and don't reflect actual portfolio performance. Users see fabricated trends that don't match real prices.
- Fix approach: Fetch real historical data from API. Cache data locally for offline support using LocalDataManager. Fall back to current quote only if historical data unavailable.

**LocalDataManager Silent Error Handling:**
- Issue: All try-catch blocks in LocalDataManager are silently swallowed with no logging or error handling
- Files: `Core/Persistence/LocalDataManager.swift` (lines 20-23, 36-39, 46-49, 57-59)
- Impact: Data corruption, encoding failures, or disk space issues go undetected. User data loss without notification.
- Fix approach: Log all encoding/decoding errors to debug or error level. Implement error recovery (e.g., clear corrupted cache). Return Result types to surface errors to callers.

**Crude Transaction Amount Input Validation:**
- Issue: Transaction amount validation relies on simple `Double(amount) > 0` check without handling edge cases
- Files: `Features/Budget/AddTransactionView.swift` (line 97), `Features/Budget/AddBudgetView.swift` (line 88)
- Impact: No validation for very large numbers, negative values from paste-in, special characters. No locale-specific decimal separator handling (European "," vs US ".").
- Fix approach: Create Decimal-based input validator. Handle all decimal separator locales. Enforce reasonable max limits (e.g., 999,999,999.99). Provide user feedback on invalid input before save.

**Notification Service Identity Generation:**
- Issue: Goal notification IDs generated with string replacement of spaces and Unix timestamp - collision risk
- Files: `Core/Notifications/NotificationService.swift` (line 67)
- Impact: Multiple goals with same name can generate duplicate IDs. Old notifications not cancelled properly.
- Fix approach: Use UUID for notification IDs instead. Store mapping of goal ID to notification ID in LocalDataManager.

## Known Bugs

**ModelContainer Fatal Error on Initialization:**
- Symptoms: App crashes on launch if SwiftData ModelContainer initialization fails
- Files: `OvaFlusApp.swift` (line 20)
- Trigger: Corrupted database file, disk space issue, or invalid schema
- Workaround: None - user must reinstall app. Add database recovery/migration logic before container creation.

**Budget Spent Amount Not Persisted:**
- Symptoms: Budget.spent value incremented in memory but not persisted to SwiftData during transaction add
- Files: `Features/Budget/AddTransactionView.swift` (line 112)
- Trigger: Create expense transaction for a budget
- Workaround: None - app shows incorrect remaining balance. Fix: Call `try? modelContext.save()` after updating budget.spent.

**Token Expiration Check Not Enforced:**
- Symptoms: Expired tokens remain in use if they expire between app sessions
- Files: `Core/Auth/AuthManager.swift` (lines 87-96)
- Trigger: User keeps app in background for extended period, token expires before they reopen app
- Workaround: Force sign out and re-authenticate. Fix: Wrap APIClient requests with automatic token refresh on 401 response.

**Missing LoginView Import:**
- Symptoms: LoginView referenced in OvaFlusApp.swift but definition may not compile if not in same module
- Files: `OvaFlusApp.swift` (line 35), `Core/Auth/AuthManager.swift` (lines 109-229)
- Trigger: Check compiler output - LoginView embedded in AuthManager.swift as placeholder
- Workaround: Currently works but should be in separate file. Refactor into Features/Auth/LoginView.swift after moving to proper module.

**Profile Fetch Failure Not Propagated:**
- Symptoms: User marked authenticated even if profile fetch fails
- Files: `Core/Auth/AuthManager.swift` (lines 99-105)
- Trigger: Valid token but profile endpoint unavailable or permission denied
- Workaround: None - app may be in partially authenticated state. Fix: Explicitly handle profile fetch errors and prevent app access if profile unavailable.

## Security Considerations

**Tokens Stored in UserDefaults Without Encryption:**
- Risk: AuthTokens (including refreshToken and accessToken) stored as plain encoded JSON in UserDefaults. Can be extracted via:
  - Device backup files if not encrypted
  - Debugger inspection
  - Jailbroken device filesystem access
  - App sandbox escape vulnerabilities
- Files: `Core/Persistence/LocalDataManager.swift` (lines 19-28), `Core/Auth/AuthManager.swift` (lines 22-30)
- Current mitigation: UserDefaults is app-sandboxed, tokens expire
- Recommendations:
  - Store tokens in Keychain instead of UserDefaults (iOS standard for secrets)
  - Use `SecureEnclave` for refresh token if iOS 11+
  - Implement short-lived access token (15 min) with longer refresh token (7 days)
  - Clear tokens immediately on biometric/passcode failure

**Biometric Auth Bypass Possible:**
- Risk: BiometricAuth return value not validated for actual success - only checks `bool(forKey: "biometric_enabled")`
- Files: `Core/Auth/AuthManager.swift` (lines 81-84, 74-78)
- Current mitigation: User still needs to authenticate on device first time
- Recommendations:
  - Verify biometric authentication actually succeeded before setting flag
  - Re-authenticate on sensitive operations (delete budget, view holdings)
  - Add rate limiting to prevent brute force attempts
  - Implement account lockout after N failed biometric attempts

**No Certificate Pinning:**
- Risk: Man-in-the-middle attack possible if attacker has valid cert for api.ova-flus.com
- Files: `Core/Network/APIClient.swift`
- Current mitigation: None - standard TLS only
- Recommendations:
  - Implement certificate pinning with backup pin
  - Use TrustKit or similar framework
  - Pin both public key and certificate

**API Endpoint Hardcoded Base URL:**
- Risk: Base URL from environment variable but no validation of URL format or domain
- Files: `Core/Network/APIClient.swift` (line 7)
- Current mitigation: Default to api.ova-flus.com if env var missing
- Recommendations:
  - Validate URL scheme is HTTPS only in non-debug builds
  - Warn if connecting to non-production domain
  - Never allow HTTP in production

**No Input Sanitization on API Requests:**
- Risk: User input passed directly to API paths via string interpolation
- Files: `Core/Network/APIEndpoints.swift` (line 69 - searchStocks path building)
- Current mitigation: Some encoding with `addingPercentEncoding` but incomplete
- Recommendations:
  - Use URLComponents to build URLs safely with query parameters
  - Validate transaction amount range before API call
  - Sanitize all user input before inclusion in requests

## Performance Bottlenecks

**Unoptimized @Query for Large Transaction Lists:**
- Problem: AnalyticsView queries ALL transactions without filtering, then filters in-memory
- Files: `Features/Analytics/AnalyticsView.swift` (line 6)
- Cause: SwiftData @Query decorator doesn't support complex predicates; iOS loads entire dataset
- Improvement path: Add FetchDescriptor with date range predicate in AnalyticsViewModel before @Query. Implement pagination for 1000+ transactions.

**Redundant API Calls in PortfolioView:**
- Problem: `fetchPortfolio()` called on .task and .refreshable, chart data regenerated synchronously on every call
- Files: `Features/Stocks/PortfolioView.swift` (lines 161-162, 158-159), `StocksViewModel.swift` (lines 31-42)
- Cause: No debouncing, refresh gesture triggers immediate fetch without checking last-fetch timestamp
- Improvement path: Add last fetch timestamp to viewModel. Debounce rapid fetches to max once per 30 seconds. Move chart generation to background thread.

**Category Breakdown Recalculated Every Render:**
- Problem: `categoryBreakdown()` called every time BudgetListView renders
- Files: `Features/Budget/BudgetViewModel.swift` (lines 13-23)
- Cause: Not memoized or cached. Inefficient for 100+ budgets
- Improvement path: Cache results in @Published property. Invalidate cache only when budgets change. Consider computed property in SwiftData model.

**Chart Data Generation Uses Random Seeding:**
- Problem: `generateChartData()` creates 30 random data points synchronously on main thread every time stock detail loads
- Files: `Features/Stocks/StocksViewModel.swift` (lines 102-110)
- Cause: Uses `Double.random()` without seeding - different data on every load. Inefficient for animation.
- Improvement path: Fetch real historical data. If unavailable, generate synthetic data with fixed seed for consistency. Move to background thread if keeping synthetic generation.

## Fragile Areas

**AuthManager Token Refresh Logic:**
- Files: `Core/Auth/AuthManager.swift` (lines 64-71)
- Why fragile:
  - Silent failure if refresh fails (line 66 - signOut called but not awaited)
  - No retry mechanism for network errors
  - Concurrent access to tokens property not thread-safe despite @MainActor
  - No timeout handling if refresh hangs
- Safe modification:
  - Create dedicated TokenRefreshError enum
  - Implement exponential backoff retry with max attempts
  - Add URLSession timeout configuration in APIClient
  - Test concurrent refresh calls (e.g., multiple simultaneous requests with expired token)

**SwiftData Model Relationships:**
- Files: `Models/SwiftDataModels.swift` (line 17, 68)
- Why fragile:
  - BudgetModel.transactions cascade delete could orphan TransactionModels if relationship broken
  - TransactionModel.budget optional reference but budgetId still stored - can become inconsistent
  - No validation that budgetId matches budget relationship
- Safe modification:
  - Add invariant checks in init() that budgetId == budget?.id or both nil
  - Write unit tests that verify cascade delete cleans up all transactions
  - Consider denormalizing: keep only bidirectional @Relationship, not ID strings

**APIClient Error Handling:**
- Files: `Core/Network/APIClient.swift` (lines 25-26)
- Why fragile:
  - All non-200-299 responses throw same `badServerResponse` error
  - No distinction between client error (400), auth error (401), server error (500)
  - Caller cannot differentiate and retry appropriately
  - Empty response bodies not handled
- Safe modification:
  - Decode error response JSON structure from server
  - Create APIError enum with associated values: case unauthorized(message: String), case notFound, case serverError(statusCode: Int)
  - Test with mock 401, 403, 404, 500 responses

**BudgetListView Delete Action:**
- Files: `Features/Budget/BudgetListView.swift` (lines 77-81)
- Why fragile:
  - No confirmation prompt before deleting budget
  - Deletes cascade to all transactions (unrecoverable)
  - No undo capability
  - No notification shown to user after successful delete
- Safe modification:
  - Add confirmation alert before delete
  - Show toast notification of successful deletion
  - Consider soft-delete (mark as inactive) instead of hard delete
  - Test that all child transactions are deleted with budget

**NotificationService Center Delegate:**
- Files: `Core/Notifications/NotificationService.swift` (lines 6-13)
- Why fragile:
  - Singleton pattern with private init() - hard to test
  - center.delegate assignment happens in init - could be overwritten by other code
  - userNotificationCenter delegate called nonisolated but accesses MainActor state
- Safe modification:
  - Create protocol for testing (NotificationCenterDelegate)
  - Add delegate assertion in didFinishLaunching
  - Ensure all delegate methods are nonisolated or properly isolated

## Scaling Limits

**SwiftData Query Performance at Scale:**
- Current capacity: Untested, likely <10,000 transactions before UI lag
- Limit: @Query decorators load entire result set into memory. 50,000+ transactions could cause 50-100MB memory spike
- Scaling path:
  - Implement pagination with FetchDescriptor
  - Add date range filtering (show only last 90 days by default)
  - Consider moving to Core Data if scaling to 100k+ records
  - Implement background sync with cloud database

**Local Cache Storage:**
- Current capacity: Caches directory on device, typically 1-5GB available after OS
- Limit: No cleanup mechanism. clearCache() only called manually. Old stock quotes, news articles accumulate.
- Scaling path:
  - Implement cache expiration (e.g., 7 days for stock quotes, 30 days for news)
  - Add cache size limit with LRU eviction
  - Monitor free disk space and alert user if <100MB available
  - Compress old cached data

**Live Chart Data Memory:**
- Current capacity: 30-point charts regenerated per stock
- Limit: If user has 100+ holdings, generating charts for each creates 3,000+ chart points in memory
- Scaling path:
  - Lazy-load charts on scroll (virtualize with LazyVStack)
  - Reduce chart resolution (downsample to 10 points for batch view)
  - Pre-compute and cache chart data in LocalDataManager

**API Request Concurrency:**
- Current capacity: URLSession.shared has default max 6 concurrent requests
- Limit: Searching for 50 stocks simultaneously could queue requests
- Scaling path:
  - Implement request batching/pagination in stock search
  - Add request queue with priority (user-triggered > background)
  - Limit concurrent requests to 3-4 with semaphore

## Dependencies at Risk

**SwiftData (iOS 17+ only):**
- Risk: Framework relatively new (released iOS 17, 2023). Limited community solutions for edge cases. Breaking changes possible in minor updates.
- Impact: If app requires iOS < 17 support, entire data layer must be rewritten to Core Data or Realm.
- Migration plan: Keep Core Data migration path documented. SwiftData -> Core Data converter is non-trivial. Test on iOS 17.0, 17.1, 17.2 for compatibility.

**Charts Framework:**
- Risk: Undocumented performance issues with large datasets. API changes in minor versions.
- Impact: Slow rendering if portfolio has 100+ holdings. Pie/donut charts may not be optimized.
- Migration plan: Have Realm Charts or MPAndroidChart as fallback. Test with 1000-point datasets.

**Biometric Auth Framework:**
- Risk: Hardware-dependent. May fail on devices without Face ID/Touch ID.
- Impact: BiometricAuth.shared calls could fail silently or crash if hardware unsupported.
- Migration plan: Graceful fallback to password auth. Check availability with `LAContext.canEvaluatePolicy()` before presenting option.

## Missing Critical Features

**No Offline Support:**
- Problem: App requires constant network connectivity. Cannot view past budgets, portfolio, or analytics offline.
- Blocks: Mobile-first finance app should work on flights, tunnels, poor signal areas.
- Workaround: Implement sync on-demand using LocalDataManager cache. Fetch latest data when online, cache results, serve cached data when offline. Mark data as stale in UI if last-fetch > 1 hour.

**No Error Recovery Mechanism:**
- Problem: Network errors, API failures, data corruption have no recovery flow.
- Blocks: User sees generic "Failed to load" message with no action to retry.
- Workaround: Add retry button to error messages. Implement exponential backoff retry internally for transient errors. Show last-known-good data while retrying.

**No Audit Trail or History:**
- Problem: Transactions, budget edits, holdings changes have no audit log.
- Blocks: Cannot see who/when/how budget amounts changed. Can't detect fraudulent modifications.
- Workaround: Add `modifiedBy`, `modifiedAt`, `change` fields to models. Log all mutations before save. Implement history view.

**No Data Export:**
- Problem: No way to export budgets, transactions, or portfolio data for tax/audit purposes.
- Blocks: Users cannot back up data or import to other finance apps.
- Workaround: Add CSV/PDF export buttons. Format transactions as OFX (banking standard). Allow scheduled email exports.

**No Biometric-Protected Data:**
- Problem: Even with biometric enabled, once unlocked, all financial data visible without re-auth.
- Blocks: Not suitable for shared devices or public use.
- Workaround: Require biometric re-auth for sensitive views (view portfolio, transactions > $1000). Implement session timeout (lock after 15 min inactivity).

## Test Coverage Gaps

**No Error Path Testing:**
- What's not tested: Network errors, API 500s, invalid JSON responses, timeout scenarios
- Files: `Core/Network/APIClient.swift`, all ViewModels
- Risk: Crashes or silent data loss if unexpected error format returned from backend
- Priority: High - error paths are most critical for app stability

**No Validation Testing:**
- What's not tested: Edge cases in amount input (negative, zero, very large), date picker ranges, empty category list
- Files: `Features/Budget/AddBudgetView.swift`, `Features/Budget/AddTransactionView.swift`
- Risk: Invalid data saved to SwiftData, UI crashes with unexpected input
- Priority: High - users will input invalid data accidentally

**No SwiftData Migration Testing:**
- What's not tested: DataMigrationService with actual corrupt data, schema changes, version upgrades
- Files: `Core/Persistence/DataMigrationService.swift`
- Risk: Data loss during app updates if migration breaks
- Priority: High - migration errors affect all users on version upgrade

**No Concurrent Access Testing:**
- What's not tested: Multiple ViewModels fetching data simultaneously, token refresh while other request pending, AuthManager @MainActor isolation
- Files: `Core/Auth/AuthManager.swift`, `Features/Stocks/StocksViewModel.swift`, `Features/Budget/BudgetViewModel.swift`
- Risk: Race conditions, incorrect auth state, duplicate API calls
- Priority: Medium - affects app reliability under load

**No Notification Testing:**
- What's not tested: Notification scheduling, budget alert thresholds, notification center delegate
- Files: `Core/Notifications/NotificationService.swift`
- Risk: Notifications never fire, alerts shown at wrong time, duplicate notifications
- Priority: Medium - core feature but not critical to function

---

*Concerns audit: 2026-02-20*
