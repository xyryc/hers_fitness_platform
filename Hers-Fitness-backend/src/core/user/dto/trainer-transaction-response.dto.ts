import { Expose } from 'class-transformer';

export class TrainerTransactionResponseDto {
    @Expose() id!: string;
    @Expose() className!: string | null;
    @Expose() memberName!: string | null;
    @Expose() amount!: string;
    @Expose() currency!: string;
    @Expose() status!: string;
    @Expose() paidAt!: Date | null;
    @Expose() createdAt!: Date;

    constructor(partial: Partial<TrainerTransactionResponseDto>) {
        Object.assign(this, partial);
    }
}
