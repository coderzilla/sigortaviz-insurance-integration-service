import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Customer } from './entities/user.entity';
import { Identity } from './entities/identity.entity';
import { QuoteSession } from '../quote-sessions/entities/quote-session.entity';
import { ID_HASH_SECRET } from '../common/constants';
import { hashIdNumber } from '../common/utils/crypto.util';
import { UserStatus } from '../common/types/domain-types';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(Customer)
    private readonly userRepo: Repository<Customer>,
    @InjectRepository(Identity)
    private readonly identityRepo: Repository<Identity>,
    @InjectRepository(QuoteSession)
    private readonly quoteSessionRepo: Repository<QuoteSession>,
  ) {}

  async findOrCreateByPhone(phoneNumber: string): Promise<Customer> {
    const existing = await this.userRepo.findOne({
      where: { phoneNumber },
    });
    if (existing) return existing;
    const created = this.userRepo.create({
      phoneNumber,
      status: UserStatus.ACTIVE,
    });
    return this.userRepo.save(created);
  }

  async save(user: Customer): Promise<Customer> {
    return this.userRepo.save(user);
  }

  async getUserById(userId: string): Promise<Customer> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async getUserWithRelations(userId: string): Promise<Customer & {
    identities: Identity[];
    quoteSessions: QuoteSession[];
  }> {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: ['identities'],
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const recentSessions = await this.quoteSessionRepo.find({
      where: { userId },
      order: { updatedAt: 'DESC' },
      take: 5,
    });
    return { ...user, quoteSessions: recentSessions } as any;
  }

  async ensureIdentity(
    user: Customer,
    idNumber: string,
    birthDate?: Date | null,
    fullName?: string | null,
  ): Promise<Identity> {
    const idNumberHash = hashIdNumber(idNumber, ID_HASH_SECRET);
    let identity = await this.identityRepo.findOne({
      where: { userId: user.id, idNumberHash },
    });
    if (!identity) {
      const existingCount = await this.identityRepo.count({
        where: { userId: user.id },
      });
      identity = this.identityRepo.create({
        userId: user.id,
        idNumber,
        idNumberHash,
        birthDate: birthDate ?? null,
        fullName: fullName ?? null,
        isPreferred: existingCount === 0,
      });
    } else {
      if (birthDate) identity.birthDate = birthDate;
      if (fullName) identity.fullName = fullName;
    }
    return this.identityRepo.save(identity);
  }

  async updatePreferredIdentity(userId: string, identityId: string) {
    const identities = await this.identityRepo.find({
      where: { userId },
    });
    await Promise.all(
      identities.map((identity) => {
        identity.isPreferred = identity.id === identityId;
        return this.identityRepo.save(identity);
      }),
    );
  }

  async anonymizeUser(userId: string): Promise<void> {
    const user = await this.getUserById(userId);
    const anonymizedPhone = `deleted-${user.id.slice(0, 8)}`;
    user.phoneNumber = anonymizedPhone;
    user.email = null;
    user.phoneVerifiedAt = null;
    user.emailVerifiedAt = null;
    user.status = UserStatus.DELETED;
    user.anonymizedAt = new Date();
    await this.userRepo.save(user);

    const identities = await this.identityRepo.find({ where: { userId } });
    for (const identity of identities) {
      identity.idNumber = '';
      identity.idNumberHash = hashIdNumber(
        `anonymized-${identity.id}`,
        ID_HASH_SECRET,
      );
      identity.fullName = null;
      identity.birthDate = null;
      await this.identityRepo.save(identity);
    }
  }
}
