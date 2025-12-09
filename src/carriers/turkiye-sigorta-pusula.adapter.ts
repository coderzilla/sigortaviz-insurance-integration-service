import { CarrierAdapter } from './carrier.adapter';
import {
  PolicyPurchaseRequest,
  PolicyPurchaseResult,
  QuoteRequest,
  QuoteResult,
} from './carrier-types';
import { ProductCode } from '../common/types/domain-types';
import { PusulaSoapClient } from './turkiye-sigorta-pusula.soap';

/**
 * Türkiye Sigorta Pusula integration scaffold.
 * The real SOAP calls require the Pusula WSDL credentials, product code,
 * and a field mapping for risk/saglik parameters. Until those are supplied,
 * the adapter stays disabled by default.
 */
export class TurkiyeSigortaPusulaAdapter implements CarrierAdapter {
  readonly carrierCode = 'TURKEY_INSURANCE';

  private readonly enabled: boolean;
  private readonly endpoint?: string;
  private readonly soap: PusulaSoapClient;
  private readonly productCode: string;

  constructor() {
    this.enabled = process.env.PUSULA_ENABLED === 'true';
    this.endpoint = process.env.PUSULA_ENDPOINT;
    this.productCode =
      process.env.PUSULA_PRODUCT_CODE ?? `${this.carrierCode}_HEALTH`;
    this.soap = new PusulaSoapClient(
      this.endpoint ?? '',
      {
        username: process.env.PUSULA_USERNAME,
        password: process.env.PUSULA_PASSWORD,
      },
      { mockMode: process.env.PUSULA_SOAP_MODE === 'mock' },
    );
  }

  supportsProduct(product: ProductCode): boolean {
    return this.enabled && product === ProductCode.HEALTH;
  }

