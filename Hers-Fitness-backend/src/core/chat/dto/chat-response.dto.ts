import { Expose } from 'class-transformer';

export class ChatParticipantResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string | null;

    @Expose()
    profileImageUrl: string | null;

    constructor(partial: Partial<ChatParticipantResponseDto>) {
        Object.assign(this, partial);
    }
}

export class ChatMessageResponseDto {
    @Expose()
    id: string;

    @Expose()
    conversationId: string;

    @Expose()
    senderUserId: string;

    @Expose()
    messageType: string;

    @Expose()
    text: string | null;

    @Expose()
    attachmentUrl: string | null;

    @Expose()
    attachmentType: string | null;

    @Expose()
    seenAt: Date | null;

    @Expose()
    createdAt: Date;

    constructor(partial: Partial<ChatMessageResponseDto>) {
        Object.assign(this, partial);
    }
}

export class ChatConversationResponseDto {
    @Expose()
    id: string;

    @Expose()
    memberUserId: string;

    @Expose()
    trainerUserId: string;

    @Expose()
    memberStatus: string;

    @Expose()
    trainerStatus: string;

    @Expose()
    lastMessageAt: Date | null;

    @Expose()
    member: ChatParticipantResponseDto;

    @Expose()
    trainer: ChatParticipantResponseDto;

    @Expose()
    lastMessage: ChatMessageResponseDto | null;

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt: Date | null;

    constructor(partial: Partial<ChatConversationResponseDto>) {
        Object.assign(this, partial);
    }
}
