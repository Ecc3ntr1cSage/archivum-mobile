import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/account_repository_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/account.dart';
import 'add_credential_page.dart' show LoginMethod, SsoProvider;

class AccountDetailPage extends ConsumerStatefulWidget {
  const AccountDetailPage({required this.account, super.key});

  final Account account;

  @override
  ConsumerState<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends ConsumerState<AccountDetailPage> {
  bool _isEditing = false;
  bool _isSaving = false;
  late Account _account;

  late TextEditingController _titleCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;

  LoginMethod _loginMethod = LoginMethod.emailPassword;
  SsoProvider? _selectedProvider;
  List<String> _tags = [];
  String? _selectedTag;

  bool get _isSso => _account.method == 'sso';

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _initControllers();
    Future.microtask(_loadTags);
  }

  void _initControllers() {
    _titleCtrl = TextEditingController(text: _account.title);
    _emailCtrl = TextEditingController(text: _account.email ?? '');
    _usernameCtrl = TextEditingController(text: _account.username ?? '');
    _passwordCtrl = TextEditingController(text: _account.password ?? '');
    _loginMethod = _account.method == 'sso'
        ? LoginMethod.sso
        : LoginMethod.emailPassword;
    _selectedTag = _account.tags;
    _selectedProvider = _providerFromText(_account.provider);
  }

