import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';

export class CreateAmenityDto {
  @ApiProperty({ description: 'Ten tien nghi', example: 'WiFi' })
  @IsString()
  @IsNotEmpty({ message: 'Ten tien nghi khong duoc de trong' })
  @MaxLength(50, { message: 'Ten tien nghi toi da 50 ky tu' })
  name: string;

  @ApiPropertyOptional({ description: 'Icon tien nghi', example: 'wifi' })
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiPropertyOptional({ description: 'Danh muc', example: 'connectivity' })
  @IsOptional()
  @IsString()
  category?: string;
}
