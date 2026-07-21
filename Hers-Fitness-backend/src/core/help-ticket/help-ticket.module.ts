import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { NotificationModule } from '../notification/notification.module';
import { HelpTicketRepository } from './domain/repositories/help-ticket.repository';
import { HelpTicketController } from './help-ticket.controller';
import { HelpTicketService } from './help-ticket.service';

@Module({
    imports: [UserModule, NotificationModule],
    controllers: [HelpTicketController],
    providers: [HelpTicketService, HelpTicketRepository],
})
export class HelpTicketModule {}
