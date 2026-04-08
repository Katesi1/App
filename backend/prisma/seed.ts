import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Default Owner account
  const ownerEmail = process.env.OWNER_EMAIL || 'owner@halong24h.vn';
  const ownerPassword = process.env.OWNER_PASSWORD || 'Abcd@1234';
  const ownerName = process.env.OWNER_NAME || 'Owner Admin';

  const existingOwner = await prisma.user.findUnique({ where: { email: ownerEmail } });
  if (!existingOwner) {
    const passwordHash = await bcrypt.hash(ownerPassword, 10);
    await prisma.user.create({
      data: {
        fullName: ownerName,
        email: ownerEmail,
        phone: '0900000000',
        passwordHash,
        role: Role.OWNER,
      },
    });
    console.log(`Owner created`);
    console.log(`  Email    : ${ownerEmail}`);
    console.log(`  Password : ${ownerPassword}`);
  } else {
    console.log('Owner already exists');
  }

  // Default room types
  const defaultRoomTypes = [
    { name: 'Standard', description: 'Phong tieu chuan', basePrice: 300000, maxCapacity: 2 },
    { name: 'Deluxe', description: 'Phong cao cap', basePrice: 500000, maxCapacity: 3 },
    { name: 'Suite', description: 'Phong suite', basePrice: 800000, maxCapacity: 4 },
    { name: 'Family', description: 'Phong gia dinh', basePrice: 700000, maxCapacity: 6 },
  ];

  for (const rt of defaultRoomTypes) {
    await prisma.roomType.upsert({
      where: { name: rt.name },
      update: {},
      create: rt,
    });
  }
  console.log('Room types seeded');

  // Default amenities
  const defaultAmenities = [
    { name: 'WiFi', icon: 'wifi', category: 'connectivity' },
    { name: 'Air Conditioning', icon: 'ac_unit', category: 'comfort' },
    { name: 'TV', icon: 'tv', category: 'entertainment' },
    { name: 'Mini Bar', icon: 'local_bar', category: 'food' },
    { name: 'Hot Water', icon: 'hot_tub', category: 'comfort' },
    { name: 'Balcony', icon: 'balcony', category: 'space' },
    { name: 'Sea View', icon: 'beach_access', category: 'view' },
    { name: 'Parking', icon: 'local_parking', category: 'facility' },
  ];

  for (const amenity of defaultAmenities) {
    await prisma.amenity.upsert({
      where: { name: amenity.name },
      update: {},
      create: amenity,
    });
  }
  console.log('Amenities seeded');

  console.log('Seed completed!');
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
