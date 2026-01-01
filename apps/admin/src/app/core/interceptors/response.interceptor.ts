import { HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { map } from 'rxjs';

export const responseInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    map(event => {
      if (event instanceof HttpResponse && event.body && typeof event.body === 'object' && 'data' in event.body) {
        const body = event.body as any;
        // Check if the response is wrapped in the standard API format { success: true, data: ... }
        if (body.success === true && body.data !== undefined) {
          // If meta exists at the top level (manually formatted responses), preserve it
          if (body.meta !== undefined) {
            return event.clone({ body: { data: body.data, meta: body.meta } });
          }
          // Otherwise just unwrap the data property
          return event.clone({ body: body.data });
        }
      }
      return event;
    })
  );
};
