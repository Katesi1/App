import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsNumber, Min, IsInt, IsDateString } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateBookingDto {
  @ApiPropertyOptional({ description: 'Ngay check-in (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  checkinDate?: string;

  @ApiPropertyOptional({ description: 'Ngay check-out (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  checkoutDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  guestCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  extraCharges?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  discount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  deposit?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
