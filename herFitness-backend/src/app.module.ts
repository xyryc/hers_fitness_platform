import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import * as Joi from 'joi';
import { AppConfigModule } from './config/app.config.module';
import { HealthModule } from './health/health.module';
import { ClientIdMiddleware } from './common/middlewares/client-id.middleware';
import { DatabaseModule } from './database/database.module';
import { CoreModule } from './core/core.module';
import { MulterModule } from '@nestjs/platform-express';
import { multerConfig } from './common/multer/multer.config';
import { CloudinaryStorageModule } from './infrastructure/storage/cloudinary/cloudinary-storage.module';
import { EmailModule } from './infrastructure/email/email.module';
import { ClientDetailsMiddleware } from './common/middlewares/client-details.middleware';
import { CountryModule } from './country/country.module';

@Module({
  imports: [ConfigModule.forRoot({
    isGlobal: true,
    ignoreEnvFile: process.env.NODE_ENV === 'production',
    envFilePath: [
      '.env.local',
      `.env.${process.env.NODE_ENV}`,
      '.env',
    ],
    validationSchema: Joi.object({
      NODE_ENV: Joi.string().valid('development', 'production').required(),
      PORT: Joi.number().default(3001),
      DATABASE_URL: Joi.string().required(),
      ADMIN_EMAIL: Joi.string().email({ tlds: { allow: false } }).default('admin@heba.local'),
      ADMIN_PASSWORD: Joi.string().min(8).default('Admin@12345'),
      ADMIN_FIRST_NAME: Joi.string().default('Admin'),
      ADMIN_LAST_NAME: Joi.string().default('User'),
      STRIPE_SECRET_KEY: Joi.string().allow('').optional(),
      STRIPE_PUBLISHABLE_KEY: Joi.string().allow('').optional(),
      STRIPE_WEBHOOK_SECRET: Joi.string().allow('').optional(),
      FIREBASE_PROJECT_ID: Joi.string().allow('').optional(),
      FIREBASE_CLIENT_EMAIL: Joi.string().allow('').optional(),
      FIREBASE_PRIVATE_KEY: Joi.string().allow('').optional(),
      FIREBASE_SERVICE_ACCOUNT_PATH: Joi.string().allow('').optional(),
      FIREBASE_SERVICE_ACCOUNT_JSON: Joi.string().allow('').optional(),
    })
  }),
    AppConfigModule,
    DatabaseModule,
    HealthModule,
    CloudinaryStorageModule,
    EmailModule,
    CoreModule,
  MulterModule.register(multerConfig),
  CountryModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(ClientDetailsMiddleware).forRoutes('/api/*path');
    consumer
      .apply(ClientIdMiddleware)
      .exclude(
        'health/check',
        'auth/login',
        'auth/register',
      )
      .forRoutes('/api/*path');
  }
}
