import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/account_repository_provider.dart';
import '../domain/account.dart';
import 'add_credential_page.dart' show InputField, SsoProviderButton, LoginMethod, SsoProvider;

class AccountDetailPage extends ConsumerStatefulWidget {
  final Account account;
  const AccountDetailPage({required this.account, super.key});

  @override
  ConsumerState<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends ConsumerState<AccountDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  bool _isSaving = false;
  late Account _account;

  // Controllers for editing
  late TextEditingController _titleCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  LoginMethod _loginMethod = LoginMethod.emailPassword;
  SsoProvider? _selectedProvider;

  List<String> _tags = [];
  String? _selectedTag;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _initControllers();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
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

    if (_account.method == 'sso' && _account.provider != null) {
      switch (_account.provider!.toLowerCase()) {
        case 'google':
          _selectedProvider = SsoProvider.google;
          break;
        case 'github':
          _selectedProvider = SsoProvider.github;
          break;
        case 'facebook':
          _selectedProvider = SsoProvider.facebook;
          break;
      }
    }
  }

  Future<void> _loadTags() async {
    if (!mounted) return;
    try {
      final tags =
          await ref.read(accountRepositoryProvider).getTags('credential');
      if (mounted) {
        setState(() {
          _tags = tags;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = Account(
        id: _account.id,
        userId: _account.userId,
        title: _titleCtrl.text.trim(),
        method:
            _loginMethod == LoginMethod.sso ? 'sso' : 'email-password',
        email: _loginMethod == LoginMethod.emailPassword &&
                _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : null,
        username: _loginMethod == LoginMethod.emailPassword &&
                _usernameCtrl.text.trim().isNotEmpty
            ? _usernameCtrl.text.trim()
            : null,
        password: _loginMethod == LoginMethod.emailPassword &&
                _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : null,
        provider: _loginMethod == LoginMethod.sso && _selectedProvider != null
            ? _selectedProvider.toString().split('.').last
            : null,
        tags: _selectedTag,
        createdAt: _account.createdAt,
      );
      final result =
          await ref.read(accountRepositoryProvider).updateAccount(updated);
      if (mounted) {
        setState(() {
          _account = result;
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credential updated')),
        );
        Navigator.of(context).pop('updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Credential'),
        content: Text(
          'Are you sure you want to delete "${_account.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(accountRepositoryProvider)
          .deleteAccount(_account.id!);
      if (mounted) {
        Navigator.of(context).pop('deleted');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final accentOrange = const Color(0xFFF97316);
    final bgColor =
        isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final headerBgColor = isDark
        ? const Color(0xFF191121).withValues(alpha: 0.95)
        : const Color(0xFFF7F6F8).withValues(alpha: 0.95);
    final cardBg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.5)
        : Colors.white;
    final isSso = _account.method == 'sso';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: headerBgColor,
            border: Border(
              bottom: BorderSide(color: primary.withValues(alpha: 0.1)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Credential' : _account.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isEditing) ...[
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: Icon(Icons.edit_outlined, color: primary),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      tooltip: 'Delete',
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _initControllers();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _isEditing ? _buildEditForm(isDark, primary, accentOrange) : _buildDetailView(isDark, primary, accentOrange, cardBg, isSso),
        ),
      ),
    );
  }

  // ── VIEW MODE ──────────────────────────────────────────────
  Widget _buildDetailView(bool isDark, Color primary, Color accentOrange,
      Color cardBg, bool isSso) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary.withValues(alpha: 0.15),
                primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForTitle(_account.title),
                  color: primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _account.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (isSso) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SSO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accentOrange,
                              ),
                            ),
                          ),
                        ],
                        if (_account.tags != null &&
                            _account.tags!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _account.tags!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSso
                          ? 'SSO via ${_account.provider ?? 'Unknown'}'
                          : (_account.email ?? 'No email'),
                      style:
                          TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Details section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: primary.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              if (!isSso) ...[
                _detailRow('Email', _account.email ?? '—', isDark,
                    copyable: true, onCopy: () => _copyToClipboard(_account.email ?? '', 'Email')),
                _divider(primary),
                _detailRow('Username', _account.username ?? '—', isDark,
                    copyable: _account.username != null),
                _divider(primary),
                _detailRow('Password', _account.password ?? '—', isDark,
                    isPassword: true,
                    copyable: _account.password != null,
                    onCopy: () => _copyToClipboard(_account.password ?? '', 'Password')),
                _divider(primary),
              ],
              _detailRow('Method', _account.method, isDark),
              if (isSso && _account.provider != null) ...[
                _divider(primary),
                _detailRow('Provider', _account.provider!, isDark),
              ],
              if (_account.tags != null && _account.tags!.isNotEmpty) ...[
                _divider(primary),
                _detailRow('Tag', _account.tags!, isDark),
              ],
              if (_account.createdAt != null) ...[
                _divider(primary),
                _detailRow(
                  'Created',
                  '${_account.createdAt!.year}-${_account.createdAt!.month.toString().padLeft(2, '0')}-${_account.createdAt!.day.toString().padLeft(2, '0')}',
                  isDark,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Delete button
        OutlinedButton.icon(
          onPressed: _deleteAccount,
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          label: const Text('Delete Credential',
              style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value,
    bool isDark, {
    bool isPassword = false,
    bool copyable = false,
    VoidCallback? onCopy,
  }) {
    final labelColor = const Color(0xFF94A3B8);
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return _ObscurableRow(
      label: label,
      value: value,
      labelColor: labelColor,
      valueColor: valueColor,
      isPassword: isPassword,
      copyable: copyable,
      onCopy: onCopy,
    );
  }

  Widget _divider(Color primary) => Divider(
        height: 24,
        color: primary.withValues(alpha: 0.07),
      );

  // ── EDIT MODE ──────────────────────────────────────────────
  Widget _buildEditForm(bool isDark, Color primary, Color accentOrange) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputField(
            controller: _titleCtrl,
            label: 'Account Title',
            hint: 'e.g. GitHub, Netflix',
          ),
          const SizedBox(height: 16),
          const Text(
            'Login Method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<LoginMethod>(
            initialValue: _loginMethod,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Color(0xFF94A3B8)),
            dropdownColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF7F6F8),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF7F6F8),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: primary.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primary, width: 2),
              ),
            ),
            items: const [
              DropdownMenuItem(
                  value: LoginMethod.emailPassword,
                  child: Text('Email-Password')),
              DropdownMenuItem(
                  value: LoginMethod.sso, child: Text('SSO')),
            ],
            onChanged: (v) {
              setState(() {
                _loginMethod = v ?? LoginMethod.emailPassword;
              });
            },
          ),
          const SizedBox(height: 16),

          if (_loginMethod == LoginMethod.emailPassword) ...[
            InputField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'Enter registered email'),
            const SizedBox(height: 16),
            InputField(
                controller: _usernameCtrl,
                label: 'Username',
                hint: 'Enter username (optional)'),
            const SizedBox(height: 16),
            InputField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Enter your password',
                isPassword: true),
            const SizedBox(height: 16),
          ],

          if (_loginMethod == LoginMethod.sso) ...[
            Container(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select SSO Provider',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: accentOrange),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SsoProviderButton(
                          selected:
                              _selectedProvider == SsoProvider.google,
                          icon: Icons.g_translate,
                          label: 'GOOGLE',
                          onTap: () => setState(
                              () => _selectedProvider = SsoProvider.google),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SsoProviderButton(
                          selected:
                              _selectedProvider == SsoProvider.github,
                          icon: Icons.code,
                          label: 'GITHUB',
                          onTap: () => setState(
                              () => _selectedProvider = SsoProvider.github),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SsoProviderButton(
                          selected:
                              _selectedProvider == SsoProvider.facebook,
                          icon: Icons.group,
                          label: 'FACEBOOK',
                          onTap: () => setState(() =>
                              _selectedProvider = SsoProvider.facebook),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],

          // Tag selector
          const Text(
            'Tag',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _tags.contains(_selectedTag) ? _selectedTag : null,
            hint: const Text('Select a tag',
                style: TextStyle(color: Color(0xFF64748B))),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Color(0xFF94A3B8)),
            dropdownColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF7F6F8),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF7F6F8),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: primary.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primary, width: 2),
              ),
            ),
            items: _tags.map((t) {
              return DropdownMenuItem(value: t, child: Text(t));
            }).toList(),
            onChanged: (v) => setState(() => _selectedTag = v),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'github':
        return Icons.terminal;
      case 'gmail':
        return Icons.mail;
      case 'adobe creative cloud':
        return Icons.palette;
      default:
        return Icons.shield_outlined;
    }
  }
}

// ── Helper widget for password reveal ──────────────────────
class _ObscurableRow extends StatefulWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool isPassword;
  final bool copyable;
  final VoidCallback? onCopy;

  const _ObscurableRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.isPassword = false,
    this.copyable = false,
    this.onCopy,
  });

  @override
  State<_ObscurableRow> createState() => _ObscurableRowState();
}

class _ObscurableRowState extends State<_ObscurableRow> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final displayValue =
        widget.isPassword && _obscure ? '••••••••' : widget.value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            widget.label,
            style: TextStyle(
                fontSize: 13,
                color: widget.labelColor,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 14,
              color: widget.valueColor,
              fontWeight: FontWeight.w600,
              fontFamily: widget.isPassword && _obscure ? null : 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.isPassword)
          GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: widget.labelColor,
              ),
            ),
          ),
        if (widget.copyable && widget.onCopy != null)
          GestureDetector(
            onTap: widget.onCopy,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.copy_outlined,
                size: 18,
                color: widget.labelColor,
              ),
            ),
          ),
      ],
    );
  }
}
