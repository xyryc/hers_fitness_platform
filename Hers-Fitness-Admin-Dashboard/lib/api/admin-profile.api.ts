import { adminApiFetch } from '@/lib/auth-api';
import type {
  AdminProfile,
  UpdateAdminProfilePayload,
} from '@/lib/types/admin-profile.types';

const BASE = '/api/admin/profile';

type AdminProfileResponse = Partial<AdminProfile> & {
  name?: string | null;
  phone?: string | null;
};

type ApiEnvelope<T> = {
  data?: T;
};

function normalizeProfile(profile: AdminProfileResponse): AdminProfile {
  return {
    id: profile.id,
    fullName: profile.fullName ?? profile.name ?? '',
    email: profile.email ?? '',
    phoneNumber: profile.phoneNumber ?? profile.phone ?? '',
    profileImageUrl: profile.profileImageUrl ?? profile.imageUrl ?? null,
    imageUrl: profile.imageUrl ?? profile.profileImageUrl ?? null,
  };
}

function unwrapProfile(
  response: ApiEnvelope<AdminProfileResponse> | AdminProfileResponse,
) {
  const profile =
    'data' in response && response.data != null
      ? response.data
      : (response as AdminProfileResponse);

  return normalizeProfile(profile);
}

export const adminProfileApi = {
  getProfile: () =>
    adminApiFetch<ApiEnvelope<AdminProfileResponse> | AdminProfileResponse>(
      BASE,
    ).then(unwrapProfile),

  updateProfile: (payload: UpdateAdminProfilePayload) =>
    adminApiFetch<ApiEnvelope<AdminProfileResponse> | AdminProfileResponse>(
      BASE,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      },
    ).then(unwrapProfile),

  uploadProfileImage: (file: File) => {
    const formData = new FormData();
    formData.append('profileImage', file);

    return adminApiFetch<
      ApiEnvelope<AdminProfileResponse> | AdminProfileResponse
    >(`${BASE}/image`, {
      method: 'POST',
      body: formData,
    }).then(unwrapProfile);
  },
};
