import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateAdminProfileDto {
    @ApiPropertyOptional({ example: 'Heba Admin', description: 'Full display name for the admin profile.' })
    @IsOptional()
    @IsString()
    @MaxLength(300)
    fullName?: string;

    @ApiPropertyOptional({ example: 'Heba', description: 'Admin first name.' })
    @IsOptional()
    @IsString()
    @MaxLength(200)
    firstName?: string;

    @ApiPropertyOptional({ example: 'Rahman', description: 'Admin last name.' })
    @IsOptional()
    @IsString()
    @MaxLength(200)
    lastName?: string;

    @ApiPropertyOptional({ example: 'Heba Admin', description: 'Admin display name.' })
    @IsOptional()
    @IsString()
    @MaxLength(300)
    displayName?: string;

    @ApiPropertyOptional({ example: 'admin@heba.local', description: 'Admin email address.' })
    @IsOptional()
    @IsEmail()
    @MaxLength(320)
    email?: string;

    @ApiPropertyOptional({ example: '+8801712345678', description: 'Admin phone number.' })
    @IsOptional()
    @IsString()
    @MaxLength(20)
    phoneNumber?: string;
}
