import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { UpdateUserDto } from './dtos/update-user.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getMe(@CurrentUser() user: any) {
    return this.usersService.getUserWithRelations(user.sub);
  }

  @Patch('me')
  async updateMe(@CurrentUser() user: any, @Body() body: UpdateUserDto) {
    const existing = await this.usersService.getUserById(user.sub);
    if (typeof body.marketingConsent === 'boolean') {
      existing.marketingConsent = body.marketingConsent;
    }
    if (typeof body.kvkkConsent === 'boolean') {
      existing.kvkkConsent = body.kvkkConsent;
    }
    if (body.email && body.email !== existing.email) {
      existing.email = body.email;
      existing.emailVerifiedAt = null;
    }
    await this.usersService.save(existing);
    return this.usersService.getUserWithRelations(user.sub);
  }

  @Delete('me')
  async anonymize(@CurrentUser() user: any) {
    await this.usersService.anonymizeUser(user.sub);
    return { status: 'anonymized' };
  }
}
