import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { OtpChallenge } from './entities/otp-challenge.entity';
import { ConsoleOtpProvider, OtpProvider } from './otp.provider';
import { UsersModule } from '../users/users.module';
import { TokenService } from './token.service';
import { JwtAuthGuard } from './auth.guard';

@Module({
  imports: [forwardRef(() => UsersModule), TypeOrmModule.forFeature([OtpChallenge])],
  providers: [
    AuthService,
    TokenService,
    JwtAuthGuard,
    ConsoleOtpProvider,
    { provide: 'OTP_PROVIDER', useExisting: ConsoleOtpProvider },
  ],
  controllers: [AuthController],
  exports: [TokenService, JwtAuthGuard, AuthService],
})
export class AuthModule {}
