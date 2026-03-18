import { PrismaService } from '../../prisma/prisma.service';

export interface PaginationParams {
  page?: number;
  limit?: number;
}

export interface PaginatedResult<T> {
  data: T[];
  meta: { page: number; limit: number; total: number };
}

export abstract class BaseRepository<T = any> {
  constructor(protected readonly prisma: PrismaService) {}

  protected paginate(params?: PaginationParams) {
    const page = params?.page || 1;
    const limit = params?.limit || 20;
    return { skip: (page - 1) * limit, take: limit, page, limit };
  }
}
