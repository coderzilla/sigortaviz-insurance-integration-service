// src/quotes/quotes.service.ts
import { Injectable } from '@nestjs/common';
import { CreateQuoteDto } from './dtos/create-quote.dto';
import { QuoteResponseDto } from './dtos/quote-response.dto';
import { CarriersService } from '../carriers/carriers.service';
import {
  PolicyPurchaseRequest,
  PolicyPurchaseResult,
  QuoteRequest,
} from '../carriers/carrier-types';
import { PurchasePolicyDto } from './dtos/purchase-policy.dto';
import { ProductCode } from '../common/types/domain-types';

@Injectable()
export class QuotesService {
  constructor(private readonly carriersService: CarriersService) {}

  async createQuote(dto: CreateQuoteDto): Promise<QuoteResponseDto> {
    const insurer = dto.insurer ?? dto.insuredPerson;
    const req: QuoteRequest = {
      product: dto.product,
      insuredPerson: dto.insuredPerson,
      insurer,
      vehicle: dto.vehicle,
      customFields: dto.customFields,
      insureds:
        dto.insureds ??
        ((dto.customFields as any)?.insureds?.length
          ? ((dto.customFields as any).insureds as any[])
          : undefined),
    };

    const result = await this.carriersService.getQuotes(req, dto.carriers);

    return {
      requestId: result.requestId,
      offers: result.offers,
      errors: result.errors,
    };
  }

  async purchasePolicy(dto: PurchasePolicyDto): Promise<PolicyPurchaseResult> {
    const request: PolicyPurchaseRequest = {
      quoteRequestId: dto.quoteRequestId,
      selectedOffer: dto.selectedOffer,
      insuredPerson: dto.insuredPerson,
      payment: dto.payment,
      customFields: dto.customFields,
    };

    return this.carriersService.buyPolicy(request);
  }

  getCarriersForProduct(product: ProductCode): string[] {
    return this.carriersService.getCarriersForProduct(product);
  }
}
