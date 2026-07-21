export interface AdminProfile {
  id?: string;
  fullName: string;
  email: string;
  phoneNumber: string;
  profileImageUrl: string | null;
  imageUrl: string | null;
}

export type UpdateAdminProfilePayload = {
  fullName: string;
  email: string;
  phoneNumber: string;
};
