import {
    IsEmail,
    IsNotEmpty,
    IsOptional,
    IsString,
    Matches,
    MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { MatchPasswords } from 'src/common/validators/match-passwords.validator';

export class RegisterMemberDto {
    @ApiProperty({ example: 'Heba Rahman' })
    @IsString()
    @IsNotEmpty({ message: 'Name is required' })
    name: string;

    @ApiProperty({ example: 'heba@example.com' })
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

    @ApiProperty({ example: 'Gulshan, Dhaka' })
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
