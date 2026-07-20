import { Expose } from 'class-transformer';

export class AdminVerificationRequestDto {
    @Expose()
    userId: string;

    @Expose()
    userCode: string;

    @Expose()
    email: string | null;

    @Expose()
    username: string | null;

    @Expose()
    firstName: string | null;

    @Expose()
    lastName: string | null;

    @Expose()
    displayName: string | null;

    @Expose()
    profileImageUrl: string | null;

    @Expose()
    requestType: string;

    @Expose()
    verificationStatus: string;

    @Expose()
    submittedAt: Date;

    @Expose()
    documentsProvided: boolean;

    @Expose()
    idCardType: string;

    @Expose()
    idCardNumber: string;

    @Expose()
    idCardFrontImageUrl: string;

    @Expose()
    idCardBackImageUrl: string;

    constructor(partial: Partial<AdminVerificationRequestDto>) {
        Object.assign(this, partial);
    }
}
