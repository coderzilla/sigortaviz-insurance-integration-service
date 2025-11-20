// src/quotes/quotes.module.ts
import { Module } from '@nestjs/common';
import { QuotesController } from './quotes.controller';
import { QuotesService } from './quotes.service';
import { CarriersModule } from '../carriers/carriers.module';

@Module({
  imports: [CarriersModule],
  controllers: [QuotesController],
  providers: [QuotesService],
})
export class QuotesModule {}
