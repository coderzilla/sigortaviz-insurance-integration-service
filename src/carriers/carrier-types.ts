// src/carriers/carrier-types.ts
import { ProductCode } from '../common/types/domain-types';

export interface QuoteRequest {
  product: ProductCode;
  carrierCode?: string; // optional: sometimes you call a single carrier
  // user data (normalized):
  insuredPerson: {
    fullName: string;
    birthDate?: string;
    tckn?: string;
    phoneNumber?: string;
    email?: string;
  };
  // product-specific data:
  vehicle?: {
    plate?: string;
    vin?: string;
    modelYear?: number;
    brand?: string;
    model?: string;
  };
  // more health-specific fields, etc.
  customFields?: Record<string, any>; // filled based on FieldConfig internalCodes
}

export interface QuoteOffer {
  carrierCode: string;
  carrierProductCode: string;
  product: ProductCode;
  grossPremium: number;
  netPremium: number;
  currency: string;
  coverageSummary: string;
  coverageDetails?: Record<string, any>;
  warnings?: string[];
  rawCarrierData?: any;
}

export interface QuoteResult {
  requestId: string;
  offers: QuoteOffer[];
  errors?: { carrierCode: string; message: string }[];
}

export interface PolicyPurchaseRequest {
  quoteRequestId: string; // or another key that links to a quote
  selectedOffer: QuoteOffer;
  insuredPerson: QuoteRequest['insuredPerson'];
  payment: {
    cardTokenId?: string;
    // ...or raw card data or iyzico/paytr etc. reference
  };
  customFields?: Record<string, any>;
}

export interface PolicyPurchaseResult {
  policyId: string;
  carrierCode: string;
  carrierPolicyNumber: string;
  effectiveFrom: string;
  effectiveTo: string;
  documents?: {
    type: 'POLICY_PDF' | 'SUMMARY_PDF';
    url: string;
  }[];
  rawCarrierData?: any;
}
