// src/quotes/quotes.controller.ts
import { Body, Controller, Post } from '@nestjs/common';
import { QuotesService } from './quotes.service';
import { CreateQuoteDto } from './dtos/create-quote.dto';
import { QuoteResponseDto } from './dtos/quote-response.dto';

@Controller('quotes')
export class QuotesController {
  constructor(private readonly quotesService: QuotesService) {
    console.log('QuotesController initialized');
  }


  @Post()
  async createQuote(@Body() body: CreateQuoteDto): Promise<QuoteResponseDto> {
    return this.quotesService.createQuote(body);
  }
}
