import { CarrierAdapter } from './carrier.adapter';
import {
  PolicyPurchaseRequest,
  PolicyPurchaseResult,
  QuoteRequest,
  QuoteResult,
} from './carrier-types';
import { ProductCode } from '../common/types/domain-types';

export class MockCarrierAdapter implements CarrierAdapter {
  readonly carrierCode = 'MOCK';

  supportsProduct(_product: ProductCode): boolean {
    return true;
  }

  async getQuote(request: QuoteRequest): Promise<QuoteResult> {
    const basePremium = 500;
    const rand = Math.round(Math.random() * 200);

    return {
      requestId: `mock-${Date.now()}`,
      offers: [
        {
          carrierCode: this.carrierCode,
          carrierProductCode: 'MOCK_PRODUCT',
          product: request.product,
          grossPremium: basePremium + rand,
          netPremium: basePremium + rand - 50,
          currency: 'TRY',
          coverageSummary: 'Mock coverage summary',
          coverageDetails: {
            includesRoadside: true,
          },
          warnings: [],
          rawCarrierData: {
            echoedRequest: request,
          },
        },
      ],
      errors: [],
    };
  }

  async buyPolicy(
    request: PolicyPurchaseRequest,
  ): Promise<PolicyPurchaseResult> {
    const now = new Date();
    const yearMs = 365 * 24 * 60 * 60 * 1000;

    return {
      policyId: `MOCK-${Date.now()}`,
      carrierCode: this.carrierCode,
      carrierPolicyNumber: `POL-${Math.round(Math.random() * 1_000_000)}`,
      effectiveFrom: now.toISOString(),
      effectiveTo: new Date(now.getTime() + yearMs).toISOString(),
      documents: [],
      rawCarrierData: { echoedRequest: request },
    };
  }
}
