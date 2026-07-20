import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class TrainerAvailabilityQueryDto {
    @ApiProperty({ example: '2026-06', description: 'Calendar month in YYYY-MM format' })
    @Matches(/^\d{4}-(0[1-9]|1[0-2])$/, { message: 'Month must be in YYYY-MM format' })
    month: string;
}
