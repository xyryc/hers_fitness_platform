import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { adminProfileApi } from '@/lib/api/admin-profile.api';
import type {
  AdminProfile,
  UpdateAdminProfilePayload,
} from '@/lib/types/admin-profile.types';

export const ADMIN_PROFILE_KEYS = {
  profile: ['admin', 'profile'] as const,
};

export function useAdminProfile() {
  return useQuery({
    queryKey: ADMIN_PROFILE_KEYS.profile,
    queryFn: adminProfileApi.getProfile,
    staleTime: 60_000,
  });
}

export function useUpdateAdminProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: UpdateAdminProfilePayload) =>
      adminProfileApi.updateProfile(payload),
    onSuccess: (profile) => {
      queryClient.setQueryData<AdminProfile | undefined>(
        ADMIN_PROFILE_KEYS.profile,
        (current) => mergeProfile(current, profile),
      );
    },
  });
}

export function useUploadAdminProfileImage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => adminProfileApi.uploadProfileImage(file),
    onSuccess: (profile) => {
      queryClient.setQueryData<AdminProfile | undefined>(
        ADMIN_PROFILE_KEYS.profile,
        (current) => mergeProfile(current, profile),
      );
      queryClient.invalidateQueries({ queryKey: ADMIN_PROFILE_KEYS.profile });
    },
  });
}

function mergeProfile(
  current: AdminProfile | undefined,
  next: AdminProfile,
): AdminProfile {
  if (!current) return next;

  return {
    ...current,
    ...next,
    fullName: next.fullName || current.fullName,
    email: next.email || current.email,
    phoneNumber: next.phoneNumber || current.phoneNumber,
    profileImageUrl: next.profileImageUrl ?? current.profileImageUrl,
    imageUrl: next.imageUrl ?? current.imageUrl,
  };
}
