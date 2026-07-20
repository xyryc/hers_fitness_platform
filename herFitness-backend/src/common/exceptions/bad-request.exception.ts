import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class BadRequestAppException extends AppException {
    constructor(message = 'Bad request', errors?: string[]) {
        super(message, HttpStatus.BAD_REQUEST, 'BAD_REQUEST', errors);
    }
}
