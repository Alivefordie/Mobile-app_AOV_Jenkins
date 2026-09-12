import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Max,
  Min,
} from 'class-validator';
import { RecipeStatus, RecipeType } from '../entities/recipe.entity';

export class SearchRecipesDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Length(1, 255)
  q!: string;

  // ตัวกรองเสริม ใช้ร่วมกับคำค้นหาได้
  @IsOptional()
  @IsString()
  category?: string;

  // กรองด้วย id ของหมวด (ฝั่งแอปเก็บ id ไม่ใช่ slug)
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsUUID()
  creatorId?: string;

  @IsOptional()
  @IsEnum(RecipeStatus)
  status?: RecipeStatus;

  @IsOptional()
  @IsEnum(RecipeType)
  type?: RecipeType;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit: number = 20;
}
