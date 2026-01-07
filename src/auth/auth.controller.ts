import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RequestOtpDto } from './dtos/request-otp.dto';
import { VerifyOtpDto } from './dtos/verify-otp.dto';
import { OtpPurpose } from '../common/types/domain-types';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('otp/request')
  async requestOtp(@Body() body: RequestOtpDto) {
    const purpose = body.purpose ?? OtpPurpose.LOGIN;
    return this.authService.requestOtp(body.phoneNumber, purpose);
  }

  @Post('otp/verify')
  async verifyOtp(@Body() body: VerifyOtpDto) {
    const purpose = body.purpose ?? OtpPurpose.LOGIN;
    return this.authService.verifyOtp(body.phoneNumber, body.code, purpose);
  }
}
