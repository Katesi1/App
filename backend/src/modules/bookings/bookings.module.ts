import { Module } from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { BookingsRepository } from './bookings.repository';
import { RoomsModule } from '../rooms/rooms.module';
import { CustomersModule } from '../customers/customers.module';

@Module({
  imports: [RoomsModule, CustomersModule],
  controllers: [BookingsController],
  providers: [BookingsService, BookingsRepository],
  exports: [BookingsService, BookingsRepository],
})
export class BookingsModule {}
