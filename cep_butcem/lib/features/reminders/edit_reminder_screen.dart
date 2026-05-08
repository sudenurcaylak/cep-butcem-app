import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/data/models/reminder_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/repositories/settings_repository.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({super.key, required this.reminder});

  static const routePath = '/reminders/edit';

  final ReminderModel reminder;

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  static const Color _purple = Color(0xFF6C4DFF);

  final ReminderRepository _repository = ReminderRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _noteCtrl;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isLoadingSettings = true;

  SettingsModel _settings = SettingsModel.defaults();

  bool get _isReminderNotificationsEnabled =>
      _settings.reminderNotificationsEnabled;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.reminder.title);
    _noteCtrl = TextEditingController(text: widget.reminder.note ?? '');

    final remindAt = DateTime.parse(widget.reminder.remindAt);
    _date = DateTime(remindAt.year, remindAt.month, remindAt.day);
    _time = TimeOfDay(hour: remindAt.hour, minute: remindAt.minute);

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsRepository.getSettings();

      if (!mounted) return;

      setState(() {
        _settings = settings;
        _isLoadingSettings = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingSettings = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ayarlar yüklenemedi: $e')));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(_date);
    final timeStr = _formatTime(_time);
    final isBusy = _isSaving || _isDeleting || _isLoadingSettings;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                _TopBar(
                  title: 'Hatırlatıcı Düzenle',
                  onBack: () => context.pop(),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isLoadingSettings &&
                            !_isReminderNotificationsEnabled) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: const Text(
                              'Hatırlatıcı bildirimleri Ayarlar ekranından kapalı. Güncelleme kaydedilir ama bildirim planlanmaz.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                        const _FieldLabel('Hatırlatıcı ismi'),
                        TextField(
                          controller: _nameCtrl,
                          enabled: !isBusy,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          enableSuggestions: true,
                          autocorrect: true,
                          decoration: const InputDecoration(
                            hintText: 'İsim',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _PickTile(
                                label: 'Tarih',
                                value: dateStr,
                                onTap: isBusy
                                    ? () {}
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _date,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() => _date = picked);
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PickTile(
                                label: 'Saat',
                                value: timeStr,
                                onTap: isBusy
                                    ? () {}
                                    : () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: _time,
                                        );
                                        if (picked != null) {
                                          setState(() => _time = picked);
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _FieldLabel('Yorum'),
                        TextField(
                          controller: _noteCtrl,
                          enabled: !isBusy,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          enableSuggestions: true,
                          autocorrect: true,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Yorum yaz',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      PrimaryButton(
                        text: _isSaving ? 'Kaydediliyor...' : 'Kaydet',
                        onPressed: isBusy ? null : _onSave,
                        backgroundColor: _purple,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isBusy ? null : _onDeletePressed,
                        child: Text(
                          _isDeleting ? 'Siliniyor...' : 'Hatırlatıcıyı Sil',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı ismi boş olamaz.')),
      );
      return;
    }

    final reminderId = widget.reminder.id;
    if (reminderId == null) return;

    final dt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    // ✅ KRİTİK FIX (geçmiş saat engelle)
    final now = DateTime.now();
    if (!dt.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen şu andan ileri bir tarih ve saat seç.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // eski bildirimi sil
      await NotificationService.instance.cancelNotification(reminderId);

      final updated = widget.reminder.copyWith(
        title: name,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        remindAt: dt.toIso8601String(),
      );

      await _repository.updateReminder(updated);

      // sadece ayar açıksa yeniden schedule
      if (_isReminderNotificationsEnabled && updated.enabled) {
        await NotificationService.instance.scheduleReminderNotification(
          id: reminderId,
          title: updated.title,
          body: (updated.note?.trim().isNotEmpty ?? false)
              ? updated.note!.trim()
              : 'Hatırlatıcı zamanı geldi.',
          scheduledAt: dt,
        );
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcı güncellenirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _onDeletePressed() async {
    final reminderId = widget.reminder.id;
    if (reminderId == null) return;

    final confirmed = await showDialog<bool>(
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
            '"${widget.reminder.title}" silinsin mi?',
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

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _repository.deleteReminder(reminderId);
      await NotificationService.instance.cancelNotification(reminderId);

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcı silinirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });
    }
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
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}.${two(t.minute)}';
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(width: 52),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8A8A8A),
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8A8A8A),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFBDBDBD), width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF777777),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
