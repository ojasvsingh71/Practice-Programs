import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Per-file Color compatibility shim (replaces deprecated withOpacity usage)
extension ColorWithValues on Color {
  Color withValues(double opacity) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int b = value & 0xFF;
    return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
  }
}


// ============================================================================
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum TransactionType { income, expense }

enum SyncStatus { pending, syncing, synced, failed }

enum AnalyticsTimeframe { week, month, year }

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700

  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color accent = Color(0xFF0EA5E9); // Blue 500

  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color income = Color(0xFF10B981); // Emerald 500
  static const Color expense = Color(0xFFEF4444); // Red 500
  static const Color success = income;
  static const Color error = expense;
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  // Category Colors
  static const List<Color> categoryPalette = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
  ];
}

class AppStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textMain,
    letterSpacing: -1,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textMain,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );
  static const TextStyle amountLg = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    letterSpacing: -1,
  );
}

// ============================================================================
// 2. UTILS, FORMATTERS & EXCEPTIONS
// ============================================================================

abstract class SyncException implements Exception {
  final String message;
  SyncException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends SyncException {
  NetworkException([String m = "Network timeout."]) : super(m);
}

class ServerException extends SyncException {
  ServerException([String m = "Server rejected payload."]) : super(m);
}

class FinancialDateUtils {
  static const List<String> _months = [
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
  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String formatCurrency(double amount) {
    String sign = amount < 0 ? '-' : '';
    String fixed = amount.abs().toStringAsFixed(2);
    // Add commas manually
    List<String> parts = fixed.split('.');
    String intPart = parts[0];
    String formattedInt = '';
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) formattedInt += ',';
      formattedInt += intPart[i];
    }
    return '$sign\$${formattedInt}.${parts[1]}';
  }

  static String formatMonthYear(DateTime d) =>
      '${_months[d.month - 1]} ${d.year}';
  static String formatShortDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';
  static String formatDayName(DateTime d) => _weekDays[d.weekday - 1];

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static String getRelativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return _weekDays[d.weekday - 1];
    return formatShortDate(d);
  }
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class TransactionRecord {
  final String id;
  final double amount;
  final String note;
  final DateTime date;
  final String categoryId;
  final TransactionType type;
  SyncStatus syncStatus;

  TransactionRecord({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.categoryId,
    required this.type,
    this.syncStatus = SyncStatus.pending,
  });

  TransactionRecord copyWith({SyncStatus? syncStatus}) {
    return TransactionRecord(
      id: id,
      amount: amount,
      note: note,
      date: date,
      categoryId: categoryId,
      type: type,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Used for mock server serialization
  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'note': note,
    'date': date.millisecondsSinceEpoch,
    'categoryId': categoryId,
    'type': type.name,
  };
}

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  MonthlySummary({required this.totalIncome, required this.totalExpense});
  double get netBalance => totalIncome - totalExpense;
}

// ============================================================================
// 4. MOCK CLOUD SYNC ENGINE
// ============================================================================

class MockCloudSyncEngine {
  static final MockCloudSyncEngine _instance = MockCloudSyncEngine._internal();
  factory MockCloudSyncEngine() => _instance;
  MockCloudSyncEngine._internal();

  final math.Random _random = math.Random();
  final List<Map<String, dynamic>> _cloudDatabase = [];

  // Seed default categories
  final List<Category> defaultCategories = [
    Category(
      id: 'C1',
      name: 'Housing',
      icon: Icons.home,
      color: AppColors.categoryPalette[0],
      type: TransactionType.expense,
    ),
    Category(
      id: 'C2',
      name: 'Food',
      icon: Icons.restaurant,
      color: AppColors.categoryPalette[1],
      type: TransactionType.expense,
    ),
    Category(
      id: 'C3',
      name: 'Transport',
      icon: Icons.directions_car,
      color: AppColors.categoryPalette[2],
      type: TransactionType.expense,
    ),
    Category(
      id: 'C4',
      name: 'Entertainment',
      icon: Icons.movie,
      color: AppColors.categoryPalette[3],
      type: TransactionType.expense,
    ),
    Category(
      id: 'C5',
      name: 'Salary',
      icon: Icons.work,
      color: AppColors.income,
      type: TransactionType.income,
    ),
    Category(
      id: 'C6',
      name: 'Freelance',
      icon: Icons.computer,
      color: AppColors.categoryPalette[5],
      type: TransactionType.income,
    ),
  ];

