import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { QuoteSession } from './quote-session.entity';

@Entity('quote_session_step_events')
export class QuoteSessionStepEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'char', length: 36 })
  quoteSessionId: string;

  @ManyToOne(() => QuoteSession, (session) => session.stepEvents, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'quoteSessionId' })
  quoteSession: QuoteSession;

  @Column({ type: 'int' })
  step: number;

  @Column({ type: 'json' })
  payloadJson: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;
}
