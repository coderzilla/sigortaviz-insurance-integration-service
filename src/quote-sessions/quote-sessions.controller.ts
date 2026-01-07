import {
  Body,
  Controller,
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
  ) {
    const userPayload = this.extractUser(req);
    const leadToken =
      (req.headers['x-lead-token'] as string | undefined) ||
      (req.headers['X-LEAD-TOKEN'] as string | undefined);
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

  private extractUser(req: Request): AccessTokenPayload | undefined {
    const header = req.headers['authorization'] as string | undefined;
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
}
