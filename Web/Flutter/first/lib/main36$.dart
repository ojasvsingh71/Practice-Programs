/// ============================================================================
/// ULTIMATE BILL REMINDER APP - PURE NATIVE FLUTTER
/// Zero External Dependencies. Features Custom Painting, Custom Calendar,
/// Advanced State Management, Animations, and Simulated Notifications.
/// ============================================================================

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


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const UltimateBillApp());
}

/// ============================================================================
/// 1. APP ROOT & THEME
/// ============================================================================
class UltimateBillApp extends StatefulWidget {
  const UltimateBillApp({Key? key}) : super(key: key);

  @override
  State<UltimateBillApp> createState() => _UltimateBillAppState();
}

class _UltimateBillAppState extends State<UltimateBillApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Bill Master',
          debugShowCheckedModeBanner: false,
          themeMode: _appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: MainNavigator(appState: _appState),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primary = Color(0xFF4F46E5); // Indigo
    const secondary = Color(0xFF10B981); // Emerald

    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        secondary: secondary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        centerTitle: true,
      ),
      cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}

/// ============================================================================
/// 2. CORE DOMAIN MODELS
/// ============================================================================
enum Recurrence { none, daily, weekly, monthly, yearly }

enum BillCategory { housing, utilities, subscriptions, creditCard, auto, other }

