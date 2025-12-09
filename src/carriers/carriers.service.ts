// src/carriers/carriers.service.ts
import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { CarrierAdapter } from './carrier.adapter';
import {
  PolicyPurchaseRequest,
  PolicyPurchaseResult,
  QuoteOffer,
  QuoteRequest,
  QuoteResult,
} from './carrier-types';
import { CARRIER_ADAPTERS } from './carrier.constants';
import { ProductCode } from '../common/types/domain-types';
import type { CarrierCode } from '../common/types/domain-types';

@Injectable()
export class CarriersService {
  constructor(
    @Inject(CARRIER_ADAPTERS)
    private readonly adapters: CarrierAdapter[],
  ) {}

  async getQuotes(
    request: QuoteRequest,
    carrierCodes?: string[],
  ): Promise<QuoteResult> {
    const requestId = this.buildRequestId();

    const targetAdapters = this.adapters.filter((adapter) => {
      const carrierAllowed =
        !carrierCodes || carrierCodes.includes(adapter.carrierCode);
      return carrierAllowed && adapter.supportsProduct(request.product);
    });

    if (!targetAdapters.length) {
      return {
        requestId,
        offers: [],
        errors: [
          {
            carrierCode: carrierCodes?.join(',') ?? 'ALL',
            message: 'No carrier adapters available for the requested product.',
          },
        ],
      };
    }

    const results = await Promise.allSettled(
      targetAdapters.map((adapter) =>
        adapter.getQuote({ ...request, carrierCode: adapter.carrierCode }),
      ),
    );

    const offers: QuoteOffer[] = [];
    const errors: NonNullable<QuoteResult['errors']> = [];

    results.forEach((result, idx) => {
      const adapter = targetAdapters[idx];
      if (result.status === 'fulfilled') {
        offers.push(...(result.value.offers || []));
        if (result.value.errors?.length) {
          errors.push(
            ...result.value.errors.map((e) => ({
              carrierCode: e.carrierCode ?? adapter.carrierCode,
              message: e.message,
            })),
          );
        }
      } else {
        errors.push({
          carrierCode: adapter.carrierCode,
          message: result.reason?.message ?? 'Unknown error',
        });
      }
    });

    return {
      requestId,
      offers,
      errors,
    };
  }

  private buildRequestId(): string {
    return `quote-${Date.now()}-${Math.round(Math.random() * 1_000_000)}`;
  }

  async buyPolicy(
    request: PolicyPurchaseRequest,
  ): Promise<PolicyPurchaseResult> {
    const carrierCode = request.selectedOffer.carrierCode;
    const adapter = this.adapters.find(
      (a) =>
        a.carrierCode === carrierCode &&
        a.supportsProduct(request.selectedOffer.product),
    );

    if (!adapter) {
      throw new NotFoundException(
        `No carrier adapter available for carrier=${carrierCode}, product=${request.selectedOffer.product}`,
      );
    }

    return adapter.buyPolicy(request);
  }

  getCarriersForProduct(product: ProductCode): CarrierCode[] {
    return this.adapters
      .filter((adapter) => adapter.supportsProduct(product))
      .map((adapter) => adapter.carrierCode as CarrierCode);
  }
}
