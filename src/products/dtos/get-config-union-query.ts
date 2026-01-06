import { Transform } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  ValidateIf,
} from 'class-validator';
import type { FormStage } from '../../common/types/field-types';

export class GetConfigUnionQuery {
  @IsOptional()
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .split(',')
          .map((c: string) => c.trim().toUpperCase())
          .filter(Boolean)
      : undefined,
  )
  @IsArray()
  @IsString({ each: true })
  carriers?: string[];

  @IsOptional()
  @IsIn(['QUOTE', 'PURCHASE'])
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  stage?: FormStage;

  // allow single carrier query param (carriers=CODE)
  @ValidateIf((o) => !o.carriers)
  @IsOptional()
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString()
  carrier?: string;
}
