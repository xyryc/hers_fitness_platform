import { Module } from '@nestjs/common';
import { UserModule } from './user/user.module';
import { AuthModule } from './auth/auth.module';
import { ClassModule } from './class/class.module';
import { LocationModule } from './location/location.module';
import { ChatModule } from './chat/chat.module';
import { ReviewModule } from './review/review.module';
import { NotificationModule } from './notification/notification.module';
import { HelpTicketModule } from './help-ticket/help-ticket.module';
import { FaqModule } from './faq/faq.module';
import { AdminModule } from './admin/admin.module';

@Module({
    imports: [UserModule, AuthModule, ClassModule, LocationModule, ChatModule, ReviewModule, NotificationModule, HelpTicketModule, FaqModule, AdminModule]
})
export class CoreModule { }
