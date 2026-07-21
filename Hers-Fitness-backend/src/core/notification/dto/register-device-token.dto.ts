import { IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export enum DevicePlatformDto {
    IOS = 'IOS',
    ANDROID = 'ANDROID',
    WEB = 'WEB',
}

export class RegisterDeviceTokenDto {
    @IsString()
    @MinLength(10)
    token: string;

    @IsEnum(DevicePlatformDto)
    platform: DevicePlatformDto;

    @IsOptional()
    @IsString()
    @MaxLength(255)
    deviceId?: string;
}

