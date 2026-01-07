import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { InitAuthQuoteSession1710000000000 } from './migrations/1710000000000-init-auth-quote-session';
import { Customer } from './users/entities/user.entity';
import { Identity } from './users/entities/identity.entity';
import { QuoteSession } from './quote-sessions/entities/quote-session.entity';
import { QuoteSessionStepEvent } from './quote-sessions/entities/quote-session-step-event.entity';
import { QuoteSessionAssetSnapshot } from './quote-sessions/entities/quote-session-asset-snapshot.entity';
import { VehicleAsset } from './quote-sessions/entities/vehicle-asset.entity';
import { PropertyAsset } from './quote-sessions/entities/property-asset.entity';
import { OtpChallenge } from './auth/entities/otp-challenge.entity';
import { Product } from './products/entities/product.entity';
import { Carrier } from './products/entities/carrier.entity';
import { CarrierProduct } from './products/entities/carrier-product.entity';
import { CarrierProductFieldSet } from './products/entities/carrier-product-field-set.entity';
import { CarrierProductField } from './products/entities/carrier-product-field.entity';
import { CarrierFieldMapping } from './products/entities/carrier-field-mapping.entity';

const AppDataSource = new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST ?? '127.0.0.1',
  port: Number(process.env.DB_PORT ?? 8889),
  username: process.env.DB_USER ?? 'root',
  password: process.env.DB_PASS ?? 'root',
  database: process.env.DB_NAME ?? 'sigortavizz',
  entities: [
    Customer,
    Identity,
    QuoteSession,
    QuoteSessionStepEvent,
    QuoteSessionAssetSnapshot,
    VehicleAsset,
    PropertyAsset,
    OtpChallenge,
    Product,
    Carrier,
    CarrierProduct,
    CarrierProductFieldSet,
    CarrierProductField,
    CarrierFieldMapping,
  ],
  migrations: [InitAuthQuoteSession1710000000000],
  migrationsTableName: 'typeorm_migrations',
  synchronize: false,
});

export default AppDataSource;
