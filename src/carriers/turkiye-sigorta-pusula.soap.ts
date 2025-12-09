interface SoapCredentials {
  username?: string;
  password?: string;
}

interface SoapCallInput {
  operation: string;
  body: string;
  soapAction?: string;
}

export interface SoapCallResult {
  success: boolean;
  raw: string;
  fault?: string;
}

/**
 * Thin SOAP client used for Türkiye Sigorta Pusula integration.
 * Uses fetch if available; otherwise throws so the caller can surface the error.
 */
export class PusulaSoapClient {
  private readonly mockMode: boolean;

  constructor(
    private readonly endpoint: string,
    private readonly creds: SoapCredentials,
    opts?: { mockMode?: boolean },
  ) {
    this.mockMode = !!opts?.mockMode;
  }

  async call(input: SoapCallInput): Promise<SoapCallResult> {
    if (this.mockMode) {
      return this.mockResponse(input.operation);
    }

    const fetchFn: any = (globalThis as any).fetch;
    if (!fetchFn) {
      throw new Error('global fetch is not available; provide a fetch polyfill.');
    }

    const envelope = this.buildEnvelope(input.operation, input.body);
    const res = await fetchFn(this.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        ...(input.soapAction ? { SOAPAction: input.soapAction } : {}),
      },
      body: envelope,
    });

    const raw = await res.text();
    if (!res.ok) {
      return { success: false, raw, fault: `HTTP ${res.status}` };
    }

    const fault = this.extractFault(raw);
    if (fault) {
      return { success: false, raw, fault };
    }

    return { success: true, raw };
  }

  // Convenience helpers for common operations
  teklifOlustur(body: string) {
    return this.call({ operation: 'teklifOlustur', body });
  }

  teklifSorgu(body: string) {
    return this.call({ operation: 'teklifSorgu', body });
  }

  teklifSorguTarih(body: string) {
    return this.call({ operation: 'teklifSorguTarih', body });
  }

  policeOlustur(body: string) {
    return this.call({ operation: 'policeOlustur', body });
  }

  policeTeklifOlustur(body: string) {
    return this.call({ operation: 'policeTeklifOlustur', body });
  }

  policeSorgu(body: string) {
    return this.call({ operation: 'policeSorgu', body });
  }

  policeSorguTarih(body: string) {
    return this.call({ operation: 'policeSorguTarih', body });
  }

  zeyilOlusturIptal(body: string) {
    return this.call({ operation: 'ZeyilOlusturIptal', body });
  }

  policeBilgisiGuncelle(body: string) {
    return this.call({ operation: 'PoliceBilgisiGuncelle', body });
  }

  dokumanIndir(body: string) {
    return this.call({ operation: 'DokumanIndir', body });
  }

  private buildEnvelope(operation: string, innerBody: string): string {
    const { username, password } = this.creds;
    const header =
      username && password
        ? `<soapenv:Header><wsse:Security xmlns:wsse="http://schemas.xmlsoap.org/ws/2002/12/secext"><wsse:UsernameToken><wsse:Username>${username}</wsse:Username><wsse:Password>${password}</wsse:Password></wsse:UsernameToken></wsse:Security></soapenv:Header>`
        : '<soapenv:Header/>';

    return [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">',
      header,
      '<soapenv:Body>',
      `<${operation}>`,
      innerBody,
      `</${operation}>`,
      '</soapenv:Body>',
      '</soapenv:Envelope>',
    ].join('');
  }

  private extractFault(raw: string): string | undefined {
    const match = raw.match(/<faultstring[^>]*>([^<]+)<\/faultstring>/i);
    return match?.[1];
  }

  private mockResponse(operation: string): SoapCallResult {
    const now = new Date().toISOString();
    const payload = `<mockResponse><operation>${operation}</operation><timestamp>${now}</timestamp></mockResponse>`;
    return { success: true, raw: payload };
  }
}
