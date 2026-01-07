import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { QuoteSession } from './quote-session.entity';
import { AssetType } from '../../common/types/domain-types';

@Entity('quote_session_asset_snapshots')
export class QuoteSessionAssetSnapshot {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  quoteSessionId: string;

  @ManyToOne(() => QuoteSession, (session) => session.assetSnapshots, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'quoteSessionId' })
  quoteSession: QuoteSession;

  @Column({ type: 'enum', enum: AssetType })
  assetType: AssetType;

  @Column({ type: 'char', length: 36, nullable: true })
  assetId?: string | null;

  @Column({ type: 'json' })
  snapshotJson: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;
}
