import type {
  CallHandler,
  ExecutionContext,
  NestInterceptor,
} from '@nestjs/common';
import {
  Injectable,
} from '@nestjs/common';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

@Injectable()
export class ErrorInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      catchError((err) => {
        // 여기에서 에러를 처리하거나 로깅합니다.
        // 예: 로깅 서비스를 사용하여 에러를 기록하거나, 사용자 지정 응답을 반환합니다.
        console.log(err);
        return throwError(err);
      }),
    );
  }
}
