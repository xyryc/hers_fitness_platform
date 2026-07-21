import {
    IsBoolean,
    IsEmail,
    IsEnum,
    IsNotEmpty,
    IsOptional,
    IsString,
    Matches,
    MinLength,
} from 'class-validator';
import { Roles } from 'src/common/enums/roles.enum';
import { IsValidGender } from 'src/common/validators/is-valid-gender.validator';

const allowedRoles = Object.values(Roles).filter(
    (role) => role !== Roles.Admin,
);

export class CreateUserDto {
    @IsString()
    @IsNotEmpty({ message: 'First name is required' })
    firstName: string;

    @IsOptional()
    @IsString()
    lastName?: string;

    @IsOptional()
    @IsString()
    phoneNumber?: string;

    @IsOptional()
    @IsValidGender()
    gender?: string | null;

    @IsEmail({}, { message: 'Please enter a valid email address' })
    @IsNotEmpty({ message: 'Email is required' })
    email: string;

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

    @IsEnum(allowedRoles, {
        message: `Role must be either ${allowedRoles.join(', ')}`,
    })
    role: Roles;

    @IsBoolean()
    @IsOptional()
    isEmailVerified?: boolean;

    @IsBoolean()
    @IsOptional()
    isPhoneVerified?: boolean;

    @IsBoolean()
    @IsOptional()
    isActive?: boolean;
}
