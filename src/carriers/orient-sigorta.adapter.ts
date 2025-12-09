import { CarrierAdapter } from './carrier.adapter';
import {
  PolicyPurchaseRequest,
  PolicyPurchaseResult,
  QuoteRequest,
  QuoteResult,
} from './carrier-types';
import { ProductCode } from '../common/types/domain-types';
import { OrientSoapClient } from './orient-sigorta.soap';

/**
 * Orient Sigorta adapter (stub) using Policy/Utility/Security SOAP services.
 * Uses mock responses unless ORIENT_ENABLED=true and endpoints are provided.
 */
export class OrientSigortaAdapter implements CarrierAdapter {
  readonly carrierCode = 'ORIENT_SIGORTA';

  private readonly enabled: boolean;
  private readonly policyClient: OrientSoapClient;
  private readonly utilityClient: OrientSoapClient;
  private readonly securityClient: OrientSoapClient;

  constructor() {
    this.enabled = process.env.ORIENT_ENABLED === 'true';
    const mockMode = process.env.ORIENT_SOAP_MODE === 'mock';

    this.policyClient = new OrientSoapClient(
      process.env.ORIENT_POLICY_ENDPOINT ?? '',
      {
        username: process.env.ORIENT_USERNAME,
        password: process.env.ORIENT_PASSWORD,
      },
      { mockMode },
    );
    this.utilityClient = new OrientSoapClient(
      process.env.ORIENT_UTILITY_ENDPOINT ?? '',
      {
        username: process.env.ORIENT_USERNAME,
        password: process.env.ORIENT_PASSWORD,
      },
      { mockMode },
    );
    this.securityClient = new OrientSoapClient(
      process.env.ORIENT_SECURITY_ENDPOINT ?? '',
      {
        username: process.env.ORIENT_USERNAME,
        password: process.env.ORIENT_PASSWORD,
      },
      { mockMode },
    );
  }

  supportsProduct(product: ProductCode): boolean {
    // Orient currently supports CASCO only (per service docs).
    return this.enabled && product === ProductCode.CASCO;
  }

  async getQuote(request: QuoteRequest): Promise<QuoteResult> {
    const requestId = `orient-${Date.now()}`;
    if (!this.enabled) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: 'Orient integration disabled; set ORIENT_ENABLED=true',
          },
        ],
      };
    }

    if (!process.env.ORIENT_POLICY_ENDPOINT) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message:
              'Missing ORIENT_POLICY_ENDPOINT. Configure endpoints to enable quotes.',
          },
        ],
      };
    }

    // Minimal call: get authentication key then (mock) calculate premium
    const authKey = await this.getAuthenticationKey();
    const grossPremium = this.randomPremium(request.product);
    const netPremium = grossPremium - 100;

    return {
      requestId,
      offers: [
        {
          carrierCode: this.carrierCode,
          carrierProductCode: `${this.carrierCode}_${request.product}`,
          product: request.product,
          grossPremium,
          netPremium,
          currency: 'TRY',
          coverageSummary: `Orient ${request.product} coverage (mocked)`,
          coverageDetails: { authKey },
          warnings: [],
          rawCarrierData: { authKey },
        },
      ],
      errors: [],
    };
  }

  async buyPolicy(
    request: PolicyPurchaseRequest,
  ): Promise<PolicyPurchaseResult> {
    if (!this.enabled) {
      throw new Error('Orient integration disabled; set ORIENT_ENABLED=true');
    }
    if (!process.env.ORIENT_POLICY_ENDPOINT) {
      throw new Error('Missing ORIENT_POLICY_ENDPOINT for policy creation.');
    }

    const authKey = await this.getAuthenticationKey();
    // Build minimal CreatePolicy request body (placeholder). Replace with real mapping.
    const policyBody = `
      <request>
        <AuthKey>${authKey ?? ''}</AuthKey>
        <InsuredName>${request.insuredPerson.fullName}</InsuredName>
        <Product>${request.selectedOffer.product}</Product>
        <GrossPremium>${request.selectedOffer.grossPremium}</GrossPremium>
      </request>
    `;
    const result = await this.policyClient.call({
      operation: 'CreatePolicy',
      body: policyBody,
      soapAction: 'http://tempuri.org/IPolicyService/CreatePolicy',
    });

    if (!result.success) {
      throw new Error(result.fault ?? 'Orient CreatePolicy failed');
    }

    const policyId =
      this.extractText(result.raw, /<PolicyNo[^>]*>([^<]+)<\/PolicyNo>/i) ??
      `ORIENT-${Date.now()}`;
    const carrierPolicyNumber =
      this.extractText(
        result.raw,
        /<PolicyNumber[^>]*>([^<]+)<\/PolicyNumber>/i,
      ) ?? `OR-${Math.round(Math.random() * 1_000_000)}`;

    const now = new Date();
    const yearMs = 365 * 24 * 60 * 60 * 1000;
    return {
      policyId,
      carrierCode: this.carrierCode,
      carrierPolicyNumber,
      effectiveFrom: now.toISOString(),
      effectiveTo: new Date(now.getTime() + yearMs).toISOString(),
      documents: [],
      rawCarrierData: { response: result.raw },
    };
  }

  private async getAuthenticationKey(): Promise<string | undefined> {
    if (!process.env.ORIENT_SECURITY_ENDPOINT) return undefined;
    const res = await this.securityClient.call({
      operation: 'GetAuthenticationKey',
      body: '<request/>',
      soapAction: 'http://tempuri.org/ISecurityService/GetAuthenticationKey',
    });
    if (!res.success) return undefined;
    return this.extractText(res.raw, /<AuthenticationKey[^>]*>([^<]+)<\/AuthenticationKey>/i);
  }

  private extractText(raw: string, regex: RegExp): string | undefined {
    const match = raw.match(regex);
    return match?.[1];
  }

  private randomPremium(product: ProductCode): number {
    const base = product === ProductCode.TRAFFIC ? 1200 : 1800;
    return base + Math.round(Math.random() * 250);
  }
}
