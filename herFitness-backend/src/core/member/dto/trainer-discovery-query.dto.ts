import { Type } from 'class-transformer';
import { IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class NearbyTrainersQueryDto {
    @Type(() => Number)
    @IsNumber({}, { message: 'lat must be a valid number' })
    @Min(-90, { message: 'lat must be greater than or equal to -90' })
    @Max(90, { message: 'lat must be less than or equal to 90' })
    lat: number;

    @Type(() => Number)
    @IsNumber({}, { message: 'lng must be a valid number' })
    @Min(-180, { message: 'lng must be greater than or equal to -180' })
    @Max(180, { message: 'lng must be less than or equal to 180' })
    lng: number;

    @Type(() => Number)
    @IsOptional()
    @IsNumber({}, { message: 'radius_km must be a valid number' })
    @Min(0.1, { message: 'radius_km must be at least 0.1' })
    radiusKm?: number = 10;
}

export class SearchTrainersQueryDto {
    @IsOptional()
    @IsString()
    specialty?: string;

    @Type(() => Number)
    @IsOptional()
    @IsNumber({}, { message: 'price_min must be a valid number' })
    @Min(0, { message: 'price_min must be 0 or greater' })
    priceMin?: number;

    @Type(() => Number)
    @IsOptional()
    @IsNumber({}, { message: 'price_max must be a valid number' })
    @Min(0, { message: 'price_max must be 0 or greater' })
    priceMax?: number;

    @IsOptional()
    @IsString()
    name?: string;
}

export class TrainerProfileDistanceQueryDto {
    @Type(() => Number)
    @IsOptional()
    @IsNumber({}, { message: 'lat must be a valid number' })
    @Min(-90, { message: 'lat must be greater than or equal to -90' })
    @Max(90, { message: 'lat must be less than or equal to 90' })
    lat?: number;

    @Type(() => Number)
    @IsOptional()
    @IsNumber({}, { message: 'lng must be a valid number' })
    @Min(-180, { message: 'lng must be greater than or equal to -180' })
    @Max(180, { message: 'lng must be less than or equal to 180' })
    lng?: number;
}
