import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity';

@Entity('banners')
export class Banner extends BaseEntity {
  @Column({ name: 'image_url', type: 'text' })
  imageUrl!: string;
}
