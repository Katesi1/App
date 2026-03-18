import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, MinLength, IsEnum, IsOptional, IsEmail, Matches, IsUUID } from 'class-validator';
import { Role } from '@prisma/client';

export class CreateUserDto {
  @ApiProperty({ description: 'Ho va ten' })
  @IsString()
  @IsNotEmpty({ message: 'Ho ten khong duoc de trong' })
  fullName: string;

  @ApiProperty({ example: 'user@halong24h.vn', description: 'Email dang nhap (unique)' })
  @IsEmail({}, { message: 'Email khong hop le' })
  @IsNotEmpty({ message: 'Email khong duoc de trong' })
  email: string;

  @ApiPropertyOptional({ example: '0900000000', description: 'So dien thoai' })
  @IsOptional()
  @IsString()
  @Matches(/^(0|\+84)[0-9]{9}$/, { message: 'So dien thoai khong hop le' })
  phone?: string;

  @ApiProperty({ minLength: 6, description: 'Mat khau (toi thieu 6 ky tu)' })
  @IsString()
  @IsNotEmpty({ message: 'Mat khau khong duoc de trong' })
  @MinLength(6, { message: 'Mat khau toi thieu 6 ky tu' })
  password: string;

  @ApiProperty({ enum: Role, description: 'Vai tro' })
  @IsEnum(Role, { message: 'Role khong hop le (OWNER, MANAGER, SALE, RECEPTIONIST)' })
  role: Role;

  @ApiPropertyOptional({ description: 'ID co so luu tru (bat buoc voi MANAGER/SALE/RECEPTIONIST)' })
  @IsOptional()
  @IsUUID('4', { message: 'propertyId khong hop le' })
  propertyId?: string;
}
