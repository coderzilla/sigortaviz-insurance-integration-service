import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Customer } from './entities/user.entity';
import { Identity } from './entities/identity.entity';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { QuoteSession } from '../quote-sessions/entities/quote-session.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [forwardRef(() => AuthModule), TypeOrmModule.forFeature([Customer, Identity, QuoteSession])],
  providers: [UsersService],
  controllers: [UsersController],
  exports: [UsersService],
})
export class UsersModule {}
