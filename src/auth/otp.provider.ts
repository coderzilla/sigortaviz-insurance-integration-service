import { Injectable } from '@nestjs/common';
import { maskPhone } from '../common/utils/mask.util';
import { OtpPurpose } from '../common/types/domain-types';

export interface OtpProvider {
  sendOtp(phoneNumber: string, code: string, purpose: OtpPurpose): Promise<void>;
}

@Injectable()
export class ConsoleOtpProvider implements OtpProvider {
  async sendOtp(
    phoneNumber: string,
    code: string,
    purpose: OtpPurpose,
  ): Promise<void> {
    const maskedPhone = maskPhone(phoneNumber);
    const shouldEcho = process.env.OTP_DEV_ECHO === 'true';
    const codeMessage = shouldEcho
      ? ` code=${code}`
      : '';
    // Avoid logging raw phone/code in production; masked only
    console.log(
      `[OTP] Sent${codeMessage} to ${maskedPhone} for purpose=${purpose}`,
    );
  }
}