class Bill {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final Recurrence recurrence;
  final BillCategory category;
  final String notes;

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.recurrence = Recurrence.none,
    this.category = BillCategory.other,
    this.notes = '',
  });

  Bill copyWith({
    String? title,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    Recurrence? recurrence,
    BillCategory? category,
    String? notes,
  }) {
    return Bill(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      recurrence: recurrence ?? this.recurrence,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}

class AlertMessage {
  final String id;
  final String message;
  final DateTime timestamp;
  AlertMessage(this.message)
    : id = UniqueKey().toString(),
      timestamp = DateTime.now();
}

/// ============================================================================
/// 3. ADVANCED STATE MANAGEMENT
/// ============================================================================
class AppState extends ChangeNotifier {
  final List<Bill> _bills = [];
  final List<AlertMessage> _alerts = [];
  bool _isDarkMode = false;
  Timer? _notificationEngine;

  AppState() {
    _seedData();
    _startNotificationEngine();
  }

  bool get isDarkMode => _isDarkMode;
  List<Bill> get allBills => List.unmodifiable(_bills);
  List<AlertMessage> get alerts => List.unmodifiable(_alerts);

  List<Bill> get upcomingBills {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _bills.where((b) => !b.isPaid && !b.dueDate.isBefore(today)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Bill> get overdueBills {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _bills.where((b) => !b.isPaid && b.dueDate.isBefore(today)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Bill> get paidBills {
    return _bills.where((b) => b.isPaid).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void addBill(Bill bill) {
    _bills.add(bill);
    _checkDuplicates(bill);
    notifyListeners();
  }

  void updateBill(Bill updated) {
    final index = _bills.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _bills[index] = updated;
      notifyListeners();
    }
  }

  void deleteBill(String id) {
    _bills.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void markAsPaid(String id) {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index != -1) {
      final bill = _bills[index];
      _bills[index] = bill.copyWith(isPaid: true);

      if (bill.recurrence != Recurrence.none) {
        _generateNextRecurrence(bill);
      }
      notifyListeners();
    }
  }

  void dismissAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void _generateNextRecurrence(Bill bill) {
    DateTime nextDate;
    switch (bill.recurrence) {
      case Recurrence.daily:
        nextDate = bill.dueDate.add(const Duration(days: 1));
        break;
      case Recurrence.weekly:
        nextDate = bill.dueDate.add(const Duration(days: 7));
        break;
      case Recurrence.monthly:
        nextDate = DateTime(
          bill.dueDate.year,
          bill.dueDate.month + 1,
          bill.dueDate.day,
        );
        break;
      case Recurrence.yearly:
        nextDate = DateTime(
          bill.dueDate.year + 1,
          bill.dueDate.month,
          bill.dueDate.day,
        );
        break;
      default:
        return;
    }

    // Prevent duplicate recurrences
    bool exists = _bills.any(
      (b) => b.title == bill.title && b.dueDate == nextDate,
    );
    if (!exists) {
      _bills.add(
        Bill(
          id: UniqueKey().toString(),
          title: bill.title,
          amount: bill.amount,
          dueDate: nextDate,
          recurrence: bill.recurrence,
          category: bill.category,
          notes: bill.notes,
        ),
      );
    }
  }

  void _checkDuplicates(Bill newBill) {
    final duplicates = _bills.where(
      (b) =>
          b.id != newBill.id &&
          b.title.toLowerCase() == newBill.title.toLowerCase() &&
          b.dueDate == newBill.dueDate,
    );
    if (duplicates.isNotEmpty) {
      _alerts.insert(
        0,
        AlertMessage(
          'Warning: You have duplicate bills for "${newBill.title}" on the same date.',
        ),
      );
    }
  }

  void _startNotificationEngine() {
    _notificationEngine = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      bool triggered = false;

      for (var bill in upcomingBills) {
        final daysLeft = bill.dueDate
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        if (daysLeft == 1 && now.hour == 9 && now.minute == 0) {
          final msg =
              'Reminder: ${bill.title} (\$$bill.amount) is due tomorrow!';
          if (!_alerts.any((a) => a.message == msg)) {
            _alerts.insert(0, AlertMessage(msg));
            triggered = true;
          }
        }
      }
      if (triggered) notifyListeners();
    });
  }

  void _seedData() {
    final today = DateTime.now();
    _bills.addAll([
      Bill(
        id: '1',
        title: 'Rent',
        amount: 1200.0,
        dueDate: DateTime(today.year, today.month, 1),
        recurrence: Recurrence.monthly,
        category: BillCategory.housing,
      ),
      Bill(
        id: '2',
        title: 'Electric',
        amount: 85.50,
        dueDate: today.add(const Duration(days: 2)),
        recurrence: Recurrence.monthly,
        category: BillCategory.utilities,
      ),
      Bill(
        id: '3',
        title: 'Netflix',
        amount: 15.99,
        dueDate: today.add(const Duration(days: 5)),
        recurrence: Recurrence.monthly,
        category: BillCategory.subscriptions,
      ),
      Bill(
        id: '4',
        title: 'Car Loan',
        amount: 350.0,
        dueDate: today.subtract(const Duration(days: 2)),
        recurrence: Recurrence.monthly,
        category: BillCategory.auto,
      ), // Overdue
    ]);
  }

  @override
  void dispose() {
    _notificationEngine?.cancel();
    super.dispose();
  }
}

/// ============================================================================
/// 4. MAIN NAVIGATOR & ROUTING
/// ============================================================================
class MainNavigator extends StatefulWidget {
  final AppState appState;
  const MainNavigator({Key? key, required this.appState}) : super(key: key);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(appState: widget.appState),
      CalendarScreen(appState: widget.appState),
      AlertsScreen(appState: widget.appState),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: widget.appState.alerts.isNotEmpty,
              label: Text(widget.appState.alerts.length.toString()),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddBillSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddBillSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditBillForm(appState: widget.appState),
    );
  }
}

/// ============================================================================
/// 5. DASHBOARD SCREEN (Charts & Lists)
/// ============================================================================
class DashboardScreen extends StatelessWidget {
  final AppState appState;
  const DashboardScreen({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final overdue = appState.overdueBills;
    final upcoming = appState.upcomingBills;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                child: SpendingChart(appState: appState),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: appState.toggleTheme,
            ),
          ],
        ),
        if (overdue.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'OVERDUE',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  BillCard(bill: overdue[index], appState: appState),
              childCount: overdue.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'UPCOMING',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        upcoming.isEmpty
            ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'You are all caught up!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      BillCard(bill: upcoming[index], appState: appState),
                  childCount: upcoming.length,
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

/// ============================================================================
/// 6. CUSTOM CHART (CustomPaint)
/// ============================================================================
class SpendingChart extends StatelessWidget {
  final AppState appState;
  const SpendingChart({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<BillCategory, double> categoryTotals = {};
    double total = 0;

    for (var bill in appState.allBills) {
      if (bill.dueDate.month == DateTime.now().month) {
        categoryTotals[bill.category] =
            (categoryTotals[bill.category] ?? 0) + bill.amount;
        total += bill.amount;
      }
    }

    if (total == 0) {
      return const Center(child: Text('No data for this month'));
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: PieChartPainter(data: categoryTotals, total: total),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This Month',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '\$${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<BillCategory, double> data;
  final double total;

  PieChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -math.pi / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    data.forEach((category, amount) {
      final sweepAngle = (amount / total) * 2 * math.pi;
      final paint = Paint()
        ..color = _getColor(category)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle - 0.1, false, paint);
      startAngle += sweepAngle;
    });
  }

  Color _getColor(BillCategory category) {
    switch (category) {
      case BillCategory.housing:
        return Colors.indigo;
      case BillCategory.utilities:
        return Colors.blue;
      case BillCategory.subscriptions:
        return Colors.purple;
      case BillCategory.creditCard:
        return Colors.redAccent;
      case BillCategory.auto:
        return Colors.orange;
      case BillCategory.other:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ============================================================================
/// 7. CUSTOM CALENDAR SCREEN
/// ============================================================================
class CalendarScreen extends StatefulWidget {
  final AppState appState;
  const CalendarScreen({Key? key, required this.appState}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _nextMonth() => setState(
    () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1),
  );
  void _prevMonth() => setState(
    () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1),
  );

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOffset =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
              ),
              Text(
                '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('S'),
                Text('M'),
                Text('T'),
                Text('W'),
                Text('T'),
                Text('F'),
                Text('S'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: daysInMonth + firstDayOffset,
              itemBuilder: (context, index) {
                if (index < firstDayOffset) return const SizedBox.shrink();
                final day = index - firstDayOffset + 1;
                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  day,
                );
                final billsForDay = widget.appState.allBills
                    .where(
                      (b) =>
                          b.dueDate.year == date.year &&
                          b.dueDate.month == date.month &&
                          b.dueDate.day == date.day,
                    )
                    .toList();

                return _buildCalendarDay(date, billsForDay);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date, List<Bill> bills) {
    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final hasUnpaid = bills.any((b) => !b.isPaid);

    return Container(
      decoration: BoxDecoration(
        color: isToday ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (bills.isNotEmpty)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasUnpaid ? Colors.red : Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int month) => [
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
  ][month - 1];
}

/// ============================================================================
/// 8. ALERTS SCREEN
/// ============================================================================
class AlertsScreen extends StatelessWidget {
  final AppState appState;
  const AlertsScreen({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (appState.alerts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerts')),
        body: const Center(
          child: Text('No active alerts', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: ListView.builder(
        itemCount: appState.alerts.length,
        itemBuilder: (context, index) {
          final alert = appState.alerts[index];
          return Dismissible(
            key: Key(alert.id),
            onDismissed: (_) => appState.dismissAlert(alert.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              title: Text(alert.message),
              subtitle: Text(
                '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================================
/// 9. SHARED WIDGETS (Bill Card)
/// ============================================================================
class BillCard extends StatelessWidget {
  final Bill bill;
  final AppState appState;

  const BillCard({Key? key, required this.bill, required this.appState})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = bill.dueDate.difference(today).inDays;

    Color statusColor = Colors.green;
    if (!bill.isPaid) {
      if (daysLeft < 0)
        statusColor = Colors.red;
      else if (daysLeft <= 3)
        statusColor = Colors.orange;
      else
        statusColor = Theme.of(context).primaryColor;
    }

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => appState.deleteBill(bill.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showOptions(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(), color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bill.dueDate.month}/${bill.dueDate.day}/${bill.dueDate.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${bill.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.isPaid
                          ? 'PAID'
                          : (daysLeft < 0 ? 'OVERDUE' : '$daysLeft days left'),
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (bill.category) {
      case BillCategory.housing:
        return Icons.home;
      case BillCategory.utilities:
        return Icons.bolt;
      case BillCategory.subscriptions:
        return Icons.play_arrow;
      case BillCategory.creditCard:
        return Icons.credit_card;
      case BillCategory.auto:
        return Icons.directions_car;
      case BillCategory.other:
        return Icons.receipt;
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!bill.isPaid)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Paid'),
                onTap: () {
                  appState.markAsPaid(bill.id);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Bill'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      AddEditBillForm(appState: appState, billToEdit: bill),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// 10. FORM SCREEN (Add/Edit)
/// ============================================================================
class AddEditBillForm extends StatefulWidget {
  final AppState appState;
  final Bill? billToEdit;
  const AddEditBillForm({Key? key, required this.appState, this.billToEdit})
    : super(key: key);

  @override
  State<AddEditBillForm> createState() => _AddEditBillFormState();
}

class _AddEditBillFormState extends State<AddEditBillForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late DateTime _dueDate;
  late Recurrence _recurrence;
  late BillCategory _category;

  @override
  void initState() {
    super.initState();
    _title = widget.billToEdit?.title ?? '';
    _amount = widget.billToEdit?.amount ?? 0.0;
    _dueDate = widget.billToEdit?.dueDate ?? DateTime.now();
    _recurrence = widget.billToEdit?.recurrence ?? Recurrence.none;
    _category = widget.billToEdit?.category ?? BillCategory.other;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newBill = Bill(
        id: widget.billToEdit?.id ?? UniqueKey().toString(),
        title: _title,
        amount: _amount,
        dueDate: _dueDate,
        recurrence: _recurrence,
        category: _category,
      );
      if (widget.billToEdit == null) {
        widget.appState.addBill(newBill);
      } else {
        widget.appState.updateBill(newBill);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.billToEdit == null ? 'Add New Bill' : 'Edit Bill',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
                onSaved: (val) => _title = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _amount == 0.0 ? '' : _amount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    double.tryParse(val!) == null ? 'Invalid Amount' : null,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(
                  '${_dueDate.month}/${_dueDate.day}/${_dueDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 1825)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: BillCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Recurrence>(
                value: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Recurrence',
                  border: OutlineInputBorder(),
                ),
                items: Recurrence.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _recurrence = val!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text(
                    'SAVE BILL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
