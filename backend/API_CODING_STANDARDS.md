# HALONG24H — API Coding Standards

> Tài liệu chuẩn hóa cách viết code cho backend NestJS.
> Mọi dev tham gia dự án **phải đọc và tuân thủ** tài liệu này.

---

## 1. KIẾN TRÚC TỔNG QUAN

### 1.1 Design Pattern: Repository Pattern

```
Request → Controller → Service → Repository → Prisma → PostgreSQL
                                                     ↘ Redis (cache/hold)
                                                     ↘ Cloudinary (images)
```

| Layer | Trách nhiệm | Ví dụ |
|-------|-------------|-------|
| **Controller** | Nhận request, gọi Service, trả response | `rooms.controller.ts` |
| **Service** | Business logic, validation nghiệp vụ, gọi Repository | `rooms.service.ts` |
| **Repository** | Data access, Prisma queries, KHÔNG có business logic | `rooms.repository.ts` |
| **DTO** | Validate input từ client | `create-room.dto.ts` |

### 1.2 Cấu trúc thư mục

```
backend/src/
├── common/                          # DÙNG CHUNG cho tất cả modules
│   ├── decorators/                  # @CurrentUser, @Public, @Roles, @Lang
│   ├── filters/                     # AllExceptionsFilter
│   ├── guards/                      # JwtAuthGuard, RolesGuard
│   ├── interceptors/                # ResponseInterceptor
│   └── repositories/                # BaseRepository (abstract class)
├── config/                          # DÙNG CHUNG - service config bên ngoài
│   ├── redis.service.ts / .module.ts
│   └── cloudinary.service.ts / .module.ts
├── prisma/                          # DÙNG CHUNG - PrismaService global
│   └── prisma.service.ts / .module.ts
├── i18n/                            # DÙNG CHUNG - đa ngôn ngữ (en.ts, vi.ts)
│   └── index.ts
└── modules/                         # RIÊNG - mỗi module độc lập
    ├── auth/
    ├── users/
    ├── properties/
    ├── room-types/
    ├── amenities/
    ├── rooms/
    ├── customers/
    ├── bookings/
    ├── payments/
    ├── notifications/
    └── reports/
```

### 1.3 File dùng CHUNG vs RIÊNG

| File/Folder | Loại | Mục đích |
|------------|------|----------|
| `common/repositories/base.repository.ts` | **CHUNG** | Abstract class cho tất cả repository |
| `common/decorators/*` | **CHUNG** | Decorators dùng ở mọi controller |
| `common/guards/*` | **CHUNG** | Auth & role guards |
| `common/filters/*` | **CHUNG** | Error handling |
| `common/interceptors/*` | **CHUNG** | Response wrapping |
| `config/*` | **CHUNG** | Redis, Cloudinary |
| `prisma/*` | **CHUNG** | Database access layer |
| `i18n/*` | **CHUNG** | Message translation |
| `modules/<name>/*.repository.ts` | **RIÊNG** | Data access cho module đó |
| `modules/<name>/*.service.ts` | **RIÊNG** | Business logic cho module đó |
| `modules/<name>/*.controller.ts` | **RIÊNG** | HTTP endpoints cho module đó |
| `modules/<name>/dto/*.dto.ts` | **RIÊNG** | Input validation cho module đó |

---

## 2. CẤU TRÚC MỖI MODULE

Khi tạo module mới, **bắt buộc** phải có đủ các file sau:

```
modules/<tên>/
├── dto/
│   ├── create-<tên>.dto.ts       # DTO cho POST
│   └── update-<tên>.dto.ts       # DTO cho PUT/PATCH
├── <tên>.repository.ts            # Data access layer
├── <tên>.service.ts               # Business logic
├── <tên>.controller.ts            # HTTP endpoints
└── <tên>.module.ts                # NestJS module registration
```

---

## 3. REPOSITORY — Data Access Layer

### 3.1 Kế thừa BaseRepository

```typescript
// ĐÚNG
@Injectable()
export class RoomsRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findById(id: string) {
    return this.prisma.room.findUnique({
      where: { id },
      include: { property: true, roomType: true },
    });
  }
}
```

### 3.2 Quy tắc Repository

