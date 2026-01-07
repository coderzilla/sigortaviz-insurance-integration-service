import {
  BadRequestException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OtpChallenge } from './entities/otp-challenge.entity';
import {
  OTP_EXPIRES_SECONDS,
  OTP_MAX_ATTEMPTS,
  OTP_RESEND_SECONDS,
  OTP_SECRET,
} from '../common/constants';
import {
  createOtpSalt,
  generateRandomCode,
  hashOtpCode,
  timingSafeEqualStr,
} from '../common/utils/crypto.util';
import { maskIdNumber, maskPhone } from '../common/utils/mask.util';
import { OtpPurpose } from '../common/types/domain-types';
import { UsersService } from '../users/users.service';
import { TokenService } from './token.service';
import type { OtpProvider } from './otp.provider';
import { Customer } from '../users/entities/user.entity';

export interface RequestOtpResult {
  expiresInSeconds: number;
  resendAfterSeconds: number;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(OtpChallenge)
    private readonly otpRepo: Repository<OtpChallenge>,
    @Inject('OTP_PROVIDER') private readonly otpProvider: OtpProvider,
    private readonly usersService: UsersService,
    private readonly tokenService: TokenService,
  ) {}

  async requestOtp(
    phoneNumber: string,
    purpose: OtpPurpose = OtpPurpose.LOGIN,
  ): Promise<RequestOtpResult> {
    const normalizedPhone = phoneNumber.trim();
    const existing = await this.otpRepo.findOne({
      where: { phoneNumber: normalizedPhone, purpose },
    });
    const now = new Date();

    if (
      existing &&
      existing.lastSentAt &&
      now.getTime() - existing.lastSentAt.getTime() <
        OTP_RESEND_SECONDS * 1000
    ) {
      throw new BadRequestException(
        `OTP recently sent. Try again after ${OTP_RESEND_SECONDS} seconds.`,
      );
    }

    const code = generateRandomCode();
    const salt = createOtpSalt();
    const codeHash = hashOtpCode(code, salt, OTP_SECRET);
    const expiresAt = new Date(now.getTime() + OTP_EXPIRES_SECONDS * 1000);

    const challenge =
      existing ??
      this.otpRepo.create({
        phoneNumber: normalizedPhone,
        purpose,
      });
    challenge.codeHash = codeHash;
    challenge.codeSalt = salt;
    challenge.expiresAt = expiresAt;
    challenge.attemptCount = 0;
    challenge.maxAttempts = OTP_MAX_ATTEMPTS;
    challenge.lastSentAt = now;

    await this.otpRepo.save(challenge);
    await this.otpProvider.sendOtp(normalizedPhone, code, purpose);

    console.log(
      `[OTP] challenge created for ${maskPhone(normalizedPhone)} purpose=${purpose}`,
    );
    return {
      expiresInSeconds: OTP_EXPIRES_SECONDS,
      resendAfterSeconds: OTP_RESEND_SECONDS,
    };
  }

  async verifyOtp(
    phoneNumber: string,
    code: string,
    purpose: OtpPurpose = OtpPurpose.LOGIN,
  ): Promise<{ accessToken: string; user: Customer }> {
    const normalizedPhone = phoneNumber.trim();
    const challenge = await this.otpRepo.findOne({
      where: { phoneNumber: normalizedPhone, purpose },
    });
    if (!challenge) {
      throw new UnauthorizedException('OTP not requested');
    }
    const now = new Date();
    if (challenge.expiresAt.getTime() < now.getTime()) {
      throw new UnauthorizedException('OTP expired');
    }
    if (challenge.attemptCount >= challenge.maxAttempts) {
      throw new UnauthorizedException('Max attempts exceeded');
    }

    const attemptedHash = hashOtpCode(code, challenge.codeSalt, OTP_SECRET);
    const match = timingSafeEqualStr(challenge.codeHash, attemptedHash);

    if (!match) {
      challenge.attemptCount += 1;
      await this.otpRepo.save(challenge);
      throw new UnauthorizedException('Invalid code');
    }

    // Reset attempts on success
    challenge.attemptCount = 0;
    await this.otpRepo.save(challenge);

    const user = await this.usersService.findOrCreateByPhone(normalizedPhone);
    if (!user.phoneVerifiedAt) {
      user.phoneVerifiedAt = now;
      await this.usersService.save(user);
    }

    const accessToken = this.tokenService.signAccessToken({
      sub: user.id,
      phoneNumber: user.phoneNumber,
    });

    console.log(
      `[OTP] verified for ${maskPhone(user.phoneNumber)} (user ${maskIdNumber(user.id)})`,
    );
    return { accessToken, user };
  }
}
