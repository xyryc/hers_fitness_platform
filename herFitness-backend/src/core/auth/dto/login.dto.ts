import {
    IsBoolean,
    IsEnum,
    IsNotEmpty,
    IsOptional,
    IsString,
    MaxLength,
    MinLength,
    ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DevicePlatformDto } from 'src/core/notification/dto/register-device-token.dto';

export class LoginDto {

    @ApiProperty({ example: 'heba@example.com', description: 'Email or username' })
    @IsString()
    @IsNotEmpty({ message: 'Username is required' })
    username: string;

    @ApiProperty({ example: 'Password@123' })
    @IsString()
    @IsNotEmpty({ message: 'Password is required' })
    password: string;

    @ApiPropertyOptional({ example: true })
    @IsOptional()
    @IsBoolean()
    rememberMe?: boolean;

    @ApiPropertyOptional({ example: 'fcm-device-token' })
    @IsOptional()
    @IsString()
    @MinLength(10)
    fcmToken?: string;

    @ApiPropertyOptional({ enum: DevicePlatformDto, example: DevicePlatformDto.ANDROID })
    @ValidateIf((model) => Boolean(model.fcmToken))
    @IsEnum(DevicePlatformDto)
    devicePlatform?: DevicePlatformDto;

    @ApiPropertyOptional({ example: 'android-device-id' })
    @IsOptional()
    @IsString()
    @MaxLength(255)
    deviceId?: string;
}
