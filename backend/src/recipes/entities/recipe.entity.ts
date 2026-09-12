import {
  Check,
  Column,
  Entity,
  Index,
  JoinColumn,
  JoinTable,
  ManyToMany,
  ManyToOne,
  OneToMany,
} from 'typeorm';
import { Category } from '../../categories/entities/category.entity';
import { BaseEntity } from '../../common/entities/base.entity';
import { Favorite } from '../../favorites/entities/favorite.entity';
import { RecipeIngredient } from '../../ingredients/entities/recipe-ingredient.entity';
import { OrderItem } from '../../orders/entities/order-item.entity';
import { RecipeAccess } from '../../recipe-access/entities/recipe-access.entity';
import { Review } from '../../reviews/entities/review.entity';
import { User } from '../../users/entities/user.entity';
import { RecipeSection } from './recipe-section.entity';

export enum RecipeStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  HIDDEN = 'hidden',
  REJECTED = 'rejected',
}

export enum RecipeDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard',
}

export enum RecipeType {
  COMMUNITY = 'community',
  OFFICIAL = 'official',
}

@Entity('recipes')
@Check('chk_recipes_price', '"price" >= 0')
@Check(
  'chk_recipes_preparation_minutes',
  '"preparation_minutes" IS NULL OR "preparation_minutes" >= 0',
)
@Check(
  'chk_recipes_cooking_minutes',
  '"cooking_minutes" IS NULL OR "cooking_minutes" >= 0',
)
@Check(
  'chk_recipes_serving_count',
  '"serving_count" IS NULL OR "serving_count" > 0',
)
export class Recipe extends BaseEntity {
  @Index()
  @Column({ name: 'creator_id', type: 'uuid' })
  creatorId!: string;

  @ManyToOne(() => User, (user) => user.recipes, {
    nullable: false,
    onDelete: 'RESTRICT',
  })
  @JoinColumn({ name: 'creator_id' })
  creator!: User;

  @Column({ type: 'varchar', length: 255 })
  title!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255 })
  slug!: string;

  @Column({ name: 'short_description', type: 'text', nullable: true })
  shortDescription!: string | null;

  @Column({ name: 'cover_image_url', type: 'text', nullable: true })
  coverImageUrl!: string | null;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: 0 })
  price!: string;

  @Column({ name: 'preparation_minutes', type: 'integer', nullable: true })
  preparationMinutes!: number | null;

  @Column({ name: 'cooking_minutes', type: 'integer', nullable: true })
  cookingMinutes!: number | null;

  @Column({ name: 'serving_count', type: 'integer', nullable: true })
  servingCount!: number | null;

  @Column({ type: 'enum', enum: RecipeDifficulty, nullable: true })
  difficulty!: RecipeDifficulty | null;

  @Column({ type: 'enum', enum: RecipeType, default: RecipeType.COMMUNITY })
  type!: RecipeType;

  @Index()
  @Column({ type: 'enum', enum: RecipeStatus, default: RecipeStatus.DRAFT })
  status!: RecipeStatus;

  @Column({ name: 'published_at', type: 'timestamptz', nullable: true })
  publishedAt!: Date | null;

  @ManyToMany(() => Category, (category) => category.recipes)
  @JoinTable({
    name: 'recipe_categories',
    joinColumn: { name: 'recipe_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'category_id', referencedColumnName: 'id' },
  })
  categories!: Category[];

  @OneToMany(() => RecipeSection, (section) => section.recipe)
  sections!: RecipeSection[];

  @OneToMany(() => RecipeIngredient, (item) => item.recipe)
  recipeIngredients!: RecipeIngredient[];

  @OneToMany(() => OrderItem, (item) => item.recipe)
  orderItems!: OrderItem[];

  @OneToMany(() => RecipeAccess, (access) => access.recipe)
  accesses!: RecipeAccess[];

  @OneToMany(() => Review, (review) => review.recipe)
  reviews!: Review[];

  @OneToMany(() => Favorite, (favorite) => favorite.recipe)
  favorites!: Favorite[];
}
