import { configureStore } from "@reduxjs/toolkit";

import { adminVerificationsApi } from "@/lib/admin-verifications-api";

export const store = configureStore({
  reducer: {
    [adminVerificationsApi.reducerPath]: adminVerificationsApi.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(adminVerificationsApi.middleware),
});

export type AppDispatch = typeof store.dispatch;
export type RootState = ReturnType<typeof store.getState>;
