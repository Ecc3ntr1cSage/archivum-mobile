import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/account_repository_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../snippets/presentation/almanac_style.dart';
import '../domain/account.dart';

enum LoginMethod { emailPassword, sso }

enum SsoProvider { google, github, facebook }

class AddCredentialPage extends ConsumerStatefulWidget {
  const AddCredentialPage({super.key});

  @override
  ConsumerState<AddCredentialPage> createState() => _AddCredentialPageState();
}

class _AddCredentialPageState extends ConsumerState<AddCredentialPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginMethod _loginMethod = LoginMethod.emailPassword;
  SsoProvider? _selectedProvider;
  List<String> _tags = [];
  String? _selectedTag;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTags);
  }

  Future<void> _loadTags() async {
    if (!mounted) return;
    try {
      final tags = await ref
          .read(accountRepositoryProvider)
          .getTags('credential');
      if (!mounted) return;
      setState(() {
        _tags = tags;
        if (!_tags.contains(_selectedTag)) _selectedTag = null;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load credential tags: ${AppError.from(error, stackTrace).message}',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showAddTagDialog() async {
    final tagController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AlmanacColors.surfaceHigh,
        title: const Text('Add account tag'),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: almanacInputDecoration('Tag name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = tagController.text.trim();
              if (text.isEmpty) return;
              try {
                await ref
                    .read(accountRepositoryProvider)
                    .addTag(text, 'credential');
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {
                  if (!_tags.contains(text)) _tags.add(text);
                  _selectedTag = text;
                });
              } catch (error, stackTrace) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to add tag: ${AppError.from(error, stackTrace).message}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    tagController.dispose();
  }

  Future<void> _saveCredential() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please provide a title')));
      return;
    }
    if (_loginMethod == LoginMethod.sso && _selectedProvider == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose an SSO provider')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final account = Account(
        userId: supabase.auth.currentUser?.id,
        title: _titleController.text.trim(),
        email:
            _emailController.text.trim().isNotEmpty &&
                _loginMethod == LoginMethod.emailPassword
            ? _emailController.text.trim()
            : null,
        username:
            _usernameController.text.trim().isNotEmpty &&
                _loginMethod == LoginMethod.emailPassword
            ? _usernameController.text.trim()
            : null,
        password:
            _passwordController.text.trim().isNotEmpty &&
                _loginMethod == LoginMethod.emailPassword
            ? _passwordController.text.trim()
            : null,
        method: _loginMethod == LoginMethod.emailPassword
            ? 'email-password'
            : 'sso',
        provider: _selectedProvider != null && _loginMethod == LoginMethod.sso
            ? _selectedProvider.toString().split('.').last
            : null,
        tags: _selectedTag,
      );

      final newAccount = await ref
          .read(accountRepositoryProvider)
          .createAccount(account);

      if (!mounted) return;
      Navigator.of(context).pop(<String, String>{
        'title': newAccount.title,
        'email': newAccount.email ?? '',
        'username': newAccount.username ?? '',
        'method': newAccount.method,
        'provider': newAccount.provider ?? '',
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save credential: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlmanacColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AlmanacBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AlmanacTopBar(
                  title: 'NEW ACCOUNT',
                  subtitle: 'Secure identity record',
                  leading: AlmanacIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                      children: [
                        AlmanacPanel(
                          borderColor: AlmanacColors.secondary.withValues(
                            alpha: 0.32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('IDENTITY NODE'),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _titleController,
                                textCapitalization: TextCapitalization.words,
                                decoration: almanacInputDecoration(
                                  'Account title',
                                  prefixIcon: Icons.key_rounded,
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<LoginMethod>(
                                initialValue: _loginMethod,
                                dropdownColor: AlmanacColors.surfaceHigh,
                                decoration: almanacInputDecoration(
                                  'Login method',
                                  prefixIcon: Icons.login_rounded,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: LoginMethod.emailPassword,
                                    child: Text('Email-password'),
                                  ),
                                  DropdownMenuItem(
                                    value: LoginMethod.sso,
                                    child: Text('SSO'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _loginMethod =
                                        value ?? LoginMethod.emailPassword;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_loginMethod == LoginMethod.emailPassword)
                          _PasswordFields(
                            emailController: _emailController,
                            usernameController: _usernameController,
                            passwordController: _passwordController,
                            obscurePassword: _obscurePassword,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          )
                        else
                          _SsoPanel(
                            selectedProvider: _selectedProvider,
                            onSelected: (provider) =>
                                setState(() => _selectedProvider = provider),
                          ),
                        const SizedBox(height: 14),
                        AlmanacPanel(
                          borderColor: AlmanacColors.outline.withValues(
                            alpha: 0.44,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(child: _FieldLabel('TAGS')),
                                  IconButton(
                                    onPressed: _showAddTagDialog,
                                    color: AlmanacColors.secondary,
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_tags.isEmpty)
                                const Text(
                                  'No tags linked yet.',
                                  style: TextStyle(color: AlmanacColors.muted),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tag in _tags)
                                      _TagChip(
                                        label: tag,
                                        selected: _selectedTag == tag,
                                        onTap: () => setState(
                                          () => _selectedTag =
                                              _selectedTag == tag ? null : tag,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveCredential,
                style: almanacCommitButtonStyle(AlmanacColors.secondary),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.enhanced_encryption_rounded),
                label: Text(_isLoading ? 'Saving...' : 'Commit account'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordFields extends StatelessWidget {
  const _PasswordFields({
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return AlmanacPanel(
      borderColor: AlmanacColors.outline.withValues(alpha: 0.44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('CREDENTIALS'),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: almanacInputDecoration(
              'Email',
              prefixIcon: Icons.alternate_email_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: usernameController,
            decoration: almanacInputDecoration(
              'Username',
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration:
                almanacInputDecoration(
                  'Password',
                  prefixIcon: Icons.password,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AlmanacColors.muted,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _SsoPanel extends StatelessWidget {
  const _SsoPanel({required this.selectedProvider, required this.onSelected});

  final SsoProvider? selectedProvider;
  final ValueChanged<SsoProvider> onSelected;

  @override
  Widget build(BuildContext context) {
    return AlmanacPanel(
      borderColor: AlmanacColors.outline.withValues(alpha: 0.44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('SSO PROVIDER'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SsoButton(
                  provider: SsoProvider.google,
                  selectedProvider: selectedProvider,
                  icon: Icons.g_translate_rounded,
                  label: 'Google',
                  onSelected: onSelected,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SsoButton(
                  provider: SsoProvider.github,
                  selectedProvider: selectedProvider,
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  onSelected: onSelected,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SsoButton(
                  provider: SsoProvider.facebook,
                  selectedProvider: selectedProvider,
                  icon: Icons.group_rounded,
                  label: 'Facebook',
                  onSelected: onSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SsoButton extends StatelessWidget {
  const _SsoButton({
    required this.provider,
    required this.selectedProvider,
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final SsoProvider provider;
  final SsoProvider? selectedProvider;
  final IconData icon;
  final String label;
  final ValueChanged<SsoProvider> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = provider == selectedProvider;
    return InkWell(
      onTap: () => onSelected(provider),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AlmanacColors.secondary.withValues(alpha: 0.12)
              : AlmanacColors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AlmanacColors.secondary : AlmanacColors.outline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AlmanacColors.secondary : AlmanacColors.muted,
            ),
            const SizedBox(height: 7),
            FittedBox(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: selected
                      ? AlmanacColors.secondary
                      : AlmanacColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AlmanacColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AlmanacColors.secondary.withValues(alpha: 0.14)
              : AlmanacColors.surfaceHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AlmanacColors.secondary : AlmanacColors.outline,
          ),
        ),
        child: Text(
          '#$label',
          style: TextStyle(
            color: selected ? AlmanacColors.secondary : AlmanacColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
