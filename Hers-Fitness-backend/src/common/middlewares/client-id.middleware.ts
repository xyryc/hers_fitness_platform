import { Request, Response, NextFunction } from 'express';
import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { AppConfig } from 'src/config/app.config';

@Injectable()
export class ClientIdMiddleware implements NestMiddleware {
  private readonly publicPaths = [
    '/health/check',
    '/auth/login',
    '/auth/register',
    '/auth/register/trainer',
    '/auth/verify-email',
    '/auth/resend-verification',
    '/auth/forgot-password',
    '/auth/verify-password-reset-otp',
    '/auth/reset-password',
  ];

  private readonly publicPathPrefixes = [
    '/static-content/',
  ];

  constructor(private readonly appConfig: AppConfig) { }

  use(req: Request, res: Response, next: NextFunction) {
    if (this.isPublicPath(req.path)) {
      next();
      return;
    }

    const clientId = req.headers['x-client-id'];
    if (!clientId) {
      throw new UnauthorizedException('Client ID is required');
    }

    if (clientId as string !== this.appConfig.api.clientId) {
      throw new UnauthorizedException('Invalid Client ID');
    }

    req.clientId = clientId as string;
    next();
  }

  private isPublicPath(path: string): boolean {
    const normalizedPath = path.startsWith('/api/')
      ? path.replace('/api', '')
      : path;

    return this.publicPaths.includes(normalizedPath)
      || normalizedPath === '/faqs'
      || this.publicPathPrefixes.some((prefix) => normalizedPath.startsWith(prefix));
  }
}
