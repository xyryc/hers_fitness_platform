import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { FirebasePushService } from './firebase-push.service';
import { NotificationController } from './notification.controller';
import { NotificationRepository } from './domain/notification.repository';
import { NotificationPreferenceRepository } from './domain/notification-preference.repository';
import { NotificationService } from './notification.service';

@Module({
    imports: [UserModule],
    controllers: [NotificationController],
    providers: [
        NotificationService,
        NotificationRepository,
        NotificationPreferenceRepository,
        FirebasePushService,
        AuthGuard,
        ApprovedAccountGuard,
        RolesGuard,
    ],
    exports: [NotificationService],
})
export class NotificationModule { }

