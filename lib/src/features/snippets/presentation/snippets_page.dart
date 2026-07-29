import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/account_repository_provider.dart';
import '../../../core/providers/snippet_repository_provider.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_detail_page.dart';
import '../../accounts/presentation/add_credential_page.dart';
import '../../indexes/domain/index_item.dart';
import '../../indexes/presentation/add_index_page.dart';
import '../../indexes/presentation/index_detail_page.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/add_note_page.dart';
import '../../notes/presentation/note_detail_page.dart';
import 'almanac_style.dart';

enum _AlmanacTab { notes, accounts, indexes }

class SnippetsPage extends ConsumerStatefulWidget {
  const SnippetsPage({super.key});

  @override
  ConsumerState<SnippetsPage> createState() => _SnippetsPageState();
}

class _SnippetsPageState extends ConsumerState<SnippetsPage> {
  final TextEditingController _searchController = TextEditingController();
  _AlmanacTab _selectedTab = _AlmanacTab.accounts;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      ref.invalidate(accountsListProvider);
    }
  }

  Future<void> _openIndex(IndexEntry index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IndexDetailPage(index: index)),
    );
    ref.invalidate(indexesListProvider);
  }

  Future<void> _openAddNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddNotePage()),
    );
    ref.invalidate(notesListProvider);
  }

  Future<void> _openAddAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCredentialPage()),
    );
    ref.invalidate(accountsListProvider);
  }

  Future<void> _openAddIndex() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddIndexPage()),
    );
    ref.invalidate(indexesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesListProvider);
    final accountsAsync = ref.watch(accountsListProvider);
    final indexesAsync = ref.watch(indexesListProvider);

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
                  title: 'ARCHIVUM',
                  subtitle: 'Almanac memory index',
                  actions: [
                    AlmanacIconButton(
                      icon: Icons.note_add_rounded,
                      tooltip: 'Add note',
                      color: AlmanacColors.primarySoft,
                      onTap: _openAddNote,
                    ),
                    const SizedBox(width: 8),
                    AlmanacIconButton(
                      icon: Icons.key_rounded,
                      tooltip: 'Add account',
                      color: AlmanacColors.secondary,
                      onTap: _openAddAccount,
                    ),
                    const SizedBox(width: 8),
                    AlmanacIconButton(
                      icon: Icons.playlist_add_rounded,
                      tooltip: 'Add index',
                      color: AlmanacColors.tertiary,
                      onTap: _openAddIndex,
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AlmanacColors.primary,
                    backgroundColor: AlmanacColors.surfaceHigh,
                    onRefresh: () async {
                      ref.invalidate(notesListProvider);
                      ref.invalidate(accountsListProvider);
                      ref.invalidate(indexesListProvider);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 118),
                      children: [
                        _SearchField(
                          controller: _searchController,
                          hasText: _searchQuery.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        _TabStrip(
                          selected: _selectedTab,
                          notesCount: notesAsync.asData?.value.length,
                          accountsCount: accountsAsync.asData?.value.length,
                          indexesCount: indexesAsync.asData?.value.length,
                          onChanged: (tab) =>
                              setState(() => _selectedTab = tab),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildSelectedContent(
                            notesAsync,
                            accountsAsync,
                            indexesAsync,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedContent(
    AsyncValue<List<Note>> notesAsync,
    AsyncValue<List<Account>> accountsAsync,
    AsyncValue<List<IndexEntry>> indexesAsync,
  ) {
    return switch (_selectedTab) {
      _AlmanacTab.notes => notesAsync.when(
        loading: () => const _LoadingState(key: ValueKey('notes-loading')),
        error: (error, _) => _ErrorState(
          key: const ValueKey('notes-error'),
          message: 'Could not load notes',
          detail: AppError.from(error).message,
          onRetry: () => ref.invalidate(notesListProvider),
        ),
        data: _buildNotesGrid,
      ),
      _AlmanacTab.accounts => accountsAsync.when(
        loading: () => const _LoadingState(key: ValueKey('accounts-loading')),
        error: (error, _) => _ErrorState(
          key: const ValueKey('accounts-error'),
          message: 'Could not load accounts',
          detail: AppError.from(error).message,
          onRetry: () => ref.invalidate(accountsListProvider),
        ),
        data: _buildAccountsGrid,
      ),
      _AlmanacTab.indexes => indexesAsync.when(
        loading: () => const _LoadingState(key: ValueKey('indexes-loading')),
        error: (error, _) => _ErrorState(
          key: const ValueKey('indexes-error'),
          message: 'Could not load indexes',
          detail: AppError.from(error).message,
          onRetry: () => ref.invalidate(indexesListProvider),
        ),
        data: _buildIndexesGrid,
      ),
    };
  }

  Widget _buildNotesGrid(List<Note> notes) {
    final filtered = _searchQuery.isEmpty
        ? notes
        : notes.where((note) {
            return note.title.toLowerCase().contains(_searchQuery) ||
                note.content.toLowerCase().contains(_searchQuery) ||
                (note.tag?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        key: const ValueKey('notes-empty'),
        icon: Icons.description_rounded,
        message: 'No note records match this query.',
        actionLabel: 'Capture note',
        onAction: _openAddNote,
      );
    }

    return _ResponsiveGrid(
      key: const ValueKey('notes-grid'),
      children: [
        for (final note in filtered)
          _NoteCard(
            note: note,
            dateLabel: _formatDateTime(note.createdAt),
            onTap: () => _openNote(note),
          ),
      ],
    );
  }

  Widget _buildAccountsGrid(List<Account> accounts) {
    final filtered = _searchQuery.isEmpty
        ? accounts
        : accounts.where((account) {
            return account.title.toLowerCase().contains(_searchQuery) ||
                account.method.toLowerCase().contains(_searchQuery) ||
                (account.email?.toLowerCase().contains(_searchQuery) ??
                    false) ||
                (account.username?.toLowerCase().contains(_searchQuery) ??
                    false) ||
                (account.provider?.toLowerCase().contains(_searchQuery) ??
                    false) ||
                (account.tags?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        key: const ValueKey('accounts-empty'),
        icon: Icons.key_rounded,
        message: 'No account records match this query.',
        actionLabel: 'Add account',
        onAction: _openAddAccount,
      );
    }

    return _ResponsiveGrid(
      key: const ValueKey('accounts-grid'),
      children: [
        for (final account in filtered)
          _AccountCard(
            account: account,
            dateLabel: _formatDateTime(account.createdAt),
            onTap: () => _openAccount(account),
          ),
      ],
    );
  }

  Widget _buildIndexesGrid(List<IndexEntry> indexes) {
    final filtered = _searchQuery.isEmpty
        ? indexes
        : indexes.where((index) {
            return index.title.toLowerCase().contains(_searchQuery) ||
                index.items.any(
                  (item) => item.item.toLowerCase().contains(_searchQuery),
                );
          }).toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        key: const ValueKey('indexes-empty'),
        icon: Icons.dataset_rounded,
        message: 'No indexes match this query.',
        actionLabel: 'Build index',
        onAction: _openAddIndex,
      );
    }

    return _ResponsiveGrid(
      key: const ValueKey('indexes-grid'),
      children: [
        for (final index in filtered)
          _IndexCard(
            index: index,
            dateLabel: _formatDateTime(index.createdAt),
            onTap: () => _openIndex(index),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hasText});

  final TextEditingController controller;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AlmanacColors.foreground,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Search the Almanac...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: AlmanacColors.surfaceLow.withValues(alpha: 0.92),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AlmanacColors.outline, width: 2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AlmanacColors.outline, width: 2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AlmanacColors.primary, width: 2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.selected,
    required this.notesCount,
    required this.accountsCount,
    required this.indexesCount,
    required this.onChanged,
  });

  final _AlmanacTab selected;
  final int? notesCount;
  final int? accountsCount;
  final int? indexesCount;
  final ValueChanged<_AlmanacTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabPill(
            label: 'Notes',
            count: notesCount,
            tab: _AlmanacTab.notes,
            selected: selected,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabPill(
            label: 'Accounts',
            count: accountsCount,
            tab: _AlmanacTab.accounts,
            selected: selected,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabPill(
            label: 'Indexes',
            count: indexesCount,
            tab: _AlmanacTab.indexes,
            selected: selected,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.tab,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final int? count;
  final _AlmanacTab tab;
  final _AlmanacTab selected;
  final ValueChanged<_AlmanacTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = tab == selected;
    return InkWell(
      onTap: () => onChanged(tab),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AlmanacColors.primary : AlmanacColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? AlmanacColors.primary
                : AlmanacColors.outline.withValues(alpha: 0.72),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AlmanacColors.primary.withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isActive
                      ? AlmanacColors.background
                      : AlmanacColors.foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    color: isActive
                        ? AlmanacColors.background.withValues(alpha: 0.74)
                        : AlmanacColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
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
    final tag = note.tag?.trim();
    return _ArchiveCard(
      onTap: onTap,
      icon: Icons.description_rounded,
      accent: AlmanacColors.primary,
      title: note.title,
      metadata: dateLabel,
      body: note.content.isEmpty ? 'No body text captured.' : note.content,
      chips: [if (tag != null && tag.isNotEmpty) '#$tag'],
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
    final provider = account.provider?.trim();
    final tag = account.tags?.trim();
    final subtitle = account.method.toLowerCase() == 'sso'
        ? 'SSO via ${provider == null || provider.isEmpty ? 'provider' : provider}'
        : account.email ?? account.username ?? 'Email-password credential';

    return _ArchiveCard(
      onTap: onTap,
      icon: _iconForAccount(account),
      accent: AlmanacColors.secondary,
      title: account.title,
      metadata: dateLabel,
      body: subtitle,
      chips: [
        account.method.toUpperCase(),
        if (tag != null && tag.isNotEmpty) '#$tag',
      ],
    );
  }

  IconData _iconForAccount(Account account) {
    final haystack = '${account.title} ${account.provider ?? ''}'.toLowerCase();
    if (haystack.contains('github')) return Icons.terminal_rounded;
    if (haystack.contains('google') || haystack.contains('gmail')) {
      return Icons.alternate_email_rounded;
    }
    return Icons.key_rounded;
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
    final completed = index.items.where((item) => item.isChecked).length;
    final total = index.items.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final preview = index.items.isEmpty
        ? 'No items yet.'
        : index.items.take(3).map((item) => item.item).join(' - ');

    return AlmanacButtonPanel(
      onTap: onTap,
      borderColor: AlmanacColors.tertiary.withValues(alpha: 0.32),
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 204,
        child: Stack(
          children: [
            Positioned(
              top: -4,
              right: -2,
              child: Icon(
                Icons.dataset_rounded,
                color: AlmanacColors.foreground.withValues(alpha: 0.08),
                size: 74,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: AlmanacColors.tertiary,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'GLOBAL INDEX',
                      style: TextStyle(
                        color: AlmanacColors.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  index.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AlmanacColors.foreground,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AlmanacColors.muted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text(
                      'PROGRESS',
                      style: TextStyle(
                        color: AlmanacColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        color: AlmanacColors.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AlmanacColors.surfaceHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AlmanacColors.tertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AlmanacColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({
    required this.onTap,
    required this.icon,
    required this.accent,
    required this.title,
    required this.metadata,
    required this.body,
    required this.chips,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color accent;
  final String title;
  final String metadata;
  final String body;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return AlmanacButtonPanel(
      onTap: onTap,
      borderColor: accent.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 202,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 21),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    metadata,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AlmanacColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AlmanacColors.foreground,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AlmanacColors.muted,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final chip in chips.where(
                  (chip) => chip.trim().isNotEmpty,
                ))
                  _Chip(label: chip, accent: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AlmanacColors.surfaceHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AlmanacColors.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey('loading-box'),
      height: 260,
      child: Center(
        child: CircularProgressIndicator(
          color: AlmanacColors.primary,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
    super.key,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AlmanacPanel(
      borderColor: AlmanacColors.error.withValues(alpha: 0.36),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AlmanacColors.error),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AlmanacColors.foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AlmanacColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AlmanacPanel(
      borderColor: AlmanacColors.outline.withValues(alpha: 0.4),
      child: SizedBox(
        height: 210,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AlmanacColors.primarySoft, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AlmanacColors.muted),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onAction,
              style: almanacCommitButtonStyle(AlmanacColors.primary),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
