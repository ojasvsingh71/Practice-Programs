import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME CONFIGURATION
// ============================================================================

enum TransactionType { income, expense, transfer }

enum BillFrequency { weekly, monthly, yearly }

enum GoalStatus { active, paused, achieved }

enum CategoryGroup {
  housing,
  food,
  transport,
  entertainment,
  utilities,
  health,
  salary,
  investment,
  miscellaneous,
}

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700

  static const Color primary = Color(0xFF8B5CF6); // Violet 500
  static const Color primaryDark = Color(0xFF6D28D9); // Violet 700
  static const Color accent = Color(0xFF06B6D4); // Cyan 500

  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color income = Color(0xFF10B981); // Emerald 500
  static const Color expense = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color gold = Color(0xFFFBBF24);
  static const Color success = income;
  static const Color error = expense;

  static Color getCategoryColor(CategoryGroup group) {
    switch (group) {
      case CategoryGroup.housing:
        return const Color(0xFF3B82F6);
      case CategoryGroup.food:
        return const Color(0xFFF43F5E);
      case CategoryGroup.transport:
        return const Color(0xFF14B8A6);
      case CategoryGroup.entertainment:
        return const Color(0xFF8B5CF6);
      case CategoryGroup.utilities:
        return const Color(0xFFF59E0B);
      case CategoryGroup.health:
        return const Color(0xFF10B981);
      case CategoryGroup.salary:
        return const Color(0xFF10B981);
      case CategoryGroup.investment:
        return const Color(0xFF6366F1);
      case CategoryGroup.miscellaneous:
        return const Color(0xFF64748B);
    }
  }
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
    letterSpacing: -0.5,
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
    fontSize: 42,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

// ============================================================================
// 2. UTILS & FORMATTERS
// ============================================================================

abstract class FinanceException implements Exception {
  final String message;
  FinanceException(this.message);
  @override
  String toString() => message;
}

class InsufficientFundsException extends FinanceException {
  InsufficientFundsException([String m = "Insufficient master balance."])
    : super(m);
}

class ValidationException extends FinanceException {
  ValidationException([String m = "Invalid input data."]) : super(m);
}

class FinFormat {
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

  static String currency(double amount, {bool hideSign = false}) {
    String sign = (amount < 0 && !hideSign) ? '-' : '';
    String fixed = amount.abs().toStringAsFixed(2);
    List<String> parts = fixed.split('.');
    String intPart = parts[0];
    String formattedInt = '';
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) formattedInt += ',';
      formattedInt += intPart[i];
    }
    return '$sign\$${formattedInt}.${parts[1]}';
  }

  static String compactCurrency(double amount) {
    if (amount >= 1000000) return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '\$${(amount / 1000).toStringAsFixed(1)}k';
    return '\$${amount.toStringAsFixed(0)}';
  }

  static String dateShort(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  static String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static DateTime nextRecurrence(DateTime current, BillFrequency freq) {
    switch (freq) {
      case BillFrequency.weekly:
        return current.add(const Duration(days: 7));
      case BillFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case BillFrequency.yearly:
        return DateTime(current.year + 1, current.month, current.day);
    }
  }
}

// ============================================================================
// 3. EVENT BUS (System Notifications)
// ============================================================================

class FinanceEvent {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  FinanceEvent(this.title, this.message, this.color, this.icon);
}

class EventBus {
  static final StreamController<FinanceEvent> _bus =
      StreamController<FinanceEvent>.broadcast();
  static Stream<FinanceEvent> get stream => _bus.stream;
  static void emit(FinanceEvent event) => _bus.sink.add(event);
}

// ============================================================================
// 4. DOMAIN MODELS
// ============================================================================

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final CategoryGroup category;
  final TransactionType type;
  final String? notes;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.notes,
  });
}

class Budget {
  final String id;
  final CategoryGroup category;
  final double limitAmount;

  Budget({required this.id, required this.category, required this.limitAmount});
}

class RecurringBill {
  final String id;
  final String name;
  final double amount;
  final CategoryGroup category;
  final BillFrequency frequency;
  DateTime nextDueDate;
  final bool isAutoPay;

  RecurringBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextDueDate,
    this.isAutoPay = false,
  });

  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime? targetDate;
  final String iconEmoji;
  GoalStatus status;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.iconEmoji,
    this.status = GoalStatus.active,
  });

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  bool get isAchieved => currentAmount >= targetAmount;
}

// ============================================================================
// 5. MOCK DATABASE ENGINE
// ============================================================================

class MockFinanceEngine {
  static final MockFinanceEngine _instance = MockFinanceEngine._internal();
  factory MockFinanceEngine() => _instance;
  MockFinanceEngine._internal() {
    _seedData();
  }

  final math.Random _rand = math.Random();
  final List<Transaction> _transactions = [];
  final List<Budget> _budgets = [];
  final List<RecurringBill> _bills = [];
  final List<SavingsGoal> _goals = [];

  double masterBalance = 12450.75;

  // Public unnamed constructor removed; singleton uses factory above.

  void _seedData() {
    final now = DateTime.now();

    // 1. Seed Budgets
    _budgets.addAll([
      Budget(id: 'B1', category: CategoryGroup.food, limitAmount: 800.0),
      Budget(id: 'B2', category: CategoryGroup.transport, limitAmount: 300.0),
      Budget(
        id: 'B3',
        category: CategoryGroup.entertainment,
        limitAmount: 200.0,
      ),
      Budget(id: 'B4', category: CategoryGroup.utilities, limitAmount: 400.0),
    ]);

    // 2. Seed Bills
    _bills.addAll([
      RecurringBill(
        id: 'RB1',
        name: 'Netflix',
        amount: 15.99,
        category: CategoryGroup.entertainment,
        frequency: BillFrequency.monthly,
        nextDueDate: now.add(const Duration(days: 3)),
        isAutoPay: true,
      ),
      RecurringBill(
        id: 'RB2',
        name: 'Car Insurance',
        amount: 85.00,
        category: CategoryGroup.transport,
        frequency: BillFrequency.monthly,
        nextDueDate: now.add(const Duration(days: 12)),
        isAutoPay: true,
      ),
      RecurringBill(
        id: 'RB3',
        name: 'Gym Membership',
        amount: 45.00,
        category: CategoryGroup.health,
        frequency: BillFrequency.monthly,
        nextDueDate: now.add(const Duration(days: 1)),
        isAutoPay: false,
      ),
      RecurringBill(
        id: 'RB4',
        name: 'Rent',
        amount: 1500.00,
        category: CategoryGroup.housing,
        frequency: BillFrequency.monthly,
        nextDueDate: now.add(const Duration(days: 8)),
        isAutoPay: true,
      ),
    ]);

    // 3. Seed Goals
    _goals.addAll([
      SavingsGoal(
        id: 'G1',
        name: 'Emergency Fund',
        targetAmount: 10000.0,
        currentAmount: 6500.0,
        iconEmoji: '🛡️',
      ),
      SavingsGoal(
        id: 'G2',
        name: 'Japan Trip',
        targetAmount: 4000.0,
        currentAmount: 1200.0,
        targetDate: now.add(const Duration(days: 180)),
        iconEmoji: '✈️',
      ),
      SavingsGoal(
        id: 'G3',
        name: 'New MacBook',
        targetAmount: 2500.0,
        currentAmount: 2500.0,
        iconEmoji: '💻',
        status: GoalStatus.achieved,
      ),
    ]);

    // 4. Seed 3 Months of Transactions
    for (int i = 0; i < 150; i++) {
      final isIncome = _rand.nextDouble() > 0.85;
      final date = now.subtract(
        Duration(days: _rand.nextInt(90), hours: _rand.nextInt(24)),
      );

      CategoryGroup cat;
      String title;
      double amt;

      if (isIncome) {
        cat = CategoryGroup.salary;
        title = _rand.nextBool() ? 'Salary Deposit' : 'Freelance Transfer';
        amt = 1500.0 + _rand.nextDouble() * 3000.0;
      } else {
        final expCats = [
          CategoryGroup.food,
          CategoryGroup.transport,
          CategoryGroup.entertainment,
          CategoryGroup.miscellaneous,
        ];
        cat = expCats[_rand.nextInt(expCats.length)];
        amt = 5.0 + _rand.nextDouble() * 150.0;
        if (cat == CategoryGroup.food)
          title = [
            'Starbucks',
            'Whole Foods',
            'UberEats',
            'Local Diner',
          ][_rand.nextInt(4)];
        else if (cat == CategoryGroup.transport)
          title = ['Uber', 'Gas Station', 'Subway Ticket'][_rand.nextInt(3)];
        else if (cat == CategoryGroup.entertainment)
          title = ['AMC Theaters', 'Steam Games', 'Spotify'][_rand.nextInt(3)];
        else
          title = 'General Store';
      }

      _transactions.add(
        Transaction(
          id: 'TXN_$i',
          title: title,
          amount: amt,
          date: date,
          category: cat,
          type: isIncome ? TransactionType.income : TransactionType.expense,
        ),
      );
    }
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _rand.nextInt(300)));

  // --- API Methods ---
  Future<List<Transaction>> getTransactions() async {
    await _latency();
    return List.from(_transactions);
  }

  Future<List<Budget>> getBudgets() async {
    await _latency();
    return List.from(_budgets);
  }

  Future<List<RecurringBill>> getBills() async {
    await _latency();
    return List.from(_bills);
  }

  Future<List<SavingsGoal>> getGoals() async {
    await _latency();
    return List.from(_goals);
  }

  Future<double> getBalance() async {
    await _latency();
    return masterBalance;
  }

  Future<Transaction> addTransaction(Transaction t) async {
    await _latency(600);
    _transactions.insert(0, t);
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    if (t.type == TransactionType.expense)
      masterBalance -= t.amount;
    else if (t.type == TransactionType.income)
      masterBalance += t.amount;

    return t;
  }

  Future<void> payBill(String billId) async {
    await _latency(800);
    final bill = _bills.firstWhere((b) => b.id == billId);

    if (masterBalance < bill.amount)
      throw InsufficientFundsException(
        "Cannot pay ${bill.name}. Balance too low.",
      );

    masterBalance -= bill.amount;

    // Create Transaction Record
    _transactions.insert(
      0,
      Transaction(
        id: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        title: bill.name,
        amount: bill.amount,
        date: DateTime.now(),
        category: bill.category,
        type: TransactionType.expense,
        notes: 'Auto/Manual Bill Payment',
      ),
    );

    // Roll over due date
    bill.nextDueDate = FinFormat.nextRecurrence(
      bill.nextDueDate,
      bill.frequency,
    );
  }

  Future<void> fundGoal(String goalId, double amount) async {
    await _latency(800);
    if (masterBalance < amount) throw InsufficientFundsException();

    final goal = _goals.firstWhere((g) => g.id == goalId);
    if (goal.status == GoalStatus.achieved)
      throw ValidationException("Goal already achieved.");

    masterBalance -= amount;
    goal.currentAmount += amount;

    if (goal.currentAmount >= goal.targetAmount) {
      goal.status = GoalStatus.achieved;
    }

    _transactions.insert(
      0,
      Transaction(
        id: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Transfer to ${goal.name}',
        amount: amount,
        date: DateTime.now(),
        category: CategoryGroup.investment,
        type: TransactionType.transfer,
      ),
    );
  }
}

