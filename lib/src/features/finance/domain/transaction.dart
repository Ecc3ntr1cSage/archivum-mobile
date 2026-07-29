enum TransactionType { income, expense, transfer }

enum TransferSide { out, in_ }

class FinanceTag {
  final String id;
  final String text;

  const FinanceTag({required this.id, required this.text});

  factory FinanceTag.fromJson(Map<String, dynamic> json) {
    return FinanceTag(id: json['id'].toString(), text: json['text'] ?? '');
  }
}

class TransactionSplit {
  final String? id;
  final String? transactionId;
  final String tagId;
  final String tagText;
  final double amount;

  const TransactionSplit({
    this.id,
    this.transactionId,
    required this.tagId,
    required this.tagText,
    required this.amount,
  });

  factory TransactionSplit.fromJson(Map<String, dynamic> json) {
    final tag = json['tags'];
    return TransactionSplit(
      id: json['id']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      tagId: json['tag_id']?.toString() ?? '',
      tagText: tag is Map<String, dynamic>
          ? tag['text']?.toString() ?? 'Other'
          : json['tag_text']?.toString() ?? 'Other',
      amount: ((json['amount'] as num?) ?? 0) / 100,
    );
  }
}

class FinancialAccount {
  final String? id;
  final String? userId;
  final String name;
  final String type;
  final String? institution;
  final String currency;
  final double openingBalance;
  final double currentBalance;
  final DateTime? createdAt;

  const FinancialAccount({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    this.institution,
    this.currency = 'MYR',
    this.openingBalance = 0,
    this.currentBalance = 0,
    this.createdAt,
  });

  FinancialAccount copyWith({double? currentBalance}) {
    return FinancialAccount(
      id: id,
      userId: userId,
      name: name,
      type: type,
      institution: institution,
      currency: currency,
      openingBalance: openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'type': type,
      if (institution != null && institution!.isNotEmpty)
        'institution': institution,
      'currency': currency,
      'opening_balance': (openingBalance * 100).round(),
    };
  }

  factory FinancialAccount.fromJson(Map<String, dynamic> json) {
    return FinancialAccount(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? 'cash',
      institution: json['institution'],
      currency: json['currency'] ?? 'MYR',
      openingBalance: ((json['opening_balance'] as num?) ?? 0) / 100,
      currentBalance: ((json['current_balance'] as num?) ?? 0) / 100,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at']),
    );
  }
}

class Budget {
  final String? id;
  final String tagId;
  final String tagText;
  final String currency;
  final double limitAmount;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double usedAmount;

  const Budget({
    this.id,
    required this.tagId,
    required this.tagText,
    this.currency = 'MYR',
    required this.limitAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.usedAmount = 0,
  });

  factory Budget.fromJson(Map<String, dynamic> json, {double usedAmount = 0}) {
    final tag = json['tags'];
    return Budget(
      id: json['id']?.toString(),
      tagId: json['tag_id']?.toString() ?? '',
      tagText: tag is Map<String, dynamic>
          ? tag['text']?.toString() ?? 'Other'
          : json['tag_text']?.toString() ?? 'Other',
      currency: json['currency'] ?? 'MYR',
      limitAmount: ((json['limit_amount'] as num?) ?? 0) / 100,
      period: json['period'] ?? 'monthly',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] as bool? ?? true,
      usedAmount: usedAmount,
    );
  }
}

class TransactionModel {
  final String id;
  final String? accountId;
  final String? accountName;
  final String? accountCurrency;
  final TransactionType type;
  final double amount;
  final String? merchant;
  final String details;
  final DateTime? date;
  final bool recurring;
  final String? recurringSourceId;
  final String? transferId;
  final TransferSide? transferSide;
  final List<TransactionSplit> splits;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    this.accountId,
    this.accountName,
    this.accountCurrency,
    required this.type,
    required this.amount,
    this.merchant,
    required this.details,
    this.date,
    this.recurring = false,
    this.recurringSourceId,
    this.transferId,
    this.transferSide,
    this.splits = const [],
    required this.createdAt,
  });

  DateTime get displayDate => date ?? createdAt;

  String get tagLabel {
    if (splits.isEmpty) return 'Transfer';
    return splits.map((split) => split.tagText).join(', ');
  }
}
