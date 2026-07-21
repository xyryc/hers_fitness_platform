"use client";

import { create } from "zustand";

export type AdminRole = {
  name: string;
  description?: string;
};

export type AdminUser = {
  id: string;
  email: string;
  roles: AdminRole[];
  isActive: boolean;
};

type AuthState = {
  accessToken: string | null;
  user: AdminUser | null;
  isReady: boolean;
  setSession: (session: {
    user: AdminUser;
    accessToken: string;
    refreshToken?: string;
  }) => void;
  setAccessToken: (accessToken: string) => void;
  markReady: () => void;
  clearSession: () => void;
};

const refreshTokenKey = "hers-fitness-admin-refresh-token";

export function getStoredRefreshToken() {
  if (typeof window === "undefined") return null;

  return window.localStorage.getItem(refreshTokenKey);
}

export function storeRefreshToken(refreshToken: string | undefined) {
  if (typeof window === "undefined" || !refreshToken) return;

  window.localStorage.setItem(refreshTokenKey, refreshToken);
}

export function clearStoredRefreshToken() {
  if (typeof window === "undefined") return;

  window.localStorage.removeItem(refreshTokenKey);
}

export const useAuthStore = create<AuthState>((set) => ({
  accessToken: null,
  user: null,
  isReady: false,
  setSession: ({ user, accessToken, refreshToken }) => {
    storeRefreshToken(refreshToken);
    set({ user, accessToken, isReady: true });
  },
  setAccessToken: (accessToken) => set({ accessToken, isReady: true }),
  markReady: () => set({ isReady: true }),
  clearSession: () => {
    clearStoredRefreshToken();
    set({ accessToken: null, user: null, isReady: true });
  },
}));
