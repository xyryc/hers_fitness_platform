import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AppConfig {
    constructor(private readonly config: ConfigService) { }

    get environment(): string {
        return this.config.get<string>('NODE_ENV', 'development');
    }

    get port(): number {
        return this.config.get<number>('PORT', 3003);
    }

    get jwt(): {
        secret: string;
        refreshSecret: string;
        audience: string;
        issuer: string;
        expiresIn: string;
        refreshExpiresIn: string;
        algorithm: string;
    } {
        return {
            secret: this.config.get<string>('JWT_SECRET', 'secretKey'),
            refreshSecret: this.config.get<string>('JWT_REFRESH_SECRET', 'refreshSecretKey'),
            audience: this.config.get<string>('JWT_AUDIENCE', 'http://localhost:3000'),
            issuer: this.config.get<string>('JWT_ISSUER', 'http://localhost:3000'),
            expiresIn: this.config.get<string>('JWT_EXPIRES_IN', '1d'),
            refreshExpiresIn: this.config.get<string>('JWT_REFRESH_EXPIRES_IN', '30d'),
            algorithm: this.config.get<string>('JWT_ALGORITHM', 'HS256')
        };
    }

    get api(): {
        clientId: string;
    } {
        return {
            clientId: this.config.get<string>('CLIENT_ID', 'clientId')
        };
    }

    get admin(): {
        email: string;
        password: string;
        firstName: string;
        lastName: string;
    } {
        return {
            email: this.config.get<string>('ADMIN_EMAIL', 'admin@heba.local'),
            password: this.config.get<string>('ADMIN_PASSWORD', 'Admin@12345'),
            firstName: this.config.get<string>('ADMIN_FIRST_NAME', 'Admin'),
            lastName: this.config.get<string>('ADMIN_LAST_NAME', 'User'),
        };
    }

    get app(): {
        name: string;
        version: string;
        mode: string;
        description: string;
        author: string;
        url: string;
    } {
        return {
            name: this.config.get<string>('APP_NAME', 'NestJs API Starter Template'),
            version: this.config.get<string>('APP_VERSION', '1.0.0'),
            mode: this.config.get<string>('APP_MODE', 'local'),
            description: this.config.get<string>('APP_DESCRIPTION', 'NestJs API Starter Template'),
            author: this.config.get<string>('APP_AUTHOR', 'NestJs API Starter Template'),
            url: this.config.get<string>('APP_URL', 'http://localhost:3000')
        };
    }

    get database(): {
        url: string;
    } {
        return {
            url: this.config.get<string>('DATABASE_URL', '')
        };
    }

    get cloudinary(): {
        cloudName: string;
        apiKey: string;
        apiSecret: string;
    } {
        return {
            cloudName: this.config.get<string>('CLOUDINARY_CLOUD_NAME', ''),
            apiKey: this.config.get<string>('CLOUDINARY_API_KEY', ''),
            apiSecret: this.config.get<string>('CLOUDINARY_API_SECRET', '')
        };
    }

    get email(): {
        fromName: string;
        fromEmail: string;
        replyToName: string;
        replyToEmail: string;
        developerEmail: string;
    } {
        return {
            fromName: this.config.get<string>('SMTP_FROM_NAME', ''),
            fromEmail: this.config.get<string>('SMTP_FROM_EMAIL', ''),
            replyToName: this.config.get<string>('SMTP_REPLY_TO_NAME', ''),
            replyToEmail: this.config.get<string>('SMTP_REPLY_TO_EMAIL', ''),
            developerEmail: this.config.get<string>('DEVELOPER_EMAIL', '')
        };
    }

    get smtp(): {
        host: string;
        port: number;
        username: string;
        password: string;
    } {
        return {
            host: this.config.get<string>('SMTP_HOST', ''),
            port: this.config.get<number>('SMTP_PORT', 587),
            username: this.config.get<string>('SMTP_USERNAME', ''),
            password: this.config.get<string>('SMTP_PASSWORD', '')
        };
    }

    get stripe(): {
        secretKey: string;
        publishableKey: string;
        webhookSecret: string;
    } {
        return {
            secretKey: this.config.get<string>('STRIPE_SECRET_KEY', ''),
            publishableKey: this.config.get<string>('STRIPE_PUBLISHABLE_KEY', ''),
            webhookSecret: this.config.get<string>('STRIPE_WEBHOOK_SECRET', ''),
        };
    }

    get firebase(): {
        projectId: string;
        clientEmail: string;
        privateKey: string;
        serviceAccountPath: string;
        serviceAccountJson: string;
    } {
        return {
            projectId: this.config.get<string>('FIREBASE_PROJECT_ID', ''),
            clientEmail: this.config.get<string>('FIREBASE_CLIENT_EMAIL', ''),
            privateKey: this.config.get<string>('FIREBASE_PRIVATE_KEY', ''),
            serviceAccountPath: this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH', ''),
            serviceAccountJson: this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON', ''),
        };
    }
}
