import { Global, Module } from '@nestjs/common';
import { EmailService } from './email.service';
import { AppConfigModule } from 'src/config/app.config.module';

@Global()
@Module({
    imports: [AppConfigModule],
    providers: [EmailService],
    exports: [EmailService],
})
export class EmailModule { }
