import {
  Body,
  Controller,
  Headers,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { QuoteSessionsService } from './quote-sessions.service';
import { CreateQuoteSessionDto } from './dtos/create-quote-session.dto';
import { UpdateQuoteSessionStepDto } from './dtos/update-quote-session-step.dto';
import type { Request } from 'express';
import { TokenService, AccessTokenPayload } from '../auth/token.service';
import { JwtAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { AssetsService } from './assets.service';
import { CreateAssetSnapshotDto } from './dtos/create-asset-snapshot.dto';

@Controller()
export class QuoteSessionsController {
  constructor(
    private readonly quoteSessionsService: QuoteSessionsService,
    private readonly tokenService: TokenService,
    private readonly assetsService: AssetsService,
  ) {}

  @Post('quote-sessions')
  async createSession(@Body() body: CreateQuoteSessionDto, @Req() req: Request) {
    const userPayload = this.extractUser(req);
    return this.quoteSessionsService.createSession(body, userPayload);
  }

  @Patch('quote-sessions/:id/step')
  async updateStep(
    @Param('id') id: string,
    @Body() body: UpdateQuoteSessionStepDto,
    @Req() req: Request,
    @Headers('Authorization') authHeader?: string,
    @Headers('x-lead-token') leadTokenHeader?: string,
  ) {
    const userPayload = this.extractUser(req, authHeader);
    const leadToken =
      leadTokenHeader ||
      this.getHeader(req, 'x-lead-token') ||
      this.getHeader(req, 'X-LEAD-TOKEN');
    return this.quoteSessionsService.updateStep(
      id,
      body,
      userPayload,
      leadToken,
    );
  }

  @Post('quote-sessions/:id/assets/snapshot')
  @UseGuards(JwtAuthGuard)
  async snapshotAsset(
    @Param('id') id: string,
    @Body() body: CreateAssetSnapshotDto,
    @CurrentUser() user: any,
  ) {
    return this.assetsService.createSnapshot(id, user, body);
  }

  private extractUser(
    req: Request,
    headerOverride?: string,
  ): AccessTokenPayload | undefined {
    const header =
      headerOverride ||
      this.getHeader(req, 'authorization') ||
      this.getHeader(req, 'Authorization');
    if (header && header.startsWith('Bearer ')) {
      const token = header.slice(7);
      try {
        return this.tokenService.verifyAccessToken(token);
      } catch {
        return undefined;
      }
    }
    return undefined;
  }

  private getHeader(req: Request, name: string): string | undefined {
    const headers = req.headers || {};
    const lower = name.toLowerCase();
    const direct =
      (headers as any)[name] ||
      (headers as any)[lower] ||
      (headers as any)[lower.toUpperCase()];
    if (direct) return direct as string;
    const raw = (req as any).raw?.headers;
    if (raw) {
      return (
        raw[name] ||
        raw[lower] ||
        raw[lower.toUpperCase()] ||
        raw[name.toLowerCase()]
      ) as string | undefined;
    }
    return undefined;
  }
}
