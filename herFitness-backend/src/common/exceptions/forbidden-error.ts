import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class ForbiddenAppException extends AppException {
    constructor(message = 'Forbidden', errorCode = 'FORBIDDEN', errors?: any) {
        super(message, HttpStatus.FORBIDDEN, errorCode, errors);
    }
}
