# Sample Web

A React + Vite + TypeScript frontend application that demonstrates the monorepo UI pattern.

## Tech Stack

- **React 19** - UI library
- **TypeScript 6** - Type safety
- **Vite 8** - Build tool and dev server
- **React Router 7** - Client-side routing
- **TanStack Query 5** - Server state management
- **Axios** - HTTP client
- **Vitest** - Unit testing
- **Testing Library** - Component testing

## Project Structure

```
src/
  app/              App root (providers, setup)
  features/         Feature modules (colocated components, hooks, services, types)
    home/           Home page feature
    health/         Health dashboard (connects to sample-api)
  shared/           Shared components, hooks, utilities
    components/     Reusable UI components
    hooks/          Shared custom hooks
    types/          Shared TypeScript types
    utils/          Utility functions
  services/         Base API client configuration
  routes/           Route definitions
  test/             Test setup and utilities
  assets/           Static assets (images, fonts)
```

## Development

```bash
# Install dependencies
npm install

# Start dev server (http://localhost:3000)
npm run dev

# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Type check
npm run type-check

# Lint
npm run lint

# Build for production
npm run build

# Preview production build
npm run preview
```

## Environment Variables

Copy `.env.example` to `.env` and configure:

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API base URL | `http://localhost:8080` |

## Connecting to the API

The dev server proxies `/api` requests to the backend:

```typescript
// Direct usage via the API client
import { apiClient } from '@/services/api';
const data = await apiClient.get('/health');
```

To run with the sample-api backend:

```bash
# From repo root
make up  # Starts sample-api on port 8080

# Then in another terminal
cd apps/sample-web && npm run dev
```

## Adding a New Feature

1. Create a new directory under `src/features/<feature-name>/`
2. Add the standard structure:
   ```
   features/my-feature/
     components/
     hooks/
     services/
     types/
     index.ts
   ```
3. Add a route in `src/routes/index.tsx`
4. Export the public API from `index.ts`
