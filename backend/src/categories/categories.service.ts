import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from './entities/category.entity';
import { RecipeType } from '../recipes/entities/recipe.entity';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
  ) {}

  findAll(type?: RecipeType): Promise<Category[]> {
    if (!type) {
      return this.categoryRepository.find({ order: { sortOrder: 'ASC' } });
    }

    return this.categoryRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect('category.recipes', 'recipe', 'recipe.type = :type', {
        type,
      })
      .leftJoinAndSelect('recipe.categories', 'categories')
      .orderBy('category.sortOrder', 'ASC')
      .getMany();
  }

  async findOne(id: string, type?: RecipeType): Promise<Category> {
    const query = this.categoryRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect(
        'category.recipes',
        'recipe',
        type ? 'recipe.type = :type' : undefined,
        type ? { type } : undefined,
      )
      .leftJoinAndSelect('recipe.categories', 'categories')
      .where('category.id = :id', { id });

    const category = await query.getOne();

    if (!category) {
      throw new NotFoundException(`Category with id ${id} not found`);
    }

    return category;
  }

  create(data: Partial<Category>): Promise<Category> {
    return this.categoryRepository.save(this.categoryRepository.create(data));
  }

  async update(id: string, data: Partial<Category>): Promise<Category> {
    const category = await this.findOne(id);
    Object.assign(category, data, { id: category.id });
    return this.categoryRepository.save(category);
  }

  async remove(id: string): Promise<void> {
    const category = await this.findOne(id);
    await this.categoryRepository.remove(category);
  }
}
