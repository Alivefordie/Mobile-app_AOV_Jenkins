import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Category } from '../categories/entities/category.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { Recipe, RecipeStatus, RecipeType } from './entities/recipe.entity';

export interface FindRecipesOptions {
  category?: string;
  creatorId?: string;
  status?: RecipeStatus;
  type?: RecipeType;
}

@Injectable()
export class RecipesService {
  constructor(
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,

    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
  ) {}

  findAll(options: FindRecipesOptions = {}): Promise<Recipe[]> {
    const query = this.recipeRepository
      .createQueryBuilder('recipe')
      .leftJoinAndSelect('recipe.creator', 'creator')
      .leftJoinAndSelect('recipe.categories', 'category')
      .orderBy('recipe.createdAt', 'DESC');

    if (options.category) {
      // กรองด้วย subquery เพื่อให้ recipe ที่ผ่านการกรองยังโหลด categories มาครบทุกอัน
      // (ถ้าใส่เงื่อนไขลงใน join ตรงๆ จะเหลือแต่ category ที่ตรงกับที่กรอง)
      query.andWhere(
        'recipe.id IN ' +
          query
            .subQuery()
            .select('filtered.id')
            .from(Recipe, 'filtered')
            .innerJoin('filtered.categories', 'filteredCategory')
            .where('filteredCategory.slug = :category')
            .getQuery(),
        { category: options.category },
      );
    }

    if (options.creatorId) {
      query.andWhere('recipe.creator_id = :creatorId', {
        creatorId: options.creatorId,
      });
    }

    if (options.status) {
      query.andWhere('recipe.status = :status', { status: options.status });
    }

    if (options.type) {
      query.andWhere('recipe.type = :type', { type: options.type });
    }

    return query.getMany();
  }

  async findOne(id: string): Promise<Recipe> {
    const recipe = await this.recipeRepository.findOne({
      where: { id },
      relations: {
        creator: true,
        categories: true,
        recipeIngredients: { ingredient: true },
        sections: { contents: true },
      },
    });
    if (!recipe) throw new NotFoundException(`Recipe with id ${id} not found`);

    recipe.sections.sort((left, right) => left.sortOrder - right.sortOrder);
    for (const section of recipe.sections) {
      section.contents.sort((left, right) => left.sortOrder - right.sortOrder);
    }

    return recipe;
  }

  async create(dto: CreateRecipeDto): Promise<Recipe> {
    const { categoryIds, ...recipeData } = dto;
    const recipe = this.recipeRepository.create(recipeData);
    recipe.categories = await this.resolveCategories(categoryIds);
    return this.recipeRepository.save(recipe);
  }

  async update(id: string, dto: UpdateRecipeDto): Promise<Recipe> {
    const { categoryIds, ...recipeData } = dto;
    const recipe = await this.findOne(id);
    Object.assign(recipe, recipeData, { id: recipe.id });
    if (categoryIds) {
      recipe.categories = await this.resolveCategories(categoryIds);
    }
    return this.recipeRepository.save(recipe);
  }

  // แปลง categoryIds -> Category entity จริง และเช็คว่ามีครบทุก id
  private async resolveCategories(categoryIds?: string[]): Promise<Category[]> {
    if (!categoryIds?.length) return [];

    const uniqueIds = [...new Set(categoryIds)];
    const categories = await this.categoryRepository.findBy({
      id: In(uniqueIds),
    });

    if (categories.length !== uniqueIds.length) {
      const found = new Set(categories.map((category) => category.id));
      const missing = uniqueIds.filter((id) => !found.has(id));
      throw new NotFoundException(
        `Categories not found: ${missing.join(', ')}`,
      );
    }

    return categories;
  }

  async remove(id: string): Promise<void> {
    const recipe = await this.findOne(id);
    await this.recipeRepository.remove(recipe);
  }
}
