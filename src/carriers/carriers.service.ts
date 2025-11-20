// src/carriers/carriers.service.ts
import { Injectable } from '@nestjs/common';
import {
  QuoteRequest,
  QuoteResult,
  QuoteOffer,
} from './carrier-types';

@Injectable()
export class CarriersService {
  /**
   * Later this will:
   * - pick the right CarrierAdapters
   * - call them in parallel
   * - aggregate their results
   */
  async getQuotes(
    request: QuoteRequest,
    carrierCodes?: string[],
  ): Promise<QuoteResult> {
    // Temporary fake response so you can test the flow
    const offer: QuoteOffer = {
      carrierCode: carrierCodes?.[0] ?? 'DUMMY_CARRIER',
      carrierProductCode: 'DUMMY_PRODUCT',
      product: request.product,
      grossPremium: 1000,
      netPremium: 900,
      currency: 'TRY',
      coverageSummary: 'Dummy coverage summary',
      coverageDetails: {},
      warnings: [],
      rawCarrierData: {},
    };

    return {
      requestId: 'dummy-request-id',
      offers: [offer],
      errors: [],
    };
  }
}
