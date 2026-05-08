import 'package:flutter/material.dart';

import '/../core/theme/app_background.dart';
import '/../core/theme/app_theme.dart';
import '/../core/widgets/primary_button.dart';
import '/../data/models/account_model.dart';
import '/../data/repositories/account_repository.dart';
import 'add_account_type_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  static const routePath = '/account';

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AccountRepository _repository = AccountRepository();

  bool _isLoading = true;
  String? _error;
  List<AccountModel> _accounts = const [];

  double get _total =>
      _accounts.fold(0.0, (sum, account) => sum + account.balance);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _ensureDefaultAccounts();
      final accounts = await _repository.getAll();

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Hesaplar yüklenemedi.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureDefaultAccounts() async {
    final existing = await _repository.getAll();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();

    await _repository.insert(
      AccountModel(
        name: 'Banka',
        balance: 0,
        iconCode: Icons.account_balance_rounded.codePoint,
        colorValue: const Color(0xFF2F6BFF).value,
        createdAt: now,
      ),
    );

    await _repository.insert(
      AccountModel(
        name: 'Cüzdan',
        balance: 0,
        iconCode: Icons.account_balance_wallet_rounded.codePoint,
        colorValue: const Color(0xFF20B45B).value,
        createdAt: now,
      ),
    );
  }

  Future<void> _editAccount(AccountModel account) async {
    final result = await _showEditDialog(account);
    if (!mounted || result == null) return;

    final updated = AccountModel(
      id: account.id,
      name: result.name,
      balance: result.amount,
      iconCode: account.iconCode,
      colorValue: account.colorValue,
      createdAt: account.createdAt,
    );

    try {
      await _repository.update(updated);

      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;
      await _loadAccounts();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hesap güncellenemedi.')));
    }
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final confirmed = await _showDeleteDialog(account);
    if (!mounted || confirmed != true) return;

    try {
      await _repository.delete(account.id!);

      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;
      await _loadAccounts();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hesap silinemedi.')));
    }
  }

  Future<_EditAccountResult?> _showEditDialog(AccountModel account) {
    return showDialog<_EditAccountResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EditAccountDialog(account: account),
    );
  }

  Future<bool?> _showDeleteDialog(AccountModel account) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DeleteAccountDialog(account: account),
    );
  }

  String _formatTl(double value) {
    final isInt = value.truncateToDouble() == value;
    final text = isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

    final parts = text.split('.');
    final integer = parts.first;
    final decimal = parts.length > 1 ? parts[1] : null;

    final buffer = StringBuffer();
    for (int i = 0; i < integer.length; i++) {
      buffer.write(integer[i]);
      final remaining = integer.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    if (decimal != null && decimal != '00') {
      return '₺${buffer.toString()},$decimal';
    }

    return '₺${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Hesap'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'Mevcut Bakiye',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTl(_total),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(child: _buildBody()),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: '+ Yeni hesap türü ekle',
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const AddAccountTypeScreen(),
                      ),
                    );

                    if (!mounted) return;

                    if (result == true) {
                      await _loadAccounts();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white70)),
      );
    }

    return ListView.separated(
      itemCount: _accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return _AccountTypeCard(
          icon: account.icon,
          iconColor: account.color,
          title: account.name,
          amount: _formatTl(account.balance),
          onEdit: () => _editAccount(account),
          onDelete: () => _deleteAccount(account),
        );
      },
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String amount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountTypeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF232634),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, color: Colors.white54, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditAccountDialog extends StatefulWidget {
  final AccountModel account;

  const _EditAccountDialog({required this.account});

  @override
  State<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<_EditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.account.name);
    _amountController = TextEditingController(
      text: widget.account.balance.truncateToDouble() == widget.account.balance
          ? widget.account.balance.toStringAsFixed(0)
          : widget.account.balance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = _EditAccountResult(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.replaceAll(',', '.').trim()),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF171A21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hesabı Düzenle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Hesap adı',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(.35)),
                  filled: true,
                  fillColor: const Color(0xFF232634),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Hesap adı boş olamaz';
                  if (text.length < 2) return 'En az 2 karakter gir';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tutar',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(.35)),
                  filled: true,
                  fillColor: const Color(0xFF232634),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tutar boş olamaz';
                  }

                  final normalized = value.replaceAll(',', '.').trim();
                  final parsed = double.tryParse(normalized);

                  if (parsed == null) return 'Geçerli bir tutar gir';
                  if (parsed < 0) return 'Tutar negatif olamaz';

                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'İptal',
                      onTap: () => Navigator.of(context).pop(),
                      backgroundColor: const Color(0xFF232634),
                      textColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogButton(
                      label: 'Kaydet',
                      onTap: _save,
                      backgroundColor: const Color(0xFFE3E0FF),
                      textColor: const Color(0xFF0B1020),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  final AccountModel account;

  const _DeleteAccountDialog({required this.account});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF171A21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hesabı Sil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${account.name} hesabını silmek istediğine emin misin?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'İptal',
                    onTap: () => Navigator.of(context).pop(false),
                    backgroundColor: const Color(0xFF232634),
                    textColor: Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: 'Sil',
                    onTap: () => Navigator.of(context).pop(true),
                    backgroundColor: const Color(0xFFFFE2E5),
                    textColor: const Color(0xFFD7263D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EditAccountResult {
  final String name;
  final double amount;

  const _EditAccountResult({required this.name, required this.amount});
}
