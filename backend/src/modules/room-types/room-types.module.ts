import { Module } from '@nestjs/common';
import { RoomTypesService } from './room-types.service';
import { RoomTypesController } from './room-types.controller';
import { RoomTypesRepository } from './room-types.repository';

@Module({
  controllers: [RoomTypesController],
  providers: [RoomTypesService, RoomTypesRepository],
  exports: [RoomTypesService, RoomTypesRepository],
})
export class RoomTypesModule {}
