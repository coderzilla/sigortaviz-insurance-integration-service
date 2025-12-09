import { CarrierAdapter } from './carrier.adapter';
import {
  PolicyPurchaseRequest,
  PolicyPurchaseResult,
  QuoteRequest,
  QuoteResult,
} from './carrier-types';
import { ProductCode } from '../common/types/domain-types';

const SUPPORTED_PRODUCTS: ProductCode[] = [
  ProductCode.TRAFFIC,
  ProductCode.HEALTH,
  ProductCode.LIFE,
  ProductCode.HOME,
  ProductCode.PET,
];

export class AllianzAdapter implements CarrierAdapter {
  readonly carrierCode = 'ALLIANZ';

  supportsProduct(product: ProductCode): boolean {
    return SUPPORTED_PRODUCTS.includes(product);
  }

  async getQuote(request: QuoteRequest): Promise<QuoteResult> {
    const basePremium = this.basePremiumByProduct(request.product);
    const variance = Math.round(Math.random() * 150);

    return {
      requestId: `allianz-${Date.now()}`,
      offers: [
        {
          carrierCode: this.carrierCode,
          carrierProductCode: `${this.carrierCode}_${request.product}`,
          product: request.product,
          grossPremium: basePremium + variance,
          netPremium: basePremium + variance - 80,
          currency: 'TRY',
          coverageSummary: `Allianz ${request.product} coverage`,
          coverageDetails: { assistance: true },
          warnings: [],
          rawCarrierData: { echoedRequest: request },
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
      policyId: `ALLIANZ-${Date.now()}`,
      carrierCode: this.carrierCode,
      carrierPolicyNumber: `ALZ-${Math.round(Math.random() * 1_000_000)}`,
      effectiveFrom: now.toISOString(),
      effectiveTo: new Date(now.getTime() + yearMs).toISOString(),
      documents: [],
      rawCarrierData: { echoedRequest: request },
    };
  }

  private basePremiumByProduct(product: ProductCode): number {
    switch (product) {
      case ProductCode.TRAFFIC:
        return 900;
      case ProductCode.HEALTH:
        return 1500;
      case ProductCode.LIFE:
        return 700;
      case ProductCode.HOME:
        return 800;
      case ProductCode.PET:
        return 400;
      default:
        return 1000;
    }
  }
}
