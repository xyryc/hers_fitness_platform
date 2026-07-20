import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface ClientInfoDetails {
    ip: string;
    userAgent: string;
}

export const ClientInfo = createParamDecorator(
    (data: unknown, ctx: ExecutionContext): ClientInfoDetails => {
        const request = ctx.switchToHttp().getRequest();

        return {
            ip: request.clientDetails?.ip || '',
            userAgent: request.clientDetails?.userAgent || '',
        };
    },
);