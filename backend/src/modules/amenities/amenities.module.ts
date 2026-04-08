import { Module } from '@nestjs/common';
import { AmenitiesService } from './amenities.service';
import { AmenitiesController } from './amenities.controller';
import { AmenitiesRepository } from './amenities.repository';

@Module({
  controllers: [AmenitiesController],
  providers: [AmenitiesService, AmenitiesRepository],
  exports: [AmenitiesService, AmenitiesRepository],
})
export class AmenitiesModule {}
