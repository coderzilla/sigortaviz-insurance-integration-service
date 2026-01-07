import { QuoteSessionsService } from './quote-sessions.service';
import { QuoteSession } from './entities/quote-session.entity';
import { QuoteSessionStepEvent } from './entities/quote-session-step-event.entity';
import { Identity } from '../users/entities/identity.entity';
import { Customer } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { TokenService } from '../auth/token.service';
import { createInMemoryRepo } from '../test-utils/in-memory-repo';
import { ProductCode, AssetType } from '../common/types/domain-types';
import { AssetsService } from './assets.service';
import { VehicleAsset } from './entities/vehicle-asset.entity';
import { PropertyAsset } from './entities/property-asset.entity';
import { QuoteSessionAssetSnapshot } from './entities/quote-session-asset-snapshot.entity';

describe('QuoteSessionsService', () => {
  let sessionRepo: any;
  let stepRepo: any;
  let identityRepo: any;
  let userRepo: any;
  let usersService: UsersService;
  let tokenService: TokenService;
  let service: QuoteSessionsService;
  let assetsService: AssetsService;
  let vehicleRepo: any;
  let propertyRepo: any;
  let snapshotRepo: any;

  beforeEach(() => {
    sessionRepo = createInMemoryRepo<QuoteSession>();
    stepRepo = createInMemoryRepo<QuoteSessionStepEvent>();
    identityRepo = createInMemoryRepo<Identity>();
    userRepo = createInMemoryRepo<Customer>();
    tokenService = new TokenService();
    usersService = new UsersService(
      userRepo as any,
      identityRepo as any,
      sessionRepo as any,
    );
    service = new QuoteSessionsService(
      sessionRepo as any,
      stepRepo as any,
      identityRepo as any,
      userRepo as any,
      usersService,
      tokenService,
    );
    vehicleRepo = createInMemoryRepo<VehicleAsset>();
    propertyRepo = createInMemoryRepo<PropertyAsset>();
    snapshotRepo = createInMemoryRepo<QuoteSessionAssetSnapshot>();
    assetsService = new AssetsService(
      vehicleRepo as any,
      propertyRepo as any,
      sessionRepo as any,
      snapshotRepo as any,
    );
  });

  it('creates sessions for same phone with different identities', async () => {
    const res1 = await service.createSession({
      phoneNumber: '+905550001111',
      idNumber: '12345678901',
      productCode: ProductCode.TRAFFIC,
    });
    const res2 = await service.createSession({
      phoneNumber: '+905550001111',
      idNumber: '99999999999',
      productCode: ProductCode.TRAFFIC,
    });
    expect(res1.session.id).not.toEqual(res2.session.id);
    expect(identityRepo.items.length).toBe(2);
  });

  it('allows multiple sessions per product', async () => {
    const first = await service.createSession({
      phoneNumber: '+905550002222',
      idNumber: '11111111111',
      productCode: ProductCode.TRAFFIC,
    });
    const second = await service.createSession({
      phoneNumber: '+905550002222',
      idNumber: '11111111111',
      productCode: ProductCode.TRAFFIC,
    });
    expect(first.session.id).not.toEqual(second.session.id);
    expect(sessionRepo.items.length).toBe(2);
  });

  it('merges step payloads and records history', async () => {
    const created = await service.createSession({
      phoneNumber: '+905550003333',
      idNumber: '12312312312',
      productCode: ProductCode.HEALTH,
    });
    const userPayload: any = {
      sub: created.session.userId,
      phoneNumber: created.session.phoneNumber,
      type: 'ACCESS',
      exp: Math.floor(Date.now() / 1000) + 1000,
    };
    await service.updateStep(
      created.session.id,
      { step: 2, payload: { email: 'user@example.com', nested: { a: 1 } } },
      userPayload,
    );
    await service.updateStep(
      created.session.id,
      { step: 3, payload: { nested: { b: 2 } } },
      userPayload,
    );
    const updated = sessionRepo.items.find(
      (s: any) => s.id === created.session.id,
    );
    expect(updated?.stepDataJson?.nested?.a).toBe(1);
    expect(updated?.stepDataJson?.nested?.b).toBe(2);
    expect(stepRepo.items.filter((e: any) => e.quoteSessionId === created.session.id).length).toBe(3); // includes step1
  });

  it('creates asset snapshot from stored asset', async () => {
    const created = await service.createSession({
      phoneNumber: '+905550004444',
      idNumber: '98765432100',
      productCode: ProductCode.CASCO,
    });
    const userPayload: any = {
      sub: created.session.userId,
      phoneNumber: created.session.phoneNumber,
      type: 'ACCESS',
      exp: Math.floor(Date.now() / 1000) + 1000,
    };
    const vehicle = await assetsService.upsertVehicle(created.session.userId!, {
      plate: '34ABC1',
      modelYear: 2020,
      brand: 'Brand',
    });
    const snapshot = await assetsService.createSnapshot(
      created.session.id,
      userPayload,
      { assetType: AssetType.VEHICLE, assetId: vehicle.id },
    );
    expect(snapshot.quoteSessionId).toEqual(created.session.id);
    expect(snapshot.snapshotJson.plate).toEqual('34ABC1');
  });
});
