import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CarrierAdapter } from './carrier.adapter';
import {
  PolicyPurchaseRequest,
  PolicyPurchaseResult,
  QuoteRequest,
  QuoteResult,
} from './carrier-types';
import { ProductCode } from '../common/types/domain-types';
import { Carrier } from '../products/entities/carrier.entity';
import { CarrierProduct } from '../products/entities/carrier-product.entity';

/**
 * Quick Sigorta adapter (REST, mocked unless enabled).
 * Wire real endpoints/keys using env:
 *  QUICK_ENABLED=true
 *  QUICK_API_BASE=https://...
 *  QUICK_CLIENT_ID=...
 *  QUICK_CLIENT_SECRET=...
 *  QUICK_MODE=mock (optional)
 *  QUICK_PRODUCTS=TRAFFIC,CASCO (optional override)
 */
@Injectable()
export class QuickSigortaAdapter implements CarrierAdapter, OnModuleInit {
  readonly carrierCode = 'QUICK_SIGORTA';

  private readonly enabled: boolean;
  private readonly baseUrl?: string;
  private readonly mockMode: boolean;
  private readonly supportedOverrideFromEnv?: Set<ProductCode>;
  private readonly defaultSupported: Set<ProductCode>;
  private supportedFromDb?: Set<ProductCode>;
  private accessToken?: string;

  constructor(
    @InjectRepository(Carrier)
    private readonly carrierRepo: Repository<Carrier>,
    @InjectRepository(CarrierProduct)
    private readonly carrierProductRepo: Repository<CarrierProduct>,
  ) {
    this.enabled = process.env.QUICK_ENABLED === 'true';
    this.baseUrl = process.env.QUICK_API_BASE;
    this.mockMode = process.env.QUICK_MODE === 'mock';

    const envProducts = process.env.QUICK_PRODUCTS
      ?.split(',')
      .map((p) => p.trim())
      .filter(Boolean) as ProductCode[] | undefined;
    this.supportedOverrideFromEnv = envProducts?.length
      ? new Set(envProducts)
      : undefined;

    this.defaultSupported = new Set([ProductCode.TRAFFIC, ProductCode.CASCO]);
  }

  async onModuleInit(): Promise<void> {
    try {
      const carrier = await this.carrierRepo.findOne({
        where: { code: this.carrierCode, isActive: true },
      });
      if (!carrier) return;

      const carrierProducts = await this.carrierProductRepo.find({
        where: { carrier: { id: carrier.id }, isActive: true },
      });

      const productCodes = carrierProducts
        .map((cp) => cp.product?.code)
        .filter(Boolean) as ProductCode[];

      if (productCodes.length) {
        this.supportedFromDb = new Set(productCodes);
      }
    } catch {
      // If DB isn't reachable at boot, fall back to env/default supported list.
    }
  }

  supportsProduct(product: ProductCode): boolean {
    if (!this.enabled) return false;
    const supported =
      this.supportedOverrideFromEnv ?? this.supportedFromDb ?? this.defaultSupported;
    return supported.has(product);
  }

