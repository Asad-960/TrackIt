import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/backup_data.dart';
import '../models/expense.dart';

class MonthlyTotal {
  const MonthlyTotal(this.month, this.total);

  final DateTime month;
  final double total;
}

class YearlyTotal {
  const YearlyTotal(this.year, this.total);

  final int year;
  final double total;
}

class ExpenseStore extends ChangeNotifier {
  ExpenseStore(this._preferences);

  static const _expensesKey = 'trackit_expenses';
  static const _settingsKey = 'trackit_settings';
  static const int _schemaVersion = 1;

  final SharedPreferences _preferences;

  List<Expense> _expenses = [];
  AppSettings _settings = AppSettings.defaults();

  List<Expense> get expenses => List.unmodifiable(_expenses);

  AppSettings get settings => _settings;

  static Future<ExpenseStore> load({String? localeTag}) async {
    final preferences = await SharedPreferences.getInstance();
    final store = ExpenseStore(preferences);
    store._loadFromPreferences(localeTag: localeTag);
    return store;
  }

  void _loadFromPreferences({String? localeTag}) {
    final rawExpenses = _preferences.getString(_expensesKey);
    if (rawExpenses != null && rawExpenses.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawExpenses) as List<dynamic>;
        _expenses = decoded
            .whereType<Map<String, dynamic>>()
            .map(Expense.fromJson)
            .toList();
        _sortExpenses();
      } catch (error) {
        debugPrint('Failed to load expenses: $error');
        _expenses = [];
      }
    }

    final rawSettings = _preferences.getString(_settingsKey);
    if (rawSettings != null && rawSettings.isNotEmpty) {
      try {
        _settings = AppSettings.fromJson(
          (jsonDecode(rawSettings) as Map).cast<String, dynamic>(),
        );
      } catch (error) {
        debugPrint('Failed to load settings: $error');
        _settings = AppSettings.defaults(localeTag: localeTag);
      }
    } else {
      _settings = AppSettings.defaults(localeTag: localeTag);
    }
  }

  Future<void> _persist() async {
    await _preferences.setString(
      _expensesKey,
      jsonEncode(_expenses.map((expense) => expense.toJson()).toList()),
    );
    await _preferences.setString(
      _settingsKey,
      jsonEncode(_settings.toJson()),
    );
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _sortExpenses();
    await _persist();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      return;
    }
    _expenses[index] = expense;
    _sortExpenses();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((expense) => expense.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _persist();
    notifyListeners();
  }

  List<Expense> expensesForDate(DateTime date) {
    final target = DateUtils.dateOnly(date);
    return _expenses
        .where((expense) => DateUtils.dateOnly(expense.date) == target)
        .toList();
  }

  double totalForDate(DateTime date) {
    return expensesForDate(date)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double totalForMonth(DateTime date) {
    return _expenses
        .where(
          (expense) =>
              expense.date.year == date.year &&
              expense.date.month == date.month,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double totalForYear(int year) {
    return _expenses
        .where((expense) => expense.date.year == year)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  List<MonthlyTotal> monthlyTotals() {
    if (_expenses.isEmpty) {
      return [];
    }

    final oldestExpense = _expenses.reduce(
      (current, candidate) =>
          candidate.date.isBefore(current.date) ? candidate : current,
    );
    final startMonth = DateTime(oldestExpense.date.year, oldestExpense.date.month);
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

    final history = <MonthlyTotal>[];
    for (var month = currentMonth;
        !month.isBefore(startMonth);
        month = DateTime(month.year, month.month - 1)) {
      final total = _expenses
          .where(
            (expense) =>
                expense.date.year == month.year &&
                expense.date.month == month.month,
          )
          .fold<double>(0, (sum, expense) => sum + expense.amount);
      history.add(MonthlyTotal(month, total));
    }
    return history;
  }

  List<YearlyTotal> yearlyTotals() {
    final totals = <int, double>{};
    for (final expense in _expenses) {
      final year = expense.date.year;
      totals[year] = (totals[year] ?? 0) + expense.amount;
    }
    final years = totals.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final year in years) YearlyTotal(year, totals[year]!)
    ];
  }

  String exportBackup() {
    final data = BackupData(
      schemaVersion: _schemaVersion,
      createdAt: DateTime.now().toUtc(),
      settings: _settings,
      expenses: _expenses,
    );
    return jsonEncode(data.toJson());
  }

  Future<void> restoreBackup(String rawJson) async {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final backup = BackupData.fromJson(decoded);
    _expenses = backup.expenses;
    _settings = backup.settings;
    _sortExpenses();
    await _persist();
    notifyListeners();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

}
