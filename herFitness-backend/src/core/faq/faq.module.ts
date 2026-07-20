import { Module } from '@nestjs/common';
import { FaqController, AdminFaqController } from './faq.controller';
import { FaqService } from './faq.service';
import { FaqRepository } from './domain/faq.repository';
import { UserModule } from '../user/user.module';

@Module({
    imports: [UserModule],
    controllers: [FaqController, AdminFaqController],
    providers: [FaqService, FaqRepository],
})
export class FaqModule {}
