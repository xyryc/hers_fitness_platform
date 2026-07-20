import { Type } from 'class-transformer';
import { IsArray, IsEnum, IsInt, IsNumber, IsOptional, IsString, Max, Min, ValidateNested } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { FitnessClassType, FitnessSessionFormat, FitnessSessionPlanType } from './create-fitness-class.dto';
import { AvailabilitySlotDto } from './availability-slot.dto';

export class UpdateFitnessClassDto {
    @ApiPropertyOptional({ example: 'Yoga Class' })
    @IsOptional()
    @IsString()
    name?: string;

    @ApiPropertyOptional({ enum: FitnessClassType, example: FitnessClassType.IN_PERSON })
    @IsOptional()
    @IsEnum(FitnessClassType, {
        message: 'Class type must be ONLINE or IN_PERSON',
    })
    classType?: FitnessClassType;

    @ApiPropertyOptional({ enum: FitnessSessionPlanType, example: FitnessSessionPlanType.SINGLE_SESSION })
    @IsOptional()
    @IsEnum(FitnessSessionPlanType, {
        message: 'Session plan type must be SINGLE_SESSION or MONTHLY_SESSION',
    })
    sessionPlanType?: FitnessSessionPlanType;

    @ApiPropertyOptional({ example: 60 })
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'Duration must be a whole number of minutes' })
    @Min(1, { message: 'Duration must be at least 1 minute' })
    @Max(1440, { message: 'Duration must be less than or equal to 1440 minutes' })
    durationMinutes?: number;

    @ApiPropertyOptional({ example: 500 })
    @IsOptional()
    @Type(() => Number)
    @IsNumber({ maxDecimalPlaces: 2 }, { message: 'Price per member must be a valid amount' })
    @Min(0, { message: 'Price per member must be 0 or greater' })
    pricePerMember?: number;

    @ApiPropertyOptional({ enum: FitnessSessionFormat, example: FitnessSessionFormat.PRIVATE })
    @IsOptional()
    @IsEnum(FitnessSessionFormat, {
        message: 'Session format must be PRIVATE or GROUP',
    })
    sessionFormat?: FitnessSessionFormat;

    @ApiPropertyOptional({ example: 10, nullable: true })
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'Capacity must be a whole number' })
    @Min(1, { message: 'Capacity must be at least 1' })
    @Max(10000, { message: 'Capacity must be less than or equal to 10000' })
    capacity?: number | null;

    @ApiPropertyOptional({ type: [AvailabilitySlotDto] })
    @IsOptional()
    @IsArray({ message: 'Available slots must be an array' })
    @ValidateNested({ each: true })
    @Type(() => AvailabilitySlotDto)
    availableSlots?: AvailabilitySlotDto[];
}
