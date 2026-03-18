import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsDateString, IsOptional, IsNumber, Min, IsInt, IsEnum, IsUUID, Matches, MaxLength } from 'class-validator';
import { Type } from 'class-transformer';
import { BookingSource } from '@prisma/client';

export class CreateBookingDto {
  @ApiProperty({ description: 'ID phong' })
  @IsUUID('4', { message: 'roomId khong hop le' })
  @IsNotEmpty({ message: 'roomId khong duoc de trong' })
  roomId: string;

  @ApiProperty({ description: 'Ten khach hang' })
  @IsString()
  @IsNotEmpty({ message: 'Ten khach hang khong duoc de trong' })
  @MaxLength(100)
  customerName: string;

  @ApiProperty({ description: 'So dien thoai khach', example: '0900000001' })
  @IsString()
  @IsNotEmpty({ message: 'So dien thoai khach khong duoc de trong' })
  @Matches(/^(0|\+84)[0-9]{9,10}$/, { message: 'So dien thoai khong hop le' })
  customerPhone: string;

  @ApiProperty({ example: '2026-04-20', description: 'Ngay check-in (YYYY-MM-DD)' })
  @IsDateString({}, { message: 'Ngay check-in khong hop le' })
  checkinDate: string;

  @ApiProperty({ example: '2026-04-22', description: 'Ngay check-out (YYYY-MM-DD)' })
  @IsDateString({}, { message: 'Ngay check-out khong hop le' })
  checkoutDate: string;

  @ApiProperty({ description: 'So luong khach', default: 1 })
  @IsInt({ message: 'So khach phai la so nguyen' })
  @Min(1, { message: 'So khach toi thieu 1' })
  @Type(() => Number)
  guestCount: number;

  @ApiPropertyOptional({ description: 'Tien coc (VND)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  deposit?: number;

  @ApiPropertyOptional({ description: 'Phu phi them (VND)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  extraCharges?: number;

  @ApiPropertyOptional({ description: 'Giam gia (VND)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  discount?: number;

  @ApiPropertyOptional({ enum: BookingSource, default: 'DIRECT' })
  @IsOptional()
  @IsEnum(BookingSource, { message: 'Nguon booking khong hop le' })
  source?: BookingSource;

  @ApiPropertyOptional({ description: 'Ghi chu' })
  @IsOptional()
  @IsString()
  notes?: string;
}
