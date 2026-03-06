import 'package:flutter/material.dart';

class InsightPage extends StatelessWidget {
  const InsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clr = theme.colorScheme;
    
    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final cardColor = isDark ? clr.primary.withValues(alpha:0.05) : Colors.grey[100];
    final borderColor = clr.primary.withValues(alpha:0.1);

    // The user requested consistent text color (only 2 colors)
    final primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha:0.8),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: clr.primary.withValues(alpha:0.1),
              ),
              child: Icon(Icons.arrow_back, color: clr.primary),
            ),
          ),
        ),
        title: Text(
          'Insights & Analytics',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: clr.primary.withValues(alpha:0.1),
                ),
                child: Icon(Icons.notifications, color: clr.primary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNotesAndQuotesSection(clr, isDark, primaryText, secondaryText, cardColor, borderColor),
              const SizedBox(height: 24),
              _buildIndexRegistrySection(clr, isDark, primaryText, secondaryText, cardColor, borderColor),
              const SizedBox(height: 24),
              _buildFaithStatisticsSection(clr, isDark, primaryText, secondaryText, cardColor, borderColor),
              const SizedBox(height: 24),
              _buildAccountSecuritySection(clr, isDark, primaryText, secondaryText, cardColor, borderColor),
              const SizedBox(height: 24),
              _buildGlobalTagsSection(clr, primaryText),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesAndQuotesSection(ColorScheme clr, bool isDark, Color primaryText, Color secondaryText, Color? cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(Icons.auto_stories, 'Notes & Quotes', clr.primary, primaryText),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL CONTENT',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '166',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: clr.primary.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics, color: clr.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Sub Items
              _buildNotesQuotesSubItem(
                title: 'Total Notes',
                count: '124',
                color: clr.primary,
                primaryText: primaryText,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildNotesQuotesSubItem(
                title: 'Total Quotes',
                count: '42',
                color: clr.secondary,
                primaryText: primaryText,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesQuotesSubItem({
    required String title,
    required String count,
    required Color color,
    required Color primaryText,
    required bool isDark,
  }) {
    final bgColor = isDark ? const Color(0xFF191121) : Colors.white;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha:0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryText,
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'TAGS BREAKDOWN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexRegistrySection(ColorScheme clr, bool isDark, Color primaryText, Color secondaryText, Color? cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(Icons.inventory_2, 'Index Registry', clr.secondary, primaryText),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL INDEXES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '8',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INDEX ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '215',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFaithStatisticsSection(ColorScheme clr, bool isDark, Color primaryText, Color secondaryText, Color? cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(Icons.volunteer_activism, 'Faith Statistics', clr.primary, primaryText),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                clr.primary.withValues(alpha:0.2),
                clr.secondary.withValues(alpha:0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: clr.primary.withValues(alpha:0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFaithStatItem('TOTAL PRAYERS', '1,284', clr.primary, secondaryText),
                  Container(width: 1, height: 40, color: clr.primary.withValues(alpha:0.1)),
                  _buildFaithStatItem('AVG DAILY', '4.2', clr.primary, secondaryText),
                  Container(width: 1, height: 40, color: clr.primary.withValues(alpha:0.1)),
                  Column(
                    children: [
                      Text(
                        'STREAK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: secondaryText,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '15',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: clr.secondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.local_fire_department, color: clr.secondary, size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: clr.primary.withValues(alpha:0.1)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion Rate',
                    style: TextStyle(fontSize: 12, color: primaryText),
                  ),
                  Text(
                    '92%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.92,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(clr.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaithStatItem(String label, String value, Color valueColor, Color secondaryText) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSecuritySection(ColorScheme clr, bool isDark, Color primaryText, Color secondaryText, Color? cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(Icons.shield_outlined, 'Account Security', clr.primary, primaryText),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL ACCOUNTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: secondaryText,
                          ),
                        ),
                        Text(
                          '12',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clr.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('VIEW DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('METHOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: clr.primary)),
                          const SizedBox(height: 8),
                          _buildAccountRow('Email/Pass', '4', primaryText),
                          const SizedBox(height: 8),
                          _buildAccountRow('SSO', '8', primaryText),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SSO PROVIDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: clr.secondary)),
                          const SizedBox(height: 8),
                          _buildAccountRow('Google', '5', primaryText),
                          const SizedBox(height: 8),
                          _buildAccountRow('GitHub', '2', primaryText),
                          const SizedBox(height: 8),
                          _buildAccountRow('Facebook', '1', primaryText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountRow(String label, String value, Color primaryText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: primaryText)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryText)),
      ],
    );
  }

  Widget _buildGlobalTagsSection(ColorScheme clr, Color primaryText) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: clr.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: clr.primary.withValues(alpha:0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sell, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM TAXONOMY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha:0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Text(
                      'Total Tags: 58',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text(
                    'Feature Breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
