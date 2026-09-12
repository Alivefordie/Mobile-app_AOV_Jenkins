import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { SearchRecipesDto } from './dto/search-recipes.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { Recipe, RecipeStatus, RecipeType } from './entities/recipe.entity';
import { PaginatedResult, RecipesService } from './recipes.service';

@Controller('recipes')
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Get()
  findAll(
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('categoryId') categoryId?: string,
    @Query('creatorId') creatorId?: string,
    @Query('status') status?: RecipeStatus,
    @Query('type') type?: RecipeType,
  ): Promise<Recipe[]> {
    return this.recipesService.findAll({
      search,
      category,
      categoryId,
      creatorId,
      status,
      type,
    });
  }

  // ต้องมาก่อน @Get(':id') ไม่งั้น 'search' จะถูกจับเป็น id
  @Get('search')
  search(@Query() dto: SearchRecipesDto): Promise<PaginatedResult<Recipe>> {
    return this.recipesService.search(dto);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<Recipe> {
    return this.recipesService.findOne(id);
  }

  @Post()
  create(@Body() dto: CreateRecipeDto): Promise<Recipe> {
    return this.recipesService.create(dto);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRecipeDto,
  ): Promise<Recipe> {
    return this.recipesService.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.recipesService.remove(id);
  }
}
