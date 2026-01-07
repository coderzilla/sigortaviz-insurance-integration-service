import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { QuoteSession } from './entities/quote-session.entity';
import { QuoteSessionStepEvent } from './entities/quote-session-step-event.entity';
import { CreateQuoteSessionDto } from './dtos/create-quote-session.dto';
import { UpdateQuoteSessionStepDto } from './dtos/update-quote-session-step.dto';
import { UsersService } from '../users/users.service';
import { TokenService, AccessTokenPayload } from '../auth/token.service';
import { deepMerge } from '../common/utils/crypto.util';
import { QUOTE_SESSION_TTL_MINUTES } from '../common/constants';
import { QuoteSessionStatus } from '../common/types/domain-types';
import { Identity } from '../users/entities/identity.entity';
import { Customer } from '../users/entities/user.entity';

@Injectable()
export class QuoteSessionsService {
  constructor(
    @InjectRepository(QuoteSession)
    private readonly quoteSessionRepo: Repository<QuoteSession>,
    @InjectRepository(QuoteSessionStepEvent)
    private readonly stepEventRepo: Repository<QuoteSessionStepEvent>,
    @InjectRepository(Identity)
    private readonly identityRepo: Repository<Identity>,
    @InjectRepository(Customer)
    private readonly userRepo: Repository<Customer>,
    private readonly usersService: UsersService,
    private readonly tokenService: TokenService,
  ) {}

  async createSession(
    dto: CreateQuoteSessionDto,
    userPayload?: AccessTokenPayload,
  ): Promise<{ session: QuoteSession; leadToken?: string }> {
    const now = new Date();
    const user = userPayload
      ? await this.usersService.getUserById(userPayload.sub)
      : await this.usersService.findOrCreateByPhone(dto.phoneNumber);

    if (dto.idempotencyKey) {
      const existing = await this.quoteSessionRepo.findOne({
        where: { idempotencyKey: dto.idempotencyKey },
      });
      if (
        existing &&
        ((userPayload && existing.userId === user.id) ||
          (!userPayload && existing.phoneNumber === dto.phoneNumber))
      ) {
        const leadToken = !userPayload
          ? this.tokenService.signLeadToken({
              sub: user.id,
              phoneNumber: dto.phoneNumber,
              sessionId: existing.id,
              productCode: existing.productCode,
            })
          : undefined;
        return { session: existing, leadToken };
      }
    }

    const identity = await this.usersService.ensureIdentity(user, dto.idNumber);
    const expiresAt = new Date(
      now.getTime() + QUOTE_SESSION_TTL_MINUTES * 60 * 1000,
    );
    const stepPayload = { phoneNumber: dto.phoneNumber, idNumber: dto.idNumber };

    const session = this.quoteSessionRepo.create({
      userId: user.id,
      phoneNumber: dto.phoneNumber,
      identityId: identity.id,
      productCode: dto.productCode,
      currentStep: 1,
      status: QuoteSessionStatus.IN_PROGRESS,
      stepDataJson: stepPayload,
      leadIdentitySnapshotJson: stepPayload,
      idempotencyKey: dto.idempotencyKey ?? null,
      expiresAt,
    });
    const saved = await this.quoteSessionRepo.save(session);

    const event = this.stepEventRepo.create({
      quoteSessionId: saved.id,
      step: 1,
      payloadJson: stepPayload,
    });
    await this.stepEventRepo.save(event);

    const leadToken = !userPayload
      ? this.tokenService.signLeadToken({
          sub: user.id,
          phoneNumber: dto.phoneNumber,
          sessionId: saved.id,
          productCode: saved.productCode,
          identityId: identity.id,
        })
      : undefined;

    return { session: saved, leadToken };
  }

  async updateStep(
    sessionId: string,
    dto: UpdateQuoteSessionStepDto,
    userPayload?: AccessTokenPayload,
    leadToken?: string,
  ): Promise<QuoteSession> {
    const session = await this.quoteSessionRepo.findOne({
      where: { id: sessionId },
    });
    if (!session) throw new NotFoundException('Quote session not found');

    await this.ensureNotExpired(session);

    if (userPayload) {
      if (session.userId !== userPayload.sub) {
        throw new ForbiddenException('Session does not belong to user');
      }
    } else if (leadToken) {
      const tokenPayload = this.tokenService.verifyLeadToken(leadToken);
      if (
        tokenPayload.sessionId !== session.id ||
        tokenPayload.phoneNumber !== session.phoneNumber
      ) {
        throw new UnauthorizedException('Lead token invalid for this session');
      }
    } else {
      throw new UnauthorizedException('Authentication required');
    }

    const event = this.stepEventRepo.create({
      quoteSessionId: session.id,
      step: dto.step,
      payloadJson: dto.payload,
    });
    await this.stepEventRepo.save(event);

    const merged = deepMerge(session.stepDataJson ?? {}, dto.payload);
    session.stepDataJson = merged;
    session.currentStep = dto.step;

    if (dto.payload.birthDate || dto.payload.fullName) {
      await this.updateIdentityFromPayload(session, dto.payload);
    }
    if (dto.payload.email) {
      await this.updateUserEmail(session, dto.payload.email);
    }

    return this.quoteSessionRepo.save(session);
  }

  private async ensureNotExpired(session: QuoteSession) {
    if (session.expiresAt && session.expiresAt.getTime() < Date.now()) {
      session.status = QuoteSessionStatus.EXPIRED;
      await this.quoteSessionRepo.save(session);
      throw new BadRequestException('Quote session expired');
    }
  }

  private async updateIdentityFromPayload(
    session: QuoteSession,
    payload: Record<string, any>,
  ) {
    if (!session.identityId) return;
    const identity = await this.identityRepo.findOne({
      where: { id: session.identityId },
    });
    if (!identity) return;
    if (payload.birthDate) {
      const birth = new Date(payload.birthDate);
      if (!Number.isNaN(birth.getTime())) {
        identity.birthDate = birth;
      }
    }
    if (payload.fullName) {
      identity.fullName = payload.fullName;
    }
    await this.identityRepo.save(identity);
  }

  private async updateUserEmail(session: QuoteSession, email: string) {
    if (!session.userId) return;
    const user = await this.userRepo.findOne({ where: { id: session.userId } });
    if (!user) return;
    user.email = email;
    user.emailVerifiedAt = null;
    await this.userRepo.save(user);
  }
}
