import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsNotEmpty, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateTrainerReviewDto {
    @ApiProperty({ example: 5, minimum: 1, maximum: 5 })
    @IsInt({ message: 'Rating must be a whole number' })
    @Min(1, { message: 'Rating must be at least 1 star' })
    @Max(5, { message: 'Rating cannot be more than 5 stars' })
    rating: number;

    @ApiProperty({ example: 'Great trainer. The session was clear, motivating, and well planned.' })
    @IsString()
    @IsNotEmpty({ message: 'Comment is required' })
    @MaxLength(2000, { message: 'Comment cannot exceed 2000 characters' })
    comment: string;
}
