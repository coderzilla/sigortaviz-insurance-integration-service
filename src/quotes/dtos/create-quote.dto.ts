// src/quotes/dtos/create-quote.dto.ts
import {
  IsEnum,
  IsObject,
  IsOptional,
  IsString,
  IsArray,
  ValidateNested,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ProductCode } from '../../common/types/domain-types';

// These mirror QuoteRequest.insuredPerson & vehicle
class InsuredPersonDto {
  @IsString()
  fullName: string;

  @IsOptional()
  @IsString()
  birthDate?: string; // ISO date string

  @IsOptional()
  @IsString()
  tckn?: string;

  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @IsOptional()
  @IsString()
  email?: string;
}

class AdditionalInsuredDto extends InsuredPersonDto {
  @IsOptional()
  @IsString()
  role?: string; // SELF | SPOUSE | CHILD

  @IsOptional()
  @IsBoolean()
  isMain?: boolean;
}

class VehicleDto {
  @IsOptional()
  @IsString()
  plate?: string;

  @IsOptional()
  @IsString()
  vin?: string;

  @IsOptional()
  modelYear?: number;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsOptional()
  @IsString()
  model?: string;
}

export class CreateQuoteDto {
  @IsEnum(ProductCode)
  product: ProductCode;

  @ValidateNested()
  @Type(() => InsuredPersonDto)
  insuredPerson: InsuredPersonDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => InsuredPersonDto)
  insurer?: InsuredPersonDto;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AdditionalInsuredDto)
  insureds?: AdditionalInsuredDto[];

  @IsOptional()
  @ValidateNested()
  @Type(() => VehicleDto)
  vehicle?: VehicleDto;

  @IsOptional()
  @IsObject()
  customFields?: Record<string, any>;

  @IsOptional()
  @IsArray()
  carriers?: string[];
}
