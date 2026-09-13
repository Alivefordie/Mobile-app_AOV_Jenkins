import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { CartItem } from './entities/cart-item.entity';
import { Cart } from './entities/cart.entity';

// รหัส error ของ postgres ตอนชน unique constraint
const UNIQUE_VIOLATION = '23505';

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof QueryFailedError &&
    (error.driverError as { code?: string })?.code === UNIQUE_VIOLATION
  );
}

@Injectable()
export class CartService {
  constructor(
    @InjectRepository(Cart)
    private readonly cartRepository: Repository<Cart>,

    @InjectRepository(CartItem)
    private readonly cartItemRepository: Repository<CartItem>,
  ) {}

  // ราคา ชื่อ รูป ของแต่ละรายการอ่านสดจาก recipe ทุกครั้ง ไม่ได้ copy ไว้ใน cart_items
  private static readonly relations = {
    items: { recipe: { creator: true, categories: true } },
  } as const;

  findAll(userId: string): Promise<Cart[]> {
    return this.cartRepository.find({
      where: { userId },
      relations: CartService.relations,
      order: { createdAt: 'DESC' },
    });
  }

  // ตะกร้าของคนอื่นให้ถือว่าไม่มีอยู่ จะได้ไม่รู้ว่า id นี้มีจริงหรือเปล่า
  async findOne(id: string, userId: string): Promise<Cart> {
    const cart = await this.cartRepository.findOne({
      where: { id, userId },
      relations: CartService.relations,
    });
    if (!cart) throw new NotFoundException(`Cart with id ${id} not found`);
    return cart;
  }

  // ตะกร้ามีได้ใบเดียวต่อ user ถ้ายังไม่มีค่อยสร้างตอนกดเพิ่มครั้งแรก
  async getOrCreate(userId: string): Promise<Cart> {
    const existing = await this.cartRepository.findOne({ where: { userId } });
    if (existing) return this.findOne(existing.id, userId);

    try {
      const created = await this.cartRepository.save(
        this.cartRepository.create({ userId }),
      );
      return this.findOne(created.id, userId);
    } catch (error) {
      // มีอีก request สร้างตัดหน้าไปแล้ว ใช้ใบที่มีอยู่
      if (!isUniqueViolation(error)) throw error;
      const cart = await this.cartRepository.findOneOrFail({
        where: { userId },
      });
      return this.findOne(cart.id, userId);
    }
  }

  async findItems(cartId: string, userId: string): Promise<CartItem[]> {
    await this.findOne(cartId, userId);
    return this.cartItemRepository.find({
      where: { cartId },
      relations: { recipe: { creator: true, categories: true } },
      order: { createdAt: 'DESC' },
    });
  }

  // กดเพิ่มสูตรเดิมซ้ำไม่ถือเป็น error แต่ก็ไม่เพิ่มแถวใหม่ คืนรายการเดิมกลับไป
  async addItem(
    cartId: string,
    userId: string,
    recipeId: string,
  ): Promise<CartItem> {
    await this.findOne(cartId, userId);

    const existing = await this.cartItemRepository.findOne({
      where: { cartId, recipeId },
      relations: { recipe: true },
    });
    if (existing) return existing;

    try {
      const created = await this.cartItemRepository.save(
        this.cartItemRepository.create({ cartId, recipeId }),
      );
      return this.cartItemRepository.findOneOrFail({
        where: { id: created.id },
        relations: { recipe: true },
      });
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      return this.cartItemRepository.findOneOrFail({
        where: { cartId, recipeId },
        relations: { recipe: true },
      });
    }
  }

  async removeItem(
    cartId: string,
    userId: string,
    itemId: string,
  ): Promise<void> {
    await this.findOne(cartId, userId);

    const item = await this.cartItemRepository.findOne({
      where: { id: itemId, cartId },
    });
    if (!item) {
      throw new NotFoundException(
        `Cart item with id ${itemId} not found in cart ${cartId}`,
      );
    }
    await this.cartItemRepository.remove(item);
  }

  async clearItems(cartId: string, userId: string): Promise<void> {
    await this.findOne(cartId, userId);
    await this.cartItemRepository.delete({ cartId });
  }

  async remove(id: string, userId: string): Promise<void> {
    const cart = await this.cartRepository.findOne({ where: { id, userId } });
    if (!cart) throw new NotFoundException(`Cart with id ${id} not found`);
    await this.cartRepository.remove(cart);
  }
}
