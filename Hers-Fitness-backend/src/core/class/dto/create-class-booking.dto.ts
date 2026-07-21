import { Type } from 'class-transformer';
import {
    ArrayMinSize,
    IsArray,
    IsBoolean,
    IsEmail,
    IsEnum,
    IsOptional,
    IsString,
    IsUUID,
    MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FitnessClassType } from './create-fitness-class.dto';

export class CreateClassBookingDto {
    @ApiProperty({ example: 'Rahman Hossain' })
    @IsString()
    @MaxLength(200)
    fullName: string;

    @ApiProperty({ example: 'rahman@example.com' })
    @IsEmail()
    email: string;

    @ApiProperty({ example: '+8801711111111' })
    @IsString()
    @MaxLength(20)
    phoneNumber: string;

    @ApiProperty({ example: 'Gulshan, Dhaka' })
    @IsString()
    @MaxLength(500)
    location: string;

    @ApiPropertyOptional({ enum: FitnessClassType, example: FitnessClassType.IN_PERSON })
    @IsOptional()
    @IsEnum(FitnessClassType)
    selectedClassType?: FitnessClassType;

    @ApiPropertyOptional({ example: 'I prefer morning sessions.' })
    @IsOptional()
    @IsString()
    @MaxLength(2000)
    comment?: string;

    @ApiPropertyOptional({ example: 'FIRSTTIME20', description: 'Placeholder only for now. No discount is applied yet.' })
    @IsOptional()
    @IsString()
    @MaxLength(100)
    couponCode?: string;

    @ApiPropertyOptional({ example: true })
    @IsOptional()
    @Type(() => Boolean)
    @IsBoolean()
    reminderEnabled?: boolean;

    @ApiPropertyOptional({ example: '01f0a1a2-3b4c-4d5e-8f90-123456789abc' })
    @IsOptional()
    @IsUUID()
    availabilitySlotId?: string;

    @ApiPropertyOptional({
        type: [String],
        example: [
            '01f0a1a2-3b4c-4d5e-8f90-123456789abc',
            '01f0a1a2-3b4c-4d5e-8f90-123456789abd',
        ],
    })
    @IsOptional()
    @IsArray()
    @ArrayMinSize(1)
    @IsUUID(undefined, { each: true })
    availabilitySlotIds?: string[];
}
