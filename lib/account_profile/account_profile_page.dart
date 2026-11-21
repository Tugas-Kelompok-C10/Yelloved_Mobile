import 'package:flutter/material.dart';
import 'package:yelloved_mobile/account_profile/account_api.dart';
import 'package:yelloved_mobile/core/app_session.dart';
import 'package:yelloved_mobile/items/items_page.dart';
import 'package:yelloved_mobile/transactions/transaction_page.dart';
import 'package:yelloved_mobile/wanted_board/wanted_board_page.dart';

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  late AccountApi _api;
  late AppSession _session;
  bool _initialized = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registering = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _profileName;
  String? _profileEmail;

  bool get _signedIn => _session.isAuthenticated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _session = AppSessionScope.of(context);
      _api = AccountApi(session: _session);
      _initialized = true;
    }
    final profile = _session.profile;
    if (_signedIn && profile != null) {
      _profileName = _readName(profile);
      _profileEmail = profile['email']?.toString() ?? _emailController.text;
    } else if (!_signedIn) {
      _profileName = null;
      _profileEmail = null;
    }
  }

  @override
  void dispose() {
    _api.close();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_registering) {
        await _api.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      await _api.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final profile = await _api.getProfile();
      if (!mounted) return;
      setState(() {
        _profileName = _readName(profile);
        _profileEmail = profile['email']?.toString() ?? _emailController.text;
      });
    } on AccountApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Tidak dapat terhubung ke server: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _readName(Map<String, dynamic> profile) {
    final name = profile['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final first = profile['first_name']?.toString().trim() ?? '';
    final last = profile['last_name']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? _emailController.text.split('@').first : combined;
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: _profileName ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama wajib diisi'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      final parts = name.text.trim().split(RegExp(r'\s+'));
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final profile = await _api.updateProfile(
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
        );
        if (mounted) setState(() => _profileName = _readName(profile));
      } on AccountApiException catch (error) {
        if (mounted) setState(() => _error = error.message);
      } catch (error) {
        if (mounted) {
          setState(() => _error = 'Tidak dapat terhubung ke server: $error');
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
    name.dispose();
  }

  void _logout() {
    _api.logout();
    setState(() {
      _profileName = null;
      _profileEmail = null;
      _passwordController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Account & Profile'),
      actions: [
        if (_signedIn)
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    body: _signedIn ? _buildProfile() : _buildAuthForm(),
  );

  Widget _buildAuthForm() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.eco_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                _registering ? 'Join Yelloved' : 'Welcome back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _registering
                    ? 'Create an account to get started.'
                    : 'Sign in to manage your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_registering) ...[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email address'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_registering ? 'Create account' : 'Sign in'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _registering = !_registering;
                        _error = null;
                      }),
                child: Text(
                  _registering
                      ? 'Already have an account? Sign in'
                      : 'New to Yelloved? Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildProfile() {
    final name = _profileName ?? 'Account';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  child: Text(initials, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_profileEmail ?? ''),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _editProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Your activity',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const _ActivityTile(
          icon: Icons.inventory_2_outlined,
          title: 'My items',
          subtitle: 'Items you have posted',
          page: ItemsPage(),
        ),
        const _ActivityTile(
          icon: Icons.push_pin_outlined,
          title: 'My wanted posts',
          subtitle: 'Things you are looking for',
          page: WantedBoardPage(),
        ),
        const _ActivityTile(
          icon: Icons.receipt_long_outlined,
          title: 'Transactions',
          subtitle: 'Your completed and ongoing transactions',
          page: TransactionPage(),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    ),
  );
}
