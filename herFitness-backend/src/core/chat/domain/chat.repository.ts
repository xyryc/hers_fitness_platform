import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { SendChatMessageDto } from '../dto/chat-message.dto';

@Injectable()
export class ChatRepository {
    constructor(private readonly prisma: PrismaService) { }

    async findOrCreateConversation(memberUserId: string, trainerUserId: string) {
        return (this.prisma as any).chatConversation.upsert({
            where: {
                uq_chat_conversations_member_trainer: {
                    memberUserId,
                    trainerUserId,
                },
            },
            update: {},
            create: {
                memberUserId,
                trainerUserId,
            },
            include: this.getConversationIncludePattern(),
        });
    }

    async findConversationById(conversationId: string) {
        return (this.prisma as any).chatConversation.findUnique({
            where: { id: conversationId },
            include: this.getConversationIncludePattern(),
        });
    }

    async findConversationsForUser(userId: string) {
        return (this.prisma as any).chatConversation.findMany({
            where: {
                OR: [
                    { memberUserId: userId },
                    { trainerUserId: userId },
                ],
            },
            include: this.getConversationIncludePattern(),
            orderBy: [
                { lastMessageAt: 'desc' },
                { createdAt: 'desc' },
            ],
        });
    }

    async createMessage(conversationId: string, senderUserId: string, model: SendChatMessageDto) {
        return (this.prisma as any).$transaction(async (tx: any) => {
            const message = await tx.chatMessage.create({
                data: {
                    conversationId,
                    senderUserId,
                    messageType: model.messageType,
                    text: model.text ?? null,
                    attachmentUrl: model.attachmentUrl ?? null,
                    attachmentType: model.attachmentType ?? null,
                },
                include: this.getMessageIncludePattern(),
            });

            await tx.chatConversation.update({
                where: { id: conversationId },
                data: {
                    lastMessageAt: message.createdAt,
                },
            });

            return message;
        });
    }

    async findMessages(conversationId: string, take: number = 50) {
        // Fetch the most-recent `take` messages (desc), then reverse so the
        // caller always receives them in oldest-first (asc) order.
        // Using desc+reverse instead of asc+take ensures newly sent messages
        // are never hidden behind older records when the conversation exceeds
        // the page limit.
        const messages = await (this.prisma as any).chatMessage.findMany({
            where: { conversationId },
            include: this.getMessageIncludePattern(),
            orderBy: { createdAt: 'desc' },
            take,
        });
        return messages.reverse();
    }

    async markMessagesSeen(conversationId: string, viewerUserId: string) {
        await (this.prisma as any).chatMessage.updateMany({
            where: {
                conversationId,
                senderUserId: {
                    not: viewerUserId,
                },
                seenAt: null,
            },
            data: {
                seenAt: new Date(),
            },
        });

        return this.findMessages(conversationId);
    }

    async updateParticipantStatus(conversationId: string, userId: string, status: 'ACTIVE' | 'INACTIVE') {
        const conversation = await this.findConversationById(conversationId);
        if (!conversation) return null;

        const data = conversation.memberUserId === userId
            ? { memberStatus: status }
            : conversation.trainerUserId === userId
                ? { trainerStatus: status }
                : null;

        if (!data) return null;

        return (this.prisma as any).chatConversation.update({
            where: { id: conversationId },
            data,
            include: this.getConversationIncludePattern(),
        });
    }

    private getConversationIncludePattern() {
        return {
            member: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    profileImageUrl: true,
                },
            },
            trainer: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    profileImageUrl: true,
                },
            },
            messages: {
                orderBy: { createdAt: 'desc' },
                take: 1,
                include: this.getMessageIncludePattern(),
            },
        };
    }

    private getMessageIncludePattern() {
        return {};
    }
}
