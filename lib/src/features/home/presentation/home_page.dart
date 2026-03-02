import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messages = ref.watch(chatControllerProvider);

    return Column(
      children: [
        // ── Header bar ────────────────────────────────────────────────
        _ChatHeader(colorScheme: colorScheme),

        // ── Chat view ─────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            reverse: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return _ChatBubble(
                text: msg.text,
                isUser: msg.isUser,
                isLoading: msg.isLoading,
                colorScheme: colorScheme,
              );
            },
          ),
        ),

        // ── Input bar ─────────────────────────────────────────────────
        _InputBar(colorScheme: colorScheme),
      ],
    );
  }
}

// ── Header widget ─────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archivum Agent',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                ),
                Text(
                  'MiniMax M2.5',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          // Online indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.greenAccent.shade400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bubble widget ─────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.isLoading,
    required this.colorScheme,
  });

  final String text;
  final bool isUser;
  final bool isLoading;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            topRight: !isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSurface,
                ),
              )
            : Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
              ),
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends ConsumerStatefulWidget {
  const _InputBar({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  ConsumerState<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<_InputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.isEmpty) return;
    ref.read(chatControllerProvider.notifier).sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: widget.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Enter search request...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: widget.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: widget.colorScheme.outlineVariant,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: widget.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded),
              color: widget.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
