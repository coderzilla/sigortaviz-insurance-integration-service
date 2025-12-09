// src/quotes/quotes.controller.ts
import {
  Body,
  Controller,
  Get,
  Param,
  ParseEnumPipe,
  Post,
} from '@nestjs/common';
import { QuotesService } from './quotes.service';
import { CreateQuoteDto } from './dtos/create-quote.dto';
import { QuoteResponseDto } from './dtos/quote-response.dto';
import { PurchasePolicyDto } from './dtos/purchase-policy.dto';
import { PolicyPurchaseResult } from '../carriers/carrier-types';
import { ProductCode } from '../common/types/domain-types';

@Controller('quotes')
export class QuotesController {
  constructor(private readonly quotesService: QuotesService) {
    console.log('QuotesController initialized');
  }

  @Get()
  async getQuotes(): Promise<{ status: string }> {
    return { status: 'Quotes service ready' };
  }

  @Get('product/:product')
  async getCarriersForProduct(
    @Param('product', new ParseEnumPipe(ProductCode)) product: ProductCode,
  ): Promise<{ product: ProductCode; carriers: string[] }> {
    const carriers = this.quotesService.getCarriersForProduct(product);
    return { product, carriers };
  }


  @Post()
  async createQuote(@Body() body: CreateQuoteDto): Promise<QuoteResponseDto> {
    return this.quotesService.createQuote(body);
  }

  @Post('purchase')
  async purchasePolicy(
    @Body() body: PurchasePolicyDto,
  ): Promise<PolicyPurchaseResult> {
    return this.quotesService.purchasePolicy(body);
  }
}
