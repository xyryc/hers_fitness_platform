import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsDateString, Max, Min } from 'class-validator';
import { Transform } from 'class-transformer';

export enum EarningsPeriod {
    WEEKLY = 'weekly',
    MONTHLY = 'monthly',
    YEARLY = 'yearly',
}

export class TrainerEarningsQueryDto {
    @ApiProperty({
        enum: EarningsPeriod,
        example: EarningsPeriod.MONTHLY,
        description: 'weekly → breakdown by day, monthly → breakdown by month, yearly → breakdown by year',
    })
    @IsEnum(EarningsPeriod, { message: 'period must be weekly, monthly, or yearly' })
    period: EarningsPeriod;

    @ApiPropertyOptional({
        example: 2026,
        description: 'Year to filter by. Used for monthly period. Defaults to current year.',
    })
    @IsOptional()
    @Transform(({ value }) => value !== undefined ? Number(value) : undefined)
    @IsInt()
    @Min(2000)
    @Max(2100)
    year?: number;

    @ApiPropertyOptional({
        example: '2026-05-24',
        description: 'Any date within the target week. Used for weekly period. Defaults to current week.',
    })
    @IsOptional()
    @IsDateString()
    date?: string;
}
