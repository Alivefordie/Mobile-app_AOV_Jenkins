import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';
import { Cart } from './cart.entity';

// หนึ่งสูตรใส่ตะกร้าเดิมได้ครั้งเดียว จึง unique (cart_id, recipe_id)
// ไม่มี quantity เพราะสูตรเป็นสินค้า digital ซื้อซ้ำไม่ได้
// ไม่เก็บราคาไว้ที่นี่ ราคาอ่านสดจาก relation recipe ตอน GET
@Entity('cart_items')
@Index(['cartId', 'recipeId'], { unique: true })
export class CartItem extends BaseEntity {
  @Column({ name: 'cart_id', type: 'uuid' })
  cartId!: string;

  @ManyToOne(() => Cart, (cart) => cart.items, {
    nullable: false,
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'cart_id' })
  cart!: Cart;

  @Column({ name: 'recipe_id', type: 'uuid' })
  recipeId!: string;

  @ManyToOne(() => Recipe, (recipe) => recipe.cartItems, {
    nullable: false,
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'recipe_id' })
  recipe!: Recipe;
}
