import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_background.dart';
import '../../data/models/settings_model.dart';
import '../../data/models/reminder_model.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/repositories/settings_repository.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  static const routePath = '/settings/notifications';

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  final ReminderRepository _reminderRepository = ReminderRepository();

  bool _isLoading = true;
  bool _isSavingReminder = false;

  SettingsModel _settings = SettingsModel.defaults();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _repository.getSettings();

      if (!mounted) return;

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildirim ayarları yüklenemedi: $e')),
      );
    }
  }

  Future<void> _cancelAllReminderNotifications() async {
    final List<ReminderModel> reminders = await _reminderRepository
        .getAllReminders();

    for (final reminder in reminders) {
      final id = reminder.id;
      if (id != null) {
        await NotificationService.instance.cancelNotification(id);
      }
    }
  }

  Future<void> _updateReminderNotifications(bool value) async {
    if (_isSavingReminder) return;

    final previousValue = _settings.reminderNotificationsEnabled;

    setState(() {
      _isSavingReminder = true;
      _settings = _settings.copyWith(reminderNotificationsEnabled: value);
    });

    try {
      await _repository.updateReminderNotifications(value);

      if (!value) {
        await _cancelAllReminderNotifications();
      }

      if (!mounted) return;

      setState(() {
        _isSavingReminder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Hatırlatıcı bildirimleri açıldı'
                : 'Hatırlatıcı bildirimleri kapatıldı',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _settings = _settings.copyWith(
          reminderNotificationsEnabled: previousValue,
        );
        _isSavingReminder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcı ayarı kaydedilemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  title: 'Bildirim Ayarları',
                  onBack: () => context.pop(),
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Bildirim Tercihleri', isDark: isDark),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _Card(
                    isDark: isDark,
                    children: [
                      _SwitchItem(
                        title: 'Hatırlatıcı Bildirimleri',
                        subtitle:
                            'Hatırlatıcı zamanı geldiğinde bildirim gönder',
                        value: _settings.reminderNotificationsEnabled,
                        isBusy: _isSavingReminder,
                        onChanged: _updateReminderNotifications,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFE6E8F0),
                      ),
                    ),
                    child: Text(
                      'Abonelik hatırlatmaları da hatırlatıcı sistemi üzerinden çalışır. Bu yüzden burada tek bir bildirim ayarı kullanılıyor.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.isDark,
  });

  final String title;
  final VoidCallback onBack;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBack,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children, required this.isDark});

  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232634) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isBusy,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isBusy ? 0.7 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ),
            ),
            IgnorePointer(
              ignoring: isBusy,
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}
