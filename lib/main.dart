import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/app_settings.dart';
import 'models/expense.dart';
import 'services/expense_store.dart';

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
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              useMaterial3: true,
            ),
            home: const LoadingScreen(),
          );
        }
        return AppStateScope(
          notifier: snapshot.data!,
          child: MaterialApp(
            title: 'TrackIt',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              useMaterial3: true,
            ),
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
    required Widget child,
  }) : super(notifier: notifier, child: child);

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
    final pages = const [
      ExpensesPage(),
      ReportsPage(),
      BackupPage(),
      SettingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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
                    'Daily total: ${formatAmount(total, store.settings.currencySymbol)}',
                    style: Theme.of(context).textTheme.titleMedium,
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
                      separatorBuilder: (_, __) =>
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
                firstDate: DateTime(2019),
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(
              title: 'This Month',
              subtitle: formatMonth(now),
              total: formatAmount(monthTotal, store.settings.currencySymbol),
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: 'This Year',
              subtitle: now.year.toString(),
              total: formatAmount(yearTotal, store.settings.currencySymbol),
            ),
            const SizedBox(height: 24),
            Text(
              'Monthly history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (monthlyTotals.isEmpty)
              const _EmptyState(
                title: 'No history yet',
                message: 'Add expenses to see monthly totals.',
              )
            else
              ...monthlyTotals.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatMonth(entry.month)),
                  trailing: Text(
                    formatAmount(
                      entry.total,
                      store.settings.currencySymbol,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Yearly totals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (yearlyTotals.isEmpty)
              const _EmptyState(
                title: 'No yearly totals yet',
                message: 'Keep tracking to see yearly totals.',
              )
            else
              ...yearlyTotals.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.year.toString()),
                  trailing: Text(
                    formatAmount(
                      entry.total,
                      store.settings.currencySymbol,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(total, style: Theme.of(context).textTheme.headlineSmall),
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
              value: _backupProvider,
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
                      firstDate: DateTime(2019),
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
                  final amount = double.parse(_amountController.text.trim());
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
      id: DateTime.now().microsecondsSinceEpoch.toString(),
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
