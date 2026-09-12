import { UserRole, UserStatus } from '../entities/user.entity';

export interface UserProfileResponse {
  id: string;
  displayName: string;
  email: string;
  avatarUrl: string | null;
  role: UserRole;
  status: UserStatus;
  recipeCount: number;
  purchasedCount: number;
  savedCount: number;
  draftCount: number;
  rating: number;
}