| Quy tắc | Giải thích |
|---------|------------|
| **KHÔNG** chứa business logic | Không throw exception nghiệp vụ, không validate |
| **KHÔNG** import Service khác | Repository chỉ biết Prisma |
| **LUÔN** dùng `select` hoặc `include` cụ thể | Tránh leak data nhạy cảm (passwordHash) |
| **LUÔN** export trong module | Để module khác có thể inject |
| Đặt tên method rõ ràng | `findById`, `findByEmail`, `findRaw`, `countActiveBookings` |

### 3.3 Naming convention cho Repository methods

```
findAll(where)           → Trả list, có thể filter
findById(id)             → Trả entity đầy đủ với relations
findRaw(id)              → Trả entity thô không relations
findByXxx(value)         → Tìm theo field cụ thể
create(data)             → Tạo mới
update(id, data)         → Cập nhật
delete(id)               → Hard delete
softDelete(id)           → Set isActive = false
countXxx(...)            → Đếm records
```

### 3.4 Pagination

```typescript
// Dùng helper từ BaseRepository
async findAll(where: any, pagination?: PaginationParams) {
  const { skip, take, page, limit } = this.paginate(pagination);

  const [data, total] = await Promise.all([
    this.prisma.room.findMany({ where, skip, take }),
    this.prisma.room.count({ where }),
  ]);

  return { data, meta: { page, limit, total } };
}
```

---

## 4. SERVICE — Business Logic

### 4.1 Quy tắc Service

```typescript
// ĐÚNG: Service inject Repository, KHÔNG inject PrismaService
@Injectable()
export class RoomsService {
  constructor(
    private repo: RoomsRepository,           // ← Repository của module này
    private propertiesRepo: PropertiesRepository, // ← Repository module khác (nếu cần)
    private cloudinary: CloudinaryService,   // ← Config service (nếu cần)
  ) {}
}

// SAI: Service inject PrismaService trực tiếp
@Injectable()
export class RoomsService {
  constructor(private prisma: PrismaService) {} // ❌ KHÔNG LÀM THẾ NÀY
}
```

### 4.2 Response format chuẩn

```typescript
// ĐÚNG: Luôn return { message, data } (hoặc { message, data, meta } cho list)
async findAll() {
  const result = await this.repo.findAll(where, { page, limit });
  return { message: msg.rooms.listSuccess, data: result.data, meta: result.meta };
}

async findOne(id: string) {
  const room = await this.repo.findById(id);
  if (!room) throw new NotFoundException(msg.rooms.notFound);
  return { message: msg.rooms.getSuccess, data: room };
}

// SAI: Return thẳng data
async findAll() {
  return this.repo.findAll(); // ❌
}
```

### 4.3 Error Handling

```typescript
// ĐÚNG: Dùng NestJS built-in exceptions
throw new NotFoundException(msg.rooms.notFound);
throw new ForbiddenException(msg.properties.forbidden);
throw new ConflictException(msg.customers.phoneDuplicate);
throw new BadRequestException(msg.bookings.checkoutBeforeCheckin);

// SAI: Throw Error thường
throw new Error('Not found'); // ❌
```

### 4.4 Message luôn lấy từ i18n

```typescript
// ĐÚNG
throw new NotFoundException(msg.rooms.notFound);
return { message: msg.rooms.createSuccess, data: room };

// SAI: Hardcode string
throw new NotFoundException('Phòng không tồn tại'); // ❌
return { message: 'Tạo phòng thành công', data: room }; // ❌
```

---

## 5. CONTROLLER — HTTP Endpoints

### 5.1 Template chuẩn

```typescript
@ApiTags('Rooms')                          // Swagger group
@ApiBearerAuth('access-token')             // Auth header
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('rooms')
@UseGuards(JwtAuthGuard, RolesGuard)       // Auth guard
export class RoomsController {
  constructor(private roomsService: RoomsService) {}

  @Get()
  @ApiOperation({ summary: 'Mo ta ngan' })
  findAll(@CurrentUser() user: any, @Lang() msg: Messages) {
    return this.roomsService.findAll(user, msg);
  }

  @Post()
  @Roles(Role.OWNER, Role.MANAGER)         // Phân quyền
  @ApiOperation({ summary: 'Tao phong moi' })
  create(@Body() dto: CreateRoomDto, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.roomsService.create(dto, user, msg);
  }
}
```

