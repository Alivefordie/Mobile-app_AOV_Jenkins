import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import type { AuthUser } from '../interfaces/jwt-payload.interface';

/** ดึง user ที่ผ่าน JwtAuthGuard มาแล้ว: @CurrentUser() user: AuthUser */
export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, context: ExecutionContext) => {
    const request = context.switchToHttp().getRequest<Request>();
    const user = request.user as AuthUser;
    return data ? user?.[data] : user;
  },
);
