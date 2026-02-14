# OVA FLUS - Cross-Platform Finance Management Application

A comprehensive personal finance management application that unifies budget tracking and stock portfolio management into a seamless cross-platform experience.

## 🌟 Features

### Budget Tracking
- Create and manage multiple budgets (monthly, weekly, yearly)
- Categorize expenses with customizable categories
- Real-time budget monitoring and alerts
- Visual progress indicators for each category
- Transaction history and detailed reporting
- Budget utilization analytics

### Stock Portfolio Management
- Track multiple investment portfolios
- Real-time stock price updates
- Automatic profit/loss calculations
- Transaction history (buy/sell)
- Portfolio performance metrics
- Holdings overview with detailed analytics

### Cross-Platform Support
- **Web**: Modern responsive web application (React)
- **Mobile**: iOS and Android apps (Flutter)
- **Desktop**: macOS support (Flutter)
- **Backend**: RESTful API for data synchronization

## 🏗️ Architecture

### Project Structure
```
ova-flus/
├── backend/          # Node.js/Express API server
│   ├── routes/       # API route handlers
│   ├── controllers/  # Business logic
│   ├── models/       # Data models
│   └── server.js     # Server entry point
├── web/              # React web application
│   ├── src/
│   │   ├── components/  # Reusable UI components
│   │   ├── pages/       # Page components
│   │   ├── services/    # API services
│   │   └── styles/      # CSS styling
│   └── public/       # Static assets
├── mobile/           # Flutter mobile/desktop app
│   ├── lib/
│   │   ├── screens/  # UI screens
│   │   ├── services/ # API integration
│   │   └── models/   # Data models
│   └── pubspec.yaml  # Flutter dependencies
└── shared/           # Shared data models
    └── models/       # Common data structures
```

## 🚀 Getting Started

### Prerequisites
- Node.js 16+ and npm
- Flutter SDK 3.0+
- Git

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file (copy from `.env.example`):
```bash
cp .env.example .env
```

4. Start the server:
```bash
npm start
# or for development with auto-reload
npm run dev
```

The API server will run on `http://localhost:3000`

### Web Application Setup

1. Navigate to the web directory:
```bash
cd web
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm start
```

The web app will run on `http://localhost:3001`

### Mobile Application Setup

1. Navigate to the mobile directory:
```bash
cd mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run on your device/emulator:
```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android

# For macOS
flutter run -d macos
```

## 📚 API Documentation

### Base URL
```
http://localhost:3000/api
```

### Endpoints

#### Budget Management
- `GET /api/budgets` - Get all budgets
- `GET /api/budgets/:id` - Get budget by ID
- `POST /api/budgets` - Create new budget
- `PUT /api/budgets/:id` - Update budget
- `DELETE /api/budgets/:id` - Delete budget
- `GET /api/budgets/:id/transactions` - Get budget transactions
- `POST /api/budgets/:id/transactions` - Add transaction

#### Portfolio Management
- `GET /api/portfolios` - Get all portfolios
- `GET /api/portfolios/:id` - Get portfolio by ID
- `POST /api/portfolios` - Create new portfolio
- `PUT /api/portfolios/:id` - Update portfolio
- `DELETE /api/portfolios/:id` - Delete portfolio
- `GET /api/portfolios/:id/transactions` - Get portfolio transactions
- `POST /api/portfolios/:id/transactions` - Add transaction
- `GET /api/portfolios/:id/performance` - Get performance metrics

#### Stock Data
- `GET /api/stocks/quote/:symbol` - Get stock quote
- `GET /api/stocks/search?q=query` - Search stocks
- `GET /api/stocks/trending` - Get trending stocks
- `POST /api/stocks/quotes` - Get multiple quotes

#### User Management
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `GET /api/users/preferences` - Get preferences
- `PUT /api/users/preferences` - Update preferences

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout

## 🎨 Technology Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **API Style**: RESTful
- **Authentication**: JWT (planned)
- **Database**: MongoDB (planned)

### Web Frontend
- **Framework**: React 18
- **Routing**: React Router 6
- **HTTP Client**: Axios
- **Charts**: Recharts
- **Styling**: CSS3, Styled Components

### Mobile/Desktop
- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **HTTP Client**: http package
- **Charts**: fl_chart
- **Navigation**: go_router

## 🔒 Security Features (Planned)
- JWT-based authentication
- Secure password hashing
- HTTPS/TLS encryption
- Input validation and sanitization
- Rate limiting
- CORS protection

## 📱 Platform Features

### Web Application
- Responsive design for all screen sizes
- Real-time data updates
- Interactive charts and graphs
- Intuitive navigation
- Fast load times

### Mobile Application
- Native iOS and Android support
- Offline data caching
- Pull-to-refresh
- Push notifications (planned)
- Biometric authentication (planned)

### Desktop Application
- macOS native experience
- Menu bar integration (planned)
- Keyboard shortcuts
- Multi-window support

## 🔄 Data Synchronization
All platforms connect to the same backend API, ensuring:
- Real-time data consistency
- Seamless cross-device experience
- Centralized data storage
- Automatic sync on app launch

## 🛠️ Development

### Running Tests
```bash
# Backend
cd backend
npm test

# Web
cd web
npm test

# Mobile
cd mobile
flutter test
```

### Building for Production

#### Web
```bash
cd web
npm run build
```

#### Mobile
```bash
cd mobile
# iOS
flutter build ios

# Android
flutter build apk

# macOS
flutter build macos
```

## 📝 License
MIT License

## 👥 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Contact
For questions or support, please open an issue on GitHub. 
