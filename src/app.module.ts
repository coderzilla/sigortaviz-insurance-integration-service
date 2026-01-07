import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CoreModule } from './core/core.module';
import { ProductsModule } from './products/products.module';
import { CarriersModule } from './carriers/carriers.module';
import { QuotesModule } from './quotes/quotes.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { QuoteSessionsModule } from './quote-sessions/quote-sessions.module';

@Module({
  imports: [
    CoreModule,
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: process.env.DB_HOST ?? '127.0.0.1',
      port: Number(process.env.DB_PORT ?? 8889), // MAMP default port
      username: process.env.DB_USER ?? 'root',
      password: process.env.DB_PASS ?? 'root',
      database: process.env.DB_NAME ?? 'sigorta',
      autoLoadEntities: true,
      synchronize: false, // Dev only; use migrations in production
    }),
    ProductsModule,
    CarriersModule,
    QuotesModule,
    AuthModule,
    UsersModule,
    QuoteSessionsModule,
  ],
})
export class AppModule {}
