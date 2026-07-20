import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { ClassModule } from '../class/class.module';
import { NotificationModule } from '../notification/notification.module';
import { TrainerUserController } from './controllers/trainer-user.controller';
import { TrainerClassController } from './controllers/trainer-class.controller';
import { TrainerAuthController } from './controllers/trainer-auth.controller';
import { TrainerNotificationController } from './controllers/trainer-notification.controller';
import { HelpTicketModule } from '../help-ticket/help-ticket.module';
import { TrainerHelpTicketController } from './controllers/trainer-help-ticket.controller';
import { LocationModule } from '../location/location.module';
import { TrainerLocationController } from './controllers/trainer-location.controller';
import { ChatModule } from '../chat/chat.module';
import { TrainerChatController } from './controllers/trainer-chat.controller';
import { StripePaymentModule } from 'src/infrastructure/payment/stripe/stripe-payment.module';

@Module({
    imports: [UserModule, AuthModule, ClassModule, NotificationModule, HelpTicketModule, LocationModule, ChatModule, StripePaymentModule],
    controllers: [
        TrainerUserController,
        TrainerClassController,
        TrainerAuthController,
        TrainerNotificationController,
        TrainerHelpTicketController,
        TrainerLocationController,
        TrainerChatController,
    ],
    providers: [],
})
export class TrainerModule {}
