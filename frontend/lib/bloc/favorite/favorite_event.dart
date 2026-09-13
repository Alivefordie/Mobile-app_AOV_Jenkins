sealed class FavoriteEvent {
  const FavoriteEvent();
}

/// อ่าน token จากเครื่องแล้วโหลดรายการหัวใจของคนนั้นใหม่ทั้งหมด
/// ไม่มี token = ไม่มีหัวใจ จึงใช้ตัวนี้ได้ทั้งตอนล็อกอิน สลับบัญชี และ logout
final class FavoritesRequested extends FavoriteEvent {
  const FavoritesRequested();
}

/// กดหัวใจหนึ่งครั้ง ยังไม่กด = บันทึก, กดไว้แล้ว = เอาออก
final class FavoriteToggled extends FavoriteEvent {
  const FavoriteToggled(this.recipeId);

  final String recipeId;
}
