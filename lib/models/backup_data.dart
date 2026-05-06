import 'app_settings.dart';
import 'expense.dart';

class BackupData {
  const BackupData({
    required this.schemaVersion,
    required this.createdAt,
    required this.settings,
    required this.expenses,
  });

  final int schemaVersion;
  final DateTime createdAt;
  final AppSettings settings;
  final List<Expense> expenses;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'settings': settings.toJson(),
      'expenses': expenses.map((expense) => expense.toJson()).toList(),
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final settingsJson =
        (json['settings'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final expensesJson = (json['expenses'] as List?) ?? const [];
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.now().toUtc();
    return BackupData(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt: createdAt,
      settings: AppSettings.fromJson(settingsJson),
      expenses: expensesJson
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList(),
    );
  }
}
