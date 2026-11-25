import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yelloved_mobile/account_profile/account_api.dart';
import 'package:yelloved_mobile/account_profile/account_ui.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.api});

  final AccountApi api;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _genders = {
    '': 'Not specified',
    'female': 'Female',
    'male': 'Male',
    'other': 'Other',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  DateTime? _dateOfBirth;
  String _gender = '';
  String? _photoUrl;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.api.session.profile ?? const {};
    _name = TextEditingController(text: profile['first_name']?.toString());
    _email = TextEditingController(text: profile['email']?.toString());
    _phone = TextEditingController(text: profile['phone_number']?.toString());
    _dateOfBirth = DateTime.tryParse(
      profile['date_of_birth']?.toString() ?? '',
    );
    final gender = profile['gender']?.toString() ?? '';
    _gender = _genders.containsKey(gender) ? gender : '';
    _photoUrl = profile['photo']?.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
    } catch (error) {
      if (mounted) {
        showAccountSnack(context, 'Tidak bisa membuka galeri: $error');
      }
      return;
    }
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const AccountApiException('Foto maksimal 5 MB.');
      }
      final profile = await widget.api.uploadProfilePhoto(
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() => _photoUrl = profile['photo']?.toString());
      showAccountSnack(context, 'Foto profil diperbarui.');
    } catch (error) {
      if (mounted) showAccountSnack(context, accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.updateProfile(
        name: _name.text,
        email: _email.text,
        phoneNumber: _phone.text,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        clearDateOfBirth: _dateOfBirth == null,
      );
      if (!mounted) return;
      showAccountSnack(context, 'Profil disimpan.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showAccountSnack(context, accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photoUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    foregroundImage: photo == null ? null : NetworkImage(photo),
                    child: const Icon(Icons.person, size: 48),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      tooltip: 'Change photo',
                      onPressed: _uploading ? null : _pickPhoto,
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AccountTextField(
              controller: _name,
              label: 'Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) => requiredField(value, 'Nama wajib diisi'),
            ),
            AccountTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Masukkan email yang valid'
                  : null,
            ),
            AccountTextField(
              controller: _phone,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of birth',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: _dateOfBirth == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear date',
                          onPressed: () => setState(() => _dateOfBirth = null),
                          icon: const Icon(Icons.clear),
                        ),
                ),
                child: InkWell(
                  onTap: _pickDate,
                  child: Text(
                    _dateOfBirth == null
                        ? 'Not set'
                        : AccountApi.formatDate(_dateOfBirth!),
                  ),
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                for (final entry in _genders.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _gender = value ?? ''),
            ),
            const SizedBox(height: 24),
            AccountSubmitButton(label: 'Save', busy: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
