import { Injectable, UnauthorizedException } from '@nestjs/common';
import crypto from 'node:crypto';
import {
  ACCESS_TOKEN_EXPIRES_SECONDS,
  JWT_SECRET,
  LEAD_TOKEN_EXPIRES_SECONDS,
} from '../common/constants';
import { timingSafeEqualStr } from '../common/utils/crypto.util';

type TokenKind = 'ACCESS' | 'LEAD';

export interface AccessTokenPayload {
  sub: string;
  phoneNumber: string;
  type: TokenKind;
  exp: number; // seconds epoch
  identityId?: string;
  sessionId?: string;
  productCode?: string;
}

@Injectable()
export class TokenService {
  signAccessToken(
    payload: Omit<AccessTokenPayload, 'type' | 'exp'>,
    expiresInSeconds: number = ACCESS_TOKEN_EXPIRES_SECONDS,
  ): string {
    return this.sign({ ...payload, type: 'ACCESS' }, expiresInSeconds);
  }

  signLeadToken(
    payload: Omit<AccessTokenPayload, 'type' | 'exp'>,
    expiresInSeconds: number = LEAD_TOKEN_EXPIRES_SECONDS,
  ): string {
    return this.sign({ ...payload, type: 'LEAD' }, expiresInSeconds);
  }

  verifyAccessToken(token: string): AccessTokenPayload {
    const payload = this.verify(token);
    if (payload.type !== 'ACCESS') {
      throw new UnauthorizedException('Invalid token type');
    }
    return payload;
  }

  verifyLeadToken(token: string): AccessTokenPayload {
    const payload = this.verify(token);
    if (payload.type !== 'LEAD') {
      throw new UnauthorizedException('Invalid token type');
    }
    return payload;
  }

  private sign(
    payload: Omit<AccessTokenPayload, 'exp'> & { type: TokenKind },
    expiresInSeconds: number,
  ): string {
    const header = {
      alg: 'HS256',
      typ: 'JWT',
    };
    const exp = Math.floor(Date.now() / 1000) + expiresInSeconds;
    const body: AccessTokenPayload = { ...payload, exp };
    const encodedHeader = Buffer.from(JSON.stringify(header)).toString(
      'base64url',
    );
    const encodedPayload = Buffer.from(JSON.stringify(body)).toString(
      'base64url',
    );
    const signature = this.createSignature(
      `${encodedHeader}.${encodedPayload}`,
    );
    return `${encodedHeader}.${encodedPayload}.${signature}`;
  }

  private verify(token: string): AccessTokenPayload {
    const [encodedHeader, encodedPayload, signature] = token.split('.');
    if (!encodedHeader || !encodedPayload || !signature) {
      throw new UnauthorizedException('Malformed token');
    }
    const data = `${encodedHeader}.${encodedPayload}`;
    const expectedSignature = this.createSignature(data);
    if (!timingSafeEqualStr(expectedSignature, signature)) {
      throw new UnauthorizedException('Invalid token signature');
    }
    const payloadJson = Buffer.from(encodedPayload, 'base64url').toString();
    const payload = JSON.parse(payloadJson) as AccessTokenPayload;
    if (payload.exp * 1000 < Date.now()) {
      throw new UnauthorizedException('Token expired');
    }
    return payload;
  }

  private createSignature(data: string): string {
    return crypto.createHmac('sha256', JWT_SECRET).update(data).digest('base64url');
  }
}
