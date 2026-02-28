enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String details;
  final String tag;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.details,
    required this.tag,
    required this.createdAt,
  });
}