  Future<List<TransactionRecord>> fetchInitialData() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    // Generate realistic historical data for the last 30 days
    final List<TransactionRecord> history = [];
    final now = DateTime.now();

    for (int i = 0; i < 40; i++) {
      final isIncome = _random.nextDouble() > 0.8; // 20% chance of income
      final cats = defaultCategories
          .where(
            (c) =>
                c.type ==
                (isIncome ? TransactionType.income : TransactionType.expense),
          )
          .toList();
      final cat = cats[_random.nextInt(cats.length)];

      final amt = isIncome
          ? (2000.0 + _random.nextDouble() * 3000.0)
          : (10.0 + _random.nextDouble() * 150.0);
      final date = now.subtract(
        Duration(days: _random.nextInt(30), hours: _random.nextInt(24)),
      );

      history.add(
        TransactionRecord(
          id: 'TXN_${date.millisecondsSinceEpoch}_${_random.nextInt(1000)}',
          amount: amt,
          note: isIncome ? 'Income' : 'Expense via POS',
          date: date,
          categoryId: cat.id,
          type: isIncome ? TransactionType.income : TransactionType.expense,
          syncStatus: SyncStatus.synced, // Historical data is already synced
        ),
      );
    }
    history.sort((a, b) => b.date.compareTo(a.date));
    return history;
  }

  /// Pushes a batch of transactions to the "Cloud".
  /// Features intentional random packet loss to simulate real-world mobile networks.
  Future<void> syncBatch(List<TransactionRecord> batch) async {
    await Future.delayed(const Duration(milliseconds: 1200)); // Network latency

    if (_random.nextDouble() < 0.2) {
      // 20% global failure rate
      throw NetworkException("Connection dropped while syncing.");
    }

    for (var tx in batch) {
      if (_random.nextDouble() < 0.05) {
        // 5% individual record failure rate
        throw ServerException("Server rejected transaction ${tx.id}");
      }
      // "Save" to cloud
      _cloudDatabase.add(tx.toMap());
    }
  }
}

// ============================================================================
// 5. STATE MANAGEMENT & BACKGROUND SYNC QUEUE
// ============================================================================

class AppState extends ChangeNotifier {
  final MockCloudSyncEngine _api = MockCloudSyncEngine();

  bool isInitializing = true;
  String? globalError;
  bool isSyncing = false;

  // Local Data Store (Local-first architecture)
  List<TransactionRecord> transactions = [];
  List<Category> get categories => _api.defaultCategories;

  // Target month for dashboard viewing
  DateTime selectedMonth = DateTime.now();

  AppState() {
    _bootSystem();
  }

  Future<void> _bootSystem() async {
    try {
      transactions = await _api.fetchInitialData();
    } catch (e) {
      globalError = "Failed to load historical data.";
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  // --- Core CRUD ---
  void addTransaction(
    double amount,
    String note,
    Category category,
    DateTime date,
  ) {
    final newTx = TransactionRecord(
      id: 'TXN_L_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      note: note.isEmpty ? category.name : note,
      date: date,
      categoryId: category.id,
      type: category.type,
      syncStatus: SyncStatus.pending,
    );

    transactions.insert(0, newTx);
    transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    _triggerBackgroundSync();
  }

  void deleteTransaction(String id) {
    transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    // In a real app, queue a delete operation to the cloud here.
  }

  // --- Background Sync Engine ---
  Timer? _syncTimer;

  void _triggerBackgroundSync() {
    if (isSyncing) return;
    // Debounce sync requests
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 2), _processSyncQueue);
  }