### 5.2 Quy tắc Controller

| Quy tắc | Giải thích |
|---------|------------|
| **KHÔNG** chứa business logic | Controller chỉ gọi Service |
| **LUÔN** có `@ApiTags`, `@ApiOperation` | Swagger documentation |
| **LUÔN** dùng `@Roles()` nếu endpoint cần phân quyền | |
| **LUÔN** truyền `@Lang() msg` vào service | Hỗ trợ đa ngôn ngữ |
| **LUÔN** truyền `@CurrentUser()` nếu cần kiểm tra quyền | |

---

## 6. DTO — Data Transfer Object

### 6.1 Validate đầy đủ

```typescript
// ĐÚNG: Mọi field đều có decorator validate
export class CreateRoomDto {
  @ApiProperty({ description: 'ID co so luu tru' })
  @IsUUID('4', { message: 'propertyId khong hop le' })
  @IsNotEmpty({ message: 'propertyId khong duoc de trong' })
  propertyId: string;

  @ApiProperty({ description: 'Gia 1 dem (VND)', example: 500000 })
  @IsNumber({}, { message: 'Gia phai la so' })
  @Min(0, { message: 'Gia phai >= 0' })
  @Type(() => Number)
  pricePerNight: number;

  @ApiPropertyOptional({ description: 'Mo ta phong' })
  @IsOptional()
  @IsString()
  description?: string;
}

// SAI: Không validate
export class CreateRoomDto {
  propertyId: string;   // ❌ thiếu decorator
  pricePerNight: number; // ❌ thiếu @IsNumber, @Min
}
```

### 6.2 Quy tắc DTO

- **Mọi field bắt buộc**: `@IsNotEmpty()` + validator type
- **Mọi field optional**: `@IsOptional()` + validator type
- **Mọi field**: `@ApiProperty()` hoặc `@ApiPropertyOptional()`
- **Number từ query/body**: Luôn dùng `@Type(() => Number)`
- **UUID**: Luôn dùng `@IsUUID('4')`
- **Email**: `@IsEmail()`
- **Phone VN**: `@Matches(/^(0|\+84)[0-9]{9,10}$/)`
- **Date**: `@IsDateString()`

---

## 7. PHÂN QUYỀN (ROLES)

### 7.1 Bảng quyền

| Role | Quyền |
|------|-------|
| **OWNER** | Toàn quyền: quản lý properties, rooms, users, bookings, reports |
| **MANAGER** | Quản lý vận hành: rooms, bookings, customers, payments trong property được gán |
| **SALE** | Tạo/xem bookings, customers trong property được gán |
| **RECEPTIONIST** | Check-in/out, xem bookings trong property được gán |

### 7.2 Access control trong Service

```typescript
// ĐÚNG: Kiểm tra ownership trong service
if (user.role === Role.OWNER && property.ownerId !== user.id) {
  throw new ForbiddenException(msg.properties.forbidden);
}

// ĐÚNG: Filter data theo role
if (user.role === Role.MANAGER) {
  where.propertyId = user.propertyId;
} else if (user.role === Role.OWNER) {
  where.property = { ownerId: user.id };
}
```

---

## 8. DATABASE

### 8.1 Thông tin kết nối

| Thành phần | Cấu hình |
|-----------|----------|
| **Database** | PostgreSQL |
| **ORM** | Prisma |
| **Connection** | `DATABASE_URL` trong `.env` |
| **Cache** | Redis (hold room, refresh token, reset token) |
| **File Storage** | Cloudinary |

### 8.2 Quy tắc Prisma

```typescript
// ĐÚNG: Select cụ thể fields (tránh leak passwordHash)
const user = await this.prisma.user.findUnique({
  where: { id },
  select: { id: true, fullName: true, email: true, role: true },
});

// SAI: Select tất cả
const user = await this.prisma.user.findUnique({ where: { id } }); // ❌ có thể lộ passwordHash
```

### 8.3 Soft Delete

