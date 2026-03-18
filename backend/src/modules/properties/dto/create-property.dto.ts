import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsEmail, IsEnum, Matches, MaxLength } from 'class-validator';
import { PropertyType } from '@prisma/client';

export class CreatePropertyDto {
  @ApiProperty({ description: 'Ten co so luu tru', maxLength: 100 })
  @IsString()
  @IsNotEmpty({ message: 'Ten co so khong duoc de trong' })
  @MaxLength(100, { message: 'Ten co so toi da 100 ky tu' })
  name: string;

  @ApiProperty({ description: 'Dia chi day du' })
  @IsString()
  @IsNotEmpty({ message: 'Dia chi khong duoc de trong' })
  address: string;

  @ApiPropertyOptional({ description: 'Thanh pho', default: 'Ha Long' })
  @IsOptional()
  @IsString()
  @MaxLength(50, { message: 'Thanh pho toi da 50 ky tu' })
  city?: string;

  @ApiPropertyOptional({ description: 'So dien thoai lien he' })
  @IsOptional()
  @IsString()
  @Matches(/^(0|\+84)[0-9]{9,10}$/, { message: 'So dien thoai khong hop le' })
  phone?: string;

  @ApiPropertyOptional({ description: 'Email lien he' })
  @IsOptional()
  @IsEmail({}, { message: 'Email khong hop le' })
  email?: string;

  @ApiProperty({ enum: PropertyType, description: 'Loai co so luu tru' })
  @IsEnum(PropertyType, { message: 'Loai co so khong hop le (HOTEL, HOMESTAY, VILLA, RESORT)' })
  type: PropertyType;

  @ApiPropertyOptional({ description: 'Mo ta gioi thieu' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'URL logo co so' })
  @IsOptional()
  @IsString()
  logoUrl?: string;
}
