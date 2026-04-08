import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsInt, Min, IsNumber, MaxLength } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateRoomTypeDto {
  @ApiProperty({ description: 'Ten loai phong', example: 'Deluxe' })
  @IsString()
  @IsNotEmpty({ message: 'Ten loai phong khong duoc de trong' })
  @MaxLength(50, { message: 'Ten loai phong toi da 50 ky tu' })
  name: string;

  @ApiPropertyOptional({ description: 'Mo ta loai phong' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Gia co ban (VND)', example: 500000 })
  @IsNumber({}, { message: 'Gia co ban phai la so' })
  @Min(0, { message: 'Gia co ban phai >= 0' })
  @Type(() => Number)
  basePrice: number;

  @ApiPropertyOptional({ description: 'Suc chua toi da', default: 2 })
  @IsOptional()
  @IsInt({ message: 'Suc chua phai la so nguyen' })
  @Min(1, { message: 'Suc chua toi thieu 1' })
  @Type(() => Number)
  maxCapacity?: number;
}
