class WalletModel {
  final String userId;
  final String currency;
  final double availableBalance;
  final double lockedBalance;
  final DateTime updatedAt;

  const WalletModel({
    required this.userId,
    this.currency = 'USD',
    this.availableBalance = 0.0,
    this.lockedBalance = 0.0,
    required this.updatedAt,
  });

  double get totalBalance => availableBalance + lockedBalance;

  WalletModel copyWith({
    String? userId,
    String? currency,
    double? availableBalance,
    double? lockedBalance,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      userId: userId ?? this.userId,
      currency: currency ?? this.currency,
      availableBalance: availableBalance ?? this.availableBalance,
      lockedBalance: lockedBalance ?? this.lockedBalance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['user_id'] ?? '',
      currency: json['currency'] ?? 'USD',
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      lockedBalance: (json['locked_balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class LedgerTransactionModel {
  final String id;
  final String userId;
  final String type; // 'DEPOSIT', 'WITHDRAWAL', 'ENTRY_FEE', 'PRIZE_PAYOUT', 'TOPUP_PURCHASE', 'REFUND'
  final double amount;
  final String direction; // 'CREDIT' or 'DEBIT'
  final String? referenceType;
  final String? referenceId;
  final String? note;
  final DateTime createdAt;

  const LedgerTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.direction,
    this.referenceType,
    this.referenceId,
    this.note,
    required this.createdAt,
  });

  bool get isCredit => direction == 'CREDIT';

  factory LedgerTransactionModel.fromJson(Map<String, dynamic> json) {
    return LedgerTransactionModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? 'TRANSACTION',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'] ?? 'CREDIT',
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      note: json['note'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