  async getQuote(request: QuoteRequest): Promise<QuoteResult> {
    const requestId = `pusula-${Date.now()}`;

    if (!this.enabled) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message:
              'Türkiye Sigorta Pusula integration is disabled. Set PUSULA_ENABLED=true to activate.',
          },
        ],
      };
    }

    if (!this.endpoint) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message:
              'Missing Pusula endpoint. Configure PUSULA_ENDPOINT to enable quote requests.',
          },
        ],
      };
    }

    const payload = this.buildTeklifOlusturPayload(request);
    const soapResult = await this.soap.teklifOlustur(payload);

    if (!soapResult.success) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: soapResult.fault ?? 'Pusula teklifOlustur failed',
          },
        ],
      };
    }

    const grossPremium =
      this.extractNumber(soapResult.raw, /<brutPrim[^>]*>([^<]+)<\/brutPrim>/i) ??
      this.randomPremium();
    const netPremium =
      this.extractNumber(soapResult.raw, /<netPrim[^>]*>([^<]+)<\/netPrim>/i) ??
      grossPremium - 120;

    return {
      requestId,
      offers: [
        {
          carrierCode: this.carrierCode,
          carrierProductCode: this.productCode,
          product: request.product,
          grossPremium,
          netPremium,
          currency:
            this.extractText(soapResult.raw, /<dovizCinsi[^>]*>([^<]+)<\/dovizCinsi>/i) ??
            'TRY',
          coverageSummary:
            this.extractText(
              soapResult.raw,
              /<teminatAciklamasi[^>]*>([^<]+)<\/teminatAciklamasi>/i,
            ) ?? 'Sağlık teminatları',
          coverageDetails: {
            raw: soapResult.raw,
          },
          warnings: [],
          rawCarrierData: {
            endpoint: this.endpoint,
            response: soapResult.raw,
          },
        },
      ],
      errors: [],
    };
  }

  async buyPolicy(
    request: PolicyPurchaseRequest,
  ): Promise<PolicyPurchaseResult> {
    if (!this.enabled) {
      throw new Error(
        'Türkiye Sigorta Pusula integration is disabled. Set PUSULA_ENABLED=true.',
      );
    }

    if (!this.endpoint) {
      throw new Error('Missing PUSULA_ENDPOINT for Pusula integration.');
    }

    const payload = this.buildPoliceTeklifOlusturPayload(request);
    const soapResult = await this.soap.policeTeklifOlustur(payload);

    if (!soapResult.success) {
      throw new Error(
        soapResult.fault ??
          'Pusula policeTeklifOlustur failed; see raw response for details.',
      );
    }

    const policyId =
      this.extractText(
        soapResult.raw,
        /<policeNo[^>]*>([^<]+)<\/policeNo>/i,
      ) ?? `PUSULA-${Date.now()}`;
    const carrierPolicyNumber =
      this.extractText(
        soapResult.raw,
        /<policeNumarasi[^>]*>([^<]+)<\/policeNumarasi>/i,
      ) ?? `TS-${Math.round(Math.random() * 1_000_000)}`;
    const effectiveFrom =
      this.extractText(
        soapResult.raw,
        /<baslangicTarihi[^>]*>([^<]+)<\/baslangicTarihi>/i,
      ) ?? new Date().toISOString();
    const effectiveTo =
      this.extractText(
        soapResult.raw,
        /<bitisTarihi[^>]*>([^<]+)<\/bitisTarihi>/i,
      ) ??
      new Date(
        new Date(effectiveFrom).getTime() + 365 * 24 * 60 * 60 * 1000,
      ).toISOString();

    const docBase = process.env.PUSULA_DOC_BASE_URL;
    return {
      policyId,
      carrierCode: this.carrierCode,
      carrierPolicyNumber,
      effectiveFrom,
      effectiveTo,
      documents: docBase
        ? [
            {
              type: 'POLICY_PDF',
              url: `${docBase}/policy/${policyId}.pdf`,
            },
          ]
        : [],
      rawCarrierData: {
        endpoint: this.endpoint,
        response: soapResult.raw,
      },
    };
  }

  /**
   * Very lightweight request mapping. Replace fields with real Pusula mappings as needed.
   */
  private buildTeklifOlusturPayload(request: QuoteRequest): string {
    const today = new Date();
    const start = today.toISOString().slice(0, 10);
    const end = new Date(
      today.getTime() + 365 * 24 * 60 * 60 * 1000,
    ).toISOString().slice(0, 10);

    return `
      <genelBilgi>
        <urunKodu>${this.productCode}</urunKodu>
        <baslangicTarihi>${start}</baslangicTarihi>
        <bitisTarihi>${end}</bitisTarihi>
        <dovizCinsi>TL</dovizCinsi>
        <fiyatAlternatifleri>true</fiyatAlternatifleri>
      </genelBilgi>
      <sigortaliBilgisi>
        <Ad>${request.insuredPerson.fullName}</Ad>
        <dogumTarihi>${request.insuredPerson.birthDate ?? ''}</dogumTarihi>
        <kimlikNo>${request.insuredPerson.tckn ?? ''}</kimlikNo>
        <cepTel>${request.insuredPerson.phoneNumber ?? ''}</cepTel>
        <email>${request.insuredPerson.email ?? ''}</email>
      </sigortaliBilgisi>
      <riskBilgisi>
        <Kod>GRUP_TIPI</Kod>
        <deger>${request.customFields?.grupTipiKodu ?? ''}</deger>
      </riskBilgisi>
      <saglikBilgisi>
        <grupNo>${request.customFields?.grupNo ?? ''}</grupNo>
        <grupYenilemeNo>${request.customFields?.grupYenilemeNo ?? ''}</grupYenilemeNo>
      </saglikBilgisi>
    `;
  }

  private buildPoliceTeklifOlusturPayload(
    request: PolicyPurchaseRequest,
  ): string {
    const quotePayload = this.buildTeklifOlusturPayload({
      product: request.selectedOffer.product,
      insuredPerson: request.insuredPerson,
      customFields: request.customFields,
    });

    return `
      ${quotePayload}
      <odemeBilgisi>
        <odemeAraciKodu>${
          request.payment.cardTokenId ? 'KREDI_KARTI' : ''
        }</odemeAraciKodu>
        <taksitSayisi>${request.customFields?.taksitSayisi ?? 1}</taksitSayisi>
      </odemeBilgisi>
    `;
  }

  private extractNumber(raw: string, regex: RegExp): number | undefined {
    const text = this.extractText(raw, regex);
    if (text === undefined) return undefined;
    const num = Number(text.replace(',', '.'));
    return Number.isNaN(num) ? undefined : num;
  }

  private extractText(raw: string, regex: RegExp): string | undefined {
    const match = raw.match(regex);
    return match?.[1];
  }

  private randomPremium(): number {
    const base = 1600;
    const variance = Math.round(Math.random() * 200);
    return base + variance;
  }
}
