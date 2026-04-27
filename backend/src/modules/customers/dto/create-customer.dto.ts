import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsEmail, IsDateString, Matches, MaxLength, IsArray } from 'class-validator';

export class CreateCustomerDto {
  @ApiProperty({ description: 'Ho va ten day du' })
  @IsString()
  @IsNotEmpty({ message: 'Ho ten khong duoc de trong' })
  @MaxLength(100, { message: 'Ho ten toi da 100 ky tu' })
  fullName: string;

  @ApiProperty({ description: 'So dien thoai (unique)', example: '0900000001' })
  @IsString()
  @IsNotEmpty({ message: 'So dien thoai khong duoc de trong' })
  @Matches(/^(0|\+84)[0-9]{9,10}$/, { message: 'So dien thoai khong hop le' })
  phone: string;

  @ApiPropertyOptional({ description: 'Email' })
  @IsOptional()
  @IsEmail({}, { message: 'Email khong hop le' })
  email?: string;

  @ApiPropertyOptional({ description: 'So CCCD/Passport' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  idCard?: string;

  @ApiPropertyOptional({ description: 'Ngay sinh (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString({}, { message: 'Ngay sinh khong hop le' })
  dateOfBirth?: string;

  @ApiPropertyOptional({ description: 'Quoc tich', default: 'Viet Nam' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  nationality?: string;

  @ApiPropertyOptional({ description: 'Dia chi thuong tru' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ description: 'Ghi chu noi bo' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Tags: VIP, Quay lai, Kho tinh...', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}