  void forceSync() => _processSyncQueue();

  Future<void> _processSyncQueue() async {
    final pending = transactions
        .where(
          (t) =>
              t.syncStatus == SyncStatus.pending ||
              t.syncStatus == SyncStatus.failed,
        )
        .toList();
    if (pending.isEmpty) return;

    isSyncing = true;
    notifyListeners();

    // Mark as syncing in UI
    for (var tx in pending) {
      _updateSyncStatus(tx.id, SyncStatus.syncing);
    }

    try {
      await _api.syncBatch(pending);
      // Success
      for (var tx in pending) {
        _updateSyncStatus(tx.id, SyncStatus.synced);
      }
    } catch (e) {
      // Failure - apply backoff logic in a real app
      for (var tx in pending) {
        _updateSyncStatus(tx.id, SyncStatus.failed);
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  void _updateSyncStatus(String id, SyncStatus status) {
    final idx = transactions.indexWhere((t) => t.id == id);
    if (idx != -1)
      transactions[idx] = transactions[idx].copyWith(syncStatus: status);
  }

  // --- Analytics & Aggregations ---

  List<TransactionRecord> get _currentMonthTransactions {
    return transactions
        .where((t) => FinancialDateUtils.isSameMonth(t.date, selectedMonth))
        .toList();
  }

  MonthlySummary get currentMonthSummary {
    double inc = 0;
    double exp = 0;
    for (var t in _currentMonthTransactions) {
      if (t.type == TransactionType.income)
        inc += t.amount;
      else
        exp += t.amount;
    }
    return MonthlySummary(totalIncome: inc, totalExpense: exp);
  }

  Map<String, double> getExpenseByCategory() {
    final map = <String, double>{};
    for (var t in _currentMonthTransactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  Category getCategory(String id) => categories.firstWhere((c) => c.id == id);

  void changeMonth(int delta) {
    selectedMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + delta,
      1,
    );
    notifyListeners();
  }
}

class AppStore extends InheritedNotifier<AppState> {
  const AppStore({Key? key, required AppState state, required Widget child})
    : super(key: key, notifier: state, child: child);
  static AppState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<AppStore>()!.notifier!;
    } else {
      final provider =
          context.getElementForInheritedWidgetOfExactType<AppStore>()?.widget
              as AppStore;
      return provider.notifier!;
    }
  }
}

// ============================================================================
// 6. MAIN APP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Finance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        home: const BootRouter(),
      ),
    );
  }
}

class BootRouter extends StatelessWidget {
  const BootRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return const MainDashboardScaffold();
  }
}

// ============================================================================
// 7. MAIN DASHBOARD SHELL
// ============================================================================

class MainDashboardScaffold extends StatefulWidget {
  const MainDashboardScaffold({Key? key}) : super(key: key);

  @override
  State<MainDashboardScaffold> createState() => _MainDashboardScaffoldState();
}