// ============================================================================
// 6. STATE MANAGEMENT (Custom AppStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockFinanceEngine _api = MockFinanceEngine();

  bool isLoading = true;
  String? globalError;

  double masterBalance = 0.0;
  List<Transaction> transactions = [];
  List<Budget> budgets = [];
  List<RecurringBill> bills = [];
  List<SavingsGoal> goals = [];

  // Analytics State
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  AppState() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      final futures = await Future.wait([
        _api.getBalance(),
        _api.getTransactions(),
        _api.getBudgets(),
        _api.getBills(),
        _api.getGoals(),
      ]);
      masterBalance = futures[0] as double;
      transactions = futures[1] as List<Transaction>;
      budgets = futures[2] as List<Budget>;
      bills = futures[3] as List<RecurringBill>;
      goals = futures[4] as List<SavingsGoal>;

      _runBackgroundChecks();
    } catch (e) {
      globalError = "Failed to load financial data.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _runBackgroundChecks() {
    // Check for due bills
    final today = DateTime.now();
    for (var b in bills) {
      if (b.nextDueDate.isBefore(today) ||
          FinFormat.isSameMonth(b.nextDueDate, today) && b.daysUntilDue == 0) {
        if (b.isAutoPay) {
          payBill(b.id, isAuto: true);
        } else {
          EventBus.emit(
            FinanceEvent(
              'Bill Due Today',
              '${b.name} is due today (${FinFormat.currency(b.amount)}).',
              AppColors.warning,
              Icons.receipt,
            ),
          );
        }
      }
    }
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    await _boot();
  }

  // --- Actions ---
  Future<bool> addTransaction(
    double amount,
    CategoryGroup cat,
    String title,
    TransactionType type,
  ) async {
    try {
      final t = Transaction(
        id: 'T_NEW',
        title: title.isEmpty ? cat.name : title,
        amount: amount,
        date: DateTime.now(),
        category: cat,
        type: type,
      );
      await _api.addTransaction(t);

      // Update local state immediately
      transactions.insert(0, t);
      if (type == TransactionType.expense)
        masterBalance -= amount;
      else if (type == TransactionType.income)
        masterBalance += amount;

      _checkBudgetWarnings(cat);
      notifyListeners();
      return true;
    } catch (e) {
      EventBus.emit(
        FinanceEvent(
          'Error',
          'Failed to add transaction.',
          AppColors.error,
          Icons.error,
        ),
      );
      return false;
    }
  }

  Future<bool> payBill(String id, {bool isAuto = false}) async {
    try {
      await _api.payBill(id);
      if (isAuto) {
        final bill = bills.firstWhere((b) => b.id == id);
        EventBus.emit(
          FinanceEvent(
            'Auto-Pay Successful',
            'Paid ${bill.name} (${FinFormat.currency(bill.amount)}).',
            AppColors.success,
            Icons.autorenew,
          ),
        );
      } else {
        EventBus.emit(
          FinanceEvent(
            'Payment Sent',
            'Bill marked as paid.',
            AppColors.success,
            Icons.check_circle,
          ),
        );
      }
      await refresh();
      return true;
    } on FinanceException catch (e) {
      EventBus.emit(
        FinanceEvent('Payment Failed', e.message, AppColors.error, Icons.error),
      );
      return false;
    }
  }

  Future<bool> fundGoal(String id, double amount) async {
    try {
      await _api.fundGoal(id, amount);
      final goal = goals.firstWhere((g) => g.id == id);
      if (goal.isAchieved) {
        EventBus.emit(
          FinanceEvent(
            'Goal Achieved! 🎉',
            'You reached your target for ${goal.name}.',
            AppColors.gold,
            Icons.emoji_events,
          ),
        );
      } else {
        EventBus.emit(
          FinanceEvent(
            'Funds Added',
            'Successfully transferred ${FinFormat.currency(amount)}.',
            AppColors.success,
            Icons.savings,
          ),
        );
      }
      await refresh();
      return true;
    } on FinanceException catch (e) {
      EventBus.emit(
        FinanceEvent(
          'Transfer Failed',
          e.message,
          AppColors.error,
          Icons.error,
        ),
      );
      return false;
    }
  }

  // --- Aggregations ---

  List<Transaction> get currentMonthTransactions {
    return transactions
        .where((t) => FinFormat.isSameMonth(t.date, currentMonth))
        .toList();
  }

  double getSpentForCategory(CategoryGroup cat) {
    return currentMonthTransactions
        .where((t) => t.category == cat && t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void _checkBudgetWarnings(CategoryGroup cat) {
    try {
      final budget = budgets.firstWhere((b) => b.category == cat);
      final spent = getSpentForCategory(cat);
      if (spent > budget.limitAmount) {
        EventBus.emit(
          FinanceEvent(
            'Budget Exceeded',
            'You have exceeded your ${cat.name} budget.',
            AppColors.error,
            Icons.warning,
          ),
        );
      } else if (spent > budget.limitAmount * 0.8) {
        EventBus.emit(
          FinanceEvent(
            'Budget Warning',
            'You are nearing your limit for ${cat.name}.',
            AppColors.warning,
            Icons.warning_amber,
          ),
        );
      }
    } catch (_) {
      /* No budget for this category */
    }
  }

  double get monthlyIncome => currentMonthTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
  double get monthlyExpense => currentMonthTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
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
// 7. MAIN APP BOOTSTRAP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FinanceApp());
}

class FinanceApp extends StatefulWidget {
  const FinanceApp({Key? key}) : super(key: key);

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = EventBus.stream.listen((event) {
      if (mounted) {
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(event.icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        event.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: event.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Finance',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _scaffoldKey,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
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
    if (state.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'NEXUS WEALTH',
                style: AppStyles.h1.copyWith(letterSpacing: 4),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }
    return const MainScaffold();
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final _screens = [
    const DashboardTab(),
    const BudgetsTab(),
    const SavingsTab(),
    const TransactionsTab(),
  ];

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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.donut_large),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Goals'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Activity',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const AddTransactionSheet(),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ============================================================================
// 8. DASHBOARD TAB
// ============================================================================

class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final upcomingBills =
        state.bills
            .where((b) => b.daysUntilDue >= 0 && b.daysUntilDue <= 14)
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Custom Wave Background
                CustomPaint(painter: _WavePainter()),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?u=a',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Total Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          FinFormat.currency(state.masterBalance),
                          style: AppStyles.amountLg.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _QuickStat(
                              icon: Icons.arrow_downward,
                              label: 'Income',
                              amount: state.monthlyIncome,
                              color: AppColors.income,
                            ),
                            const SizedBox(width: 24),
                            _QuickStat(
                              icon: Icons.arrow_upward,
                              label: 'Expense',
                              amount: state.monthlyExpense,
                              color: AppColors.expense,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            transform: Matrix4.translationValues(0.0, -20.0, 0.0),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Upcoming Bills Horizontal List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Upcoming Bills', style: AppStyles.h2),
                      Icon(Icons.arrow_forward, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: upcomingBills.isEmpty
                      ? const Center(
                          child: Text(
                            'No upcoming bills in the next 14 days.',
                            style: AppStyles.caption,
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: upcomingBills.length,
                          itemBuilder: (ctx, i) =>
                              _BillCard(bill: upcomingBills[i]),
                        ),
                ),

                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text('Recent Activity', style: AppStyles.h2),
                ),
                const SizedBox(height: 16),

                ...state.transactions
                    .take(5)
                    .map((t) => _TransactionTile(tx: t))
                    .toList(),

                const SizedBox(height: 100), // FAB padding
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height * 0.85,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.9,
    );
    path.lineTo(size.width, 0);
    path.close();

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [AppColors.primaryDark, AppColors.primary],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  const _QuickStat({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              FinFormat.compactCurrency(amount),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final RecurringBill bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context, listen: false);
    final isUrgent = bill.daysUntilDue <= 3;
    final color = AppColors.getCategoryColor(bill.category);

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? AppColors.error.withOpacity(0.5)
              : AppColors.surfaceHighlight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt, color: color, size: 16),
              ),
              if (bill.isAutoPay)
                const Icon(
                  Icons.autorenew,
                  color: AppColors.textMuted,
                  size: 16,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bill.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                FinFormat.currency(bill.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bill.daysUntilDue == 0 ? 'Today' : 'In ${bill.daysUntilDue}d',
                style: TextStyle(
                  color: isUrgent ? AppColors.error : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!bill.isAutoPay)
                GestureDetector(
                  onTap: () => state.payBill(bill.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final bool isIncome = tx.type == TransactionType.income;
    final bool isTransfer = tx.type == TransactionType.transfer;
    final color = AppColors.getCategoryColor(tx.category);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isTransfer
              ? Icons.swap_horiz
              : (isIncome ? Icons.arrow_downward : Icons.shopping_bag),
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        tx.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${FinFormat.dateShort(tx.date)} • ${tx.category.name.toUpperCase()}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${FinFormat.currency(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isTransfer
              ? AppColors.textMain
              : (isIncome ? AppColors.income : AppColors.textMain),
        ),
      ),
    );
  }
}

// ============================================================================
// 9. BUDGETS TAB & CUSTOM DONUT PAINTER
// ============================================================================

class BudgetsTab extends StatelessWidget {
  const BudgetsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final budgets = state.budgets;

    double totalLimit = 0;
    double totalSpent = 0;
    for (var b in budgets) {
      totalLimit += b.limitAmount;
      totalSpent += state.getSpentForCategory(b.category);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Budgets')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Master Budget Ring
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CustomPaint(
                    painter: _MasterBudgetRingPainter(
                      spent: totalSpent,
                      limit: totalLimit,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BudgetLegend(
                      title: 'Total Budget',
                      amount: totalLimit,
                      color: AppColors.textMuted,
                    ),
                    _BudgetLegend(
                      title: 'Total Spent',
                      amount: totalSpent,
                      color: totalSpent > totalLimit
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Category Budgets', style: AppStyles.h2),
          const SizedBox(height: 16),

          ...budgets.map((b) {
            final spent = state.getSpentForCategory(b.category);
            final prog = (spent / b.limitAmount).clamp(0.0, 1.0);
            final isExceeded = spent > b.limitAmount;
            final color = AppColors.getCategoryColor(b.category);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category, color: color, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            b.category.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${FinFormat.currency(spent)} / ${FinFormat.currency(b.limitAmount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExceeded
                              ? AppColors.error
                              : AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: prog,
                      minHeight: 8,
                      backgroundColor: AppColors.background,
                      color: isExceeded ? AppColors.error : color,
                    ),
                  ),
                  if (isExceeded)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Budget Exceeded!',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _BudgetLegend extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  const _BudgetLegend({
    required this.title,
    required this.amount,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 8),
            Text(title, style: AppStyles.caption),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          FinFormat.currency(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _MasterBudgetRingPainter extends CustomPainter {
  final double spent;
  final double limit;
  _MasterBudgetRingPainter({required this.spent, required this.limit});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const stroke = 24.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (limit == 0) return;

    double progress = spent / limit;
    bool isExceeded = progress > 1.0;

    // Main Progress Arc
    final activePaint = Paint()
      ..color = isExceeded ? AppColors.error : AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * math.min(progress, 1.0),
      false,
      activePaint,
    );

    // Overflow Arc (if > 100%, draw a second darker red arc representing the overflow)
    if (isExceeded) {
      double overflow = progress - 1.0;
      final overflowPaint = Paint()
        ..color = AppColors.error.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * math.min(overflow, 1.0),
        false,
        overflowPaint,
      );
    }

    // Center Text
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.text = TextSpan(
      text: '${(progress * 100).toInt()}%\n',
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      children: [TextSpan(text: 'Used', style: AppStyles.caption)],
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 10. SAVINGS GOALS TAB
// ============================================================================

class SavingsTab extends StatelessWidget {
  const SavingsTab({Key? key}) : super(key: key);

  void _showFundDialog(BuildContext context, AppState state, SavingsGoal goal) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Fund ${goal.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Amount',
            prefixText: '\$',
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text) ?? 0;
              if (amt > 0) {
                Navigator.pop(ctx);
                state.fundGoal(goal.id, amt);
              }
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final goals = state.goals;

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: goals.length,
        itemBuilder: (ctx, i) {
          final g = goals[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: g.isAchieved
                    ? AppColors.gold.withOpacity(0.5)
                    : AppColors.surfaceHighlight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        g.iconEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, style: AppStyles.h2),
                          if (g.targetDate != null)
                            Text(
                              'Target: ${FinFormat.dateShort(g.targetDate!)}',
                              style: AppStyles.caption,
                            ),
                        ],
                      ),
                    ),
                    if (g.isAchieved)
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.gold,
                        size: 32,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saved', style: AppStyles.caption),
                        Text(
                          FinFormat.currency(g.currentAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'of ${FinFormat.currency(g.targetAmount)}',
                      style: AppStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: g.progress,
                    minHeight: 12,
                    backgroundColor: AppColors.background,
                    color: g.isAchieved ? AppColors.gold : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: g.isAchieved
                          ? AppColors.surfaceHighlight
                          : AppColors.primary,
                    ),
                    onPressed: g.isAchieved
                        ? null
                        : () => _showFundDialog(context, state, g),
                    child: Text(
                      g.isAchieved ? 'GOAL COMPLETED' : 'ADD FUNDS',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 11. TRANSACTIONS TAB & CUSTOM BAR CHART
// ============================================================================

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: Column(
        children: [
          // Bar Chart Simulation
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _CashFlowBarChartPainter(
                transactions: state.transactions,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: state.transactions.length,
              itemBuilder: (ctx, i) =>
                  _TransactionTile(tx: state.transactions[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowBarChartPainter extends CustomPainter {
  final List<Transaction> transactions;
  _CashFlowBarChartPainter({required this.transactions});

  @override
  void paint(Canvas canvas, Size size) {
    // Highly simplified mock bar chart logic based on randomized dates.
    // In production, aggregate transactions into 6 monthly buckets.
    final paintInc = Paint()
      ..color = AppColors.income
      ..style = PaintingStyle.fill;
    final paintExp = Paint()
      ..color = AppColors.expense
      ..style = PaintingStyle.fill;

    final barW = (size.width / 6) * 0.3;
    final maxH = size.height - 20;

    for (int i = 0; i < 6; i++) {
      // Fake normalized data for visual structure
      double incH = maxH * (0.3 + math.Random(i).nextDouble() * 0.6);
      double expH = maxH * (0.2 + math.Random(i + 10).nextDouble() * 0.5);

      double xCenter = (i * (size.width / 6)) + (size.width / 12);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xCenter - barW - 2,
            size.height - incH - 20,
            barW,
            incH,
          ),
          const Radius.circular(4),
        ),
        paintInc,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xCenter + 2, size.height - expH - 20, barW, expH),
          const Radius.circular(4),
        ),
        paintExp,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 12. CUSTOM NUMPAD & ADD TRANSACTION SHEET
// ============================================================================

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({Key? key}) : super(key: key);

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _amount = '0';
  TransactionType _type = TransactionType.expense;
  CategoryGroup _category = CategoryGroup.food;
  final _noteCtrl = TextEditingController();

  void _onKey(String val) {
    setState(() {
      if (val == 'C') {
        _amount = '0';
      } else if (val == '<') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
      } else if (val == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0')
          _amount = val;
        else {
          if (_amount.contains('.')) {
            final p = _amount.split('.');
            if (p[1].length >= 2) return;
          }
          if (_amount.length < 8) _amount += val;
        }
      }
    });
  }

  void _submit(AppState state) async {
    final amt = double.tryParse(_amount) ?? 0;
    if (amt <= 0) return;
    final success = await state.addTransaction(
      amt,
      _category,
      _noteCtrl.text,
      _type,
    );
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final color = _type == TransactionType.expense
        ? AppColors.expense
        : AppColors.income;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Transaction', style: AppStyles.h2),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Type Toggle
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith(
                (states) => states.contains(MaterialState.selected)
                    ? color
                    : AppColors.surface,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Amount Display
          Text(
            '\$$_amount',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 24),

          // Details Form
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<CategoryGroup>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    value: _category,
                    items: CategoryGroup.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      hintText: 'Note (Optional)',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Custom Numpad
                  _buildNumpad(),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _amount == '0' ? null : () => _submit(state),
                      child: const Text(
                        'SAVE TRANSACTION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
      children: keys
          .map(
            (row) => Row(
              children: row
                  .map(
                    (k) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: InkWell(
                          onTap: () => _onKey(k),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: k == '<'
                                ? const Icon(Icons.backspace)
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
          )
          .toList(),
    );
  }
}
