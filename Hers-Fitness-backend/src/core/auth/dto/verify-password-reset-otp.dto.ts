import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Matches } from 'class-validator';

export class VerifyPasswordResetOtpDto {
    @ApiProperty({ example: 'heba@example.com' })
    @IsEmail({}, { message: 'Please enter a valid email address' })
    @IsNotEmpty({ message: 'Email is required' })
    email: string;

    @ApiProperty({ example: '123456', description: '6 digit OTP sent to the user email' })
    @IsString()
    @IsNotEmpty({ message: 'OTP is required' })
    @Matches(/^\d{6}$/, { message: 'OTP must be a 6 digit code' })
    otp: string;
}
