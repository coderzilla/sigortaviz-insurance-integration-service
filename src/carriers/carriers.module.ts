import { Module } from '@nestjs/common';
import { CarriersService } from './carriers.service';

@Module({
  providers: [CarriersService],
  exports: [CarriersService], // so other modules (QuotesModule) can use it
})
export class CarriersModule {}
