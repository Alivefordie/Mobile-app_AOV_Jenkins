sealed class ProfileEvent {
  const ProfileEvent();
}

final class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

final class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}
