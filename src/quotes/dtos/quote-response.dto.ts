// src/quotes/dtos/quote-response.dto.ts
import { QuoteOffer } from '../../carriers/carrier-types';

export class QuoteResponseDto {
  requestId: string;
  offers: QuoteOffer[];
  errors?: { carrierCode: string; message: string }[];
}
