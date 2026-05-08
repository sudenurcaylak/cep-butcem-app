import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/primary_button.dart';
import '../../core/theme/app_background.dart';
import '../../core/state/profile_store.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, this.initialData});

  static const route = '/profile/edit';

  final ProfileData? initialData;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _occupationCtrl;

  @override
  void initState() {
    super.initState();

    _firstNameCtrl = TextEditingController(
      text: widget.initialData?.firstName ?? '',
    );
    _lastNameCtrl = TextEditingController(
      text: widget.initialData?.lastName ?? '',
    );
    _occupationCtrl = TextEditingController(
      text: widget.initialData?.occupation ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _occupationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final data = ProfileData(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      occupation: _occupationCtrl.text.trim(),
    );

    final repo = ProfileRepository();
    await repo.saveProfile(data);

    final store = ProfileScope.of(context);
    store.setProfile(data);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottomInset),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.pop(),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: isDark ? Colors.white : null,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Profili Düzenle',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 44),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8B5CFF),
                                      Color(0xFF6C4DFF),
                                      Color(0xFF5B2EFF),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName.isEmpty ? '—' : fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _occupationCtrl.text.trim().isEmpty
                                          ? 'Meslek eklenmedi'
                                          : _occupationCtrl.text.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          _FieldCard(
                            label: 'Ad',
                            isDark: isDark,
                            child: TextFormField(
                              controller: _firstNameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Ad',
                                border: InputBorder.none,
                              ),
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) {
                                  return 'Ad boş olamaz';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),

                          const SizedBox(height: 12),

                          _FieldCard(
                            label: 'Soyad',
                            isDark: isDark,
                            child: TextFormField(
                              controller: _lastNameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Soyad',
                                border: InputBorder.none,
                              ),
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) {
                                  return 'Soyad boş olamaz';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),

                          const SizedBox(height: 12),

                          _FieldCard(
                            label: 'Meslek',
                            isDark: isDark,
                            child: TextFormField(
                              controller: _occupationCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Meslek (opsiyonel)',
                                border: InputBorder.none,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),

                          const SizedBox(height: 24),

                          PrimaryButton(text: 'Kaydet', onPressed: _save),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.child,
    required this.isDark,
  });

  final String label;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232634) : const Color(0xFFF1EDFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: child,
        ),
      ],
    );
  }
}
