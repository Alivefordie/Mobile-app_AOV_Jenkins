import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CartService } from './cart.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { CartItem } from './entities/cart-item.entity';
import { Cart } from './entities/cart.entity';

// ตะกร้าเป็นของส่วนตัว userId จึงอ่านจาก token ไม่ใช่จาก query ที่ปลอมได้
@UseGuards(JwtAuthGuard)
@Controller('carts')
export class CartController {
  constructor(private readonly cartService: CartService) {}

  // คืนเป็น array (0 หรือ 1 ใบ) ยังไม่เคยกดเพิ่มของ = ได้ array ว่าง ไม่ใช่ 404
  @Get()
  findAll(@CurrentUser('id') userId: string): Promise<Cart[]> {
    return this.cartService.findAll(userId);
  }

  // get-or-create ตะกร้าของคนที่ล็อกอินอยู่ เรียกซ้ำได้ไม่สร้างเพิ่ม
  @Post()
  create(@CurrentUser('id') userId: string): Promise<Cart> {
    return this.cartService.getOrCreate(userId);
  }

  @Get(':id')
  findOne(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Cart> {
    return this.cartService.findOne(id, userId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.cartService.remove(id, userId);
  }

  @Get(':cartId/items')
  findItems(
    @CurrentUser('id') userId: string,
    @Param('cartId', ParseUUIDPipe) cartId: string,
  ): Promise<CartItem[]> {
    return this.cartService.findItems(cartId, userId);
  }

  @Post(':cartId/items')
  addItem(
    @CurrentUser('id') userId: string,
    @Param('cartId', ParseUUIDPipe) cartId: string,
    @Body() dto: AddCartItemDto,
  ): Promise<CartItem> {
    return this.cartService.addItem(cartId, userId, dto.recipeId);
  }

  @Delete(':cartId/items')
  @HttpCode(HttpStatus.NO_CONTENT)
  clearItems(
    @CurrentUser('id') userId: string,
    @Param('cartId', ParseUUIDPipe) cartId: string,
  ): Promise<void> {
    return this.cartService.clearItems(cartId, userId);
  }

  @Delete(':cartId/items/:itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeItem(
    @CurrentUser('id') userId: string,
    @Param('cartId', ParseUUIDPipe) cartId: string,
    @Param('itemId', ParseUUIDPipe) itemId: string,
  ): Promise<void> {
    return this.cartService.removeItem(cartId, userId, itemId);
  }
}
