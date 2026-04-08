import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersRepository } from '../users/users.repository';
import { RedisService } from '../../config/redis.service';
import { LoginDto } from './dto/login.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { Messages } from '../../i18n';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AuthService {
  constructor(
    private usersRepo: UsersRepository,
    private jwtService: JwtService,
    private configService: ConfigService,
    private redisService: RedisService,
  ) {}

  async login(dto: LoginDto, msg: Messages) {
    const user = await this.usersRepo.findByIdentifier(dto.identifier);

    if (!user) {
      throw new UnauthorizedException(msg.auth.invalidCredentials);
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException(msg.auth.invalidCredentials);
    }

    const tokens = await this.generateTokens(user.id, user.email, user.role);

    await this.usersRepo.update(user.id, { lastLoginAt: new Date() });

    const hashedRefresh = await bcrypt.hash(tokens.refreshToken, 10);
    await this.redisService.set(`refresh:${user.id}`, hashedRefresh, 30 * 24 * 3600);

    return {
      message: msg.auth.loginSuccess,
      data: {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: 900,
        user: {
          id: user.id,
          fullName: user.fullName,
          role: user.role,
          propertyId: user.propertyId,
        },
      },
    };
  }

  async refreshToken(refreshToken: string, msg: Messages) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      const user = await this.usersRepo.findRawById(payload.sub);

      if (!user || !user.isActive) {
        throw new ForbiddenException(msg.auth.invalidRefreshToken);
      }

      const storedHash = await this.redisService.get(`refresh:${user.id}`);
      if (!storedHash) throw new ForbiddenException(msg.auth.invalidRefreshToken);

      const isValid = await bcrypt.compare(refreshToken, storedHash);
      if (!isValid) throw new ForbiddenException(msg.auth.invalidRefreshToken);

      const tokens = await this.generateTokens(user.id, user.email, user.role);
      const hashedRefresh = await bcrypt.hash(tokens.refreshToken, 10);
      await this.redisService.set(`refresh:${user.id}`, hashedRefresh, 30 * 24 * 3600);

      return {
        message: msg.auth.refreshSuccess,
        data: { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, expiresIn: 900 },
      };
    } catch (error) {
      if (error instanceof ForbiddenException) throw error;
      throw new ForbiddenException(msg.auth.expiredRefreshToken);
    }
  }

  async logout(userId: string, msg: Messages) {
    await this.redisService.del(`refresh:${userId}`);
    return { message: msg.auth.logoutSuccess, data: null };
  }

  async getProfile(userId: string, msg: Messages) {
    const user = await this.usersRepo.findById(userId);
    return { message: msg.auth.profileSuccess, data: user };
  }

  async forgotPassword(dto: ForgotPasswordDto, msg: Messages) {
    const user = await this.usersRepo.findByIdentifier(dto.identifier);
    if (!user) throw new NotFoundException(msg.auth.accountDisabled);

    const resetToken = uuidv4();
    await this.redisService.set(`reset:${resetToken}`, user.id, 900);

    return { message: msg.auth.forgotPasswordSuccess, data: { resetToken } };
  }

  async resetPassword(dto: ResetPasswordDto, msg: Messages) {
    const userId = await this.redisService.get(`reset:${dto.token}`);
    if (!userId) throw new BadRequestException(msg.auth.invalidResetToken);

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await this.usersRepo.update(userId, { passwordHash });

    await this.redisService.del(`reset:${dto.token}`);
    await this.redisService.del(`refresh:${userId}`);

    return { message: msg.auth.resetPasswordSuccess, data: null };
  }

  private async generateTokens(userId: string, email: string, role: string) {
    const payload = { sub: userId, email, role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_SECRET'),
        expiresIn: 900,
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: '30d',
      }),
    ]);

    return { accessToken, refreshToken };
  }
}
