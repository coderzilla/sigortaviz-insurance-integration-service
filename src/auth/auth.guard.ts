import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { TokenService, AccessTokenPayload } from './token.service';
import { Request } from 'express';

export interface RequestWithUser extends Request {
  user?: AccessTokenPayload;
}

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly tokenService: TokenService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<RequestWithUser>();
    const header =
      (req.headers?.authorization as string | undefined) ||
      (req.headers?.Authorization as string | undefined);
    if (!header || typeof header !== 'string') {
      throw new UnauthorizedException('Missing Authorization header');
    }
    const [type, token] = header.split(' ');
    if (type !== 'Bearer' || !token) {
      throw new UnauthorizedException('Invalid Authorization header');
    }
    const payload = this.tokenService.verifyAccessToken(token);
    req.user = payload;
    return true;
  }
}
