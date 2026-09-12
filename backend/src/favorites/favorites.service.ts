import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from './entities/favorite.entity';

@Injectable()
export class FavoritesService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
  ) {}

  findAll(userId?: string): Promise<Favorite[]> {
    return this.favoriteRepository.find({
      where: userId ? { userId } : {},
      relations: { recipe: { creator: true, categories: true } },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Favorite> {
    const favorite = await this.favoriteRepository.findOne({
      where: { id },
      relations: { recipe: true },
    });
    if (!favorite)
      throw new NotFoundException(`Favorite with id ${id} not found`);
    return favorite;
  }

  create(data: Partial<Favorite>): Promise<Favorite> {
    return this.favoriteRepository.save(this.favoriteRepository.create(data));
  }

  async remove(id: string): Promise<void> {
    const favorite = await this.findOne(id);
    await this.favoriteRepository.remove(favorite);
  }
}
