import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateCommissionConfigDto {
    @ApiProperty({
        description: 'Platform commission percentage (0–100). E.g. 15 means the platform takes 15% of every booking.',
        example: 15,
        minimum: 0,
        maximum: 100,
    })
    @Type(() => Number)
    @IsNumber({ maxDecimalPlaces: 2 })
    @Min(0)
    @Max(100)
    commissionRate: number;
}

export class CommissionConfigResponseDto {
    id: string;
    commissionRate: string;
    updatedByUserId: string | null;
    updatedAt: Date | null;
    createdAt: Date;

    constructor(data: {
        id: string;
        commissionRate: any;
        updatedByUserId: string | null;
        updatedAt: Date | null;
        createdAt: Date;
    }) {
        this.id = data.id;
        this.commissionRate = data.commissionRate?.toString() ?? '0';
        this.updatedByUserId = data.updatedByUserId ?? null;
        this.updatedAt = data.updatedAt ?? null;
        this.createdAt = data.createdAt;
    }
}
