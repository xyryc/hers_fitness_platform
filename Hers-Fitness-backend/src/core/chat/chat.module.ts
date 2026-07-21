import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { ChatController } from './chat.controller';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';
import { ChatRepository } from './domain/chat.repository';
import { NotificationModule } from '../notification/notification.module';

@Module({
    imports: [UserModule, NotificationModule],
    controllers: [ChatController],
    providers: [ChatGateway, ChatService, ChatRepository],
})
export class ChatModule { }
