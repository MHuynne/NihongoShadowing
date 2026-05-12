class UserModel {
  final String name;
  final String avatarUrl;
  final int streakDays;
  final int balanceYen;
  final List<DateTime> activeDates;

  UserModel({
    required this.name,
    required this.avatarUrl,
    required this.streakDays,
    required this.balanceYen,
    this.activeDates = const [],
  });
}
