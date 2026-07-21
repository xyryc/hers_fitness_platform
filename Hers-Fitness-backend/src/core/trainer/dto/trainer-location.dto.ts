import { Type } from 'class-transformer';
import { IsBoolean, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class TrainerBaseLocationDto {
    @Type(() => Number)
    @IsNumber({}, { message: 'Latitude must be a valid number' })
    @Min(-90, { message: 'Latitude must be greater than or equal to -90' })
    @Max(90, { message: 'Latitude must be less than or equal to 90' })
    lat: number;

    @Type(() => Number)
    @IsNumber({}, { message: 'Longitude must be a valid number' })
    @Min(-180, { message: 'Longitude must be greater than or equal to -180' })
    @Max(180, { message: 'Longitude must be less than or equal to 180' })
    lng: number;

    @IsOptional()
    @IsString()
    timezone?: string;
}

export class TrainerLiveLocationDto extends TrainerBaseLocationDto { }

export class TrainerOnlineStatusDto {
    @Type(() => Boolean)
    @IsBoolean({ message: 'isOnline must be a boolean value' })
    isOnline: boolean;
}
