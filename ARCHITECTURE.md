# Architecture Overview

## System Architecture

OVA FLUS uses a client-server architecture with multiple client platforms connecting to a central RESTful API.

```
┌─────────────────────────────────────────────────────────┐
│                    Client Layer                          │
├─────────────────┬──────────────┬────────────────────────┤
│   Web (React)   │ Mobile (iOS) │ Mobile (Android/macOS) │
│                 │   Flutter    │      Flutter           │
└────────┬────────┴──────┬───────┴────────┬───────────────┘
         │               │                │
         └───────────────┼────────────────┘
                         │
                    HTTP/REST
                         │
         ┌───────────────┴────────────────┐
         │      Backend API Server         │
         │      (Node.js/Express)         │
         └───────────────┬────────────────┘
                         │
         ┌───────────────┴────────────────┐
         │      Database Layer            │
         │      (MongoDB/PostgreSQL)      │
         └────────────────────────────────┘
```

## Component Architecture

### Backend API

The backend follows a layered architecture:

1. **Routes Layer**: Handles HTTP requests and routing
2. **Controller Layer**: Business logic and validation
3. **Service Layer**: Data processing and external API calls
4. **Model Layer**: Data structures and database schemas

### Web Application

React-based SPA with component-driven architecture:

1. **Pages**: Top-level page components
2. **Components**: Reusable UI components
3. **Services**: API communication layer
4. **Utils**: Helper functions and utilities

### Mobile Application

Flutter application with widget-based architecture:

1. **Screens**: Full-page widgets
2. **Widgets**: Reusable UI components
3. **Services**: API and local storage
4. **Models**: Data models

## Data Flow

### Budget Tracking Flow
```
User Input → Web/Mobile UI → API Request → Backend Validation
→ Data Processing → Database Update → Response → UI Update
```

### Portfolio Management Flow
```
User Transaction → UI Form → API Request → Backend Processing
→ Portfolio Calculation → Stock Price Update (if needed)
→ Database Update → Response → UI Refresh
```

## API Design

### RESTful Principles
- Resource-based URLs
- HTTP methods (GET, POST, PUT, DELETE)
- JSON request/response format
- Stateless communication
- Standard HTTP status codes

### Authentication Flow (Planned)
```
Login Request → Backend Validation → JWT Generation
→ Token Storage (Client) → Authenticated Requests (with token)
→ Token Verification → Protected Resource Access
```

## Data Models

### Budget Model
```javascript
{
  id: string,
  userId: string,
  name: string,
  period: 'monthly' | 'weekly' | 'yearly',
  totalLimit: number,
  categories: [
    {
      id: string,
      name: string,
      limit: number,
      spent: number,
      color: string,
      icon: string
    }
  ]
}
```

### Portfolio Model
```javascript
{
  id: string,
  userId: string,
  name: string,
  cash: number,
  holdings: [
    {
      id: string,
      stockId: string,
      symbol: string,
      shares: number,
      avgPurchasePrice: number,
      currentPrice: number
    }
  ]
}
```

## Security Considerations

1. **Authentication**: JWT-based authentication
2. **Authorization**: Role-based access control
3. **Data Validation**: Input sanitization and validation
4. **HTTPS**: Encrypted communication
5. **CORS**: Configured for allowed origins
6. **Rate Limiting**: API request throttling

## Scalability

### Horizontal Scaling
- Stateless API design allows multiple instances
- Load balancer distribution
- Database connection pooling

### Caching Strategy
- Client-side caching for static data
- Server-side caching for frequently accessed data
- Cache invalidation on data updates

### Performance Optimization
- Lazy loading of components
- Pagination for large datasets
- Optimized database queries
- CDN for static assets

## Deployment Architecture

### Development
```
Local Machine → Backend (localhost:3000) + Web (localhost:3001)
```

### Production (Planned)
```
Users → CDN (Static Assets) → Load Balancer
→ App Servers (API) → Database Cluster
```

## Monitoring and Logging

1. **Application Logs**: Request/response logging
2. **Error Tracking**: Centralized error logging
3. **Performance Metrics**: API response times
4. **User Analytics**: Usage patterns and metrics

## Technology Decisions

### Why Node.js?
- JavaScript across full stack
- Large ecosystem (npm)
- Excellent for I/O operations
- Good performance for API services

### Why React?
- Component-based architecture
- Large community and ecosystem
- Virtual DOM for performance
- Excellent developer tools

### Why Flutter?
- Single codebase for multiple platforms
- Native performance
- Rich UI framework
- Hot reload for fast development
