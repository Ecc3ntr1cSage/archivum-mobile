import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/account_repository_provider.dart';
import '../domain/account.dart';
import 'account_detail_page.dart';
import 'add_credential_page.dart';

// ── Credential card ─────────────────────────────────────────
class CredentialCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;

  const CredentialCard({required this.account, required this.onTap, super.key});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final accentOrange = const Color(0xFFF97316);

    final isSso = account.method.toLowerCase() == 'sso';
    final cardBgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.4)
        : const Color(0xFFF7F6F8);

    final isOrangeTheme = account.title.toLowerCase() == 'gmail';
    final themeColor = isOrangeTheme ? accentOrange : primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: primary.withValues(alpha: 0.05),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              // Icon avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getIconForTitle(account.title),
                    color: themeColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title + tag + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              height: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSso) ...[
                          const SizedBox(width: 6),
                          _Chip(
                            label: 'SSO',
                            color: accentOrange,
                          ),
                        ],
                        if (account.tags != null &&
                            account.tags!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _Chip(
                            label: account.tags!,
                            color: primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSso
                          ? 'Primary: ${account.provider ?? ''} Login'
                          : (account.email ?? ''),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Main page ───────────────────────────────────────────────
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  List<Account> _all = [];
  bool _isLoading = true;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Tag filter
  List<String> _availableTags = [];
  String? _selectedTagFilter; // null = All

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(accountRepositoryProvider);
      final accounts = await repository.listAccounts();
      final tags = await repository.getTags('credential');
      if (mounted) {
        setState(() {
          _all = accounts;
          _availableTags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load accounts: ${e.toString()}')),
        );
      }
    }
  }

  List<Account> get _filtered {
    return _all.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a.title.toLowerCase().contains(_searchQuery);
      final matchesTag = _selectedTagFilter == null ||
          (a.tags != null &&
              a.tags!.toLowerCase() ==
                  _selectedTagFilter!.toLowerCase());
      return matchesSearch && matchesTag;
    }).toList();
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCredentialPage(),
      ),
    );
    if (result != null) {
      _fetchAccounts();
    }
  }

  Future<void> _navigateToDetail(Account account) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountDetailPage(account: account),
      ),
    );
    if (result == 'updated' || result == 'deleted') {
      _fetchAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final bgColor =
        isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final headerBgColor = isDark
        ? const Color(0xFF191121).withValues(alpha: 0.8)
        : const Color(0xFFF7F6F8).withValues(alpha: 0.8);

    final filtered = _filtered;

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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      'Accounts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  // Plus button on the right
                  ElevatedButton(
                    onPressed: _navigateToAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      elevation: 8,
                      shadowColor: primary.withValues(alpha: 0.3),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Search bar ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: primary.withValues(alpha: 0.15)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search by title…',
                  hintStyle:
                      const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: Color(0xFF64748B)),
                          onPressed: () {
                            _searchCtrl.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header row ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Credentials',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtered.length} Total'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Tag filter radio buttons ─────────────────
            if (!_isLoading && _availableTags.isNotEmpty)
              _TagFilterBar(
                tags: _availableTags,
                selected: _selectedTagFilter,
                onChanged: (tag) {
                  setState(() => _selectedTagFilter = tag);
                },
                primary: primary,
                isDark: isDark,
              ),

            const SizedBox(height: 16),

            // ── List ────────────────────────────────────
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  _searchQuery.isNotEmpty || _selectedTagFilter != null
                      ? 'No results found'
                      : 'No credentials saved yet',
                  style:
                      const TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              ...filtered.map(
                (a) => CredentialCard(
                  account: a,
                  onTap: () => _navigateToDetail(a),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Tag filter strip ────────────────────────────────────────
class _TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final Color primary;
  final bool isDark;

  const _TagFilterBar({
    required this.tags,
    required this.selected,
    required this.onChanged,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final allTags = ['All', ...tags];
    final inactiveColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.8);
    final textColor =
        isDark ? Colors.white70 : const Color(0xFF475569);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allTags.map((tag) {
          final isAll = tag == 'All';
          final isActive =
              isAll ? selected == null : selected == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(isAll ? null : tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? primary.withValues(alpha: 0.15)
                      : inactiveColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? primary
                        : primary.withValues(alpha: 0.1),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Radio dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? primary
                            : (isDark
                                ? Colors.white24
                                : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? primary : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
