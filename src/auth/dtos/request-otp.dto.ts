import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, Matches } from 'class-validator';
import { OtpPurpose } from '../../common/types/domain-types';

export class RequestOtpDto {
  @IsString()
  @Matches(/^[0-9+]{8,20}$/)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  phoneNumber: string;

  @IsOptional()
  @IsEnum(OtpPurpose)
  purpose?: OtpPurpose;
}
