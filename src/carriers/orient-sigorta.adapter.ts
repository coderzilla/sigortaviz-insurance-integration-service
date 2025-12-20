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

  // K10 tariff statistic defaults (from excel dump).
  private static readonly STAT_DEFAULTS: Record<string, string> = {
    AKL: '001', // Kullanım şekli
    RNT: '000', // Kullanım amacı
  };

  private readonly enabled: boolean;
  private readonly policyClient: OrientSoapClient;
  private readonly utilityClient: OrientSoapClient;
  private readonly securityClient: OrientSoapClient;
  private readonly appSecurityKey?: string;
  private readonly mockMode: boolean;
  // Default product/tariff/agency codes can be overridden via customFields.orient
  private readonly defaultProductCode?: string;
  private readonly defaultTariffCode?: string;
  private readonly defaultAgencyNo?: string;

  constructor() {
    this.enabled = process.env.ORIENT_ENABLED === 'true';
    this.mockMode = process.env.ORIENT_SOAP_MODE === 'mock';
    this.appSecurityKey = process.env.ORIENT_APP_SECURITY_KEY;
    this.defaultProductCode = process.env.ORIENT_PRODUCT_CODE;
    this.defaultTariffCode = process.env.ORIENT_TARIFF_CODE;
    this.defaultAgencyNo = process.env.ORIENT_AGENCY_NO;

    this.policyClient = new OrientSoapClient(
      process.env.ORIENT_POLICY_ENDPOINT ?? '',
      {
        username: process.env.ORIENT_USERNAME,
        password: process.env.ORIENT_PASSWORD,
      },
      { mockMode: this.mockMode },
    );
    this.utilityClient = new OrientSoapClient(
      process.env.ORIENT_UTILITY_ENDPOINT ?? '',
      {
        username: process.env.ORIENT_USERNAME,
        password: process.env.ORIENT_PASSWORD,
      },
      { mockMode: this.mockMode },
    );
    this.securityClient = new OrientSoapClient(
      process.env.ORIENT_SECURITY_ENDPOINT ?? '',
      {
        username: process.env.ORIENT_USERNAME,
        password: process.env.ORIENT_PASSWORD,
      },
      { mockMode: this.mockMode },
    );
  }

  private buildPolicyPayloadFromQuote(
    request: QuoteRequest,
    authKey: string | undefined,
  ): string | undefined {
    if (!authKey) return undefined;
    const orientCfg = (request.customFields as any)?.orient ?? {};
    const productCode =
      orientCfg.productCode ?? this.defaultProductCode ?? 'CASCO';
    const tariffCode = orientCfg.tariffCode ?? this.defaultTariffCode ?? '';
    const agencyNo = orientCfg.agencyNo ?? this.defaultAgencyNo ?? '';
    const riskAddress = orientCfg.riskAddress ?? {};
    const insured = request.insuredPerson;
    const vehicle = request.vehicle ?? {};

    const statisticsXml = this.buildStatistics(orientCfg, vehicle);

    const safe = (val: any) =>
      val === undefined || val === null ? '' : String(val);

    const startDate = (orientCfg.startDate ?? new Date().toISOString()).slice(
      0,
      19,
    );
    const endDate = (
      orientCfg.endDate ??
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
    ).slice(0, 19);

    return `
      <authenticationKey>${authKey}</authenticationKey>
      <entity xmlns:a="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.Policy" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <a:Insured xmlns:b="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.TypeMapping">
          <b:ACENTA_NO>${agencyNo}</b:ACENTA_NO>
          <b:AD1>${safe(insured.fullName)}</b:AD1>
          <b:TC_KIMLIK_NO>${safe(insured.tckn)}</b:TC_KIMLIK_NO>
        </a:Insured>
        <a:Item xmlns:b="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.TypeMapping">
          <b:PLAKA_CINS>${safe(orientCfg.plateType ?? '')}</b:PLAKA_CINS>
          <b:PLAKA_IL_KOD>${safe(orientCfg.plateProvince ?? vehicle.plate?.slice(0, 2) ?? '')}</b:PLAKA_IL_KOD>
          <b:TARIFE_KOD>${tariffCode}</b:TARIFE_KOD>
          <b:TEM_KOD>${productCode}</b:TEM_KOD>
          <b:BASLAMA_TARIH>${startDate}</b:BASLAMA_TARIH>
          <b:BITIS_TARIH>${endDate}</b:BITIS_TARIH>
        </a:Item>
        <a:RiskAddress xmlns:b="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.TypeMapping">
          <b:IL>${safe(riskAddress.city)}</b:IL>
          <b:ILCE>${safe(riskAddress.county)}</b:ILCE>
          <b:SEMT>${safe(riskAddress.district)}</b:SEMT>
          <b:SOKAK>${safe(riskAddress.street)}</b:SOKAK>
          <b:NO>${safe(riskAddress.no)}</b:NO>
          <b:POSTA_KODU>${safe(riskAddress.postalCode)}</b:POSTA_KODU>
        </a:RiskAddress>
        ${statisticsXml}
      </entity>
      <startDate>${startDate}</startDate>
      <endDate>${endDate}</endDate>
      <addNewAddress>1</addNewAddress>
    `.replace(/\s+/g, ' ');
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

    // Mock path still available for local testing.
    if (this.mockMode) {
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
            coverageDetails: {},
            warnings: [],
            rawCarrierData: { mode: 'mock' },
          },
        ],
        errors: [],
      };
    }

    const orientCfg = (request.customFields as any)?.orient ?? {};
    const authKey = await this.getAuthenticationKey();
    if (!authKey) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: 'Could not retrieve Orient authentication key.',
          },
        ],
      };
    }

    const quotePayload: string | undefined =
      orientCfg.quotePayload ??
      this.buildPolicyPayloadFromQuote(request, authKey);
    const quoteOperation: string = orientCfg.quoteOperation ?? 'CreatePolicy';
    const quoteSoapAction: string | undefined = orientCfg.quoteSoapAction;
    const targetService: 'policy' | 'utility' =
      orientCfg.service === 'utility' ? 'utility' : 'policy';

    const client =
      targetService === 'utility' ? this.utilityClient : this.policyClient;

    const payloadWithKey = this.injectAuthKey(quotePayload!, authKey);
    const soapResult = await client.call({
      operation: quoteOperation,
      body: payloadWithKey,
      soapAction:
        quoteSoapAction ??
        `http://tempuri.org/I${
          targetService === 'utility' ? 'Utility' : 'Policy'
        }Service/${quoteOperation}`,
    });

    if (!soapResult.success) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: this.carrierCode,
            message: soapResult.fault ?? 'Orient quote call failed',
          },
        ],
      };
    }

    const { gross, net } = this.extractPremiums(soapResult.raw);
    const grossPremium = gross ?? this.randomPremium(request.product);
    const netPremium = net ?? grossPremium - 100;

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
          coverageSummary: `Orient ${request.product} coverage`,
          coverageDetails: { raw: soapResult.raw },
          warnings: [],
          rawCarrierData: { response: soapResult.raw },
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

    if (this.mockMode) {
      const now = new Date();
      const yearMs = 365 * 24 * 60 * 60 * 1000;
      return {
        policyId: `ORIENT-${Date.now()}`,
        carrierCode: this.carrierCode,
        carrierPolicyNumber: `OR-${Math.round(Math.random() * 1_000_000)}`,
        effectiveFrom: now.toISOString(),
        effectiveTo: new Date(now.getTime() + yearMs).toISOString(),
        documents: [],
        rawCarrierData: { mode: 'mock' },
      };
    }

    const authKey = await this.getAuthenticationKey();
    if (!authKey) {
      throw new Error('Could not retrieve Orient authentication key.');
    }

    const orientCfg = (request.customFields as any)?.orient ?? {};
    const policyOperation: string = orientCfg.policyOperation ?? 'CreatePolicy';
    const policySoapAction: string | undefined = orientCfg.policySoapAction;
    const startDate =
      orientCfg.startDate ?? new Date().toISOString();
    const endDate =
      orientCfg.endDate ??
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString();

    const policyPayload = this.buildPolicyPayload(
      request,
      authKey,
      startDate,
      endDate,
    );

    const result = await this.policyClient.call({
      operation: policyOperation,
      body: policyPayload,
      soapAction:
        policySoapAction ??
        `http://tempuri.org/IPolicyService/${policyOperation}`,
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
    if (!this.appSecurityKey) {
      throw new Error('Missing ORIENT_APP_SECURITY_KEY for Orient security service.');
    }
    if (!process.env.ORIENT_USERNAME || !process.env.ORIENT_PASSWORD) {
      throw new Error('Missing ORIENT_USERNAME/ORIENT_PASSWORD for Orient security service.');
    }

    // Security service expects appSecurityKey + credentials in the request body.
    const body = [
      `<appSecurityKey>${this.appSecurityKey}</appSecurityKey>`,
      `<userName>${process.env.ORIENT_USERNAME}</userName>`,
      `<password>${process.env.ORIENT_PASSWORD}</password>`,
    ].join('');

    const res = await this.securityClient.call({
      operation: 'GetAuthenticationKey',
      body,
      soapAction: 'http://tempuri.org/ISecurityService/GetAuthenticationKey',
    });
    if (!res.success) return undefined;
    // SecurityService may return either <AuthenticationKey>...</AuthenticationKey>
    // or <GetAuthenticationKeyResult>...</GetAuthenticationKeyResult> (plain/base64).
    return (
      this.extractText(res.raw, /<AuthenticationKey[^>]*>([^<]+)<\/AuthenticationKey>/i) ??
      this.extractText(res.raw, /<GetAuthenticationKeyResult[^>]*>([^<]+)<\/GetAuthenticationKeyResult>/i)
    );
  }

  private injectAuthKey(payload: string, authKey: string): string {
    return payload.includes('{{AUTH_KEY}}')
      ? payload.replace(/{{AUTH_KEY}}/g, authKey)
      : payload;
  }

  private buildStatistics(
    orientCfg: Record<string, any>,
    vehicle?: { plate?: string; brand?: string; model?: string; modelYear?: number },
  ): string {
    const veh = orientCfg.vehicle ?? vehicle ?? {};
    const plate = orientCfg.plate ?? (veh?.plate as string | undefined) ?? '';
    const plateProvince =
      orientCfg.plateProvince ??
      (plate && plate.length >= 2 ? plate.slice(0, 2) : undefined);

    const entries: { code: string; value: string }[] = [];
    const pushIf = (code: string, value?: string | number | null) => {
      if (value !== undefined && value !== null && `${value}`.length > 0) {
        entries.push({ code, value: `${value}` });
      }
    };

    // Defaults from excel
    Object.entries(OrientSigortaAdapter.STAT_DEFAULTS).forEach(([k, v]) =>
      pushIf(k, v),
    );

    pushIf('MRG', veh.brand);
    pushIf('MAR', veh.model);
    pushIf('YIL', veh.modelYear ? String(veh.modelYear) : undefined);
    pushIf('ILK', orientCfg.ilKod ?? plateProvince);
    pushIf('PIK', orientCfg.plakaKod ?? plateProvince);
    pushIf('MIL', orientCfg.mernisIl);
    pushIf('MIC', orientCfg.mernisIlce);
    pushIf('AKL', orientCfg.kullanimSekli);
    pushIf('RNT', orientCfg.kullanimAmaci);

    if (!entries.length) return '';

    return `
      <a:Statistics xmlns:b="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.TypeMapping">
        <b:Value>
          ${entries
            .map(
              (e) => `
            <b:EXT_WS_ISTDEG_REC>
              <b:IST_KOD>${e.code}</b:IST_KOD>
              <b:DEG_KOD>${e.value}</b:DEG_KOD>
            </b:EXT_WS_ISTDEG_REC>
          `,
            )
            .join('')}
        </b:Value>
      </a:Statistics>
    `;
  }

  private buildPolicyPayload(
    request: PolicyPurchaseRequest,
    authKey: string,
    startDateIso: string,
    endDateIso: string,
  ): string {
    const orientCfg = (request.customFields as any)?.orient ?? {};
    const productCode =
      orientCfg.productCode ??
      this.defaultProductCode ??
      request.selectedOffer?.carrierProductCode ??
      'CASCO';
    const tariffCode = orientCfg.tariffCode ?? this.defaultTariffCode ?? '';
    const agencyNo = orientCfg.agencyNo ?? this.defaultAgencyNo ?? '';
    const riskAddress = orientCfg.riskAddress ?? {};
    const insured = request.insuredPerson;
    const statisticsXml = this.buildStatistics(orientCfg, orientCfg.vehicle);

    // Dates in yyyy-MM-ddTHH:mm:ss format
    const startDate = startDateIso.slice(0, 19);
    const endDate = endDateIso.slice(0, 19);

    const safe = (val: any) => (val === undefined || val === null ? '' : String(val));

    // Build minimal Policy entity. Many fields exist in XSDs; include key identifiers and allow extension via custom XML snippets.
    const extraPolicyXml = orientCfg.extraPolicyXml ?? '';
    const extraInsuredXml = orientCfg.extraInsuredXml ?? '';
    const extraItemXml = orientCfg.extraItemXml ?? '';

    // Return only the inner body; OrientSoapClient wraps with <CreatePolicy>...</CreatePolicy>
    return `
      <authenticationKey>${authKey}</authenticationKey>
      <entity xmlns:a="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.Policy" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <a:Insured xmlns:b="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.TypeMapping">
          <b:ACENTA_NO>${agencyNo}</b:ACENTA_NO>
          <b:AD1>${safe(insured.fullName)}</b:AD1>
          <b:TC_KIMLIK_NO>${safe(insured.tckn)}</b:TC_KIMLIK_NO>
          ${extraInsuredXml}
        </a:Insured>
        <a:Item xmlns:b="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.TypeMapping">
          <b:PLAKA_CINS>${safe(orientCfg.plateType ?? '')}</b:PLAKA_CINS>
          <b:PLAKA_IL_KOD>${safe(orientCfg.plateProvince ?? '')}</b:PLAKA_IL_KOD>
          <b:POL_TANZIM_BOLGE_KOD>${safe(orientCfg.issueRegionCode ?? '')}</b:POL_TANZIM_BOLGE_KOD>
          <b:TARIFE_KOD>${tariffCode}</b:TARIFE_KOD>
          <b:TEM_KOD>${productCode}</b:TEM_KOD>
          <b:POLICE_SERINO>${safe(orientCfg.policySerie ?? '')}</b:POLICE_SERINO>
          <b:BASLAMA_TARIH>${startDate}</b:BASLAMA_TARIH>
          <b:BITIS_TARIH>${endDate}</b:BITIS_TARIH>
          ${extraItemXml}
        </a:Item>
        <a:RiskAddress xmlns:b="http://schemas.datacontract.org/2004/07/EntitySpaces.NonLife.TypeMapping">
          <b:IL>${safe(riskAddress.city)}</b:IL>
          <b:ILCE>${safe(riskAddress.county)}</b:ILCE>
          <b:SEMT>${safe(riskAddress.district)}</b:SEMT>
          <b:SOKAK>${safe(riskAddress.street)}</b:SOKAK>
          <b:NO>${safe(riskAddress.no)}</b:NO>
          <b:POSTA_KODU>${safe(riskAddress.postalCode)}</b:POSTA_KODU>
        </a:RiskAddress>
        ${statisticsXml}
        ${extraPolicyXml}
      </entity>
      <startDate>${startDate}</startDate>
      <endDate>${endDate}</endDate>
      <addNewAddress>1</addNewAddress>
    `.replace(/\s+/g, ' ');
  }

  private extractPremiums(raw: string): { gross?: number; net?: number } {
    const gross =
      this.extractNumber(raw, /<BrutPrim[^>]*>([^<]+)<\/BrutPrim>/i) ??
      this.extractNumber(raw, /<brutPrim[^>]*>([^<]+)<\/brutPrim>/i) ??
      this.extractNumber(raw, /<GrossPremium[^>]*>([^<]+)<\/GrossPremium>/i) ??
      this.extractNumber(raw, /<ToplamPrim[^>]*>([^<]+)<\/ToplamPrim>/i);
    const net =
      this.extractNumber(raw, /<NetPrim[^>]*>([^<]+)<\/NetPrim>/i) ??
      this.extractNumber(raw, /<netPrim[^>]*>([^<]+)<\/netPrim>/i) ??
      this.extractNumber(raw, /<NetPremium[^>]*>([^<]+)<\/NetPremium>/i);
    return { gross, net };
  }

  private extractNumber(raw: string, regex: RegExp): number | undefined {
    const value = this.extractText(raw, regex);
    if (value === undefined) return undefined;
    const num = Number(value.replace(',', '.'));
    return Number.isFinite(num) ? num : undefined;
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
