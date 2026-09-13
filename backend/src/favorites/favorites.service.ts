import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { Favorite } from './entities/favorite.entity';

// รหัส error ของ postgres ตอนชน unique constraint
const UNIQUE_VIOLATION = '23505';

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof QueryFailedError &&
    (error.driverError as { code?: string })?.code === UNIQUE_VIOLATION
  );
}

@Injectable()
export class FavoritesService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
  ) {}

  findAll(userId: string): Promise<Favorite[]> {
    return this.favoriteRepository.find({
      where: { userId },
      relations: { recipe: { creator: true, categories: true } },
      order: { createdAt: 'DESC' },
    });
  }

  // รายการโปรดของคนอื่นให้ถือว่าไม่มีอยู่
  async findOne(id: string, userId: string): Promise<Favorite> {
    const favorite = await this.favoriteRepository.findOne({
      where: { id, userId },
      relations: { recipe: true },
    });
    if (!favorite)
      throw new NotFoundException(`Favorite with id ${id} not found`);
    return favorite;
  }

  // กดหัวใจสูตรเดิมซ้ำไม่ควรพัง คืนแถวเดิมกลับไปแทนการสร้างซ้ำ
  async create(userId: string, recipeId: string): Promise<Favorite> {
    const existing = await this.favoriteRepository.findOne({
      where: { userId, recipeId },
    });
    if (existing) return existing;

    try {
      return await this.favoriteRepository.save(
        this.favoriteRepository.create({ userId, recipeId }),
      );
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      return this.favoriteRepository.findOneOrFail({
        where: { userId, recipeId },
      });
    }
  }

  async remove(id: string, userId: string): Promise<void> {
    const favorite = await this.findOne(id, userId);
    await this.favoriteRepository.remove(favorite);
  }

  // ฝั่งแอปรู้แค่ว่ากดหัวใจสูตรไหน ไม่รู้ favoriteId จึงลบด้วยคู่ user + recipe ได้ตรง ๆ
  async removeByRecipe(userId: string, recipeId: string): Promise<void> {
    const favorite = await this.favoriteRepository.findOne({
      where: { userId, recipeId },
    });
    if (!favorite) {
      throw new NotFoundException(
        `Favorite for recipe ${recipeId} not found for user ${userId}`,
      );
    }
    await this.favoriteRepository.remove(favorite);
  }
}
