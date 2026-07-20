import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class AvailabilitySlotDto {
    @ApiProperty({ example: '2026-05-20', description: 'Slot date in YYYY-MM-DD format' })
    @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Date must be in YYYY-MM-DD format' })
    date: string;

    @ApiProperty({ example: '07:00', description: 'Slot start time in HH:mm format' })
    @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Start time must be in HH:mm format' })
    startTime: string;

    @ApiProperty({ example: '08:00', description: 'Slot end time in HH:mm format' })
    @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'End time must be in HH:mm format' })
    endTime: string;
}
