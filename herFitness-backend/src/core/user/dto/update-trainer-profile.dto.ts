import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsEnum, IsOptional, IsString, MaxLength, ArrayMaxSize } from 'class-validator';

enum SessionFormat {
    Online = 'Online',
    InPerson = 'In person',
    Both = 'Both',
}

export class UpdateTrainerProfileDto {
    @ApiPropertyOptional({ example: 'Sarah Johnson' })
    @IsOptional()
    @IsString()
    @MaxLength(300)
    displayName?: string;

    @ApiPropertyOptional({ example: '+1 (229) 555-0109' })
    @IsOptional()
    @IsString()
    @MaxLength(20)
    phoneNumber?: string;

    @ApiPropertyOptional({ example: 'Connecticut' })
    @IsOptional()
    @IsString()
    @MaxLength(200)
    state?: string;

    @ApiPropertyOptional({ example: 'Syracuse, Connecticut' })
    @IsOptional()
    @IsString()
    @MaxLength(500)
    location?: string;

    @ApiPropertyOptional({ example: '10-year certified NASM trainer specializing in strength and HIIT.' })
    @IsOptional()
    @IsString()
    bio?: string;

    @ApiPropertyOptional({
        example: ['Yoga', 'Strength Training', 'HIIT'],
        type: [String],
        description: 'Classes the trainer teaches (max 10)',
    })
    @IsOptional()
    @IsArray()
    @ArrayMaxSize(10)
    @IsString({ each: true })
    fitnessClasses?: string[];

    @ApiPropertyOptional({ example: '5yr' })
    @IsOptional()
    @IsString()
    @MaxLength(200)
    instructorDuration?: string;

    @ApiPropertyOptional({ example: 'NASM CPT, ACE Certified' })
    @IsOptional()
    @IsString()
    certifications?: string;

    @ApiPropertyOptional({ enum: SessionFormat, example: SessionFormat.Both })
    @IsOptional()
    @IsEnum(SessionFormat, {
        message: 'sessionFormat must be one of: Online, In person, Both',
    })
    sessionFormat?: string;
}
