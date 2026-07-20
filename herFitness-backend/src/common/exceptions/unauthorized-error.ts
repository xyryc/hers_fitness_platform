import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class UnauthorizedAppException extends AppException {
    constructor(message = 'Unauthorized', errorCode = 'UNAUTHORIZED', errors?: any) {
        super(message, HttpStatus.UNAUTHORIZED, errorCode, errors);
    }
}
