class Allotment {
  final String id;
  final DateTime date;
  final String table;
  final double amount;

  Allotment({
    required this.id,
    required this.date,
    required this.table,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'table': table,
        'amount': amount,
      };

  factory Allotment.fromJson(Map<String, dynamic> json) => Allotment(
        id: json['id'],
        date: DateTime.parse(json['date']),
        table: json['table'],
        amount: (json['amount'] as num).toDouble(),
      );
}

class Expense {
  final String id;
  final DateTime date;
  final String table;
  final double amount;
  final String reason;

  Expense({
    required this.id,
    required this.date,
    required this.table,
    required this.amount,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'table': table,
        'amount': amount,
        'reason': reason,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        date: DateTime.parse(json['date']),
        table: json['table'],
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'],
      );
}
