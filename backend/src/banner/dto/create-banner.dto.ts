import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateBannerDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(2048)
  imageUrl!: string;
}
