import { IsUUID } from 'class-validator';

export class AddCartItemDto {
  @IsUUID()
  recipeId!: string;
}
