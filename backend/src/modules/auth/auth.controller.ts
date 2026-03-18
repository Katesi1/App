import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import type { Messages } from '../../i18n';

@ApiTags('Auth')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Public()
  @Post('login')
  @ApiOperation({ summary: 'Dang nhap bang email/SDT + mat khau' })
  login(@Body() dto: LoginDto, @Lang() msg: Messages) {
    return this.authService.login(dto, msg);
  }

  @Public()
  @Post('refresh-token')
  @ApiOperation({ summary: 'Cap lai access token moi' })
  refresh(@Body() dto: RefreshTokenDto, @Lang() msg: Messages) {
    return this.authService.refreshToken(dto.refreshToken, msg);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Dang xuat, thu hoi refresh token' })
  logout(@CurrentUser('id') userId: string, @Lang() msg: Messages) {
    return this.authService.logout(userId, msg);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Lay thong tin profile user dang dang nhap' })
  getProfile(@CurrentUser('id') userId: string, @Lang() msg: Messages) {
    return this.authService.getProfile(userId, msg);
  }

  @Public()
  @Post('forgot-password')
  @ApiOperation({ summary: 'Gui OTP/link reset mat khau ve email/SDT' })
  forgotPassword(@Body() dto: ForgotPasswordDto, @Lang() msg: Messages) {
    return this.authService.forgotPassword(dto, msg);
  }

  @Public()
  @Post('reset-password')
  @ApiOperation({ summary: 'Dat lai mat khau moi bang token reset' })
  resetPassword(@Body() dto: ResetPasswordDto, @Lang() msg: Messages) {
    return this.authService.resetPassword(dto, msg);
  }
}
