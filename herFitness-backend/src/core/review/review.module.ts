import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { TrainerReviewRepository } from './domain/repositories/trainer-review.repository';
import { ReviewController } from './review.controller';
import { ReviewService } from './review.service';
import { NotificationModule } from '../notification/notification.module';

@Module({
    imports: [UserModule, NotificationModule],
    controllers: [ReviewController],
    providers: [ReviewService, TrainerReviewRepository],
})
export class ReviewModule { }
