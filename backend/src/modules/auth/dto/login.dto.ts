import { IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ description: 'Email hoac so dien thoai', example: 'admin@halong24h.vn' })
  @IsString()
  @IsNotEmpty({ message: 'Email hoac so dien thoai khong duoc de trong' })
  identifier: string;

  @ApiProperty({ description: 'Mat khau', example: 'Abcd@1234' })
  @IsString()
  @IsNotEmpty({ message: 'Mat khau khong duoc de trong' })
  @MinLength(6, { message: 'Mat khau toi thieu 6 ky tu' })
  password: string;

  @ApiProperty({ description: 'FCM token thiet bi', required: false })
  @IsOptional()
  @IsString()
  deviceToken?: string;
}
