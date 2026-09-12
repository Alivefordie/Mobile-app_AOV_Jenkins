import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Category } from '../categories/entities/category.entity';
import { RecipesController } from './recipes.controller';
import { RecipesService } from './recipes.service';
import { RecipeContent } from './entities/recipe-content.entity';
import { RecipeSection } from './entities/recipe-section.entity';
import { Recipe } from './entities/recipe.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Recipe, RecipeSection, RecipeContent, Category]),
  ],
  controllers: [RecipesController],
  providers: [RecipesService],
})
export class RecipesModule {}
