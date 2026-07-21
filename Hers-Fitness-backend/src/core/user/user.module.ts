import { Module } from '@nestjs/common';
import { UserController, StaticContentController } from './user.controller';
import { UserService } from './user.service';
import { UserRepository } from './domain/repositories/user.repository';
import { UserTokenRepository } from './domain/repositories/user-token.repository';
import { UserSessionRepository } from './domain/repositories/user-session.repository';
import { UserPasswordHistoryRepository } from './domain/repositories/user-password-history.repository';
import { RoleRepository } from './domain/repositories/role.repository';
import { UserVerificationRepository } from './domain/repositories/user-verification.repository';
import { TrainerProfileRepository } from './domain/repositories/trainer-profile.repository';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { MemberFitnessAssessmentRepository } from './domain/repositories/member-fitness-assessment.repository';
import { AdminBootstrapService } from './admin-bootstrap.service';
import { FavoriteTrainerRepository } from './domain/repositories/favorite-trainer.repository';
import { StripePaymentModule } from 'src/infrastructure/payment/stripe/stripe-payment.module';

@Module({
    imports: [StripePaymentModule],
    controllers: [UserController, StaticContentController],
    providers: [UserService, UserRepository, UserTokenRepository, UserSessionRepository, UserPasswordHistoryRepository, RoleRepository, UserVerificationRepository, TrainerProfileRepository, MemberFitnessAssessmentRepository, FavoriteTrainerRepository, AdminBootstrapService, AuthGuard, RolesGuard, ApprovedAccountGuard],
    exports: [UserService],
})
export class UserModule { }
