import { Transform } from 'class-transformer';
import { IsEnum, IsString, Matches } from 'class-validator';
import { OtpPurpose } from '../../common/types/domain-types';

export class VerifyOtpDto {
  @IsString()
  @Matches(/^[0-9+]{8,20}$/)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  phoneNumber: string;

  @IsString()
  @Matches(/^[0-9]{4,8}$/)
  code: string;

  @IsEnum(OtpPurpose)
  purpose: OtpPurpose = OtpPurpose.LOGIN;
}
