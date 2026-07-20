import { Injectable } from '@nestjs/common';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { Roles } from 'src/common/enums/roles.enum';
import { CloudinaryStorageService } from 'src/infrastructure/storage/cloudinary/cloudinary-storage.service';
import { UserService } from '../user/user.service';
import { ChatRepository } from './domain/chat.repository';
import { ChatMessageTypeDto, SendChatMessageDto, StartConversationDto } from './dto/chat-message.dto';
import { ChatConversationResponseDto, ChatMessageResponseDto, ChatParticipantResponseDto } from './dto/chat-response.dto';
import { NotificationService, NotificationType } from '../notification/notification.service';

@Injectable()
export class ChatService {
    constructor(
        private readonly chatRepository: ChatRepository,
        private readonly userService: UserService,
        private readonly cloudinaryStorageService: CloudinaryStorageService,
        private readonly notificationService: NotificationService,
    ) { }

    async startConversation(currentUserId: string, model: StartConversationDto): Promise<ChatConversationResponseDto> {
        const currentUser = await this.ensureUser(currentUserId);
        const trainer = await this.ensureUser(model.trainerUserId);
        const currentRoleNames = currentUser.roles?.map((role) => role.name) ?? [];
        const trainerRoleNames = trainer.roles?.map((role) => role.name) ?? [];

        if (!currentRoleNames.includes(Roles.Member)) {
            throw new BadRequestAppException('Only members can start support chat with a trainer.', ['MEMBER_ONLY_FEATURE']);
        }

        if (!trainerRoleNames.includes(Roles.Trainer)) {
            throw new BadRequestAppException('Conversation target must be a trainer.', ['TRAINER_REQUIRED']);
        }

        const conversation = await this.chatRepository.findOrCreateConversation(currentUserId, model.trainerUserId);
        return this.mapConversation(conversation);
    }

    async findConversations(currentUserId: string): Promise<ChatConversationResponseDto[]> {
        const conversations = await this.chatRepository.findConversationsForUser(currentUserId);
        return conversations.map((conversation: any) => this.mapConversation(conversation));
    }

    /**
     * Returns the raw conversation IDs for a user — used by the gateway's
     * handleConnection to join all rooms and mark the user ACTIVE without
     * mapping full DTOs for each conversation.
     */
    async findConversationIds(userId: string): Promise<string[]> {
        const conversations = await this.chatRepository.findConversationsForUser(userId);
        return conversations.map((c: any) => c.id as string);
    }

    async findMessages(currentUserId: string, conversationId: string): Promise<ChatMessageResponseDto[]> {
        await this.ensureConversationParticipant(currentUserId, conversationId);
        const messages = await this.chatRepository.findMessages(conversationId);
        return messages.map((message: any) => this.mapMessage(message));
    }

    async sendMessage(currentUserId: string, conversationId: string, model: SendChatMessageDto): Promise<ChatMessageResponseDto> {
        const conversation = await this.ensureConversationParticipant(currentUserId, conversationId);
        const message = await this.chatRepository.createMessage(conversationId, currentUserId, model);
        await this.notifyChatRecipient(conversation, currentUserId, model.text ?? 'Sent a message');
        return this.mapMessage(message);
    }

    async sendImageMessage(
        currentUserId: string,
        conversationId: string,
        image?: Express.Multer.File,
    ): Promise<ChatMessageResponseDto> {
        const conversation = await this.ensureConversationParticipant(currentUserId, conversationId);

        if (!image) {
            throw new BadRequestAppException('Image file is required.', ['IMAGE_REQUIRED']);
        }

        const uploadResponse = await this.cloudinaryStorageService.uploadImage(image, 'chat/images');
        if (!uploadResponse.secureUrl) {
            throw new BadRequestAppException('Failed to upload chat image.', ['FILE_UPLOAD_ERROR']);
        }

        const message = await this.chatRepository.createMessage(conversationId, currentUserId, {
            messageType: ChatMessageTypeDto.IMAGE,
            attachmentUrl: uploadResponse.secureUrl,
            attachmentType: uploadResponse.fileType,
        });

        await this.notifyChatRecipient(conversation, currentUserId, 'Sent an image');

        return this.mapMessage(message);
    }

