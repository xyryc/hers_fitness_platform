import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export enum ResolveHelpTicketStatus {
    RESOLVED = 'RESOLVED',
    CLOSED = 'CLOSED',
}

export class ResolveHelpTicketDto {
    @ApiProperty({ enum: ResolveHelpTicketStatus, example: ResolveHelpTicketStatus.RESOLVED })
    @IsEnum(ResolveHelpTicketStatus, { message: 'Status must be RESOLVED or CLOSED' })
    status: ResolveHelpTicketStatus;

    @ApiPropertyOptional({ example: 'We have investigated and fixed the issue. Please update the app to version 2.1.0.' })
    @IsOptional()
    @IsString()
    @MaxLength(2000, { message: 'Admin note cannot exceed 2000 characters' })
    adminNote?: string;
}
