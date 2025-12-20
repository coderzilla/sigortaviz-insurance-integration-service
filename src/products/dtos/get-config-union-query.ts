import {
  IsArray,
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  ValidateIf,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ProductCode } from '../../common/types/domain-types';
import type { FormStage } from '../../common/types/field-types';

export class GetConfigUnionQuery {
  @IsEnum(ProductCode)
  product: ProductCode;

  @IsOptional()
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .split(',')
          .map((c: string) => c.trim())
          .filter(Boolean)
      : undefined,
  )
  @IsArray()
  @IsString({ each: true })
  carriers?: string[];

  @IsOptional()
  @IsIn(['QUOTE', 'PURCHASE'])
  stage?: FormStage;

  // allow single carrier query param (carriers=CODE)
  @ValidateIf((o) => !o.carriers)
  @IsOptional()
  @IsString()
  carrier?: string;
}
