import {
    CallHandler,
    ExecutionContext,
    Injectable,
    NestInterceptor,
} from '@nestjs/common';
import { map, Observable } from 'rxjs';
import CustomResponse from '../dto/custom-response.dto';

@Injectable()
export class ResponseInterceptor<T>
    implements NestInterceptor<T, CustomResponse<T>> {
    intercept(
        context: ExecutionContext,
        next: CallHandler,
    ): Observable<CustomResponse<T>> {
        return next.handle().pipe(
            map((data) => {
                // If already wrapped, return as is
                if (data instanceof CustomResponse) {
                    return data;
                }

                return new CustomResponse<T>(
                    undefined,
                    data,
                    context.switchToHttp().getResponse().statusCode,
                );
            }),
        );
    }
}
