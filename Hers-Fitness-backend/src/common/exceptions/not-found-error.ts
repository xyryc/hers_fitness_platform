import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class NotFoundAppException extends AppException {
    constructor(message = 'Resource not found', errorCode = 'NOT_FOUND', errors?: any) {
        super(message, HttpStatus.NOT_FOUND, errorCode, errors);
    }
}
