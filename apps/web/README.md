# OvaFlus Web App

Progressive web application built with Next.js 14 (App Router). Provides the full OvaFlus experience in the browser with SSR for performance and SEO, offline support via service workers, and responsive design for desktop and mobile.

## Tech Stack

- Next.js 14 (App Router)
- React 18 with Server Components
- Tailwind CSS for styling
- Zustand for client state management
- React Query for server state
- Recharts for data visualization
- AWS Amplify for authentication (Cognito)
- PWA support via next-pwa

## Prerequisites

- Node.js 18+ (recommended: 20 LTS)
- npm 9+

## Getting Started

1. Install dependencies:

```bash
npm install
```

2. Set up environment variables:

```bash
cp .env.local.example .env.local
```

Edit `.env.local` with your configuration values:

- `NEXT_PUBLIC_API_URL` - Backend API base URL
- `NEXT_PUBLIC_GRAPHQL_URL` - GraphQL endpoint
- `NEXT_PUBLIC_AWS_REGION` - AWS region for Cognito
- `NEXT_PUBLIC_COGNITO_USER_POOL_ID` - Cognito User Pool ID
- `NEXT_PUBLIC_COGNITO_CLIENT_ID` - Cognito App Client ID

3. Run the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm start` | Start production server |
| `npm run lint` | Run ESLint |
| `npm run type-check` | Run TypeScript compiler check |

## Building for Production

```bash
npm run build
npm start
```

## PWA Testing

The PWA service worker is disabled in development mode. To test PWA features:

1. Build the production version: `npm run build`
2. Start the production server: `npm start`
3. Open Chrome DevTools > Application > Service Workers to verify registration
4. Check the Manifest tab for install prompt readiness

## Project Structure

```
app/
  (auth)/          # Auth pages (login, register)
  (dashboard)/     # Main app pages (dashboard, budgets, portfolio, etc.)
  layout.tsx       # Root layout
  globals.css      # Global styles
components/
  layout/          # Sidebar, TopNav, MobileTabBar
  ui/              # Reusable UI components (Button, Card, Modal, etc.)
  charts/          # Recharts chart components
  budget/          # Budget domain components
  portfolio/       # Portfolio domain components
  Providers.tsx    # App-wide providers (React Query, Theme)
lib/
  api/             # API client and endpoint functions
  auth/            # AWS Amplify auth configuration
  hooks/           # React Query hooks
  store/           # Zustand stores (auth, UI)
public/
  manifest.json    # PWA manifest
```
