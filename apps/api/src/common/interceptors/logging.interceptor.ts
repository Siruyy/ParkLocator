/* eslint-disable */
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
     
    const request = context.switchToHttp().getRequest();

     
    console.log('[LoggingInterceptor] RAW request.body:', request.body);

    console.log(
      '[LoggingInterceptor] supportsFutureBooking RAW value:',
      request.body?.supportsFutureBooking,
      'type:',
       
      typeof request.body?.supportsFutureBooking,
    );

    return next.handle();
  }
}
