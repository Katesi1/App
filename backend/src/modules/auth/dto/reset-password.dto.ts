import { IsNotEmpty, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResetPasswordDto {
  @ApiProperty({ description: 'Reset token nhan duoc qua email/SMS' })
  @IsString()
  @IsNotEmpty({ message: 'Reset token khong duoc de trong' })
  token: string;

  @ApiProperty({ description: 'Mat khau moi' })
  @IsString()
  @IsNotEmpty({ message: 'Mat khau moi khong duoc de trong' })
  @MinLength(6, { message: 'Mat khau toi thieu 6 ky tu' })
  newPassword: string;
}
