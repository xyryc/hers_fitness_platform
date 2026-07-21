import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class CustomException extends AppException {
    constructor(message = 'Resource not found', errorCode = 'INTERNAL_SERVER_ERROR', httpStatus: HttpStatus = HttpStatus.INTERNAL_SERVER_ERROR, errors?: any) {
        super(message, httpStatus, errorCode, errors);
    }
}