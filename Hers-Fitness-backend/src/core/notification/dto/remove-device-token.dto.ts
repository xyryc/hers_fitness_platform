import { IsString, MinLength } from 'class-validator';

export class RemoveDeviceTokenDto {
    @IsString()
    @MinLength(10)
    token: string;
}

