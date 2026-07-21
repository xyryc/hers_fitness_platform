import { IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class TestPushNotificationDto {
    @IsOptional()
    @IsString()
    @MaxLength(200)
    title?: string;

    @IsOptional()
    @IsString()
    @MaxLength(1000)
    body?: string;

    @IsOptional()
    @IsObject()
    data?: Record<string, unknown>;
}

