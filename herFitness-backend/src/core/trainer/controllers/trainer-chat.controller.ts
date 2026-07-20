import { Body, Controller, Get, HttpCode, Param, Patch, Post, Request, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { ApprovedAccountGuard } from '../../auth/guards/approved-account.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { ChatService } from '../../chat/chat.service';
import { ChatGateway } from '../../chat/chat.gateway';
import { SendChatMessageDto, StartConversationDto } from '../../chat/dto/chat-message.dto';
import { ChatConversationResponseDto, ChatMessageResponseDto } from '../../chat/dto/chat-response.dto';

@ApiTags('5. Messaging')
@ApiBearerAuth('access-token')
@Controller('chat')
@UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
export class TrainerChatController {
    constructor(
        private readonly chatService: ChatService,
        private readonly chatGateway: ChatGateway,
    ) { }

    @Post('conversations')
    @HttpCode(201)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: Start or get an existing member-trainer conversation' })
    async startConversation(@Body() model: StartConversationDto, @Request() req) {
        const conversation = await this.chatService.startConversation(req.user.currentUserId, model);
        return new CustomResponse<ChatConversationResponseDto>('Conversation ready', conversation, 201);
    }

    @Get('conversations')
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: List conversations' })
    async findConversations(@Request() req) {
        const conversations = await this.chatService.findConversations(req.user.currentUserId);
        return new CustomResponse<ChatConversationResponseDto[]>('Conversations fetched successfully', conversations, 200);
    }

    @Get('conversations/:conversationId/messages')
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: List messages in a conversation' })
    async findMessages(@Param('conversationId') conversationId: string, @Request() req) {
        const messages = await this.chatService.findMessages(req.user.currentUserId, conversationId);
        return new CustomResponse<ChatMessageResponseDto[]>('Messages fetched successfully', messages, 200);
    }

    @Post('conversations/:conversationId/messages')
    @HttpCode(201)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: Send a message' })
    async sendMessage(
        @Param('conversationId') conversationId: string,
        @Body() model: SendChatMessageDto,
        @Request() req,
    ) {
        const message = await this.chatService.sendMessage(req.user.currentUserId, conversationId, model);
        this.chatGateway.broadcastNewMessage(conversationId, message);
        return new CustomResponse<ChatMessageResponseDto>('Message sent successfully', message, 201);
    }

    @Post('conversations/:conversationId/messages/image')
    @HttpCode(201)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: Upload and send an image message' })
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
        this.chatGateway.broadcastNewMessage(conversationId, message);
        return new CustomResponse<ChatMessageResponseDto>('Image message sent successfully', message, 201);
    }

    @Patch('conversations/:conversationId/seen')
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: Mark conversation messages as seen' })
    async markSeen(@Param('conversationId') conversationId: string, @Request() req) {
        const messages = await this.chatService.markSeen(req.user.currentUserId, conversationId);
        return new CustomResponse<ChatMessageResponseDto[]>('Messages marked as seen', messages, 200);
    }
}
