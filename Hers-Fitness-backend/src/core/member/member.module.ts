import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { ClassModule } from '../class/class.module';
import { ReviewModule } from '../review/review.module';
import { NotificationModule } from '../notification/notification.module';
import { MemberUserController } from './controllers/member-user.controller';
import { MemberClassController } from './controllers/member-class.controller';
import { MemberAuthController } from './controllers/member-auth.controller';
import { MemberReviewController } from './controllers/member-review.controller';
import { MemberNotificationController } from './controllers/member-notification.controller';
import { HelpTicketModule } from '../help-ticket/help-ticket.module';
import { MemberHelpTicketController } from './controllers/member-help-ticket.controller';
import { LocationModule } from '../location/location.module';
import { MemberLocationController } from './controllers/member-location.controller';
import { ChatModule } from '../chat/chat.module';
import { MemberChatController } from './controllers/member-chat.controller';

@Module({
    imports: [UserModule, AuthModule, ClassModule, ReviewModule, NotificationModule, HelpTicketModule, LocationModule, ChatModule],
    controllers: [
        MemberUserController,
        MemberClassController,
        MemberAuthController,
        MemberReviewController,
        MemberNotificationController,
        MemberHelpTicketController,
        MemberLocationController,
        MemberChatController,
    ],
    providers: [],
})
export class MemberModule {}
