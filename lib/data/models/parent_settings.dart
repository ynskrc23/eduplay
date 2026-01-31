class ParentSettings {
  final int? id;
  final int maxDailyMinutes;
  final bool notificationsEnabled;
  final bool adsEnabled;
  final bool premiumActive;

  ParentSettings({
    this.id,
    required this.maxDailyMinutes,
    required this.notificationsEnabled,
    required this.adsEnabled,
    required this.premiumActive,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'max_daily_minutes': maxDailyMinutes,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'ads_enabled': adsEnabled ? 1 : 0,
        'premium_active': premiumActive ? 1 : 0,
      };

  static ParentSettings fromJson(Map<String, dynamic> json) => ParentSettings(
        id: json['id'] as int?,
        maxDailyMinutes: json['max_daily_minutes'] as int,
        notificationsEnabled: json['notifications_enabled'] == 1,
        adsEnabled: json['ads_enabled'] == 1,
        premiumActive: json['premium_active'] == 1,
      );
}
