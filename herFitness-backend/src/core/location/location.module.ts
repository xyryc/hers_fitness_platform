import { Module } from '@nestjs/common';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { UserModule } from '../user/user.module';
import { LocationController } from './location.controller';
import { LocationService } from './location.service';
import { LocationRepository } from './domain/repositories/location.repository';

@Module({
    imports: [UserModule],
    controllers: [LocationController],
    providers: [LocationService, LocationRepository, AuthGuard, RolesGuard],
})
export class LocationModule { }
