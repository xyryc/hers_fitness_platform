import {
  getStoredRefreshToken,
  type AdminUser,
  useAuthStore,
} from "@/lib/auth-store";

const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? "";
const clientId = process.env.NEXT_PUBLIC_CLIENT_ID ?? "";

function applyClientHeaders(headers: Headers) {
  if (clientId) {
    headers.set("x-client-id", clientId);
  }

  return headers;
}

export type LoginPayload = {
  username: string;
  password: string;
  rememberMe: boolean;
};

type AuthResponse = {
  message: string;
  data: {
    user: AdminUser;
    accessToken: string;
    refreshToken: string;
  };
  statusCode: number;
};

type RefreshResponse = {
  message?: string;
  data?: {
    accessToken?: string;
    refreshToken?: string;
    user?: AdminUser;
  };
  accessToken?: string;
  refreshToken?: string;
};

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

function buildUrl(path: string) {
  if (/^https?:\/\//.test(path)) return path;

  return `${apiBaseUrl}${path}`;
}

async function parseJsonResponse<T>(response: Response): Promise<T> {
  const text = await response.text();
  const body = text ? JSON.parse(text) : null;

  if (!response.ok) {
    throw new ApiError(
      body?.message ?? body?.error ?? "Something went wrong. Please try again.",
      response.status,
    );
  }

  return body as T;
}

export function isAdmin(user: AdminUser) {
  return user.roles.some((role) => role.name === "ADMIN");
}

export async function loginAdmin(payload: LoginPayload) {
  const headers = applyClientHeaders(
    new Headers({
      "Content-Type": "application/json",
    }),
  );

  const response = await fetch(buildUrl("/auth/login"), {
    method: "POST",
    headers,
    body: JSON.stringify(payload),
  });

  const result = await parseJsonResponse<AuthResponse>(response);

  if (!isAdmin(result.data.user)) {
    throw new ApiError("Access denied. This portal is only for admins.", 403);
  }

  return result.data;
}

let refreshPromise: Promise<string> | null = null;

export async function refreshAccessToken() {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    const refreshToken = getStoredRefreshToken();

    if (!refreshToken) {
      throw new ApiError("Your session has expired. Please log in again.", 401);
    }

    const response = await fetch(buildUrl("/auth/refresh-token"), {
      method: "POST",
      headers: applyClientHeaders(
        new Headers({
          "Content-Type": "application/json",
        }),
      ),
      body: JSON.stringify({ refreshToken }),
    });

    const result = await parseJsonResponse<RefreshResponse>(response);
    const accessToken = result.data?.accessToken ?? result.accessToken;
    const nextRefreshToken = result.data?.refreshToken ?? result.refreshToken;
    const user = result.data?.user;

    if (!accessToken) {
      throw new ApiError("Could not refresh the session.", 401);
    }

    const store = useAuthStore.getState();

    if (user) {
      if (!isAdmin(user)) {
        store.clearSession();
        throw new ApiError("Access denied. This portal is only for admins.", 403);
      }

      store.setSession({ user, accessToken, refreshToken: nextRefreshToken });
    } else {
      store.setAccessToken(accessToken);
    }

    return accessToken;
  })().finally(() => {
    refreshPromise = null;
  });

  return refreshPromise;
}

export async function adminApiFetch<T>(
  path: string,
  init: RequestInit = {},
  options: { retryOnUnauthorized?: boolean } = {},
) {
  const retryOnUnauthorized = options.retryOnUnauthorized ?? true;
  const token = useAuthStore.getState().accessToken;
  const headers = applyClientHeaders(new Headers(init.headers));

  if (token) {
    headers.set("Authorization", `Bearer ${token}`);
  }

  const response = await fetch(buildUrl(path), {
    ...init,
    headers,
  });

  if (response.status === 401 && retryOnUnauthorized) {
    const newToken = await refreshAccessToken();
    const retryHeaders = applyClientHeaders(new Headers(init.headers));

    retryHeaders.set("Authorization", `Bearer ${newToken}`);

    const retryResponse = await fetch(buildUrl(path), {
      ...init,
      headers: retryHeaders,
    });

    return parseJsonResponse<T>(retryResponse);
  }

  return parseJsonResponse<T>(response);
}

export async function logoutAdmin() {
  const token = useAuthStore.getState().accessToken;

  if (!token) return;

  await adminApiFetch("/auth/logout", { method: "POST" }, {
    retryOnUnauthorized: false,
  });
}
