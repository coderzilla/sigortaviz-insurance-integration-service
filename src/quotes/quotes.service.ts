// src/quotes/quotes.service.ts
import { Injectable } from '@nestjs/common';
import { CreateQuoteDto } from './dtos/create-quote.dto';
import { QuoteResponseDto } from './dtos/quote-response.dto';
import { CarriersService } from '../carriers/carriers.service';
import { QuoteRequest } from '../carriers/carrier-types';

@Injectable()
export class QuotesService {
  constructor(private readonly carriersService: CarriersService) {}

  async createQuote(dto: CreateQuoteDto): Promise<QuoteResponseDto> {
    const req: QuoteRequest = {
      product: dto.product,
      insuredPerson: dto.insuredPerson,
      vehicle: dto.vehicle,
      customFields: dto.customFields,
    };

    const result = await this.carriersService.getQuotes(req, dto.carriers);

    return {
      requestId: result.requestId,
      offers: result.offers,
      errors: result.errors,
    };
  }
}
