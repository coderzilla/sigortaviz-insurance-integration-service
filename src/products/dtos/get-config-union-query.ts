import {
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  ValidateIf,
} from 'class-validator';
import { Transform } from 'class-transformer';
import type { FormStage } from '../../common/types/field-types';

export class GetConfigUnionQuery {
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
