import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/data/models/reminder_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/repositories/settings_repository.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  static const Color _purple = Color(0xFF6C4DFF);

  final ReminderRepository _repository = ReminderRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  ReminderFrequency _freq = ReminderFrequency.weekly;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  bool _isSaving = false;
  bool _isLoadingSettings = true;
  SettingsModel _settings = SettingsModel.defaults();

  bool get _isReminderNotificationsEnabled =>
      _settings.reminderNotificationsEnabled;

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                _TopBar(
                  title: 'Hatırlatıcı Oluştur',
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
                              'Hatırlatıcı bildirimleri Ayarlar ekranından kapalı. Kayıt oluşturulacak ama bildirim planlanmayacak.',
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

                        const _FieldLabel('Hatırlatma sıklığı'),
                        DropdownButtonFormField<ReminderFrequency>(
                          value: _freq,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                          items: ReminderFrequency.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _freq = v ?? _freq),
                        ),
                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: _PickTile(
                                label: 'Tarih',
                                value: dateStr,
                                onTap: () async {
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
                                onTap: () async {
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
                  child: PrimaryButton(
                    text: _isSaving
                        ? 'Kaydediliyor...'
                        : _isLoadingSettings
                        ? 'Yükleniyor...'
                        : 'Oluştur',
                    onPressed: (_isSaving || _isLoadingSettings)
                        ? null
                        : _onCreate,
                    backgroundColor: _purple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCreate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı ismi boş olamaz.')),
      );
      return;
    }

    final dt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

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
      final model = ReminderModel(
        title: name,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        remindAt: dt.toIso8601String(),
        isDone: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      final insertedId = await _repository.insertReminder(model);

      if (_isReminderNotificationsEnabled) {
        await NotificationService.instance.scheduleReminderNotification(
          id: insertedId,
          title: name,
          body: _noteCtrl.text.trim().isEmpty
              ? 'Hatırlatıcı zamanı geldi.'
              : _noteCtrl.text.trim(),
          scheduledAt: dt,
        );
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcı kaydedilirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
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
