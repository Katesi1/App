import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsInt, Min, IsNumber, IsUUID, IsArray, MaxLength } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateRoomDto {
  @ApiProperty({ description: 'ID co so luu tru' })
  @IsUUID('4', { message: 'propertyId khong hop le' })
  @IsNotEmpty({ message: 'propertyId khong duoc de trong' })
  propertyId: string;

  @ApiProperty({ description: 'ID loai phong' })
  @IsUUID('4', { message: 'roomTypeId khong hop le' })
  @IsNotEmpty({ message: 'roomTypeId khong duoc de trong' })
  roomTypeId: string;

  @ApiProperty({ description: 'Ten/so phong', example: 'P.101' })
  @IsString()
  @IsNotEmpty({ message: 'Ten phong khong duoc de trong' })
  @MaxLength(50, { message: 'Ten phong toi da 50 ky tu' })
  name: string;

  @ApiPropertyOptional({ description: 'Tang', default: 1 })
  @IsOptional()
  @IsInt({ message: 'Tang phai la so nguyen' })
  @Min(0, { message: 'Tang phai >= 0' })
  @Type(() => Number)
  floor?: number;

  @ApiProperty({ description: 'So khach toi da', default: 2 })
  @IsInt({ message: 'Suc chua phai la so nguyen' })
  @Min(1, { message: 'Suc chua toi thieu 1' })
  @Type(() => Number)
  capacity: number;

  @ApiPropertyOptional({ description: 'Dien tich phong (m2)' })
  @IsOptional()
  @IsNumber({}, { message: 'Dien tich phai la so' })
  @Min(0)
  @Type(() => Number)
  areaSqm?: number;

  @ApiProperty({ description: 'Gia 1 dem (VND)', example: 500000 })
  @IsNumber({}, { message: 'Gia phai la so' })
  @Min(0, { message: 'Gia phai >= 0' })
  @Type(() => Number)
  pricePerNight: number;

  @ApiPropertyOptional({ description: 'Gia cuoi tuan (VND)' })
  @IsOptional()
  @IsNumber({}, { message: 'Gia cuoi tuan phai la so' })
  @Min(0)
  @Type(() => Number)
  weekendPrice?: number;

  @ApiPropertyOptional({ description: 'Mo ta phong' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Ghi chu noi bo' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Danh sach amenity IDs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true, message: 'Amenity ID khong hop le' })
  amenityIds?: string[];
}
