import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  meta?: { page: number; limit: number; total: number };
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => {
        if (data && typeof data === 'object' && 'message' in data && 'data' in data) {
          const { message, data: responseData, meta, ...rest } = data as any;
          const result: any = { success: true, message, data: responseData };
          if (meta) result.meta = meta;
          return { ...result, ...rest };
        }
        return { success: true, data };
      }),
    );
  }
}
