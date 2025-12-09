import {
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import type { QuoteOffer, QuoteRequest } from '../../carriers/carrier-types';

class PaymentDto {
  @IsOptional()
  @IsString()
  cardTokenId?: string;
}

export class PurchasePolicyDto {
  @IsString()
  quoteRequestId: string;

  @IsObject()
  selectedOffer: QuoteOffer;

  @IsObject()
  insuredPerson: QuoteRequest['insuredPerson'];

  @ValidateNested()
  @Type(() => PaymentDto)
  payment: PaymentDto;

  @IsOptional()
  @IsObject()
  customFields?: Record<string, any>;
}
