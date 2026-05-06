class Expense {
  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.category = '',
    this.notes = '',
  });

  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final String category;
  final String notes;

  Expense copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'notes': notes,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: (json['category'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
    );
  }
}
