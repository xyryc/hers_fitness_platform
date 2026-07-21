import { ValidationPipe, ValidationError } from '@nestjs/common';
import { BadRequestAppException } from '../exceptions/bad-request.exception';

export class AppValidationPipe extends ValidationPipe {
    constructor() {
        super({
            whitelist: true,
            forbidNonWhitelisted: true,
            transform: true,
            exceptionFactory: (errors: ValidationError[]) => {
                const messages = errors.flatMap((err) =>
                    Object.values(err.constraints || {}),
                );

                throw new BadRequestAppException(
                    'Validation failed',
                    messages,
                );
            },
        });
    }
}