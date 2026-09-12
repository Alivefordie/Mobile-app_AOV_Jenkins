import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateBannerDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(2048)
  imageUrl?: string;
}
