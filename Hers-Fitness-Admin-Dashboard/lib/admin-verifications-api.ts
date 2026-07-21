import { createApi, fakeBaseQuery } from "@reduxjs/toolkit/query/react";

import { adminApiFetch } from "@/lib/auth-api";

export type VerificationRequestType = "MEMBER" | "TRAINER";
export type VerificationStatus = "PENDING" | "APPROVED" | "REJECTED" | string;

export type AdminVerification = {
  userId: string;
  userCode?: string | null;
  email: string;
  username?: string | null;
  firstName?: string | null;
  lastName?: string | null;
  displayName?: string | null;
  profileImageUrl?: string | null;
  requestType: VerificationRequestType;
  verificationStatus: VerificationStatus;
  submittedAt?: string | null;
  documentsProvided?: boolean;
  idCardType?: string | null;
  idCardNumber?: string | null;
  idCardFrontImageUrl?: string | null;
  idCardBackImageUrl?: string | null;
};

type ApiEnvelope<T> = {
  data?: T;
  message?: string;
  status?: number;
  statusCode?: number;
  success?: boolean;
};

type VerificationsResponse = AdminVerification[] | ApiEnvelope<AdminVerification[]>;

function unwrapData<T>(response: T | ApiEnvelope<T>) {
  if (
    response &&
    typeof response === "object" &&
    "data" in response &&
    (response as ApiEnvelope<T>).data !== undefined
  ) {
    return (response as ApiEnvelope<T>).data as T;
  }

  return response as T;
}

export const adminVerificationsApi = createApi({
  reducerPath: "adminVerificationsApi",
  baseQuery: fakeBaseQuery(),
  tagTypes: ["AdminVerifications"],
  endpoints: (builder) => ({
    getAdminVerifications: builder.query<
      AdminVerification[],
      VerificationRequestType | undefined
    >({
      async queryFn(type) {
        try {
          const query = type ? `?type=${encodeURIComponent(type)}` : "";
          const response = await adminApiFetch<VerificationsResponse>(
            `/api/users/admin/verifications${query}`,
          );

          return { data: unwrapData(response) };
        } catch (error) {
          return { error };
        }
      },
      providesTags: (_result, _error, type) => [
        { type: "AdminVerifications", id: type ?? "ALL" },
        { type: "AdminVerifications", id: "ALL" },
      ],
    }),
    approveAdminVerification: builder.mutation<unknown, string>({
      async queryFn(userId) {
        try {
          const response = await adminApiFetch<unknown>(
            `/api/users/admin/${userId}/approve`,
            { method: "PATCH" },
          );

          return { data: response };
        } catch (error) {
          return { error };
        }
      },
      invalidatesTags: [{ type: "AdminVerifications", id: "ALL" }],
    }),
  }),
});

export const {
  useApproveAdminVerificationMutation,
  useGetAdminVerificationsQuery,
} = adminVerificationsApi;
