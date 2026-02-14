# OvaFlus Desktop (macOS)

Native macOS application built with SwiftUI. Shares core logic with the iOS app while providing a desktop-optimized experience with multi-window support, menu bar widget, and keyboard shortcuts.

## Requirements

- Xcode 15.0+
- macOS 14.0+ (Sonoma) deployment target
- Swift 5.9+

## Tech Stack

- SwiftUI for UI
- Swift Charts for data visualization
- NavigationSplitView for sidebar navigation
- Keychain Services for secure token storage
- AWS Amplify Swift SDK for backend integration

## Project Structure

```
OvaFlusDesktop/
├── OvaFlusDesktopApp.swift      # App entry point, window + menu bar setup
├── AppState.swift               # Global observable state
├── OvaFlusCommands.swift        # macOS menu bar commands
├── Views/
│   ├── MainWindowView.swift     # NavigationSplitView sidebar
│   ├── Auth/
│   │   └── LoginView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift  # Multi-column dashboard
│   ├── Budget/
│   │   ├── BudgetListView.swift
│   │   ├── BudgetDetailView.swift
│   │   └── AddTransactionSheet.swift
│   ├── Transactions/
│   │   └── TransactionListView.swift
│   ├── Portfolio/
│   │   ├── PortfolioView.swift
│   │   └── StockDetailView.swift
│   ├── Watchlist/
│   │   └── WatchlistView.swift
│   ├── MenuBar/
│   │   └── MenuBarView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Core/
│   ├── Network/
│   │   └── APIClient.swift
│   ├── Auth/
│   │   └── AuthManager.swift
│   └── DragDrop/
│       └── ReceiptDropDelegate.swift
└── Models/
    ├── Budget.swift
    ├── Transaction.swift
    ├── Portfolio.swift
    └── User.swift
```

## Building and Running

### Using Swift Package Manager

```bash
cd apps/macos
swift build
swift run
```

### Using Xcode

1. Open `Package.swift` in Xcode
2. Select the `OvaFlusDesktop` scheme
3. Press Cmd+R to build and run

## Code Signing for Distribution

For distributing outside the Mac App Store:

1. Create a Developer ID certificate in your Apple Developer account
2. In Xcode, select your team under Signing & Capabilities
3. Archive the app: Product > Archive
4. Distribute with Developer ID signing
5. Notarize the app: `xcrun notarytool submit`

For Mac App Store distribution:

1. Add a sandbox entitlements file
2. Configure App Store signing
3. Submit via Xcode Organizer or Transporter

## Features

- **Multi-window support** — Main window, settings, and menu bar widget
- **Keyboard shortcuts** — Cmd+N (new transaction), Cmd+R (refresh), Cmd+I (import)
- **Menu bar widget** — Quick portfolio and budget overview
- **Drag and drop** — Drop receipt images/PDFs onto transactions
- **Native tables** — Sortable, filterable macOS tables for transactions and holdings
- **Swift Charts** — Spending, portfolio performance, and allocation charts