class _MainDashboardScaffoldState extends State<MainDashboardScaffold> {
  int _currentIndex = 0;
  final _screens = [const HomeTab(), const AnalyticsTab(), const SettingsTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                  fullscreenDialog: true,
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ============================================================================
// 8. HOME TAB (Dashboard & Transaction List)
// ============================================================================

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final summary = state.currentMonthSummary;
    final txns = state._currentMonthTransactions;

    // Group transactions by Date
    final Map<String, List<TransactionRecord>> groupedTxns = {};
    for (var t in txns) {
      final key = FinancialDateUtils.getRelativeDate(t.date);
      groupedTxns.putIfAbsent(key, () => []).add(t);
    }

    return CustomScrollView(
      slivers: [
        // App Bar & Sync Status
        SliverAppBar(
          floating: true,
          title: const Text(
            'NEXUS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: state.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted,
                        ),
                      )
                    : Icon(
                        Icons.cloud_done,
                        color:
                            state.transactions.any(
                              (t) => t.syncStatus == SyncStatus.failed,
                            )
                            ? AppColors.error
                            : AppColors.success,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),

        // Month Selector & Master Balance
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => state.changeMonth(-1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        FinancialDateUtils.formatMonthYear(state.selectedMonth),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => state.changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Available Balance', style: AppStyles.caption),
                const SizedBox(height: 8),
                Text(
                  FinancialDateUtils.formatCurrency(summary.netBalance),
                  style: AppStyles.amountLg,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Income',
                        amount: summary.totalIncome,
                        color: AppColors.income,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expense',
                        amount: summary.totalExpense,
                        color: AppColors.expense,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Transaction History
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent Transactions', style: AppStyles.h2),
                const SizedBox(height: 24),
                if (txns.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No transactions this month.',
                        style: AppStyles.caption,
                      ),
                    ),
                  )
                else
                  ...groupedTxns.entries
                      .map(
                        (group) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Text(
                                group.key,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...group.value
                                .map((t) => _TransactionTile(transaction: t))
                                .toList(),
                          ],
                        ),
                      )
                      .toList(),
                const SizedBox(height: 80), // padding for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          Text(FinancialDateUtils.formatCurrency(amount), style: AppStyles.h3),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionRecord transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final category = state.getCategory(transaction.categoryId);
    final isIncome = transaction.type == TransactionType.income;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        state.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
                child: Icon(category.icon, color: category.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.note,
                    style: AppStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${FinancialDateUtils.formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncome ? AppColors.income : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                _SyncStatusIndicator(status: transaction.syncStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  const _SyncStatusIndicator({required this.status});
  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.synced) return const SizedBox.shrink();

    IconData icon;
    Color color;
    switch (status) {
      case SyncStatus.pending:
        icon = Icons.schedule;
        color = AppColors.textMuted;
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = AppColors.accent;
        break;
      case SyncStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.error;
        break;
      default:
        return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(status.name, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

// ============================================================================
// 9. CUSTOM NUMPAD & ADD TRANSACTION SCREEN
// ============================================================================

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amountStr = '0';
  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  final _noteCtrl = TextEditingController();

  void _handleKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _amountStr = '0';
      } else if (key == '<') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          // Limit to 2 decimal places
          if (_amountStr.contains('.')) {
            final parts = _amountStr.split('.');
            if (parts[1].length >= 2) return;
          }
          if (_amountStr.length < 9) _amountStr += key;
        }
      }
    });
  }

