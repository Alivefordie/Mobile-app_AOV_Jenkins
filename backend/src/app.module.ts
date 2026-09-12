import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import databaseConfig from '../config/database.config';
import jwtConfig from '../config/jwt.config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { BannerModule } from './banner/banner.module';
import { CategoriesModule } from './categories/categories.module';
import { DatabaseModule } from './database/database.module';
import { FavoritesModule } from './favorites/favorites.module';
import { IngredientsModule } from './ingredients/ingredients.module';
import { OrdersModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { RecipeAccessModule } from './recipe-access/recipe-access.module';
import { RecipesModule } from './recipes/recipes.module';
import { ReviewsModule } from './reviews/reviews.module';
import { UploadsModule } from './uploads/uploads.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.production', '.env'],
      load: [databaseConfig, jwtConfig],
    }),
    DatabaseModule,
    UsersModule,
    AuthModule,
    BannerModule,
    CategoriesModule,
    RecipesModule,
    IngredientsModule,
    OrdersModule,
    PaymentsModule,
    RecipeAccessModule,
    ReviewsModule,
    FavoritesModule,
    UploadsModule,
    // FoodsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
