import { Expose } from 'class-transformer';

export class FaqResponseDto {
    @Expose() id!: string;
    @Expose() question!: string;
    @Expose() answer!: string;
    @Expose() order!: number;
    @Expose() isActive!: boolean;

    constructor(partial: Partial<FaqResponseDto>) {
        Object.assign(this, partial);
    }
}
