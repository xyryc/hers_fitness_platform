import { ApiProperty } from '@nestjs/swagger';

export class NotificationResponseDto {
    @ApiProperty()
    id: string;

    @ApiProperty()
    userId: string;

    @ApiProperty()
    type: string;

    @ApiProperty()
    title: string;

    @ApiProperty()
    body: string;

    @ApiProperty({ required: false, nullable: true })
    data?: Record<string, unknown> | null;

    @ApiProperty({ required: false, nullable: true })
    readAt?: Date | null;

    @ApiProperty()
    createdAt: Date;

    constructor(partial: Partial<NotificationResponseDto>) {
        Object.assign(this, partial);
    }
}

export class NotificationUnreadCountResponseDto {
    @ApiProperty()
    unreadCount: number;

    constructor(partial: Partial<NotificationUnreadCountResponseDto>) {
        Object.assign(this, partial);
    }
}

