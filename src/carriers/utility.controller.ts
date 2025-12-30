import {
  BadRequestException,
  Body,
  Controller,
  Post,
  Query,
} from '@nestjs/common';
import { UtilityProxyBodyDto, UtilityProxyQueryDto } from './dtos/utility-proxy.dto';
import { QuickSigortaAdapter } from './quick-sigorta.adapter';

@Controller('utility')
export class UtilityController {
  constructor(private readonly quickAdapter: QuickSigortaAdapter) {}

  @Post('proxy')
  async proxy(
    @Query() query: UtilityProxyQueryDto,
    @Body() body: UtilityProxyBodyDto,
  ) {
    const url = query.url?.trim();
    if (!url) {
      throw new BadRequestException('url query param is required');
    }

    const method = body?.method ?? 'GET';
    const params = body?.params ?? undefined;

    const provider = this.resolveProvider(url);
    if (!provider) {
      throw new BadRequestException('URL not allowed for utility proxy');
    }

    if (provider === 'quick') {
      return this.quickAdapter.callUtilityUrl(url, method, params);
    }

    throw new BadRequestException(
      `Utility proxy not yet implemented for provider: ${provider}`,
    );
  }

  private resolveProvider(url: string): 'quick' | 'orient' | 'pusula' | null {
    const normalized = url.trim();
    const quickBase = (process.env.QUICK_API_BASE ?? '').replace(/\/$/, '');
    const orientBase = (process.env.ORIENT_UTILITY_ENDPOINT ?? '').replace(/\/$/, '');
    const pusulaBase = (process.env.PUSULA_ENDPOINT ?? '').replace(/\/$/, '');

    if (quickBase && normalized.startsWith(quickBase)) return 'quick';
    if (orientBase && normalized.startsWith(orientBase)) return 'orient';
    if (pusulaBase && normalized.startsWith(pusulaBase)) return 'pusula';
    return null;
  }
}
