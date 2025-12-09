import { Module } from '@nestjs/common';
import { CarriersService } from './carriers.service';
import { CARRIER_ADAPTERS } from './carrier.constants';
import { AllianzAdapter } from './allianz.adapter';
import { AxaAdapter } from './axa.adapter';
import { TurkiyeSigortaPusulaAdapter } from './turkiye-sigorta-pusula.adapter';
import { OrientSigortaAdapter } from './orient-sigorta.adapter';
import { QuickSigortaAdapter } from './quick-sigorta.adapter';

@Module({
  providers: [
    AllianzAdapter,
    AxaAdapter,
    TurkiyeSigortaPusulaAdapter,
    OrientSigortaAdapter,
    QuickSigortaAdapter,
    {
      provide: CARRIER_ADAPTERS,
      useFactory: (
        allianz: AllianzAdapter,
        axa: AxaAdapter,
        pusula: TurkiyeSigortaPusulaAdapter,
        orient: OrientSigortaAdapter,
        quick: QuickSigortaAdapter,
      ) => [allianz, axa, pusula, orient, quick],
      inject: [
        AllianzAdapter,
        AxaAdapter,
        TurkiyeSigortaPusulaAdapter,
        OrientSigortaAdapter,
        QuickSigortaAdapter,
      ],
    },
    CarriersService,
  ],
  exports: [CarriersService], // so other modules (QuotesModule) can use it
})
export class CarriersModule {}
