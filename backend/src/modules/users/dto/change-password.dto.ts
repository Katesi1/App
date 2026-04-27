import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class ChangePasswordDto {
  @ApiProperty({ description: 'Mat khau hien tai' })
  @IsString()
  @IsNotEmpty({ message: 'Mat khau hien tai khong duoc de trong' })
  currentPassword: string;

  @ApiProperty({ description: 'Mat khau moi (toi thieu 6 ky tu)' })
  @IsString()
  @IsNotEmpty({ message: 'Mat khau moi khong duoc de trong' })
  @MinLength(6, { message: 'Mat khau moi toi thieu 6 ky tu' })
  newPassword: string;
}
