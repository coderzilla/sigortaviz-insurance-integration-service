import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, Matches, MaxLength } from 'class-validator';
import { ProductCode } from '../../common/types/domain-types';

export class CreateQuoteSessionDto {
  @IsEnum(ProductCode)
  productCode: ProductCode;

  @IsString()
  @Matches(/^[0-9+]{8,20}$/)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  phoneNumber: string;

  @IsString()
  @MaxLength(64)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  idNumber: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  idempotencyKey?: string;
}