  async getQuote(request: QuoteRequest): Promise<QuoteResult> {
    const requestId = `quick-${Date.now()}`;

    if (!this.enabled) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: 'Quick Sigorta integration disabled. Set QUICK_ENABLED=true.',
          },
        ],
      };
    }

    if (!this.baseUrl) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: 'Missing QUICK_API_BASE configuration.',
          },
        ],
      };
    }

    if (this.mockMode) {
      const grossPremium = this.randomPremium(request.product);
      return {
        requestId,
        offers: [
          {
            carrierCode: this.carrierCode,
            carrierProductCode: `${this.carrierCode}_${request.product}`,
            product: request.product,
            grossPremium,
            netPremium: grossPremium - 90,
            currency: 'TRY',
            coverageSummary: `Quick ${request.product} coverage (mock)`,
            warnings: [],
            rawCarrierData: { mode: 'mock' },
          },
        ],
        errors: [],
      };
    }

    const fetchFn: any = (globalThis as any).fetch;
    if (!fetchFn) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: 'Fetch API not available to call Quick Sigorta.',
          },
        ],
      };
    }

    try {
      const token = await this.getAccessToken(fetchFn);
      const proposalPayload =
        (request.customFields as any)?.proposalPayload ??
        this.buildMinimalProposal(request);

      if (!proposalPayload) {
        return {
          requestId,
          offers: [],
          errors: [
            {
              carrierCode: this.carrierCode,
              message:
                'Missing proposal payload for Quick Sigorta. Provide customFields.proposalPayload.',
            },
          ],
        };
      }

      const res = await fetchFn(`${this.baseUrl}/api/policy/proposal`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(proposalPayload),
      });
      const data = await res.json();
      if (!res.ok) {
        return {
          requestId,
          offers: [],
          errors: [
            {
              carrierCode: this.carrierCode,
              message: data?.message ?? `HTTP ${res.status}`,
            },
          ],
        };
      }

      const offer = {
        carrierCode: this.carrierCode,
        carrierProductCode: `${this.carrierCode}_${request.product}`,
        product: request.product,
        grossPremium: Number(data?.premium ?? data?.grossPremium ?? this.randomPremium(request.product)),
        netPremium: Number(
          data?.netPremium ?? data?.premium ?? this.randomPremium(request.product) - 90,
        ),
        currency: data?.currency ?? 'TRY',
        coverageSummary: data?.coverageSummary ?? 'Quick Sigorta Teklif',
        coverageDetails: data,
        warnings: [],
        rawCarrierData: data,
      };

      return { requestId, offers: [offer], errors: [] };
    } catch (err: any) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: err?.message ?? 'Quick Sigorta quote failed',
          },
        ],
      };
    }
  }

  async buyPolicy(
    request: PolicyPurchaseRequest,
  ): Promise<PolicyPurchaseResult> {
    if (!this.enabled) {
      throw new Error('Quick Sigorta integration disabled. Set QUICK_ENABLED=true.');
    }

    if (!this.baseUrl) {
      throw new Error('Missing QUICK_API_BASE configuration.');
    }

    if (this.mockMode) {
      const now = new Date();
      const yearMs = 365 * 24 * 60 * 60 * 1000;
      return {
        policyId: `QUICK-${Date.now()}`,
        carrierCode: this.carrierCode,
        carrierPolicyNumber: `QS-${Math.round(Math.random() * 1_000_000)}`,
        effectiveFrom: now.toISOString(),
        effectiveTo: new Date(now.getTime() + yearMs).toISOString(),
        documents: [],
        rawCarrierData: { mode: 'mock', selectedOffer: request.selectedOffer },
      };
    }

    const fetchFn: any = (globalThis as any).fetch;
    if (!fetchFn) {
      throw new Error('Fetch API not available to call Quick Sigorta.');
    }

    const token = await this.getAccessToken(fetchFn);
    const approvePayload =
      (request.customFields as any)?.approvePayload ??
      this.buildMinimalApprove(request);

    const res = await fetchFn(`${this.baseUrl}/api/policy/approve`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(approvePayload),
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data?.message ?? `Quick Sigorta policy creation failed: HTTP ${res.status}`);
    }

    const now = new Date();
    return {
      policyId: data.policyId ?? `QUICK-${Date.now()}`,
      carrierCode: this.carrierCode,
      carrierPolicyNumber: data.carrierPolicyNumber ?? data.policyNumber ?? `QS-${Math.round(Math.random() * 1_000_000)}`,
      effectiveFrom: data.effectiveFrom ?? now.toISOString(),
      effectiveTo:
        data.effectiveTo ??
        new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000).toISOString(),
      documents: data.documents ?? [],
      rawCarrierData: data,
    };
  }

  // Helpers for other documented endpoints:
  async getPrintTypes(params: {
    productId: string;
    policyNo: string;
    renewalNo?: number;
    endorsNo?: number;
  }) {
    return this.authedGet('/api/print/policy/print-type', params);
  }

  async printPolicy(params: {
    productId: string;
    policyNo: string;
    renewalNo?: number;
    endorsNo?: number;
    printType: number;
  }) {
    return this.authedGet('/api/print/policy', params);
  }

  async sendPolicy(params: {
    productId: string;
    policyNo: string;
    renewalNo?: number;
    endorsNo?: number;
    type: 'email' | 'sms';
    target?: string;
  }) {
    return this.authedPost('/api/print/policy/send', params);
  }

  async hasPolicy(payload: { idNumber: string; birthDate: string; productId: string }) {
    return this.authedPost('/api/policy/has-policy', payload);
  }

  async getEncryptionKey() {
    return this.authedGet('/api/common/encryption/key');
  }

  private async authedGet(path: string, params?: Record<string, any>) {
    if (!this.baseUrl) throw new Error('Missing QUICK_API_BASE');
    const fetchFn: any = (globalThis as any).fetch;
    if (!fetchFn) throw new Error('Fetch API not available.');
    const token = await this.getAccessToken(fetchFn);
    const url = new URL(`${this.baseUrl}${path}`);
    if (params) {
      Object.entries(params).forEach(([k, v]) => {
        if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v));
      });
    }
    const res = await fetchFn(url.toString(), {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}` },
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data?.message ?? `HTTP ${res.status}`);
    return data;
  }

  private async authedPost(path: string, body?: any) {
    if (!this.baseUrl) throw new Error('Missing QUICK_API_BASE');
    const fetchFn: any = (globalThis as any).fetch;
    if (!fetchFn) throw new Error('Fetch API not available.');
    const token = await this.getAccessToken(fetchFn);
    const res = await fetchFn(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data?.message ?? `HTTP ${res.status}`);
    return data;
  }

  private async getAccessToken(fetchFn: any): Promise<string> {
    if (this.accessToken) return this.accessToken;
    if (!this.baseUrl) throw new Error('Missing QUICK_API_BASE');
    const clientId = process.env.QUICK_CLIENT_ID;
    const clientSecret = process.env.QUICK_CLIENT_SECRET;
    const res = await fetchFn(`${this.baseUrl}/auth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId ?? '',
        client_secret: clientSecret ?? '',
        grant_type: 'client_credentials',
      }).toString(),
    });
    const data = await res.json();
    if (!res.ok || !data?.access_token) {
      throw new Error(data?.error_description ?? 'Quick Sigorta token retrieval failed');
    }
    this.accessToken = data.access_token;
    return this.accessToken!;
  }

  private buildMinimalProposal(request: QuoteRequest): any | undefined {
    const productId = this.mapProduct(request.product);
    if (!productId) return undefined;

    const customInsureds = (request.customFields as any)?.insureds;
    const insuredsSource =
      request.insureds && request.insureds.length
        ? request.insureds
        : Array.isArray(customInsureds)
          ? customInsureds
          : undefined;

    const insurerSource = request.insurer ?? request.insuredPerson;
    const insurer = {
      idNumber: insurerSource.tckn ?? insurerSource.fullName,
      birthDate: insurerSource.birthDate,
      email: insurerSource.email,
      phoneNumber: insurerSource.phoneNumber,
    };

    const insureds =
      insuredsSource?.length
        ? insuredsSource.map((p: any, idx: number) => ({
            idNumber: p.tckn ?? p.idNumber ?? insurer.idNumber,
            birthDate: p.birthDate ?? insurer.birthDate,
            email: p.email ?? insurer.email,
            phoneNumber: p.phoneNumber ?? insurer.phoneNumber,
            isMain:
              Boolean(p.isMain) ||
              p.role === 'SELF' ||
              (idx === 0 && !insuredsSource.some((x: any) => x?.isMain)),
          }))
        : [
            {
              idNumber: insurer.idNumber,
              birthDate: insurer.birthDate,
              email: insurer.email,
              phoneNumber: insurer.phoneNumber,
              isMain: true,
            },
          ];

    const questions =
      (request.customFields as any)?.questions ??
      (request.customFields as any)?.travelQuestions ??
      undefined;

    return {
      productId,
      insurer,
      insureds,
      vehicle: request.vehicle,
      questions,
      customFields: request.customFields,
    };
  }

  private buildMinimalApprove(request: PolicyPurchaseRequest): any {
    const raw = request.selectedOffer.rawCarrierData || {};
    return {
      productId: this.mapProduct(request.selectedOffer.product),
      policyNo:
        request.quoteRequestId ??
        (raw.policyNo as string | undefined) ??
        (raw.policyNumber as string | undefined),
      renewalNo: 0,
      endorsNo: 0,
      paymentType: request.payment.cardTokenId ? 'card' : 'cash',
      cardTokenId: request.payment.cardTokenId,
    };
  }

  private mapProduct(product: ProductCode): string | undefined {
    switch (product) {
      case ProductCode.TRAFFIC:
        return '101';
      case ProductCode.CASCO:
        return '111';
      case ProductCode.HEALTH:
        return '600'; // travel health as placeholder
      case ProductCode.HOME:
        return '202'; // Dask
      case ProductCode.LIFE:
        return '500'; // personal accident as placeholder
      default:
        return undefined;
    }
  }

  private randomPremium(product: ProductCode): number {
    const base =
      product === ProductCode.TRAFFIC ? 950 : product === ProductCode.CASCO ? 2400 : 1500;
    return base + Math.round(Math.random() * 180);
  }
}
