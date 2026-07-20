import { HttpException, HttpStatus } from '@nestjs/common';

export abstract class AppException extends HttpException {
    public readonly errorCode?: string;
    public readonly errors?: string[];

    constructor(
        message: string,
        status: HttpStatus,
        errorCode?: string,
        errors?: string[],
    ) {
        super(
            {
                message,
                errorCode,
                errors,
            },
            status,
        );

        this.errorCode = errorCode;
        this.errors = errors;
    }
}
