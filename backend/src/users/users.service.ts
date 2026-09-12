import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from '../favorites/entities/favorite.entity';
import {
  RecipeAccess,
  RecipeAccessType,
} from '../recipe-access/entities/recipe-access.entity';
import { Recipe, RecipeStatus } from '../recipes/entities/recipe.entity';
import { Review, ReviewStatus } from '../reviews/entities/review.entity';
import type { UserProfileResponse } from './dto/user-profile-response.dto';
import { User, UserRole, UserStatus } from './entities/user.entity';

export interface CreateUserInput {
  email: string;
  passwordHash: string;
  displayName: string;
  avatarUrl?: string | null;
  role?: UserRole;
}

export interface UpdateUserInput {
  email?: string;
  displayName?: string;
  avatarUrl?: string | null;
  role?: UserRole;
  status?: UserStatus;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(RecipeAccess)
    private readonly accessRepository: Repository<RecipeAccess>,
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
  ) {}

  findAll(): Promise<User[]> {
    return this.userRepository.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) throw new NotFoundException(`User with id ${id} not found`);
    return user;
  }

  findById(id: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id } });
  }

  findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email: email.toLowerCase() },
    });
  }

  /** ใช้ตอน login เท่านั้น เพราะ passwordHash เป็นคอลัมน์ select: false */
  findByEmailWithPassword(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email: email.toLowerCase() },
      select: {
        id: true,
        email: true,
        passwordHash: true,
        displayName: true,
        avatarUrl: true,
        role: true,
        status: true,
      },
    });
  }

  async findProfile(id: string): Promise<UserProfileResponse> {
    const user = await this.findOne(id);

    const [recipeCount, draftCount, savedCount, purchasedCount, ratingRow] =
      await Promise.all([
        this.recipeRepository.count({
          where: { creatorId: id, status: RecipeStatus.PUBLISHED },
        }),
        this.recipeRepository.count({
          where: { creatorId: id, status: RecipeStatus.DRAFT },
        }),
        this.favoriteRepository.count({ where: { userId: id } }),
        this.accessRepository
          .createQueryBuilder('access')
          .where('access.user_id = :userId', { userId: id })
          .andWhere('access.access_type = :accessType', {
            accessType: RecipeAccessType.PURCHASE,
          })
          .andWhere('access.revoked_at IS NULL')
          .andWhere(
            '(access.expires_at IS NULL OR access.expires_at > CURRENT_TIMESTAMP)',
          )
          .getCount(),
        this.reviewRepository
          .createQueryBuilder('review')
          .innerJoin('review.recipe', 'recipe')
          .select('COALESCE(AVG(review.rating), 0)', 'rating')
          .where('recipe.creator_id = :creatorId', { creatorId: id })
          .andWhere('recipe.status = :recipeStatus', {
            recipeStatus: RecipeStatus.PUBLISHED,
          })
          .andWhere('review.status = :reviewStatus', {
            reviewStatus: ReviewStatus.PUBLISHED,
          })
          .getRawOne<{ rating: string | number | null }>(),
      ]);

    const rating = Number(ratingRow?.rating ?? 0);

    return {
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      avatarUrl: user.avatarUrl,
      role: user.role,
      status: user.status,
      recipeCount,
      purchasedCount,
      savedCount,
      draftCount,
      rating: Number.isFinite(rating) ? Number(rating.toFixed(1)) : 0,
    };
  }

  async create(input: CreateUserInput): Promise<User> {
    const user = await this.userRepository.save(
      this.userRepository.create({
        ...input,
        email: input.email.toLowerCase(),
      }),
    );
    return this.findOne(user.id);
  }

  async update(id: string, input: UpdateUserInput): Promise<User> {
    const user = await this.findOne(id);
    Object.assign(user, input, { id: user.id });
    await this.userRepository.save(user);
    return this.findOne(user.id);
  }

  async remove(id: string): Promise<void> {
    const user = await this.findOne(id);
    await this.userRepository.remove(user);
  }
}
