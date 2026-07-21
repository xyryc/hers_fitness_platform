import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Matches } from 'class-validator';

export class BookingRescheduleDto {
    @ApiPropertyOptional({ example: '2026-05-23', description: 'Preferred field for the new booking date.' })
    @IsOptional()
    @IsString()
    @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'scheduledDate must be in YYYY-MM-DD format' })
    scheduledDate?: string;

    @ApiPropertyOptional({ example: '2026-05-23', description: 'Alias accepted for scheduledDate.' })
    @IsOptional()
    @IsString()
    @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be in YYYY-MM-DD format' })
    date?: string;

    @ApiPropertyOptional({ example: '14:30' })
    @IsString()
    @Matches(/^\d{2}:\d{2}$/, { message: 'startTime must be in HH:mm format' })
    startTime: string;
}
