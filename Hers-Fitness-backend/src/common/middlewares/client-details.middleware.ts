import { Request, Response, NextFunction } from 'express';
import { Injectable, NestMiddleware } from '@nestjs/common';
import { AppConfig } from 'src/config/app.config';
import { getClientIP, parseUserAgent } from 'src/utils/client.utils';

@Injectable()
export class ClientDetailsMiddleware implements NestMiddleware {

    constructor(private readonly appConfig: AppConfig) { }

    use(req: Request, res: Response, next: NextFunction) {

        req.clientDetails = {
            ip: getClientIP(req) || '',
            userAgent: req.headers['user-agent'] || '',
            referer: req.headers.referer || (req.headers.referrer as string),
            origin: req.headers.origin,
            host: req.headers.host,
            acceptLanguage: req.headers['accept-language'],
            acceptEncoding: (req.headers['accept-encoding'] || '') as string,
            connection: req.headers.connection,
            timestamp: new Date().toISOString(),
            method: req.method,
            url: req.url,
            protocol: req.protocol,
            secure: req.secure,
            xForwardedFor: req.headers['x-forwarded-for'] as string,
            xRealIp: req.headers['x-real-ip'] as string,
            cfRay: req.headers['cf-ray'] as string,
            cfIpCountry: req.headers['cf-ipcountry'] as string,
            userAgentParsed: parseUserAgent(req),
        };

        next();
    }
}