  void _submit() {
    final amt = double.tryParse(_amountStr) ?? 0.0;
    if (amt <= 0 || _selectedCategory == null) return;

    AppStore.of(
      context,
      listen: false,
    ).addTransaction(amt, _noteCtrl.text, _selectedCategory!, DateTime.now());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final validCategories = state.categories
        .where((c) => c.type == _selectedType)
        .toList();
    if (_selectedCategory == null || _selectedCategory!.type != _selectedType) {
      _selectedCategory = validCategories.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: SegmentedButton<TransactionType>(
          segments: const [
            ButtonSegment(
              value: TransactionType.expense,
              label: Text('Expense'),
            ),
            ButtonSegment(value: TransactionType.income, label: Text('Income')),
          ],
          selected: {_selectedType},
          onSelectionChanged: (val) =>
              setState(() => _selectedType = val.first),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) => states.contains(MaterialState.selected)
                  ? (_selectedType == TransactionType.income
                        ? AppColors.income
                        : AppColors.expense)
                  : AppColors.surface,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Display Amount
          Expanded(
            child: Center(
              child: Text(
                '\$$_amountStr',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2,
                ),
              ),
            ),
          ),

          // Config Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Category Selector
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: validCategories.length,
                    itemBuilder: (context, index) {
                      final c = validCategories[index];
                      final isSelected = c.id == _selectedCategory?.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = c),
                        child: Container(
                          width: 64,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                              ? c.color.withOpacity(0.2)
                              : AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? c.color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                c.icon,
                                color: isSelected
                                    ? c.color
                                    : AppColors.textMuted,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? c.color
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Note Input
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Custom Numpad
                _buildNumpad(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];
    return Column(
      children: [
        for (var row in keys)
          Row(
            children: row
                .map(
                  (k) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: InkWell(
                        onTap: () => _handleKeyPress(k),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: k == '<'
                              ? const Icon(
                                  Icons.backspace,
                                  color: AppColors.textMain,
                                )
                              : Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedType == TransactionType.income
                  ? AppColors.income
                  : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: (_amountStr == '0' || _selectedCategory == null)
                ? null
                : _submit,
            child: const Text(
              'SAVE TRANSACTION',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 10. ANALYTICS TAB & CUSTOM CHARTS
// ============================================================================

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({Key? key}) : super(key: key);

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _chartAnimCtrl;

  @override
  void initState() {
    super.initState();
    _chartAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _chartAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final expenseMap = state.getExpenseByCategory();
    final totalExp = state.currentMonthSummary.totalExpense;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Analytics', style: AppStyles.h1),
          const SizedBox(height: 32),

          // Donut Chart
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('Expense Breakdown', style: AppStyles.h3),
                const SizedBox(height: 32),
                SizedBox(
                  height: 250,
                  child: AnimatedBuilder(
                    animation: _chartAnimCtrl,
                    builder: (ctx, child) => CustomPaint(
                      painter: _AnimatedDonutChartPainter(
                        dataMap: expenseMap,
                        categories: state.categories,
                        total: totalExp,
                        progress: _chartAnimCtrl.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Legend / Detail List
          const Text('Top Categories', style: AppStyles.h3),
          const SizedBox(height: 16),
          if (expenseMap.isEmpty)
            const Text('No data for this month.', style: AppStyles.caption)
          else
            ...(expenseMap.entries.toList()..sort(
                  (a, b) => b.value.compareTo(a.value),
                ) // Sort descending
                )
                .map((e) {
                  final cat = state.getCategory(e.key);
                  final perc = totalExp == 0 ? 0 : (e.value / totalExp) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: cat.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${perc.toStringAsFixed(1)}%',
                          style: AppStyles.caption,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          FinancialDateUtils.formatCurrency(e.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),

          const SizedBox(height: 32),

          // Dual Bar Chart
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cash Flow', style: AppStyles.h3),
                const SizedBox(height: 8),
                const Text(
                  'Income vs Expense (Last 7 Days)',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _chartAnimCtrl,
                    builder: (ctx, child) => CustomPaint(
                      painter: _DualBarChartPainter(
                        transactions: state.transactions,
                        progress: _chartAnimCtrl.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDonutChartPainter extends CustomPainter {
  final Map<String, double> dataMap;
  final List<Category> categories;
  final double total;
  final double progress;

  _AnimatedDonutChartPainter({
    required this.dataMap,
    required this.categories,
    required this.total,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    if (total == 0) {
      final paint = Paint()
        ..color = AppColors.surfaceHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30;
      canvas.drawCircle(center, radius - 15, paint);
      _drawCenterText(canvas, center, '\$0.00');
      return;
    }

    double startAngle = -math.pi / 2;
    final strokeWidth = 30.0;

    for (var entry in dataMap.entries) {
      if (entry.value <= 0) continue;

      final cat = categories.firstWhere((c) => c.id == entry.key);
      final sweepAngle =
          (entry.value / total) * 2 * math.pi * progress; // Animate sweep

      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round; // Rounded ends for premium feel

      // Slight gap between arcs
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 15),
        startAngle + 0.05,
        sweepAngle - 0.1,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    _drawCenterText(
      canvas,
      center,
      FinancialDateUtils.formatCurrency(total * progress),
    );
  }

  void _drawCenterText(Canvas canvas, Offset center, String text) {
    final tp1 = TextPainter(
      text: TextSpan(text: 'Total Spent\n', style: AppStyles.caption),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    final tp2 = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    tp1.paint(canvas, Offset(center.dx - tp1.width / 2, center.dy - 16));
    tp2.paint(canvas, Offset(center.dx - tp2.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Needs repaint during animation
}

class _DualBarChartPainter extends CustomPainter {
  final List<TransactionRecord> transactions;
  final double progress;

  _DualBarChartPainter({required this.transactions, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    // Pre-calculate last 7 days buckets
    List<double> incomeData = List.filled(7, 0.0);
    List<double> expenseData = List.filled(7, 0.0);
    List<String> labels = [];

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      labels.add(
        FinancialDateUtils.formatDayName(targetDate).substring(0, 1),
      ); // M, T, W...

      for (var t in transactions) {
        if (FinancialDateUtils.isSameDay(t.date, targetDate)) {
          if (t.type == TransactionType.income)
            incomeData[6 - i] += t.amount;
          else
            expenseData[6 - i] += t.amount;
        }
      }
    }

    double maxVal = math.max(
      incomeData.reduce(math.max),
      expenseData.reduce(math.max),
    );
    if (maxVal == 0) maxVal = 100; // prevent div by zero

    final colWidth = size.width / 7;
    final barWidth = 8.0;

    final bgPaint = Paint()
      ..color = AppColors.surfaceHighlight
      ..strokeWidth = 1;
    // Grid lines
    for (int i = 0; i <= 3; i++) {
      double y = i * (size.height / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bgPaint);
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 7; i++) {
      double xCenter = (i * colWidth) + (colWidth / 2);

      // Income Bar
      double incH = (incomeData[i] / maxVal) * size.height * progress;
      final incPaint = Paint()
        ..color = AppColors.income
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xCenter - barWidth - 2,
            size.height - incH,
            barWidth,
            incH,
          ),
          const Radius.circular(4),
        ),
        incPaint,
      );

      // Expense Bar
      double expH = (expenseData[i] / maxVal) * size.height * progress;
      final expPaint = Paint()
        ..color = AppColors.expense
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xCenter + 2, size.height - expH, barWidth, expH),
          const Radius.circular(4),
        ),
        expPaint,
      );

      // Label
      tp.text = TextSpan(text: labels[i], style: AppStyles.caption);
      tp.layout();
      tp.paint(canvas, Offset(xCenter - tp.width / 2, size.height + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 11. SETTINGS & SYNC DEBUG TAB
// ============================================================================

class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final pendingCount = state.transactions
        .where((t) => t.syncStatus != SyncStatus.synced)
        .length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: AppStyles.h1),
            const SizedBox(height: 32),

            const Text('Cloud Sync Engine', style: AppStyles.h3),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        size: 40,
                        color: state.isSyncing
                            ? AppColors.accent
                            : (pendingCount > 0
                                  ? AppColors.warning
                                  : AppColors.success),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isSyncing
                                  ? 'Syncing data...'
                                  : (pendingCount > 0
                                        ? 'Changes pending'
                                        : 'All data synced'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '$pendingCount items waiting for network',
                              style: AppStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceHighlight,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.sync),
                        label: const Text('FORCE SYNC NOW'),
                        onPressed: state.isSyncing
                            ? null
                            : () => state.forceSync(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Preferences', style: AppStyles.h3),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.notifications,
                color: AppColors.textMuted,
              ),
              title: const Text('Notifications'),
              trailing: Switch(
                value: true,
                activeColor: AppColors.primary,
                onChanged: (v) {},
              ),
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.security, color: AppColors.textMuted),
              title: const Text('Biometric Lock'),
              trailing: Switch(
                value: false,
                activeColor: AppColors.primary,
                onChanged: (v) {},
              ),
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
