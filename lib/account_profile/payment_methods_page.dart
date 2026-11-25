import 'package:flutter/material.dart';
import 'package:yelloved_mobile/account_profile/account_api.dart';
import 'package:yelloved_mobile/account_profile/account_models.dart';
import 'package:yelloved_mobile/account_profile/account_ui.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key, required this.api});

  final AccountApi api;

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late Future<List<PaymentMethod>> _future = widget.api.listPaymentMethods();

  Future<void> _reload() async {
    final future = widget.api.listPaymentMethods();
    setState(() => _future = future);
    await future.catchError((_) => <PaymentMethod>[]);
  }

  Future<void> _openForm([PaymentMethod? method]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodFormPage(api: widget.api, method: method),
      ),
    );
    if (saved == true) await _reload();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      showAccountSnack(context, done);
      await _reload();
    } catch (error) {
      if (mounted) showAccountSnack(context, accountErrorMessage(error));
    }
  }

  Future<void> _delete(PaymentMethod method) async {
    final confirmed = await confirmAccountAction(
      context,
      title: 'Delete payment method?',
      message: '${method.provider} (${method.accountIdentifier}) akan dihapus.',
    );
    if (confirmed) {
      await _run(
        () => widget.api.deletePaymentMethod(method.id!),
        'Metode pembayaran dihapus.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment methods')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openForm(),
      icon: const Icon(Icons.add),
      label: const Text('Add method'),
    ),
    body: RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<PaymentMethod>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AccountMessage(
              icon: Icons.error_outline,
              text: accountErrorMessage(snapshot.error!),
            );
          }
          final methods = snapshot.data!;
          if (methods.isEmpty) {
            return const AccountMessage(
              icon: Icons.credit_card_off_outlined,
              text: 'Belum ada metode pembayaran.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    method.methodType == 'bank'
                        ? Icons.account_balance_outlined
                        : Icons.account_balance_wallet_outlined,
                  ),
                  title: Text(
                    method.isDefault
                        ? '${method.provider} · Default'
                        : method.provider,
                  ),
                  subtitle: Text(
                    '${method.typeLabel} · ${method.accountName}\n'
                    '${method.accountIdentifier}',
                  ),
                  isThreeLine: true,
                  onTap: () => _openForm(method),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => switch (value) {
                      'default' => _run(
                        () => widget.api.updatePaymentMethod(method.id!, {
                          'is_default': true,
                        }),
                        'Metode utama diperbarui.',
                      ),
                      'edit' => _openForm(method),
                      _ => _delete(method),
                    },
                    itemBuilder: (_) => [
                      if (!method.isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('Set as default'),
                        ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class PaymentMethodFormPage extends StatefulWidget {
  const PaymentMethodFormPage({super.key, required this.api, this.method});

  final AccountApi api;
  final PaymentMethod? method;

  @override
  State<PaymentMethodFormPage> createState() => _PaymentMethodFormPageState();
}

class _PaymentMethodFormPageState extends State<PaymentMethodFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _type = widget.method?.methodType ?? 'bank';
  late final _provider = TextEditingController(text: widget.method?.provider);
  late final _accountName = TextEditingController(
    text: widget.method?.accountName,
  );

  /// Left empty when editing: the server only returns a masked number, so an
  /// empty field means "keep the current account number".
  final _identifier = TextEditingController();
  late bool _isDefault = widget.method?.isDefault ?? false;
  bool _saving = false;

  bool get _editing => widget.method != null;

  @override
  void dispose() {
    _provider.dispose();
    _accountName.dispose();
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final identifier = _identifier.text.trim();
      final method = widget.method;
      if (method == null) {
        await widget.api.createPaymentMethod(
          PaymentMethod(
            methodType: _type,
            provider: _provider.text.trim(),
            accountName: _accountName.text.trim(),
            accountIdentifier: identifier,
            isDefault: _isDefault,
          ),
        );
      } else {
        await widget.api.updatePaymentMethod(method.id!, {
          'method_type': _type,
          'provider': _provider.text.trim(),
          'account_name': _accountName.text.trim(),
          'is_default': _isDefault,
          if (identifier.isNotEmpty) 'account_identifier': identifier,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showAccountSnack(context, accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_editing ? 'Edit payment method' : 'Add payment method'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SegmentedButton<String>(
              segments: [
                for (final entry in PaymentMethod.types.entries)
                  ButtonSegment(value: entry.key, label: Text(entry.value)),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
          ),
          AccountTextField(
            controller: _provider,
            label: _type == 'bank'
                ? 'Bank (e.g. BCA)'
                : 'E-wallet (e.g. GoPay)',
            icon: Icons.business_outlined,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _accountName,
            label: 'Account holder',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _identifier,
            label: _editing
                ? 'New account / phone number (leave empty to keep '
                      '${widget.method!.accountIdentifier})'
                : 'Account / phone number',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            validator: _editing ? null : requiredField,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as default payment method'),
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
          ),
          const SizedBox(height: 16),
          AccountSubmitButton(label: 'Save', busy: _saving, onPressed: _save),
        ],
      ),
    ),
  );
}
