import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { RecipeAccess } from './entities/recipe-access.entity';
import { RecipeAccessService } from './recipe-access.service';

@Controller('recipe-access')
export class RecipeAccessController {
  constructor(private readonly recipeAccessService: RecipeAccessService) {}

  @Get()
  findAll(): Promise<RecipeAccess[]> {
    return this.recipeAccessService.findAll();
  }

  @Get('check/:userId/:recipeId')
  hasActiveAccess(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<boolean> {
    return this.recipeAccessService.hasActiveAccess(userId, recipeId);
  }

  @Get('user/:userId')
  findPurchasedByUser(
    @Param('userId', ParseUUIDPipe) userId: string,
  ): Promise<RecipeAccess[]> {
    return this.recipeAccessService.findPurchasedByUser(userId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<RecipeAccess> {
    return this.recipeAccessService.findOne(id);
  }

  @Post()
  create(@Body() data: Partial<RecipeAccess>): Promise<RecipeAccess> {
    return this.recipeAccessService.create(data);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() data: Partial<RecipeAccess>,
  ): Promise<RecipeAccess> {
    return this.recipeAccessService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.recipeAccessService.remove(id);
  }
}
