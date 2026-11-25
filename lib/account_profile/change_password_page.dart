import 'package:flutter/material.dart';
import 'package:yelloved_mobile/account_profile/account_api.dart';
import 'package:yelloved_mobile/account_profile/account_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.api});

  final AccountApi api;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.changePassword(
        oldPassword: _old.text,
        newPassword: _new.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      showAccountSnack(context, 'Password berhasil diubah.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) showAccountSnack(context, accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Change password')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AccountTextField(
            controller: _old,
            label: 'Current password',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _new,
            label: 'New password',
            icon: Icons.lock_reset,
            obscureText: true,
            validator: (value) =>
                value == null || value.length < 8 ? 'Minimal 8 karakter' : null,
          ),
          AccountTextField(
            controller: _confirm,
            label: 'Confirm new password',
            icon: Icons.lock_reset,
            obscureText: true,
            validator: (value) =>
                value != _new.text ? 'Password tidak sama' : null,
          ),
          const SizedBox(height: 8),
          AccountSubmitButton(
            label: 'Update password',
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
}
