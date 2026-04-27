import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, Min, IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { Type } from 'class-transformer';
import { PaymentMethod, PaymentType } from '@prisma/client';

export class CreatePaymentDto {
  @ApiProperty({ description: 'ID booking' })
  @IsUUID('4', { message: 'bookingId khong hop le' })
  @IsNotEmpty({ message: 'bookingId khong duoc de trong' })
  bookingId: string;

  @ApiProperty({ description: 'So tien giao dich (VND)', example: 500000 })
  @IsNumber()
  @Min(0, { message: 'So tien phai >= 0' })
  @Type(() => Number)
  amount: number;

  @ApiProperty({ enum: PaymentMethod, default: 'CASH' })
  @IsEnum(PaymentMethod, { message: 'Phuong thuc thanh toan khong hop le' })
  method: PaymentMethod;

  @ApiProperty({ enum: PaymentType, default: 'FULL_PAYMENT' })
  @IsEnum(PaymentType, { message: 'Loai thanh toan khong hop le' })
  type: PaymentType;

  @ApiPropertyOptional({ description: 'Ma giao dich ngan hang / vi dien tu' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  transactionRef?: string;

  @ApiPropertyOptional({ description: 'Ghi chu giao dich' })
  @IsOptional()
  @IsString()
  note?: string;
}
