import { IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { MatchPasswords } from 'src/common/validators/match-passwords.validator';

export class ResetPasswordDto {
    @ApiProperty({ example: 'reset_8e9d0f...', description: 'Reset key returned after OTP verification' })
    @IsString()
    @IsNotEmpty({ message: 'Reset key is required' })
    resetKey: string;

    @ApiProperty({ example: 'NewPassword@123' })
    @IsString()
    @IsNotEmpty({ message: 'New password is required' })
    @MinLength(8, { message: 'New password must be at least 8 characters' })
    @Matches(
        /^.*(?=.{8,})((?=.*[!@#$%^&*()\-_=+{};:,<.>]){1})(?=.*\d)((?=.*[a-z]){1})((?=.*[A-Z]){1}).*$/,
        {
            message:
                'New password must contain at least 8 characters, one uppercase, one number and one special character',
        },
    )
    newPassword: string;

    @ApiProperty({ example: 'NewPassword@123' })
    @IsString()
    @IsNotEmpty({ message: 'Confirm new password is required' })
    @MatchPasswords('newPassword', {
        message: 'New password and confirm new password must match',
    })
    confirmNewPassword: string;
}
