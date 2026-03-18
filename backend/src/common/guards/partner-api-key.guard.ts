import {
  Injectable, CanActivate, ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PartnerApiKeyGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const apiKey = request.headers['x-partner-key'];

    if (!apiKey) {
      throw new UnauthorizedException('API key bị thiếu');
    }

    const partner = await this.prisma.partnerKey.findUnique({
      where: { apiKey },
    });

    if (!partner || !partner.isActive) {
      throw new UnauthorizedException('API key không hợp lệ');
    }

    request.partner = partner;
    return true;
  }
}
