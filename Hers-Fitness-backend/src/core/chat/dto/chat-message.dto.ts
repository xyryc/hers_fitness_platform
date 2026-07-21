import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString, IsUUID, IsUrl, ValidateIf } from 'class-validator';

export enum ChatMessageTypeDto {
    TEXT = 'TEXT',
    IMAGE = 'IMAGE',
}

export class StartConversationDto {
    @ApiProperty({ example: '7db96c57-5e0e-4b35-bb85-0123456789ab' })
    @IsUUID('4', { message: 'Trainer user ID must be a valid UUID' })
    trainerUserId: string;
}

export class SendChatMessageDto {
    @ApiProperty({ enum: ChatMessageTypeDto, example: ChatMessageTypeDto.TEXT })
    @IsEnum(ChatMessageTypeDto, { message: 'Message type must be TEXT or IMAGE' })
    messageType: ChatMessageTypeDto;

    @ApiPropertyOptional({ example: 'Hello, are you available tomorrow?' })
    @ValidateIf((dto: SendChatMessageDto) => dto.messageType === ChatMessageTypeDto.TEXT)
    @IsString()
    @IsNotEmpty({ message: 'Text is required for text messages' })
    text?: string;

    @ApiPropertyOptional({ example: 'https://res.cloudinary.com/demo/image/upload/sample.png' })
    @ValidateIf((dto: SendChatMessageDto) => dto.messageType === ChatMessageTypeDto.IMAGE)
    @IsUrl({}, { message: 'Attachment URL must be a valid URL' })
    attachmentUrl?: string;

    @ApiPropertyOptional({ example: 'image/png' })
    @IsOptional()
    @IsString()
    attachmentType?: string;
}

export class ChatTypingDto {
    @ApiProperty({ example: '7db96c57-5e0e-4b35-bb85-0123456789ab' })
    @IsUUID('4', { message: 'Conversation ID must be a valid UUID' })
    conversationId: string;

    @ApiProperty({ example: true })
    isTyping: boolean;
}

export class MarkMessagesSeenDto {
    @ApiProperty({ example: '7db96c57-5e0e-4b35-bb85-0123456789ab' })
    @IsUUID('4', { message: 'Conversation ID must be a valid UUID' })
    conversationId: string;
}
