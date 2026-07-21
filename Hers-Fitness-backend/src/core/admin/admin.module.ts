import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminRepository } from './domain/admin.repository';
import { DatabaseModule } from 'src/database/database.module';
import { UserModule } from '../user/user.module';

@Module({
    imports: [DatabaseModule, UserModule],
    controllers: [AdminController],
    providers: [AdminService, AdminRepository],
    exports: [AdminRepository], // exported so fitness-class.repository can look up the current rate
})
export class AdminModule { }
