
export interface UserPasswordHistoryEntity {
    id: string;
    userId: string;
    passwordHash: string;
    createdAt: Date;
}