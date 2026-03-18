import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ForgotPasswordDto {
  @ApiProperty({ description: 'Email hoac so dien thoai', example: 'admin@halong24h.vn' })
  @IsString()
  @IsNotEmpty({ message: 'Email hoac so dien thoai khong duoc de trong' })
  identifier: string;
}
