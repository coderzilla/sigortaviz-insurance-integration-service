// src/products/dtos/get-config.query.ts
import { IsEnum, IsString } from 'class-validator';
import { ProductCode } from '../../common/types/domain-types';

export class GetConfigQuery {
  @IsEnum(ProductCode)
  product: ProductCode;

  @IsString()
  carrier: string;
}
