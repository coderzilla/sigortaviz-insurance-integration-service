// src/carriers/carrier.adapter.ts
import { ProductCode } from '../common/types/domain-types';
import { QuoteRequest, QuoteResult, PolicyPurchaseRequest, PolicyPurchaseResult } from './carrier-types';

export interface CarrierAdapter {
  readonly carrierCode: string; // CarrierCode

  supportsProduct(product: ProductCode): boolean;

  getQuote(request: QuoteRequest): Promise<QuoteResult>;

  buyPolicy(request: PolicyPurchaseRequest): Promise<PolicyPurchaseResult>;

  // optional extras:
  // getPolicyDetails(policyId: string): Promise<PolicyDetails>;
  // cancelPolicy(request: PolicyCancelRequest): Promise<void>;
}
