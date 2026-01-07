import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { OtpPurpose } from '../../common/types/domain-types';

@Entity('otp_challenges')
@Index(['phoneNumber', 'purpose'])
export class OtpChallenge {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 32 })
  phoneNumber: string;

  @Column({ type: 'enum', enum: OtpPurpose, default: OtpPurpose.LOGIN })
  purpose: OtpPurpose;

  @Column({ type: 'varchar', length: 256 })
  codeHash: string;

  @Column({ type: 'varchar', length: 64 })
  codeSalt: string;

  @Column({ type: 'datetime' })
  expiresAt: Date;

  @Column({ type: 'int', default: 0 })
  attemptCount: number;

  @Column({ type: 'int', default: 5 })
  maxAttempts: number;

  @Column({ type: 'datetime' })
  lastSentAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
