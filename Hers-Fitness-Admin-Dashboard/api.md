# State Management Guide: TanStack Query + Zustand
> For AI coding agents (Codex, Cursor, Copilot, etc.) — follow this strictly when implementing state in this project.

---

## Core Philosophy

| State Type | Tool | Examples |
|---|---|---|
| **Server / API state** | TanStack Query | Users list, orders, dashboard stats, any GET/POST/PUT/DELETE |
| **Global UI / client state** | Zustand | Auth user, sidebar open, theme, modal visibility, filters |
| **Local component state** | `useState` | Input values, toggles scoped to one component |

**Rule:** Never use Zustand to cache API responses. Never use TanStack Query for UI toggles.

---

## TanStack Query — When & How

### Use TanStack Query for ALL of these:
- Fetching any data from the backend (`GET` requests)
- Creating, updating, or deleting resources (`POST`, `PUT`, `PATCH`, `DELETE`) via `useMutation`
- Paginated or infinite scroll lists
- Data that needs background refetching or cache invalidation
- Loading and error states for API calls

### Setup (do once in `main.tsx`)

```tsx
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
})

root.render(
  <QueryClientProvider client={queryClient}>
    <App />
    <ReactQueryDevtools initialIsOpen={false} />
  </QueryClientProvider>
)
```

### Query Pattern (fetching data)

```tsx
// hooks/useUsers.ts
import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'

export const useUsers = () => {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => api.get('/users').then(res => res.data),
  })
}

// In component:
const { data: users, isLoading, isError, error } = useUsers()
```

### Mutation Pattern (create / update / delete)

```tsx
// hooks/useCreateUser.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'

export const useCreateUser = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (newUser) => api.post('/users', newUser).then(res => res.data),
    onSuccess: () => {
      // Invalidate cache so the users list refetches automatically
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })
}

// In component:
const { mutate: createUser, isPending } = useCreateUser()
createUser({ name: 'Alif', email: 'alif@example.com' })
```

### Query Key Convention

```ts
// Always use array keys, from general → specific
['users']                         // all users
['users', userId]                 // single user
['users', { role: 'admin' }]      // filtered users
['orders', orderId, 'items']      // nested resource
```

### Dependent Queries (fetch B only after A)

```tsx
const { data: user } = useQuery({ queryKey: ['user', id], queryFn: ... })

const { data: orders } = useQuery({
  queryKey: ['orders', user?.id],
  queryFn: () => fetchOrders(user.id),
  enabled: !!user?.id, // only runs after user is loaded
})
```

### Pagination

```tsx
const { data, isPlaceholderData } = useQuery({
  queryKey: ['users', { page }],
  queryFn: () => fetchUsers(page),
  placeholderData: keepPreviousData, // smooth page transitions
})
```

---

## Zustand — When & How

### Use Zustand for ALL of these:
- Auth state (current user, token, role)
- UI layout state (sidebar open/closed, active tab, theme)
- Global filters or search state shared across pages
- Notification/toast queue
- Any state that must persist across route changes but is NOT from an API

### Setup pattern

```ts
// store/authStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  user: User | null
  token: string | null
  setUser: (user: User) => void
  setToken: (token: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      setUser: (user) => set({ user }),
      setToken: (token) => set({ token }),
      logout: () => set({ user: null, token: null }),
    }),
    { name: 'auth-storage' } // persists to localStorage
  )
)
```

```ts
// store/uiStore.ts
import { create } from 'zustand'

interface UIState {
  sidebarOpen: boolean
  toggleSidebar: () => void
  setSidebarOpen: (open: boolean) => void
}

export const useUIStore = create<UIState>()((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
  setSidebarOpen: (open) => set({ sidebarOpen: open }),
}))
```

### Usage in components

```tsx
// Read only what you need — avoid subscribing to whole store
const user = useAuthStore((state) => state.user)
const logout = useAuthStore((state) => state.logout)

// Outside React (e.g. Axios interceptor)
const token = useAuthStore.getState().token
```

---

## Auth Flow — Full Implementation

### 1. Axios instance with interceptors

```ts
// lib/api.ts
import axios from 'axios'
import { useAuthStore } from '@/store/authStore'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
})

// Attach token to every request
api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Handle 401 globally — auto logout
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      useAuthStore.getState().logout()
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)
```

### 2. Login mutation

```ts
// hooks/useLogin.ts
export const useLogin = () => {
  const setUser = useAuthStore((s) => s.setUser)
  const setToken = useAuthStore((s) => s.setToken)

  return useMutation({
    mutationFn: (creds) => api.post('/auth/login', creds).then(r => r.data),
    onSuccess: ({ user, token }) => {
      setToken(token)
      setUser(user)
    },
  })
}
```

### 3. Session hydration on app load

```ts
// hooks/useMe.ts — fetches current user from token
export const useMe = () => {
  const token = useAuthStore((s) => s.token)

  return useQuery({
    queryKey: ['me'],
    queryFn: () => api.get('/auth/me').then(r => r.data),
    enabled: !!token, // only run if token exists
    staleTime: Infinity,
  })
}
```

### 4. Protected route wrapper

```tsx
// components/PrivateRoute.tsx
import { Navigate } from 'react-router-dom'
import { useAuthStore } from '@/store/authStore'

export const PrivateRoute = ({ children }) => {
  const user = useAuthStore((s) => s.user)
  if (!user) return <Navigate to="/login" replace />
  return children
}
```

---

## Decision Tree (for Codex)

```
Need to fetch/create/update/delete data from API?
  → YES → Use TanStack Query (useQuery / useMutation)
  → NO  ↓

Is the state shared across multiple pages/components?
  → YES → Use Zustand store
  → NO  ↓

Is the state only used inside one component?
  → YES → Use useState
```

---

## File Structure Convention

```
src/
├── store/
│   ├── authStore.ts       # Zustand — auth (user, token, logout)
│   └── uiStore.ts         # Zustand — sidebar, theme, modals
├── hooks/
│   ├── useUsers.ts        # TanStack — GET /users
│   ├── useCreateUser.ts   # TanStack — POST /users
│   ├── useLogin.ts        # TanStack — POST /auth/login
│   └── useMe.ts           # TanStack — GET /auth/me
├── lib/
│   └── api.ts             # Axios instance with interceptors
└── components/
    └── PrivateRoute.tsx   # Auth guard using Zustand
```

---

## Common Mistakes to Avoid

| ❌ Wrong | ✅ Correct |
|---|---|
| Storing API response in Zustand | Use `useQuery` — it caches automatically |
| Using `useState` for auth user across routes | Use Zustand store |
| Manual `useEffect` + `fetch` for API calls | Use `useQuery` |
| Forgetting `queryClient.invalidateQueries` after mutation | Always invalidate related query keys on `onSuccess` |
| Subscribing to the whole Zustand store | Select only the slice you need: `useStore(s => s.value)` |
| Checking token in every component | Use Axios interceptor — handle it once globally |