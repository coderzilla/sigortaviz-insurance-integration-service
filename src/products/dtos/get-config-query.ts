// src/products/dtos/get-config.query.ts
import { IsEnum, IsIn, IsOptional, IsString } from 'class-validator';
import { ProductCode } from '../../common/types/domain-types';
import type { FormStage } from '../../common/types/field-types';

export class GetConfigQuery {
  @IsEnum(ProductCode)
  product: ProductCode;

  @IsString()
  carrier: string;

  @IsOptional()
  @IsIn(['QUOTE', 'PURCHASE'])
  stage?: FormStage;
}
