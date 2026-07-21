import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateHelpTicketDto {
    @ApiProperty({ example: 'App is crashing on login' })
    @IsString()
    @IsNotEmpty({ message: 'Title is required' })
    @MaxLength(300, { message: 'Title cannot exceed 300 characters' })
    title: string;

    @ApiProperty({ example: 'Every time I try to log in with Google, the app crashes immediately after the redirect.' })
    @IsString()
    @IsNotEmpty({ message: 'Body is required' })
    @MaxLength(5000, { message: 'Body cannot exceed 5000 characters' })
    body: string;
}
