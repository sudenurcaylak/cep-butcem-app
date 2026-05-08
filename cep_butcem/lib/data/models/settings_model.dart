class SettingsModel {
  final int? id;
  final String themeMode; // dark, light, system
  final String languageCode; // tr, en
  final bool reminderNotificationsEnabled;
  final bool subscriptionNotificationsEnabled;

  const SettingsModel({
    this.id,
    required this.themeMode,
    required this.languageCode,
    required this.reminderNotificationsEnabled,
    required this.subscriptionNotificationsEnabled,
  });

  factory SettingsModel.defaults() {
    return const SettingsModel(
      id: 1,
      themeMode: 'dark',
      languageCode: 'tr',
      reminderNotificationsEnabled: true,
      subscriptionNotificationsEnabled: true,
    );
  }

  SettingsModel copyWith({
    int? id,
    String? themeMode,
    String? languageCode,
    bool? reminderNotificationsEnabled,
    bool? subscriptionNotificationsEnabled,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      reminderNotificationsEnabled:
          reminderNotificationsEnabled ?? this.reminderNotificationsEnabled,
      subscriptionNotificationsEnabled:
          subscriptionNotificationsEnabled ??
          this.subscriptionNotificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'theme_mode': themeMode,
      'language_code': languageCode,
      'reminder_notifications_enabled': reminderNotificationsEnabled ? 1 : 0,
      'subscription_notifications_enabled': subscriptionNotificationsEnabled
          ? 1
          : 0,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'] as int?,
      themeMode: (map['theme_mode'] as String?) ?? 'dark',
      languageCode: (map['language_code'] as String?) ?? 'tr',
      reminderNotificationsEnabled:
          ((map['reminder_notifications_enabled'] as num?)?.toInt() ?? 1) == 1,
      subscriptionNotificationsEnabled:
          ((map['subscription_notifications_enabled'] as num?)?.toInt() ?? 1) ==
          1,
    );
  }
}
