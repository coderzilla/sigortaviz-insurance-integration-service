import { AuthService } from './auth.service';
import { TokenService } from './token.service';
import { OtpPurpose } from '../common/types/domain-types';
import { createInMemoryRepo } from '../test-utils/in-memory-repo';
import { OtpChallenge } from './entities/otp-challenge.entity';

describe('AuthService', () => {
  let service: AuthService;
  let otpRepo: any;
  let usersServiceMock: any;
  let otpProviderMock: any;
  let tokenService: TokenService;
  let lastCode = '';

  beforeEach(() => {
    otpRepo = createInMemoryRepo<OtpChallenge>();
    otpProviderMock = {
      sendOtp: jest.fn(async (_phone: string, code: string) => {
        lastCode = code;
      }),
    };
    usersServiceMock = {
      findOrCreateByPhone: jest.fn(async (phone: string) => ({
        id: 'user-1',
        phoneNumber: phone,
      })),
      save: jest.fn(async (user: any) => user),
    };
    tokenService = new TokenService();
    service = new AuthService(
      otpRepo as any,
      otpProviderMock as any,
      usersServiceMock as any,
      tokenService,
    );
    lastCode = '';
  });

  it('sends and verifies otp', async () => {
    await service.requestOtp('+905551234567', OtpPurpose.LOGIN);
    expect(otpProviderMock.sendOtp).toHaveBeenCalled();
    const result = await service.verifyOtp('+905551234567', lastCode);
    expect(result.accessToken).toBeDefined();
    expect(result.user.phoneNumber).toEqual('+905551234567');
  });

  it('rejects wrong code and increments attempts', async () => {
    await service.requestOtp('+905551234568', OtpPurpose.LOGIN);
    await expect(
      service.verifyOtp('+905551234568', '000000'),
    ).rejects.toThrow('Invalid code');
    const challenge = otpRepo.items[0];
    expect(challenge.attemptCount).toBe(1);
  });

  it('rejects expired code', async () => {
    await service.requestOtp('+905551234569', OtpPurpose.LOGIN);
    otpRepo.items[0].expiresAt = new Date(Date.now() - 1000);
    await expect(
      service.verifyOtp('+905551234569', lastCode),
    ).rejects.toThrow('OTP expired');
  });

  it('rate limits repeated requests', async () => {
    await service.requestOtp('+905551234570', OtpPurpose.LOGIN);
    await expect(
      service.requestOtp('+905551234570', OtpPurpose.LOGIN),
    ).rejects.toThrow('OTP recently sent');
  });

  it('enforces max attempts', async () => {
    await service.requestOtp('+905551234571', OtpPurpose.LOGIN);
    for (let i = 0; i < 5; i++) {
      await expect(
        service.verifyOtp('+905551234571', '999999'),
      ).rejects.toThrow('Invalid code');
    }
    await expect(
      service.verifyOtp('+905551234571', '999999'),
    ).rejects.toThrow('Max attempts exceeded');
  });
});
