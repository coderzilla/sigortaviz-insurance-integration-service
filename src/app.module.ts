import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CoreModule } from './core/core.module';
import { ProductsModule } from './products/products.module';
import { CarriersModule } from './carriers/carriers.module';
import { QuotesModule } from './quotes/quotes.module';

@Module({
  imports: [
    CoreModule,
    // TypeOrmModule.forRoot({
    //   type: 'mysql',
    //   host: process.env.DB_HOST,
    //   port: Number(process.env.DB_PORT ?? 3306),
    //   username: process.env.DB_USER,
    //   password: process.env.DB_PASS,
    //   database: process.env.DB_NAME,
    //   autoLoadEntities: true,
    //   synchronize: true, // enable in dev only
    // }),
    ProductsModule,
    CarriersModule,
    QuotesModule,
  ],
})
export class AppModule {}