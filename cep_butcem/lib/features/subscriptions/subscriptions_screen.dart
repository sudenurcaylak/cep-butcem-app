import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_background.dart';
import '../../data/models/reminder_model.dart';
import '../../data/models/settings_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import 'edit_subscription_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  final ReminderRepository _reminderRepository = ReminderRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  final List<SubscriptionModel> _items = [];
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
        _repository.getAllSubscriptions(),
        _settingsRepository.getSettings(),
      ]);

      final loadedSubscriptions = results[0] as List<SubscriptionModel>;
      final loadedSettings = results[1] as SettingsModel;

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(loadedSubscriptions);
        _settings = loadedSettings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abonelikler yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _updateSub(SubscriptionModel sub) async {
    if (sub.id == null) return;
    await _repository.updateSubscription(sub);
  }

  Future<void> _createReminderFromSubscription(SubscriptionModel s) async {
    try {
      final now = DateTime.now();

      final due = s.nextDueDate(now);
      final remindDay = due.subtract(Duration(days: s.remindDaysBefore));

      final reminderDateTime = DateTime(
        remindDay.year,
        remindDay.month,
        remindDay.day,
        20,
        0,
      );

      if (!reminderDateTime.isAfter(now)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu abonelik için hatırlatma zamanı geçmiş. Lütfen ödeme tarihini ileri bir tarihe al.',
            ),
          ),
        );
        return;
      }

      final reminderTitle =
          '${s.name} ödemesi (${s.remindDaysBefore} gün kaldı)';

      final reminderIso = reminderDateTime.toIso8601String();

      final existingReminders = await _reminderRepository.getAllReminders();

      final alreadyExists = existingReminders.any((r) {
        return r.title == reminderTitle && r.remindAt == reminderIso;
      });

      if (alreadyExists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu abonelik için hatırlatıcı zaten oluşturulmuş.'),
          ),
        );
        return;
      }

      final reminder = ReminderModel(
        title: reminderTitle,
        note: '${s.name} aboneliği için otomatik oluşturuldu.',
        remindAt: reminderIso,
        isDone: false,
        createdAt: now.toIso8601String(),
      );

      final insertedId = await _reminderRepository.insertReminder(reminder);

      if (_isReminderNotificationsEnabled) {
        await NotificationService.instance.scheduleReminderNotification(
          id: insertedId,
          title: reminder.title,
          body: reminder.note ?? 'Hatırlatıcı zamanı geldi.',
          scheduledAt: reminderDateTime,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isReminderNotificationsEnabled
                ? 'Hatırlatıcı kaydedildi ✅ Bildirim saat 20:00’ye kuruldu.'
                : 'Hatırlatıcı kaydedildi. Bildirimler Ayarlar’dan kapalı.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hatırlatıcı oluşturulamadı: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                _TopBar(title: 'Abonelikler', onBack: () => context.pop()),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final created = await context.push<bool>(
                        '/subscriptions/create',
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
                          Icon(Icons.add, size: 20, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'YENİ ABONELİK EKLE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
                              final s = _items[i];
                              final due = s.nextDueDate(now);
                              final dueStr = _formatDate(due);

                              return _SubscriptionCard(
                                sub: s,
                                dueText: 'Sonraki ödeme: $dueStr',
                                onEdit: () async {
                                  final updated = await context.push<bool>(
                                    EditSubscriptionScreen.routePath,
                                    extra: s,
                                  );

                                  if (updated == true) {
                                    await _loadData();
                                  }
                                },
                                onToggleAutoPay: (v) async {
                                  final updated = s.copyWith(autoPay: v);
                                  await _updateSub(updated);
                                  await _loadData();
                                },
                                onToggleRemind: (v) async {
                                  final updated = s.copyWith(
                                    remindersEnabled: v,
                                  );
                                  await _updateSub(updated);
                                  await _loadData();
                                },
                                onCreateReminder: () async {
                                  await _createReminderFromSubscription(s);
                                },
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

  String _formatDate(DateTime d) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
        const Expanded(child: SizedBox()),
        Expanded(
          flex: 2,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        const Expanded(child: SizedBox()),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.sub,
    required this.dueText,
    required this.onEdit,
    required this.onToggleAutoPay,
    required this.onToggleRemind,
    required this.onCreateReminder,
  });

  final SubscriptionModel sub;
  final String dueText;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleAutoPay;
  final ValueChanged<bool> onToggleRemind;
  final VoidCallback onCreateReminder;

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF141826).withOpacity(0.55),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  _ProviderAvatar(provider: sub.provider),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dueText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '${sub.amount.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      text: sub.period.label,
                      icon: Icons.calendar_month_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Pill(
                      text: 'Ayın ${sub.billingDay}. günü',
                      icon: Icons.event_available_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Otomatik Ödeme',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: sub.autoPay,
                    onChanged: onToggleAutoPay,
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hatırlat',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: sub.remindersEnabled,
                    onChanged: onToggleRemind,
                  ),
                ],
              ),

              if (sub.remindersEnabled) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onCreateReminder,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 18,
                            color: Colors.white.withOpacity(0.92),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Hatırlatıcıya ekle',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  label: const Text(
                    'Düzenle',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({required this.provider});

  final SubscriptionProvider provider;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final String text;

    switch (provider) {
      case SubscriptionProvider.netflix:
        bg = const Color(0xFFE50914);
        text = 'N';
        break;
      case SubscriptionProvider.youtube:
        bg = const Color(0xFFFF0000);
        text = 'YT';
        break;
      case SubscriptionProvider.blutv:
        bg = const Color(0xFF0C3CFF);
        text = 'blu';
        break;
      case SubscriptionProvider.other:
        bg = const Color(0xFF6C4DFF);
        text = '•';
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  BoxDecoration _pillDecoration() {
    return BoxDecoration(
      color: const Color(0xFF111628).withOpacity(0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _pillDecoration(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.92),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Henüz abonelik yok.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
