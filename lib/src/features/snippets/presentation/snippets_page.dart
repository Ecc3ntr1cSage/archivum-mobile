import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/account_repository_provider.dart';
import '../../../core/providers/snippet_repository_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_detail_page.dart';
import '../../indexes/domain/index_item.dart';
import '../../indexes/presentation/index_detail_page.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/note_detail_page.dart';

class SnippetsPage extends ConsumerStatefulWidget {
  const SnippetsPage({super.key});

  @override
  ConsumerState<SnippetsPage> createState() => _SnippetsPageState();
}

class _SnippetsPageState extends ConsumerState<SnippetsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _notesSearchController = TextEditingController();
  final TextEditingController _accountsSearchController =
      TextEditingController();
  final TextEditingController _indexesSearchController =
      TextEditingController();

  String _notesSearchQuery = '';
  String _accountsSearchQuery = '';
  String _indexesSearchQuery = '';

  List<Account> _accounts = [];
  bool _accountsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notesSearchController.addListener(() {
      setState(
        () => _notesSearchQuery = _notesSearchController.text.toLowerCase(),
      );
    });
    _accountsSearchController.addListener(() {
      setState(
        () =>
            _accountsSearchQuery = _accountsSearchController.text.toLowerCase(),
      );
    });
    _indexesSearchController.addListener(() {
      setState(
        () => _indexesSearchQuery = _indexesSearchController.text.toLowerCase(),
      );
    });
    Future.microtask(_loadAccounts);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesSearchController.dispose();
    _accountsSearchController.dispose();
    _indexesSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() => _accountsLoading = true);
    try {
      final repository = ref.read(accountRepositoryProvider);
      final accounts = await repository.listAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _accountsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _accountsLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load accounts: $error')),
      );
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _openNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailPage(note: note)),
    );
    ref.invalidate(notesListProvider);
  }

  Future<void> _openAccount(Account account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountDetailPage(account: account)),
    );

    if (result == 'updated' || result == 'deleted') {
      await _loadAccounts();
    }
  }

  Future<void> _openIndex(IndexEntry index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IndexDetailPage(index: index)),
    );
    ref.invalidate(indexesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AlmanacHeader(theme: theme),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _AlmanacTabs(controller: _tabController),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotesTab(),
                  _buildAccountsTab(),
                  _buildIndexesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    final notesAsync = ref.watch(notesListProvider);

    return notesAsync.when(
      loading: () => const _LoadingState(),
      error: (error, _) => _ErrorState(
        message: 'Could not load notes',
        detail: error.toString(),
        onRetry: () => ref.invalidate(notesListProvider),
      ),
      data: (notes) {
        final filtered = _notesSearchQuery.isEmpty
            ? notes
            : notes.where((note) {
                return note.title.toLowerCase().contains(_notesSearchQuery) ||
                    note.content.toLowerCase().contains(_notesSearchQuery) ||
                    (note.tag?.toLowerCase().contains(_notesSearchQuery) ??
                        false);
              }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(notesListProvider),
          child: _AlmanacList(
            search: _SearchField(
              controller: _notesSearchController,
              hint: 'Search notes',
            ),
            emptyIcon: Icons.edit_note_rounded,
            emptyMessage: 'No notes found',
            isEmpty: filtered.isEmpty,
            children: [
              for (final note in filtered)
                _NoteCard(
                  note: note,
                  dateLabel: _formatDateTime(note.createdAt),
                  onTap: () => _openNote(note),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountsTab() {
    final filtered = _accountsSearchQuery.isEmpty
        ? _accounts
        : _accounts.where((account) {
            return account.title.toLowerCase().contains(_accountsSearchQuery) ||
                account.method.toLowerCase().contains(_accountsSearchQuery) ||
                (account.email?.toLowerCase().contains(_accountsSearchQuery) ??
                    false) ||
                (account.provider?.toLowerCase().contains(
                      _accountsSearchQuery,
                    ) ??
                    false) ||
                (account.tags?.toLowerCase().contains(_accountsSearchQuery) ??
                    false);
          }).toList();

    if (_accountsLoading) return const _LoadingState();

    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: _AlmanacList(
        search: _SearchField(
          controller: _accountsSearchController,
          hint: 'Search accounts',
        ),
        emptyIcon: Icons.shield_outlined,
        emptyMessage: 'No accounts found',
        isEmpty: filtered.isEmpty,
        children: [
          for (final account in filtered)
            _AccountCard(
              account: account,
              dateLabel: _formatDateTime(account.createdAt),
              onTap: () => _openAccount(account),
            ),
        ],
      ),
    );
  }

  Widget _buildIndexesTab() {
    final indexesAsync = ref.watch(indexesListProvider);

    return indexesAsync.when(
      loading: () => const _LoadingState(),
      error: (error, _) => _ErrorState(
        message: 'Could not load indexes',
        detail: error.toString(),
        onRetry: () => ref.invalidate(indexesListProvider),
      ),
      data: (indexes) {
        final filtered = _indexesSearchQuery.isEmpty
            ? indexes
            : indexes.where((index) {
                return index.title.toLowerCase().contains(
                      _indexesSearchQuery,
                    ) ||
                    index.items.any(
                      (item) =>
                          item.item.toLowerCase().contains(_indexesSearchQuery),
                    );
              }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(indexesListProvider),
          child: _AlmanacList(
            search: _SearchField(
              controller: _indexesSearchController,
              hint: 'Search indexes',
            ),
            emptyIcon: Icons.list_alt_rounded,
            emptyMessage: 'No indexes found',
            isEmpty: filtered.isEmpty,
            children: [
              for (final index in filtered)
                _IndexCard(
                  index: index,
                  dateLabel: _formatDateTime(index.createdAt),
                  onTap: () => _openIndex(index),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AlmanacHeader extends StatelessWidget {
  const _AlmanacHeader({required this.theme});

  final ArchivumTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: theme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almanac',
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Notes, credentials, and lists in one quiet place.',
                  style: TextStyle(color: theme.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlmanacTabs extends StatelessWidget {
  const _AlmanacTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.muted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorPadding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        labelColor: theme.primary,
        unselectedLabelColor: theme.mutedForeground,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Notes'),
          Tab(text: 'Accounts'),
          Tab(text: 'Indexes'),
        ],
      ),
    );
  }
}

class _AlmanacList extends StatelessWidget {
  const _AlmanacList({
    required this.search,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.isEmpty,
    required this.children,
  });

  final Widget search;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      children: [
        search,
        const SizedBox(height: 14),
        if (isEmpty)
          _EmptyState(icon: emptyIcon, message: emptyMessage)
        else
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return TextField(
      controller: controller,
      style: TextStyle(color: theme.foreground, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.mutedForeground,
          size: 20,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.mutedForeground,
                  size: 18,
                ),
              ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.dateLabel,
    required this.onTap,
  });

  final Note note;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final tag = note.tag?.trim();

    return _SurfaceCard(
      onTap: onTap,
      icon: Icons.edit_note_rounded,
      accent: theme.primary,
      title: note.title,
      subtitle: note.content,
      metadata: dateLabel,
      chip: tag == null || tag.isEmpty ? null : tag,
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.dateLabel,
    required this.onTap,
  });

  final Account account;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final subtitle = account.method.toLowerCase() == 'sso'
        ? 'SSO via ${account.provider ?? 'provider'}'
        : account.email ?? account.username ?? account.method;

    return _SurfaceCard(
      onTap: onTap,
      icon: _iconForAccount(account.title),
      accent: theme.secondary,
      title: account.title,
      subtitle: subtitle,
      metadata: dateLabel,
      chip: account.tags,
    );
  }

  IconData _iconForAccount(String title) {
    switch (title.toLowerCase()) {
      case 'github':
        return Icons.terminal_rounded;
      case 'gmail':
        return Icons.mail_outline_rounded;
      default:
        return Icons.shield_outlined;
    }
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({
    required this.index,
    required this.dateLabel,
    required this.onTap,
  });

  final IndexEntry index;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final completed = index.items.where((item) => item.isChecked).length;
    final total = index.items.length;
    final preview = index.items.isEmpty
        ? 'No items yet'
        : index.items.take(3).map((item) => item.item).join(' - ');

    return _SurfaceCard(
      onTap: onTap,
      icon: Icons.list_alt_rounded,
      accent: theme.chart1,
      title: index.title,
      subtitle: preview,
      metadata: dateLabel,
      chip: '$completed/$total done',
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.onTap,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.metadata,
    this.chip,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String metadata;
  final String? chip;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: theme.foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        metadata,
                        style: TextStyle(
                          color: theme.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle.isEmpty ? 'No details' : subtitle,
                    style: TextStyle(
                      color: theme.mutedForeground,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chip != null && chip!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chip!,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.mutedForeground,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Center(
      child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: theme.destructive),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: theme.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.mutedForeground, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(icon, color: theme.primary.withValues(alpha: 0.34), size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: theme.mutedForeground, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
