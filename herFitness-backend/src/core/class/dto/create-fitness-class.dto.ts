import { Type } from 'class-transformer';
import {
    ArrayMinSize,
    IsArray,
    IsEnum,
    IsInt,
    IsNotEmpty,
    IsNumber,
    IsString,
    Max,
    Min,
    ValidateIf,
    ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AvailabilitySlotDto } from './availability-slot.dto';

export enum FitnessClassType {
    ONLINE = 'ONLINE',
    IN_PERSON = 'IN_PERSON',
}

export enum FitnessSessionFormat {
    PRIVATE = 'PRIVATE',
    GROUP = 'GROUP',
}

export enum FitnessSessionPlanType {
    SINGLE_SESSION = 'SINGLE_SESSION',
    MONTHLY_SESSION = 'MONTHLY_SESSION',
}

export class CreateFitnessClassDto {
    @ApiProperty({ example: 'Yoga Class' })
    @IsString()
    @IsNotEmpty({ message: 'Class name is required' })
    name: string;

    @ApiProperty({ enum: FitnessClassType, example: FitnessClassType.IN_PERSON })
    @IsEnum(FitnessClassType, {
        message: 'Class type must be ONLINE or IN_PERSON',
    })
    classType: FitnessClassType;

    @ApiProperty({ enum: FitnessSessionPlanType, example: FitnessSessionPlanType.SINGLE_SESSION })
    @IsEnum(FitnessSessionPlanType, {
        message: 'Session plan type must be SINGLE_SESSION or MONTHLY_SESSION',
    })
    sessionPlanType: FitnessSessionPlanType = FitnessSessionPlanType.SINGLE_SESSION;

    @ApiProperty({ example: 60 })
    @Type(() => Number)
    @IsInt({ message: 'Duration must be a whole number of minutes' })
    @Min(1, { message: 'Duration must be at least 1 minute' })
    @Max(1440, { message: 'Duration must be less than or equal to 1440 minutes' })
    durationMinutes: number;

    @ApiProperty({ example: 500 })
    @Type(() => Number)
    @IsNumber({ maxDecimalPlaces: 2 }, { message: 'Price per member must be a valid amount' })
    @Min(0, { message: 'Price per member must be 0 or greater' })
    pricePerMember: number;

    @ApiProperty({ enum: FitnessSessionFormat, example: FitnessSessionFormat.PRIVATE })
    @IsEnum(FitnessSessionFormat, {
        message: 'Session format must be PRIVATE or GROUP',
    })
    sessionFormat: FitnessSessionFormat;

    @ApiPropertyOptional({ example: 10, nullable: true })
    @ValidateIf((o: CreateFitnessClassDto) => o.sessionFormat === FitnessSessionFormat.GROUP)
    @Type(() => Number)
    @IsInt({ message: 'Capacity must be a whole number' })
    @Min(1, { message: 'Capacity must be at least 1' })
    @Max(10000, { message: 'Capacity must be less than or equal to 10000' })
    capacity?: number;

    @ApiProperty({ type: [AvailabilitySlotDto] })
    @IsArray({ message: 'Available slots must be an array' })
    @ArrayMinSize(1, { message: 'At least one available slot is required' })
    @ValidateNested({ each: true })
    @Type(() => AvailabilitySlotDto)
    availableSlots: AvailabilitySlotDto[];
}
