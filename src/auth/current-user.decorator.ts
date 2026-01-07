import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AccessTokenPayload } from './token.service';

export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AccessTokenPayload | undefined => {
    const request = ctx.switchToHttp().getRequest();
    return request.user as AccessTokenPayload | undefined;
  },
);
