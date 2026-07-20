import {
    IsEmail,
    IsEnum,
    IsNotEmpty,
    IsOptional,
    IsString,
    Matches,
    MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { MatchPasswords } from 'src/common/validators/match-passwords.validator';

export enum TrainerClassDeliveryMode {
    ONLINE = 'ONLINE',
    OFFLINE = 'OFFLINE',
    BOTH = 'BOTH',
}

export class RegisterTrainerDto {
    @ApiProperty({ example: 'Heba Trainer' })
    @IsString()
    @IsNotEmpty({ message: 'Name is required' })
    name: string;

    @ApiProperty({ example: 'trainer@example.com' })
    @IsEmail({}, { message: 'Please enter a valid email address' })
    @IsNotEmpty({ message: 'Email is required' })
    email: string;

    @ApiProperty({ example: '+8801712345678' })
    @IsString()
    @IsNotEmpty({ message: 'Phone number is required' })
    phoneNumber: string;

    @ApiProperty({ example: 'Dhaka' })
    @IsString()
    @IsNotEmpty({ message: 'State is required' })
    state: string;

    @ApiProperty({ example: 'Banani, Dhaka' })
    @IsString()
    @IsNotEmpty({ message: 'Location is required' })
    location: string;

    @ApiProperty({ example: 'Asia/Dhaka', required: false })
    @IsOptional()
    @IsString()
    timezone?: string;

    @ApiProperty({ example: 'NID' })
    @IsString()
    @IsNotEmpty({ message: 'ID card type is required' })
    idCardType: string;

    @ApiProperty({ example: '1234567890' })
    @IsString()
    @IsNotEmpty({ message: 'ID card number is required' })
    idCardNumber: string;

    @ApiProperty({ example: 'Certified strength and mobility coach.' })
    @IsString()
    @IsNotEmpty({ message: 'Personal bio is required' })
    bio: string;

    @ApiProperty({ example: 'Strength training, yoga, HIIT' })
    @IsString()
    @IsNotEmpty({ message: 'Fitness classes are required' })
    classesTaught: string;

    @ApiProperty({ example: '5 years' })
    @IsString()
    @IsNotEmpty({ message: 'Instructor experience is required' })
    instructorExperience: string;

    @ApiProperty({ example: 'ACE CPT, CPR certified' })
    @IsString()
    @IsNotEmpty({ message: 'Certifications are required' })
    certifications: string;

    @ApiProperty({ enum: TrainerClassDeliveryMode, example: TrainerClassDeliveryMode.BOTH })
    @IsEnum(TrainerClassDeliveryMode, {
        message: 'Class delivery mode must be ONLINE, OFFLINE, or BOTH',
    })
    classDeliveryMode: TrainerClassDeliveryMode;

    @ApiProperty({ example: 'Password@123' })
    @IsNotEmpty({ message: 'Password is required' })
    @MinLength(8, { message: 'Password must be at least 8 characters' })
    @Matches(
        /^.*(?=.{8,})((?=.*[!@#$%^&*()\-_=+{};:,<.>]){1})(?=.*\d)((?=.*[a-z]){1})((?=.*[A-Z]){1}).*$/,
        {
            message:
                'Password must contain at least 8 characters, one uppercase, one number and one special character',
        },
    )
    password: string;

    @ApiProperty({ example: 'Password@123' })
    @IsNotEmpty({ message: 'Confirm password is required' })
    @MatchPasswords('password', {
        message: 'Password and confirm password must match',
    })
    confirmPassword: string;
}
