export interface CreateMemberDto {
    name: string;
    email: string;
    phoneNumber: string;
    state: string;
    location: string;
    timezone?: string | null;
    profileImageUrl: string;
}
