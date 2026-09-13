import { IsUUID } from 'class-validator';

export class RemoveFavoriteDto {
  @IsUUID()
  recipeId!: string;
}
