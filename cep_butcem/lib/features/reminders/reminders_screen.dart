import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/data/models/reminder_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_background.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'edit_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const Color _purple = Color(0xFF6C4DFF);

  final ReminderRepository _repository = ReminderRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  final List<ReminderModel> _items = [];
  SettingsModel? _settings;

  bool _isLoading = true;

  bool get _isReminderNotificationsEnabled =>
      _settings?.reminderNotificationsEnabled ?? true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _repository.getAllReminders(),
        _settingsRepository.getSettings(),
      ]);

      final loadedReminders = results[0] as List<ReminderModel>;
      final loadedSettings = results[1] as SettingsModel;

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(loadedReminders);
        _settings = loadedSettings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcılar yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _loadRemindersOnly() async {
    try {
      final loaded = await _repository.getAllReminders();

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(loaded);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcılar yenilenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _updateReminder(ReminderModel reminder) async {
    if (reminder.id == null) return;
    await _repository.updateReminder(reminder);
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    final reminderId = reminder.id;
    if (reminderId == null) return;

    try {
      await _repository.deleteReminder(reminderId);
      await NotificationService.instance.cancelNotification(reminderId);

      if (!mounted) return;
      await _loadRemindersOnly();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hatırlatıcı silindi')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcı silinirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _confirmDelete(ReminderModel reminder) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Hatırlatıcıyı sil',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '"${reminder.title}" silinsin mi?',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteReminder(reminder);
    }
  }

  Future<void> _toggleReminder(ReminderModel item, bool value) async {
    if (!_isReminderNotificationsEnabled) return;

    try {
      final updated = item.copyWith(isDone: !value);
      await _updateReminder(updated);

      final reminderId = updated.id;
      if (reminderId != null) {
        if (value) {
          final scheduledAt = DateTime.parse(updated.remindAt);

          await NotificationService.instance.scheduleReminderNotification(
            id: reminderId,
            title: updated.title,
            body: (updated.note?.trim().isNotEmpty ?? false)
                ? updated.note!.trim()
                : 'Hatırlatıcı zamanı geldi.',
            scheduledAt: scheduledAt,
          );
        } else {
          await NotificationService.instance.cancelNotification(reminderId);
        }
      }

      await _loadRemindersOnly();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcı güncellenirken hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGlobalReminderEnabled = _isReminderNotificationsEnabled;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                _TopBar(title: 'Hatırlatıcılar', onBack: () => context.pop()),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final created = await context.push<bool>(
                        '/reminders/create',
                      );

                      if (created == true) {
                        await _loadData();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'OLUŞTUR',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isGlobalReminderEnabled) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Text(
                      'Hatırlatıcı bildirimleri Ayarlar ekranından kapalı. Açmadan buradan manuel kontrol yapılamaz.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(top: 6, bottom: 12),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, i) {
                              final item = _items[i];

                              return _ReminderCard(
                                title: item.title,
                                enabled:
                                    item.enabled && isGlobalReminderEnabled,
                                isInteractive: isGlobalReminderEnabled,
                                onToggle: (v) async {
                                  await _toggleReminder(item, v);
                                },
                                onDelete: () => _confirmDelete(item),
                                onEdit: () async {
                                  final updated = await context.push<bool>(
                                    EditReminderScreen.routePath,
                                    extra: item,
                                  );

                                  if (updated == true) {
                                    await _loadData();
                                  }
                                },
                                accent: _purple,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBack,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        const Expanded(child: SizedBox()),
        Expanded(
          flex: 2,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const Expanded(child: SizedBox()),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.enabled,
    required this.isInteractive,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.accent,
  });

  final String title;
  final bool enabled;
  final bool isInteractive;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isInteractive ? 1 : 0.65,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 108, 76, 242).withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color.fromARGB(255, 108, 76, 242).withOpacity(0.4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.white70,
                  splashRadius: 20,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 218, 218, 218),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  color: Colors.white70,
                  splashRadius: 20,
                ),
                IgnorePointer(
                  ignoring: !isInteractive,
                  child: Switch.adaptive(
                    value: enabled,
                    activeColor: accent,
                    onChanged: onToggle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Henüz hatırlatıcı yok.',
        style: TextStyle(color: Color(0xFF8A8A8A), fontWeight: FontWeight.w700),
      ),
    );
  }
}
