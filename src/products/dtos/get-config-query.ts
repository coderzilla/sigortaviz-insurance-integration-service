// src/products/dtos/get-config.query.ts
import { Transform } from 'class-transformer';
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
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  stage?: FormStage;
}