```typescript
// ĐÚNG: Dùng soft delete cho User, Property, Room
await this.repo.softDelete(id); // → isActive: false

// SAI: Hard delete (mất lịch sử)
await this.prisma.room.delete({ where: { id } }); // ❌ chỉ dùng cho Customer, Amenity
```

---

## 9. API RESPONSE FORMAT

### 9.1 Thành công

```json
{
  "success": true,
  "message": "Room list retrieved successfully",
  "data": [ ... ],
  "meta": { "page": 1, "limit": 20, "total": 142 }
}
```

### 9.2 Lỗi

```json
{
  "success": false,
  "error": {
    "code": "HTTP_404",
    "message": "Room not found"
  },
  "path": "/api/v1/rooms/xxx",
  "timestamp": "2026-03-18T10:00:00.000Z"
}
```

### 9.3 HTTP Status Codes

| Code | Khi nào |
|------|---------|
| 200 | GET/PUT/PATCH thành công |
| 201 | POST tạo mới thành công |
| 400 | Validation lỗi, logic sai (checkout < checkin) |
| 401 | Token hết hạn, không hợp lệ |
| 403 | Không có quyền (role/ownership) |
| 404 | Resource không tồn tại |
| 409 | Conflict (phòng đã đặt, email trùng) |
| 500 | Lỗi server |

---

## 10. QUY TRÌNH THÊM TÍNH NĂNG MỚI

### Step-by-step

```
1. Cập nhật Prisma schema (nếu cần bảng/field mới)
   → prisma/schema.prisma
   → npx prisma migrate dev --name <tên>

2. Thêm i18n messages
   → src/i18n/en.ts
   → src/i18n/vi.ts

3. Tạo DTO
   → src/modules/<module>/dto/create-xxx.dto.ts
   → src/modules/<module>/dto/update-xxx.dto.ts

4. Tạo Repository
   → src/modules/<module>/xxx.repository.ts
   → Kế thừa BaseRepository

5. Tạo Service
   → src/modules/<module>/xxx.service.ts
   → Inject Repository (KHÔNG inject PrismaService)

6. Tạo Controller
   → src/modules/<module>/xxx.controller.ts
   → @ApiTags, @Roles, @ApiOperation

7. Đăng ký Module
   → src/modules/<module>/xxx.module.ts
   → providers: [Service, Repository]
   → exports: [Service, Repository]

8. Import vào AppModule
   → src/app.module.ts
```

---

## 11. BẢO MẬT

### 11.1 KHÔNG BAO GIỜ

- Commit `.env` lên git
- Log password / token ra console
- Return `passwordHash` hoặc `refreshToken` trong response
- Dùng `Role.OWNER` mặc định khi tạo user
- Dùng `origin: '*'` trên production

### 11.2 LUÔN LUÔN

- Hash password bằng bcrypt (cost = 10)
- Validate input bằng DTO trước khi vào service
- Kiểm tra ownership trước khi UPDATE/DELETE
- Dùng `@IsUUID()` cho tất cả ID params
- Select cụ thể fields trong Repository (tránh leak data)

### 11.3 Image Upload

- Validate MIME: chỉ `image/jpeg`, `image/png`, `image/webp`
- Giới hạn: 10MB/file, 20 ảnh/phòng
- Upload Cloudinary, KHÔNG lưu file trên server

---

## 12. TÀI KHOẢN MẶC ĐỊNH (Seed)

| Thông tin | Giá trị |
|-----------|---------|
| Email | `owner@halong24h.vn` |
| Password | `Abcd@1234` |
| Role | `OWNER` |

> Đổi password ngay sau khi deploy production.

---

## 13. CHECKLIST TRƯỚC KHI COMMIT

- [ ] `npx tsc --noEmit` — không có TypeScript error
- [ ] DTO validate đầy đủ input (mọi field đều có decorator)
- [ ] Service kiểm tra quyền role + ownership
- [ ] Response đúng format `{ message, data }` hoặc `{ message, data, meta }`
- [ ] Messages lấy từ i18n, không hardcode string
- [ ] Repository không chứa business logic
- [ ] Service không import PrismaService trực tiếp
- [ ] Không có `console.log` debug trong code
- [ ] Không leak passwordHash / sensitive data trong response
