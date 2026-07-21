import { Expose, Type } from 'class-transformer';

export class HelpTicketSenderResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string | null;

    @Expose()
    email: string | null;

    @Expose()
    profileImageUrl: string | null;

    @Expose()
    role: string | null;

    constructor(partial: Partial<HelpTicketSenderResponseDto>) {
        Object.assign(this, partial);
    }
}

export class HelpTicketResponseDto {
    @Expose()
    id: string;

    @Expose()
    senderUserId: string;

    @Expose()
    title: string;

    @Expose()
    body: string;

    @Expose()
    status: string;

    @Expose()
    adminNote: string | null;

    @Expose()
    resolvedAt: Date | null;

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt: Date | null;

    @Expose()
    @Type(() => HelpTicketSenderResponseDto)
    sender?: HelpTicketSenderResponseDto;

    constructor(partial: Partial<HelpTicketResponseDto>) {
        Object.assign(this, partial);
    }
}
