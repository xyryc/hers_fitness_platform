import { Body, Controller, Get, HttpCode, Param, Patch, Post, Request, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { MarkMessagesSeenDto, SendChatMessageDto, StartConversationDto } from './dto/chat-message.dto';
import { ChatConversationResponseDto, ChatMessageResponseDto } from './dto/chat-response.dto';

@ApiTags('5. Messaging')
@ApiBearerAuth('access-token')
@Controller('chat')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class ChatController {
    constructor(
        private readonly chatService: ChatService,
        private readonly chatGateway: ChatGateway,
    ) { }

    @Post('conversations')
    @HttpCode(201)
    @ApiOperation({ summary: 'Start or get an existing member-trainer conversation' })
    async startConversation(@Body() model: StartConversationDto, @Request() req) {
        const conversation = await this.chatService.startConversation(req.user.currentUserId, model);
        return new CustomResponse<ChatConversationResponseDto>('Conversation ready', conversation, 201);
    }

    @Get('conversations')
    @ApiOperation({ summary: 'List current user conversations' })
    async findConversations(@Request() req) {
        const conversations = await this.chatService.findConversations(req.user.currentUserId);
        return new CustomResponse<ChatConversationResponseDto[]>('Conversations fetched successfully', conversations, 200);
    }

    @Get('conversations/:conversationId/messages')
    @ApiOperation({ summary: 'List messages in a conversation' })
    async findMessages(@Param('conversationId') conversationId: string, @Request() req) {
        const messages = await this.chatService.findMessages(req.user.currentUserId, conversationId);
        return new CustomResponse<ChatMessageResponseDto[]>('Messages fetched successfully', messages, 200);
    }

    @Post('conversations/:conversationId/messages')
    @HttpCode(201)
    @ApiOperation({ summary: 'Send a message through REST fallback' })
    async sendMessage(
        @Param('conversationId') conversationId: string,
        @Body() model: SendChatMessageDto,
        @Request() req,
    ) {
        const message = await this.chatService.sendMessage(req.user.currentUserId, conversationId, model);
        // Broadcast to the OTHER participant via socket so they get real-time delivery.
        // The sender already has the message from this REST response — exclude them by
        // using the gateway's broadcastNewMessage which emits to the whole room (since
        // REST has no socket client to exclude, the sender's socket will also receive it,
        // but _addOrReplaceMessage deduplicates by id so there is no visible duplicate).
        this.chatGateway.broadcastNewMessage(conversationId, message);
        return new CustomResponse<ChatMessageResponseDto>('Message sent successfully', message, 201);
    }

    @Post('conversations/:conversationId/messages/image')
    @HttpCode(201)
    @ApiOperation({ summary: 'Upload and send an image message through REST fallback' })
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        schema: {
            type: 'object',
            required: ['image'],
            properties: {
                image: {
                    type: 'string',
                    format: 'binary',
                },
            },
        },
    })
    @UseInterceptors(FileInterceptor('image'))
    async sendImageMessage(
        @Param('conversationId') conversationId: string,
        @UploadedFile() image: Express.Multer.File,
        @Request() req,
    ) {
        const message = await this.chatService.sendImageMessage(req.user.currentUserId, conversationId, image);
        // Broadcast via socket so the recipient's chat screen updates in real-time.
        // Without this, the image is saved to DB but the other user never sees it
        // until they reload the conversation.
        this.chatGateway.broadcastNewMessage(conversationId, message);
        return new CustomResponse<ChatMessageResponseDto>('Image message sent successfully', message, 201);
    }

    @Patch('conversations/:conversationId/seen')
    @ApiOperation({ summary: 'Mark conversation messages as seen' })
    async markSeen(@Param('conversationId') conversationId: string, @Request() req) {
        const messages = await this.chatService.markSeen(req.user.currentUserId, conversationId);
        return new CustomResponse<ChatMessageResponseDto[]>('Messages marked as seen', messages, 200);
    }
}
