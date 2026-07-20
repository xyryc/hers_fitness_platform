import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsOptional, IsString, MaxLength, ValidateNested } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AvailabilitySlotDto } from './availability-slot.dto';

export class RescheduleFitnessClassDto {
    @ApiProperty({ type: [AvailabilitySlotDto] })
    @IsArray({ message: 'Available slots must be an array' })
    @ArrayMinSize(1, { message: 'At least one proposed slot is required' })
    @ValidateNested({ each: true })
    @Type(() => AvailabilitySlotDto)
    availableSlots: AvailabilitySlotDto[];

    @ApiPropertyOptional({ example: 'Trainer is unavailable at the original time.' })
    @IsOptional()
    @IsString()
    @MaxLength(1000, { message: 'Reschedule note must be 1000 characters or fewer' })
    note?: string;
}
