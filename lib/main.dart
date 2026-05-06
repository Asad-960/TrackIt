import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/app_settings.dart';
import 'models/expense.dart';
import 'services/expense_store.dart';

final ThemeData _appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F766E),
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF7F8FA),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFE7EAF0)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFCCEFEA),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD8DEE9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD8DEE9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
    ),
  ),
);

final DateTime _firstAllowedDate = DateTime(2019, 1, 1);
final Random _idRandom = Random();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final localeTag =
      WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
  runApp(TrackItApp(localeTag: localeTag));
}

class TrackItApp extends StatelessWidget {
  TrackItApp({super.key, required String localeTag})
      : _storeFuture = ExpenseStore.load(localeTag: localeTag);

  final Future<ExpenseStore> _storeFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExpenseStore>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            title: 'TrackIt',
            theme: _appTheme,
            debugShowCheckedModeBanner: false,
            home: const LoadingScreen(),
          );
        }
        return AppStateScope(
          notifier: snapshot.data!,
          child: MaterialApp(
            title: 'TrackIt',
            theme: _appTheme,
            debugShowCheckedModeBanner: false,
            home: const HomeShell(),
          ),
        );
      },
    );
  }
}

class AppStateScope extends InheritedNotifier<ExpenseStore> {
  const AppStateScope({
    super.key,
    required ExpenseStore notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ExpenseStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('AppStateScope not found in widget tree.');
    }
    return scope.notifier!;
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Expenses',
    'Reports',
    'Backup',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_currentIndex]),
            Text(
              _titles[_currentIndex] == 'Expenses'
                  ? 'Track today and review the full timeline.'
                  : _titles[_currentIndex] == 'Reports'
                      ? 'Scan month-by-month history and yearly totals.'
                      : _titles[_currentIndex] == 'Backup'
                          ? 'Export or restore your local data.'
                          : 'Personalize the app to your preference.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FBF9), Color(0xFFF7F8FA)],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            ExpensesPage(),
            ReportsPage(),
            BackupPage(),
            SettingsPage(),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExpenseFormPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_upload),
            label: 'Backup',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final expenses = store.expensesForDate(_selectedDate);
        final total = store.totalForDate(_selectedDate);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateSelector(
                    selectedDate: _selectedDate,
                    onChanged: (date) {
                      setState(() {
                        _selectedDate = DateUtils.dateOnly(date);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Daily total',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatAmount(total, store.settings.currencySymbol),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: expenses.isEmpty
                  ? const _EmptyState(
                      title: 'No expenses yet',
                      message: 'Tap + to add your first expense for the day.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: expenses.length,
                        separatorBuilder: (context, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return _ExpenseTile(expense: expense);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.of(context);
    final subtitleParts = <String>[];
    if (expense.category.trim().isNotEmpty) {
      subtitleParts.add('Category: ${expense.category}');
    }
    if (expense.notes.trim().isNotEmpty) {
      subtitleParts.add(expense.notes);
    }
    return Card(
      child: ListTile(
        title: Text(expense.name),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(subtitleParts.join(' • ')),
        trailing: Text(
          formatAmount(expense.amount, store.settings.currencySymbol),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExpenseFormPage(expense: expense),
            ),
          );
        },
        onLongPress: () => _confirmDelete(context, expense),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Expense expense) async {
    final store = AppStateScope.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.name}" from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete ?? false) {
      await store.deleteExpense(expense.id);
    }
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.onChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(selectedDate.subtract(const Duration(days: 1))),
        ),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: _firstAllowedDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: Text(formatDate(selectedDate)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(selectedDate.add(const Duration(days: 1))),
        ),
      ],
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final monthlyTotals = store.monthlyTotals();
        final yearlyTotals = store.yearlyTotals();
        final now = DateTime.now();
        final monthTotal = store.totalForMonth(now);
        final yearTotal = store.totalForYear(now.year);
        final trackedMonths = monthlyTotals.where((entry) => entry.total > 0).length;
        final totalTracked = monthlyTotals.fold<double>(0, (sum, entry) => sum + entry.total);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracking overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${monthlyTotals.isEmpty ? 0 : monthlyTotals.length} months in the timeline',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'This Month',
                          subtitle: formatMonth(now),
                          total: formatAmount(
                            monthTotal,
                            store.settings.currencySymbol,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'This Year',
                          subtitle: now.year.toString(),
                          total: formatAmount(
                            yearTotal,
                            store.settings.currencySymbol,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Tracked months',
                    value: trackedMonths.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Lifetime total',
                    value: formatAmount(
                      totalTracked,
                      store.settings.currencySymbol,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Monthly history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (monthlyTotals.isEmpty)
              const _EmptyState(
                title: 'No history yet',
                message: 'Add expenses to see monthly totals.',
              )
            else
              ..._historySections(monthlyTotals).map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.year.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...section.months.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: entry.total == 0
                                      ? const Color(0xFFF5F7FA)
                                      : const Color(0xFFEAF8F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  title: Text(formatMonth(entry.month)),
                                  subtitle: entry.total == 0
                                      ? const Text('No spending recorded')
                                      : const Text('Activity recorded this month'),
                                  trailing: Text(
                                    formatAmount(
                                      entry.total,
                                      store.settings.currencySymbol,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Yearly totals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (yearlyTotals.isEmpty)
              const _EmptyState(
                title: 'No yearly totals yet',
                message: 'Keep tracking to see yearly totals.',
              )
            else
              ...yearlyTotals.map(
                (entry) => Card(
                  child: ListTile(
                    title: Text(entry.year.toString()),
                    subtitle: const Text('Yearly spending total'),
                    trailing: Text(
                      formatAmount(
                        entry.total,
                        store.settings.currencySymbol,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _HistorySection {
  const _HistorySection({required this.year, required this.months});

  final int year;
  final List<MonthlyTotal> months;
}

List<_HistorySection> _historySections(List<MonthlyTotal> totals) {
  final sections = <_HistorySection>[];
  for (final entry in totals) {
    if (sections.isEmpty || sections.last.year != entry.month.year) {
      sections.add(_HistorySection(year: entry.month.year, months: [entry]));
    } else {
      sections.last.months.add(entry);
    }
  }
  return sections;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.total,
  });

  final String title;
  final String subtitle;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(total, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup & Restore',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Export a secure JSON backup and store it somewhere safe. '
                      'You can restore it later from any device.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showBackup(context, store),
                      icon: const Icon(Icons.copy),
                      label: const Text('Export backup'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _restoreBackup(context, store),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Restore from backup'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (store.settings.backupProvider == BackupProvider.cloud)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Cloud backup is selected but not configured yet. '
                    'Use manual backups for now.',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showBackup(BuildContext context, ExpenseStore store) async {
    final backup = store.exportBackup();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup JSON',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SelectableText(backup),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: backup));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup copied.')),
                      );
                    }
                  },
                  child: const Text('Copy'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreBackup(BuildContext context, ExpenseStore store) async {
    final controller = TextEditingController();
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Paste backup JSON',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (shouldRestore ?? false) {
      try {
        await store.restoreBackup(controller.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored.')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $error')),
          );
        }
      }
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _localeController = TextEditingController();
  BackupProvider? _backupProvider;
  bool _initialized = false;

  @override
  void dispose() {
    _currencyController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!_initialized) {
          _currencyController.text = store.settings.currencySymbol;
          _localeController.text = store.settings.localeTag;
          _backupProvider = store.settings.backupProvider;
          _initialized = true;
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currencyController,
              decoration: const InputDecoration(
                labelText: 'Currency symbol',
                helperText: 'Used in totals and reports.',
                border: OutlineInputBorder(),
              ),
              maxLength: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _localeController,
              decoration: const InputDecoration(
                labelText: 'Locale tag',
                helperText: 'Optional override (e.g., en-US).',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BackupProvider>(
              initialValue: _backupProvider,
              decoration: const InputDecoration(
                labelText: 'Backup provider',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: BackupProvider.local,
                  child: Text('Local (manual JSON backup)'),
                ),
                DropdownMenuItem(
                  value: BackupProvider.cloud,
                  child: Text('Cloud (setup required)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _backupProvider = value;
                });
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Storage mode'),
              subtitle: const Text('Offline-first on-device storage'),
              leading: const Icon(Icons.storage),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Device locale'),
              subtitle: Text(Localizations.localeOf(context).toLanguageTag()),
              leading: const Icon(Icons.language),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final symbol = _currencyController.text.trim();
                if (symbol.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Currency symbol is required.')),
                  );
                  return;
                }
                await store.updateSettings(
                  store.settings.copyWith(
                    currencySymbol: symbol,
                    localeTag: _localeController.text.trim(),
                    backupProvider: _backupProvider ?? BackupProvider.local,
                  ),
                );
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved.')),
                );
              },
              child: const Text('Save settings'),
            ),
          ],
        );
      },
    );
  }
}

class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toStringAsFixed(2) : '',
    );
    _categoryController =
        TextEditingController(text: widget.expense?.category ?? '');
    _notesController =
        TextEditingController(text: widget.expense?.notes ?? '');
    _selectedDate =
        widget.expense != null ? widget.expense!.date : DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the item name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(formatDate(_selectedDate)),
                trailing: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: _firstAllowedDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final amount = double.tryParse(_amountController.text.trim());
                  if (amount == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid amount.'),
                      ),
                    );
                    return;
                  }
                  final expense = (widget.expense ?? _newExpense()).copyWith(
                    name: _nameController.text.trim(),
                    amount: amount,
                    category: _categoryController.text.trim(),
                    notes: _notesController.text.trim(),
                    date: _selectedDate,
                  );
                  if (widget.expense == null) {
                    await store.addExpense(expense);
                  } else {
                    await store.updateExpense(expense);
                  }
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                },
                child: Text(widget.expense == null ? 'Add expense' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expense _newExpense() {
    return Expense(
      id: 'exp_${DateTime.now().microsecondsSinceEpoch}_${_idRandom.nextInt(100000)}',
      name: _nameController.text.trim(),
      amount: 0,
      date: _selectedDate,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String formatAmount(double amount, String symbol) {
  return '$symbol${amount.toStringAsFixed(2)}';
}

String formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String formatMonth(DateTime date) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final name = monthNames[date.month - 1];
  return '$name ${date.year}';
}
