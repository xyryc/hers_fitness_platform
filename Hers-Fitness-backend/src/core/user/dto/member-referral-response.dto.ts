import { Expose } from 'class-transformer';

export class MemberReferralResponseDto {
    @Expose() referralCode!: string;
    @Expose() referralLink!: string;

    constructor(partial: Partial<MemberReferralResponseDto>) {
        Object.assign(this, partial);
    }
}
