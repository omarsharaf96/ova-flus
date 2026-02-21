# OvaFlus iOS App

Native iOS application built with SwiftUI. Provides budget tracking, transaction management, and stock portfolio features with a native iOS experience including Face ID authentication, widgets, and Apple Watch companion app support.

## Tech Stack

- SwiftUI (iOS 17+)
- Swift Charts for data visualization
- Swift Package Manager for dependencies
- AWS Amplify iOS SDK for backend integration
- WidgetKit for home screen widgets
- LocalAuthentication for Face ID / Touch ID

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS 14.0+ (for development)
- Apple Developer Account (for device testing and TestFlight)

## Getting Started

### 1. Clone and open the project

```bash
cd apps/ios
open Package.swift
```

Or open the `OvaFlus` directory in Xcode.

### 2. Configure API endpoint

Set the `API_BASE_URL` environment variable in your Xcode scheme:

1. Product > Scheme > Edit Scheme
2. Run > Arguments > Environment Variables
3. Add `API_BASE_URL` with value `http://localhost:3000/v1` (for local development)

For production, the default endpoint `https://api.ova-flus.com/v1` is used.

### 3. Set up AWS Amplify

1. Install the Amplify CLI: `npm install -g @aws-amplify/cli`
2. Run `amplify init` in the project root
3. Copy the generated `amplifyconfiguration.json` to the `OvaFlus/` directory
4. Ensure the file is added to the Xcode project

### 4. Running on Simulator

1. Select a simulator target (iPhone 15 Pro recommended)
2. Press Cmd+R or click the Run button

### 5. Running on Device

1. Select your connected device as the target
2. Ensure your Apple Developer team is configured in Signing & Capabilities
3. Press Cmd+R

## Project Structure

```
OvaFlus/
├── OvaFlusApp.swift              # App entry point
├── ContentView.swift             # Main TabView navigation
├── Features/
│   ├── Dashboard/                # Home dashboard with summary cards
│   ├── Budget/                   # Budget management and transactions
│   ├── Stocks/                   # Portfolio and stock tracking
│   └── Profile/                  # User profile and settings
├── Core/
│   ├── Network/                  # API client and endpoints
│   ├── Auth/                     # Authentication and biometrics
│   ├── Persistence/              # Local data caching
│   └── Extensions/               # Color theme and view helpers
├── Models/                       # Data models (User, Budget, Transaction, Portfolio)
├── OvaFlusWidget/                # WidgetKit home screen widget
└── Info.plist                    # App configuration
```

## TestFlight Distribution

1. Archive the project: Product > Archive
2. In the Organizer, click "Distribute App"
3. Select "App Store Connect" and follow the prompts
4. In App Store Connect, add testers to the TestFlight build

## Key Features

- **Dashboard**: Overview of budget spending (donut chart), portfolio value, and recent transactions
- **Budget Tracking**: Create budgets by category, track spending with progress bars
- **Transaction Entry**: Quick add with category picker, date, merchant, notes, and receipt scanning
- **Stock Portfolio**: Holdings list, performance charts, watchlist with live prices
- **Biometric Auth**: Face ID / Touch ID for secure access
- **Home Screen Widget**: Budget summary and portfolio value at a glance
- **Offline Support**: Local data caching for offline access
