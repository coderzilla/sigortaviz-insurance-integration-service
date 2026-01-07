import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QuoteSessionsService } from './quote-sessions.service';
import { QuoteSessionsController } from './quote-sessions.controller';
import { QuoteSession } from './entities/quote-session.entity';
import { QuoteSessionStepEvent } from './entities/quote-session-step-event.entity';
import { QuoteSessionAssetSnapshot } from './entities/quote-session-asset-snapshot.entity';
import { VehicleAsset } from './entities/vehicle-asset.entity';
import { PropertyAsset } from './entities/property-asset.entity';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';
import { AssetsService } from './assets.service';
import { AssetsController } from './assets.controller';
import { Identity } from '../users/entities/identity.entity';
import { Customer } from '../users/entities/user.entity';

@Module({
  imports: [
    UsersModule,
    AuthModule,
    TypeOrmModule.forFeature([
      QuoteSession,
      QuoteSessionStepEvent,
      QuoteSessionAssetSnapshot,
      VehicleAsset,
      PropertyAsset,
      Identity,
      Customer,
    ]),
  ],
  providers: [QuoteSessionsService, AssetsService],
  controllers: [QuoteSessionsController, AssetsController],
  exports: [QuoteSessionsService],
})
export class QuoteSessionsModule {}
