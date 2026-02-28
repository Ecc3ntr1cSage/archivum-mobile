import 'package:flutter/material.dart';
import 'add_credential_page.dart';

// Reusable credential card for saved items
class CredentialCard extends StatelessWidget {
  final Map<String, String> item;

  const CredentialCard({required this.item, super.key});

  IconData _getIconForService(String service) {
    switch (service.toLowerCase()) {
      case 'github':
        return Icons.terminal;
      case 'gmail':
        return Icons.mail;
      case 'adobe creative cloud':
        return Icons.palette;
      default:
        return Icons.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final accentOrange = const Color(0xFFF97316);

    final isSso = item['method'] == 'SSO';
    final cardBgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.4)
        : const Color(0xFFF7F6F8);
    final hoverBgColor = primary.withValues(alpha: 0.05);

    // Some simple mock logic to color code icons
    final isOrangeTheme = item['service']?.toLowerCase() == 'gmail';
    final themeColor = isOrangeTheme ? accentOrange : primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        hoverColor: hoverBgColor,
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getIconForService(item['service'] ?? ''),
                    color: themeColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item['service'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            height: 1,
                          ),
                        ),
                        if (isSso) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SSO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accentOrange,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSso
                          ? 'Primary: ${item['provider']} Login'
                          : (item['email'] ?? ''),
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

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  // Mock data as in the HTML design
  final List<Map<String, String>> _saved = [
    {
      'service': 'GitHub',
      'email': 'johndoe@example.com',
      'username': 'johndoe',
      'method': 'Username',
      'provider': '',
    },
    {
      'service': 'Gmail',
      'email': 'johndoe@gmail.com',
      'username': '',
      'method': 'SSO',
      'provider': 'Google',
    },
    {
      'service': 'Adobe Creative Cloud',
      'email': 'creative.mind@studio.com',
      'username': '',
      'method': 'Username',
      'provider': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final headerBgColor = isDark
        ? const Color(0xFF191121).withValues(alpha: 0.8)
        : const Color(0xFFF7F6F8).withValues(alpha: 0.8);

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account Credentials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newItem = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddCredentialPage(),
                        ),
                      );
                      if (newItem != null && newItem is Map<String, String>) {
                        setState(() {
                          _saved.insert(0, newItem);
                        });
                      }
                    },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saved Credentials Section
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_saved.length} Total'.toUpperCase(),
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
            const SizedBox(height: 16),

            Column(
              children: _saved.isEmpty
                  ? [
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text(
                          'No credentials saved yet',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ]
                  : _saved.map((e) => CredentialCard(item: e)).toList(),
            ),

            const SizedBox(height: 80), // Padding for bottom navbar
          ],
        ),
      ),
    );
  }
}