  SsoProvider? _providerFromText(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'google':
        return SsoProvider.google;
      case 'github':
        return SsoProvider.github;
      case 'facebook':
        return SsoProvider.facebook;
      default:
        return null;
    }
  }

  Future<void> _loadTags() async {
    if (!mounted) return;
    try {
      final tags = await ref
          .read(accountRepositoryProvider)
          .getTags('credential');
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load credential tags: ${AppError.from(error, stackTrace).message}',
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = Account(
        id: _account.id,
        userId: _account.userId,
        title: _titleCtrl.text.trim(),
        method: _loginMethod == LoginMethod.sso ? 'sso' : 'email-password',
        email:
            _loginMethod == LoginMethod.emailPassword &&
                _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : null,
        username:
            _loginMethod == LoginMethod.emailPassword &&
                _usernameCtrl.text.trim().isNotEmpty
            ? _usernameCtrl.text.trim()
            : null,
        password:
            _loginMethod == LoginMethod.emailPassword &&
                _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : null,
        provider: _loginMethod == LoginMethod.sso && _selectedProvider != null
            ? _selectedProvider.toString().split('.').last
            : null,
        tags: _selectedTag,
        createdAt: _account.createdAt,
      );

      final result = await ref
          .read(accountRepositoryProvider)
          .updateAccount(updated);
      if (!mounted) return;

      setState(() {
        _account = result;
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credential updated')));
      Navigator.of(context).pop('updated');
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final theme = context.archivumTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.popover,
        title: Text(
          'Delete Credential',
          style: TextStyle(color: theme.popoverForeground),
        ),
        content: Text(
          'Delete "${_account.title}"? This cannot be undone.',
          style: TextStyle(color: theme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.destructive,
              foregroundColor: theme.destructiveForeground,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(accountRepositoryProvider).deleteAccount(_account.id!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _titleCtrl.dispose();
      _emailCtrl.dispose();
      _usernameCtrl.dispose();
      _passwordCtrl.dispose();
      _initControllers();
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Recently';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  IconData _iconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'github':
        return Icons.code_rounded;
      case 'gmail':
        return Icons.mail_outline_rounded;
      case 'adobe creative cloud':
        return Icons.palette_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final accent = theme.secondary;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        leading: IconButton(
          onPressed: () {
            if (_isEditing) {
              _cancelEditing();
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(
            _isEditing ? Icons.close_rounded : Icons.arrow_back_rounded,
          ),
        ),
        title: Text(_isEditing ? 'Edit Credential' : _account.title),
        actions: _isEditing
            ? [
                TextButton(
                  onPressed: _cancelEditing,
                  child: const Text('Cancel'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ]
            : [
                IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: Icon(Icons.edit_outlined, color: accent),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: _deleteAccount,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.destructive,
                  ),
                  tooltip: 'Delete',
                ),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeroCard(
              accent: accent,
              icon: _iconForTitle(_account.title),
              eyebrow: _isEditing ? 'Credential editor' : 'Credential',
              title: _account.title,
              subtitle: _isEditing
                  ? 'Update login details, provider, and tag without leaving the page.'
                  : (_isSso
                        ? 'SSO via ${_account.provider ?? 'provider'}'
                        : _account.email ??
                              _account.username ??
                              _account.method),
              chips: [
                _HeroChip(label: _account.method.toUpperCase(), accent: accent),
                if ((_account.tags ?? '').isNotEmpty)
                  _HeroChip(label: _account.tags!, accent: accent),
                _HeroChip(
                  label: _formatDate(_account.createdAt),
                  accent: accent,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isEditing)
              _buildEditForm(theme, accent)
            else
              _buildDetailView(theme, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(ArchivumTheme theme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Access details',
          accent: accent,
          child: Column(
            children: [
              if (!_isSso) ...[
                _DetailItem(
                  label: 'Email',
                  value: _account.email ?? '-',
                  copyable: (_account.email ?? '').isNotEmpty,
                  onCopy: () => _copyToClipboard(_account.email ?? '', 'Email'),
                ),
                _SectionDivider(theme: theme),
                _DetailItem(
                  label: 'Username',
                  value: _account.username ?? '-',
                  copyable: (_account.username ?? '').isNotEmpty,
                  onCopy: () =>
                      _copyToClipboard(_account.username ?? '', 'Username'),
                ),
                _SectionDivider(theme: theme),
                _DetailItem(
                  label: 'Password',
                  value: _account.password ?? '-',
                  isSecret: true,
                  copyable: (_account.password ?? '').isNotEmpty,
                  onCopy: () =>
                      _copyToClipboard(_account.password ?? '', 'Password'),
                ),
                _SectionDivider(theme: theme),
              ],
              _DetailItem(label: 'Method', value: _account.method),
              if (_isSso && (_account.provider ?? '').isNotEmpty) ...[
                _SectionDivider(theme: theme),
                _DetailItem(label: 'Provider', value: _account.provider!),
              ],
              if ((_account.tags ?? '').isNotEmpty) ...[
                _SectionDivider(theme: theme),
                _DetailItem(label: 'Tag', value: _account.tags!),
              ],
              if (_account.createdAt != null) ...[
                _SectionDivider(theme: theme),
                _DetailItem(
                  label: 'Created',
                  value: _formatDate(_account.createdAt),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _deleteAccount,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.destructive,
            side: BorderSide(color: theme.destructive.withValues(alpha: 0.35)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete Credential'),
        ),
      ],
    );
  }

  Widget _buildEditForm(ArchivumTheme theme, Color accent) {
    return _SectionCard(
      title: 'Edit fields',
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Account title', accent: accent),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'GitHub, Netflix, Linear',
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Login method', accent: accent),
          const SizedBox(height: 8),
          DropdownButtonFormField<LoginMethod>(
            initialValue: _loginMethod,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(
                value: LoginMethod.emailPassword,
                child: Text('Email / password'),
              ),
              DropdownMenuItem(value: LoginMethod.sso, child: Text('SSO')),
            ],
            onChanged: (value) {
              setState(() => _loginMethod = value ?? LoginMethod.emailPassword);
            },
          ),
          const SizedBox(height: 16),
          if (_loginMethod == LoginMethod.emailPassword) ...[
            _FieldLabel(label: 'Email', accent: accent),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(hintText: 'name@example.com'),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Username', accent: accent),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(hintText: 'Optional username'),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Password', accent: accent),
            const SizedBox(height: 8),
            _PasswordEditField(controller: _passwordCtrl),
            const SizedBox(height: 16),
          ],
          if (_loginMethod == LoginMethod.sso) ...[
            _FieldLabel(label: 'SSO provider', accent: accent),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final provider in SsoProvider.values)
                  _ChoiceChip(
                    label: provider.toString().split('.').last.toUpperCase(),
                    selected: _selectedProvider == provider,
                    accent: accent,
                    onTap: () => setState(() => _selectedProvider = provider),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _FieldLabel(label: 'Tag', accent: accent),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                _ChoiceChip(
                  label: tag,
                  selected: _selectedTag == tag,
                  accent: accent,
                  onTap: () => setState(() {
                    _selectedTag = _selectedTag == tag ? null : tag;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  const _DetailHeroCard({
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  final Color accent;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.mutedForeground,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: title, accent: accent),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.theme});

  final ArchivumTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: theme.border),
    );
  }
}

class _DetailItem extends StatefulWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    this.isSecret = false,
    this.copyable = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool isSecret;
  final bool copyable;
  final VoidCallback? onCopy;

  @override
  State<_DetailItem> createState() => _DetailItemState();
}

class _DetailItemState extends State<_DetailItem> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final displayValue = widget.isSecret && _obscured
        ? '........'
        : widget.value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            widget.label,
            style: TextStyle(
              color: theme.mutedForeground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              fontFamily: widget.isSecret && _obscured ? null : 'monospace',
            ),
          ),
        ),
        if (widget.isSecret)
          IconButton(
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: theme.mutedForeground,
              size: 18,
            ),
            tooltip: _obscured ? 'Show' : 'Hide',
          ),
        if (widget.copyable && widget.onCopy != null)
          IconButton(
            onPressed: widget.onCopy,
            icon: Icon(
              Icons.copy_outlined,
              color: theme.mutedForeground,
              size: 18,
            ),
            tooltip: 'Copy',
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : theme.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : theme.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : theme.mutedForeground,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PasswordEditField extends StatefulWidget {
  const _PasswordEditField({required this.controller});

  final TextEditingController controller;

  @override
  State<_PasswordEditField> createState() => _PasswordEditFieldState();
}

class _PasswordEditFieldState extends State<_PasswordEditField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      decoration: InputDecoration(
        hintText: 'Enter password',
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscured = !_obscured),
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