    async markSeen(currentUserId: string, conversationId: string): Promise<ChatMessageResponseDto[]> {
        await this.ensureConversationParticipant(currentUserId, conversationId);
        const messages = await this.chatRepository.markMessagesSeen(conversationId, currentUserId);
        return messages.map((message: any) => this.mapMessage(message));
    }

    async updateActiveStatus(currentUserId: string, conversationId: string, isActive: boolean): Promise<ChatConversationResponseDto> {
        await this.ensureConversationParticipant(currentUserId, conversationId);
        const conversation = await this.chatRepository.updateParticipantStatus(
            conversationId,
            currentUserId,
            isActive ? 'ACTIVE' : 'INACTIVE',
        );

        if (!conversation) {
            throw new NotFoundAppException('Conversation not found.', 'CONVERSATION_NOT_FOUND');
        }

        return this.mapConversation(conversation);
    }

    async ensureConversationParticipant(currentUserId: string, conversationId: string): Promise<any> {
        const conversation = await this.chatRepository.findConversationById(conversationId);
        if (!conversation) {
            throw new NotFoundAppException('Conversation not found.', 'CONVERSATION_NOT_FOUND');
        }

        if (conversation.memberUserId !== currentUserId && conversation.trainerUserId !== currentUserId) {
            throw new BadRequestAppException('You are not part of this conversation.', ['CHAT_ACCESS_DENIED']);
        }

        return conversation;
    }

    private async ensureUser(userId: string) {
        const user = await this.userService.findById(userId);
        if (!user) {
            throw new NotFoundAppException('User not found.', 'USER_NOT_FOUND');
        }

        return user;
    }

    private mapConversation(conversation: any): ChatConversationResponseDto {
        return new ChatConversationResponseDto({
            id: conversation.id,
            memberUserId: conversation.memberUserId,
            trainerUserId: conversation.trainerUserId,
            memberStatus: conversation.memberStatus,
            trainerStatus: conversation.trainerStatus,
            lastMessageAt: conversation.lastMessageAt ?? null,
            member: this.mapParticipant(conversation.member),
            trainer: this.mapParticipant(conversation.trainer),
            lastMessage: conversation.messages?.[0] ? this.mapMessage(conversation.messages[0]) : null,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt ?? null,
        });
    }

    private mapParticipant(user: any): ChatParticipantResponseDto {
        return new ChatParticipantResponseDto({
            id: user.id,
            name: user.displayName ?? user.firstName ?? null,
            profileImageUrl: user.profileImageUrl ?? null,
        });
    }

    private mapMessage(message: any): ChatMessageResponseDto {
        return new ChatMessageResponseDto({
            id: message.id,
            conversationId: message.conversationId,
            senderUserId: message.senderUserId,
            messageType: message.messageType,
            text: message.text ?? null,
            attachmentUrl: message.attachmentUrl ?? null,
            attachmentType: message.attachmentType ?? null,
            seenAt: message.seenAt ?? null,
            createdAt: message.createdAt,
        });
    }

    private async notifyChatRecipient(conversation: any, senderUserId: string, preview: string): Promise<void> {
        const recipientUserId = conversation.memberUserId === senderUserId
            ? conversation.trainerUserId
            : conversation.memberUserId;

        await this.notificationService.notifyUser({
            userId: recipientUserId,
            type: NotificationType.CHAT_MESSAGE,
            title: 'New message',
            body: preview.length > 120 ? `${preview.slice(0, 117)}...` : preview,
            data: {
                conversationId: conversation.id,
                senderUserId,
            },
        });
    }
}
