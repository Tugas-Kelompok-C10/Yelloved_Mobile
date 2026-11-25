import 'package:flutter/material.dart';
import 'package:yelloved_mobile/account_profile/account_api.dart';
import 'package:yelloved_mobile/account_profile/account_models.dart';
import 'package:yelloved_mobile/account_profile/account_ui.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key, required this.api});

  final AccountApi api;

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  late Future<List<Address>> _future = widget.api.listAddresses();

  Future<void> _reload() async {
    final future = widget.api.listAddresses();
    setState(() => _future = future);
    await future.catchError((_) => <Address>[]);
  }

  Future<void> _openForm([Address? address]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormPage(api: widget.api, address: address),
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

  Future<void> _delete(Address address) async {
    final confirmed = await confirmAccountAction(
      context,
      title: 'Delete address?',
      message: '"${address.label}" akan dihapus.',
    );
    if (confirmed) {
      await _run(
        () => widget.api.deleteAddress(address.id!),
        'Alamat dihapus.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My addresses')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openForm(),
      icon: const Icon(Icons.add),
      label: const Text('Add address'),
    ),
    body: RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<Address>>(
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
          final addresses = snapshot.data!;
          if (addresses.isEmpty) {
            return const AccountMessage(
              icon: Icons.location_off_outlined,
              text: 'Belum ada alamat tersimpan.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    address.isDefault ? Icons.home : Icons.place_outlined,
                  ),
                  title: Row(
                    children: [
                      Flexible(child: Text(address.label)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        const _DefaultChip(),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${address.recipientName} · ${address.phoneNumber}\n'
                    '${address.summary}',
                  ),
                  isThreeLine: true,
                  onTap: () => _openForm(address),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => switch (value) {
                      'default' => _run(
                        () => widget.api.setDefaultAddress(address.id!),
                        'Alamat utama diperbarui.',
                      ),
                      'edit' => _openForm(address),
                      _ => _delete(address),
                    },
                    itemBuilder: (_) => [
                      if (!address.isDefault)
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

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key, required this.api, this.address});

  final AccountApi api;
  final Address? address;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(
    text: widget.address?.label ?? 'Home',
  );
  late final _recipient = TextEditingController(
    text: widget.address?.recipientName,
  );
  late final _phone = TextEditingController(text: widget.address?.phoneNumber);
  late final _street = TextEditingController(
    text: widget.address?.streetAddress,
  );
  late final _city = TextEditingController(text: widget.address?.city);
  late final _province = TextEditingController(text: widget.address?.province);
  late final _postal = TextEditingController(text: widget.address?.postalCode);
  late bool _isDefault = widget.address?.isDefault ?? false;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _label, _recipient, _phone, _street, _city, _province, _postal, //
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final address = Address(
      label: _label.text.trim(),
      recipientName: _recipient.text.trim(),
      phoneNumber: _phone.text.trim(),
      streetAddress: _street.text.trim(),
      city: _city.text.trim(),
      province: _province.text.trim(),
      postalCode: _postal.text.trim(),
      isDefault: _isDefault,
    );
    setState(() => _saving = true);
    try {
      final id = widget.address?.id;
      if (id == null) {
        await widget.api.createAddress(address);
      } else {
        await widget.api.updateAddress(id, address);
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
      title: Text(widget.address == null ? 'Add address' : 'Edit address'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AccountTextField(
            controller: _label,
            label: 'Label (e.g. Home, Kos)',
            icon: Icons.label_outline,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _recipient,
            label: 'Recipient name',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _phone,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _street,
            label: 'Street address',
            icon: Icons.signpost_outlined,
            maxLines: 3,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _city,
            label: 'City',
            icon: Icons.location_city_outlined,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _province,
            label: 'Province',
            icon: Icons.map_outlined,
            validator: requiredField,
          ),
          AccountTextField(
            controller: _postal,
            label: 'Postal code',
            icon: Icons.markunread_mailbox_outlined,
            keyboardType: TextInputType.number,
            validator: requiredField,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as default address'),
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

class _DefaultChip extends StatelessWidget {
  const _DefaultChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Default',
        style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer),
      ),
    );
  }
}
