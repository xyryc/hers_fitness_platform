import { Expose } from 'class-transformer';

export class MemberTransactionResponseDto {
    @Expose() id!: string;
    @Expose() fitnessClassId!: string;
    @Expose() className!: string | null;
    @Expose() trainerName!: string | null;
    @Expose() totalAmount!: string;
    @Expose() currency!: string;
    @Expose() couponCode!: string | null;
    @Expose() paymentMethod!: string | null;
    @Expose() provider!: string | null;
    @Expose() status!: string;
    @Expose() paidAt!: Date | null;
    @Expose() createdAt!: Date;

    constructor(partial: Partial<MemberTransactionResponseDto>) {
        Object.assign(this, partial);
    }
}
