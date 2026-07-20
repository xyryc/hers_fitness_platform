import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { ClassController } from './class.controller';
import { ClassService } from './class.service';
import { FitnessClassRepository } from './domain/repositories/fitness-class.repository';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { StripePaymentModule } from 'src/infrastructure/payment/stripe/stripe-payment.module';
import { NotificationModule } from '../notification/notification.module';
import { AdminModule } from '../admin/admin.module';

@Module({
    imports: [UserModule, AuthModule, StripePaymentModule, NotificationModule, AdminModule],
    controllers: [ClassController],
    providers: [ClassService, FitnessClassRepository, ApprovedAccountGuard, RolesGuard],
})
export class ClassModule { }
