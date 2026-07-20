import { Controller, Get } from '@nestjs/common';
import { AppConfig } from '../config/app.config';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('8. System')
@Controller('health')
export class HealthController {
    constructor(private readonly appConfig: AppConfig) { }

    @Get('check')
    getHealth(): {
        appName: string;
        appVersion: string;
        appMode: string;
        appDescription: string;
        appAuthor: string;
        appUrl: string;
    } {
        return {
            appName: this.appConfig.app.name,
            appVersion: this.appConfig.app.version,
            appMode: this.appConfig.app.mode,
            appDescription: this.appConfig.app.description,
            appAuthor: this.appConfig.app.author,
            appUrl: this.appConfig.app.url,
        };
    }

}
