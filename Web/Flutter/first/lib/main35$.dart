import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
// Per-file Color compatibility shim (replaces deprecated withOpacity usage)
extension ColorWithValues on Color {
  Color withValues(double opacity) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int b = value & 0xFF;
    return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
  }
}


// Minimal `intl` shim (per-file) to avoid external dependency
class NumberFormat {
  final String? _symbol;
  final int? _decimalDigits;
  // ignore: unused_field
  final bool _isDecimalPattern;
  NumberFormat.currency({String symbol = '', int decimalDigits = 2})
    : _symbol = symbol,
      _decimalDigits = decimalDigits,
      _isDecimalPattern = false;
  NumberFormat.decimalPattern()
    : _symbol = null,
      _decimalDigits = null,
      _isDecimalPattern = true;

  String format(num value) {
    final negative = value < 0;
    final abs = value.abs();
    final int decimals = _decimalDigits ?? (abs % 1 == 0 ? 0 : 2);
    final fixed = abs.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? '.' + parts[1] : '';
    final withCommas = _addCommas(intPart);
    final out = '${_symbol ?? ''}$withCommas$fracPart';
    return negative ? '-$out' : out;
  }

  static String _addCommas(String s) {
    final rev = s.split('').reversed.toList();
    final buf = <String>[];
    for (var i = 0; i < rev.length; i++) {
      if (i != 0 && i % 3 == 0) buf.add(',');
      buf.add(rev[i]);
    }
    return buf.reversed.join();
  }
}

class DateFormat {
  final String pattern;
  DateFormat(this.pattern);
  String format(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    if (pattern.contains('HH') ||
        pattern.contains('mm') ||
        pattern.contains('ss')) {
      return pattern
          .replaceAll('HH', two(dt.hour))
          .replaceAll('mm', two(dt.minute))
          .replaceAll('ss', two(dt.second));
    }
    if (pattern.contains('MMM')) {
      const months = [
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
      return pattern
          .replaceAll('MMM', months[dt.month - 1])
          .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
          .replaceAll('yyyy', dt.year.toString());
    }
    return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)}';
  }
}

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const VaultApp());
}

class VaultApp extends StatelessWidget {
  const VaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SavingsStateProvider(
      child: MaterialApp(
        title: 'Vault: Enterprise Savings Engine',
        debugShowCheckedModeBanner: false,
        home: MasterSavingsDashboard(),
      ),
    );
  }
}

// ==========================================
// 1. DATA PARADIGMS & STRUCTURES
// ==========================================

enum AppSection { dashboard, activeGoals, completed, settings }

class DepositRecord {
  final String id;
  final double amount;
  final DateTime timestamp;

  const DepositRecord({
    required this.id,
    required this.amount,
    required this.timestamp,
  });
}

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final DateTime deadline;
  final IconData icon;
  final Color themeColor;
  final List<DepositRecord> deposits;
  final bool remindersEnabled;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.deadline,
    required this.icon,
    required this.themeColor,
    List<DepositRecord>? deposits,
    this.remindersEnabled = true,
  }) : deposits = deposits ?? [];

  double get currentAmount => deposits.fold(0, (sum, dep) => sum + dep.amount);
  double get remainingAmount => math.max(0, targetAmount - currentAmount);
  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  bool get isCompleted => currentAmount >= targetAmount;

  int get daysRemaining {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  double get requiredDailyPacing {
    if (isCompleted || daysRemaining == 0) return 0;
    return remainingAmount / daysRemaining;
  }

  double get requiredMonthlyPacing => requiredDailyPacing * 30.44;

  // Milestone tracking (Returns highest milestone reached: 0, 25, 50, 75, 100)
  int get currentMilestone {
    double p = progress * 100;
    if (p >= 100) return 100;
    if (p >= 75) return 75;
    if (p >= 50) return 50;
    if (p >= 25) return 25;
    return 0;
  }
}

// ==========================================
// 2. STATE MANAGEMENT & ARCHITECTURE
// ==========================================

class SavingsEngineController extends ChangeNotifier {
  AppSection currentSection = AppSection.dashboard;
  SavingsGoal? focusedGoal;

  // Ephemeral state for UI triggers
  bool showCelebration = false;
  int milestoneReached = 0;

  final List<SavingsGoal> _goals = [];

  SavingsEngineController() {
    _seedEnterpriseData();
  }

  void _seedEnterpriseData() {
    final now = DateTime.now();
    _goals.addAll([
      SavingsGoal(
        id: 'G-101',
        title: 'Tesla Model 3 Downpayment',
        targetAmount: 15000,
        deadline: now.add(const Duration(days: 365)),
        icon: Icons.electric_car,
        themeColor: const Color(0xff0ea5e9),
        deposits: [
          DepositRecord(
            id: 'D-1',
            amount: 2500,
            timestamp: now.subtract(const Duration(days: 60)),
          ),
          DepositRecord(
            id: 'D-2',
            amount: 1200,
            timestamp: now.subtract(const Duration(days: 30)),
          ),
        ],
      ),
      SavingsGoal(
        id: 'G-102',
        title: 'Kyoto Vacation Fund',
        targetAmount: 6500,
        deadline: now.add(const Duration(days: 120)),
        icon: Icons.flight_takeoff,
        themeColor: const Color(0xff10b981),
        deposits: [
          DepositRecord(
            id: 'D-3',
            amount: 3250,
            timestamp: now.subtract(const Duration(days: 10)),
          ),
        ],
      ),
      SavingsGoal(
        id: 'G-103',
        title: 'Emergency Liquid Runway',
        targetAmount: 25000,
        deadline: now.add(const Duration(days: 730)),
        icon: Icons.shield_outlined,
        themeColor: const Color(0xfff59e0b),
        deposits: [
          DepositRecord(
            id: 'D-4',
            amount: 5000,
            timestamp: now.subtract(const Duration(days: 180)),
          ),
        ],
      ),
    ]);
  }

  List<SavingsGoal> get activeGoals =>
      _goals.where((g) => !g.isCompleted).toList();
  List<SavingsGoal> get completedGoals =>
      _goals.where((g) => g.isCompleted).toList();

  double get totalPortfolioSaved =>
      _goals.fold(0, (sum, goal) => sum + goal.currentAmount);
  double get totalPortfolioTarget =>
      _goals.fold(0, (sum, goal) => sum + goal.targetAmount);
  double get globalProgress => totalPortfolioTarget == 0
      ? 0
      : totalPortfolioSaved / totalPortfolioTarget;

  void switchSection(AppSection section) {
    currentSection = section;
    focusedGoal = null;
    notifyListeners();
  }

  void focusGoal(String id) {
    focusedGoal = _goals.firstWhere((g) => g.id == id);
    currentSection = AppSection.activeGoals;
    notifyListeners();
  }

  void executeDeposit(String goalId, double amount) {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex == -1 || amount <= 0) return;

    final goal = _goals[goalIndex];
    final int preMilestone = goal.currentMilestone;

    goal.deposits.add(
      DepositRecord(
        id: 'D-${math.Random().nextInt(90000)}',
        amount: amount,
        timestamp: DateTime.now(),
      ),
    );

    final int postMilestone = goal.currentMilestone;

    // Trigger Celebration if a new milestone is crossed
    if (postMilestone > preMilestone) {
      triggerCelebration(postMilestone);
    }

    notifyListeners();
  }

  void triggerCelebration(int milestone) {
    showCelebration = true;
    milestoneReached = milestone;
    notifyListeners();

    // Auto-dismiss celebration overlay
    Future.delayed(const Duration(seconds: 4), () {
      showCelebration = false;
      notifyListeners();
    });
  }

  void toggleReminders(String goalId) {
    // In a real app, this interfaces with flutter_local_notifications
    // Handled purely in state for this architecture demo.
    notifyListeners();
  }
}

// Inherited Architecture Context
class SavingsStateProvider extends StatefulWidget {
  final Widget child;
  const SavingsStateProvider({super.key, required this.child});

  static SavingsEngineController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedSavingsProvider>();
    return result!.controller;
  }

  @override
  State<SavingsStateProvider> createState() => _SavingsStateProviderState();
}

class _SavingsStateProviderState extends State<SavingsStateProvider> {
  late SavingsEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = SavingsEngineController()..addListener(_stateListener);
  }

  void _stateListener() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_stateListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSavingsProvider(
      controller: controller,
      child: widget.child,
    );
  }
}

class _InheritedSavingsProvider extends InheritedWidget {
  final SavingsEngineController controller;
  const _InheritedSavingsProvider({
    required this.controller,
    required super.child,
  });
  @override
  bool updateShouldNotify(covariant _InheritedSavingsProvider oldWidget) =>
      true;
}

// ==========================================
// 3. MASTER UI SHELL & NAVIGATION
// ==========================================

class MasterSavingsDashboard extends StatelessWidget {
  const MasterSavingsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SavingsStateProvider.of(context);

    Widget interfaceView;
    if (controller.focusedGoal != null) {
      interfaceView = GoalDetailView(goal: controller.focusedGoal!);
    } else {
      switch (controller.currentSection) {
        case AppSection.dashboard:
          interfaceView = const DashboardOverviewView();
          break;
        case AppSection.activeGoals:
          interfaceView = const ActiveGoalsView();
          break;
        case AppSection.completed:
          interfaceView = const Center(child: Text("Completed Goals Archive"));
          break;
        case AppSection.settings:
          interfaceView = const Center(
            child: Text("System Settings & Reminders"),
          );
          break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Stack(
        children: [
          Row(
            children: [
              // Rail Navigation
              Container(
                width: 260,
                color: const Color(0xff020617),
                child: Column(
                  children: [
                    const SizedBox(height: 54),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          color: Color(0xff38bdf8),
                          size: 36,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "VAULT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      "WEALTH ACCUMULATION",
                      style: TextStyle(
                        color: Color(0xff334155),
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 54),
                    _SidebarNavButton(
                      icon: Icons.grid_view_rounded,
                      label: "Portfolio Dashboard",
                      target: AppSection.dashboard,
                    ),
                    _SidebarNavButton(
                      icon: Icons.track_changes,
                      label: "Active Operations",
                      target: AppSection.activeGoals,
                    ),
                    _SidebarNavButton(
                      icon: Icons.verified,
                      label: "Completed Archives",
                      target: AppSection.completed,
                    ),
                    _SidebarNavButton(
                      icon: Icons.settings,
                      label: "System Alerts",
                      target: AppSection.settings,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: interfaceView,
                ),
              ),
            ],
          ),

          // Milestone Celebration Overlay
          if (controller.showCelebration)
            const Positioned.fill(
              child: IgnorePointer(child: ParticleCelebrationOverlay()),
            ),

          if (controller.showCelebration)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff020617),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    "🏆 MILESTONE REACHED: ${controller.milestoneReached}% COMPLETED!",
                    style: const TextStyle(
                      color: Color(0xfff59e0b),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppSection target;

  const _SidebarNavButton({
    required this.icon,
    required this.label,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final controller = SavingsStateProvider.of(context);
    bool selected =
        controller.currentSection == target && controller.focusedGoal == null;

    return InkWell(
      onTap: () => controller.switchSection(target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: selected ? const Color(0xff38bdf8) : Colors.transparent,
              width: 4,
            ),
          ),
          color: selected ? const Color(0xff0f172a) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xff38bdf8)
                  : const Color(0xff475569),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xff94a3b8),
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. VIEW 1: PORTFOLIO DASHBOARD
// ==========================================

class DashboardOverviewView extends StatelessWidget {
  const DashboardOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SavingsStateProvider.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Portfolio Overview",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xff020617),
            ),
          ),
          const Text(
            "Aggregate metrics across all active financial parameters.",
            style: TextStyle(color: Color(0xff64748b), fontSize: 16),
          ),
          const SizedBox(height: 48),

          // Hero Metric Card
          Container(
            padding: const EdgeInsets.all(42),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff020617), Color(0xff0f172a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TOTAL LIQUIDITY SECURED",
                      style: TextStyle(
                        color: Color(0xff38bdf8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmt.format(controller.totalPortfolioSaved),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Target Trajectory: ${fmt.format(controller.totalPortfolioTarget)}",
                      style: const TextStyle(
                        color: Color(0xff94a3b8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CustomPaint(
                    painter: _GlobalProgressPainter(
                      progress: controller.globalProgress,
                    ),
                    child: Center(
                      child: Text(
                        "${(controller.globalProgress * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
          const Text(
            "Priority Targets",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff020617),
            ),
          ),
          const SizedBox(height: 24),

          // Goals Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.1,
            ),
            itemCount: controller.activeGoals.length,
            itemBuilder: (context, index) {
              final goal = controller.activeGoals[index];
              return InkWell(
                onTap: () => controller.focusGoal(goal.id),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: goal.themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              goal.icon,
                              color: goal.themeColor,
                              size: 28,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${goal.daysRemaining} Days Left",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fmt.format(goal.currentAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                fmt.format(goal.targetAmount),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: goal.progress,
                            backgroundColor: const Color(0xfff1f5f9),
                            color: goal.themeColor,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. VIEW 2: ACTIVE GOAL DETAIL & DEPOSITOR
// ==========================================

class GoalDetailView extends StatefulWidget {
  final SavingsGoal goal;
  const GoalDetailView({super.key, required this.goal});

  @override
  State<GoalDetailView> createState() => _GoalDetailViewState();
}

class _GoalDetailViewState extends State<GoalDetailView> {
  final _depositController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = SavingsStateProvider.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.switchSection(AppSection.dashboard),
              ),
              const SizedBox(width: 16),
              Icon(widget.goal.icon, color: widget.goal.themeColor, size: 32),
              const SizedBox(width: 16),
              Text(
                widget.goal.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Radial Progress & Metrics
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 280,
                        width: 280,
                        child: CustomPaint(
                          painter: _RadialGoalPainter(
                            progress: widget.goal.progress,
                            themeColor: widget.goal.themeColor,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${(widget.goal.progress * 100).toInt()}%",
                                  style: TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    color: widget.goal.themeColor,
                                  ),
                                ),
                                const Text(
                                  "ACHIEVED",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatBlock(
                            label: "CURRENT BALANCE",
                            val: fmt.format(widget.goal.currentAmount),
                          ),
                          _StatBlock(
                            label: "REMAINING",
                            val: fmt.format(widget.goal.remainingAmount),
                          ),
                          _StatBlock(
                            label: "DAYS LEFT",
                            val: widget.goal.daysRemaining.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),

              // Right Panel: Deposit & Ledger
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Action: Deposit
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xff020617),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "EXECUTE DEPOSIT",
                            style: TextStyle(
                              color: Color(0xff38bdf8),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _depositController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              prefixText: "\$ ",
                              prefixStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 24,
                              ),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              hintText: "0.00",
                              hintStyle: const TextStyle(color: Colors.white24),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.goal.themeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                double? amt = double.tryParse(
                                  _depositController.text,
                                );
                                if (amt != null && amt > 0) {
                                  controller.executeDeposit(
                                    widget.goal.id,
                                    amt,
                                  );
                                  _depositController.clear();
                                }
                              },
                              child: const Text(
                                "CONFIRM TRANSFER",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Required Pacing / Mo",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  fmt.format(widget.goal.requiredMonthlyPacing),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action: Ledger
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xffe2e8f0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Transaction Ledger",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (widget.goal.deposits.isEmpty)
                            const Text(
                              "No transactions recorded.",
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.goal.deposits.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, idx) {
                                final dep = widget.goal.deposits.reversed
                                    .toList()[idx];
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.arrow_downward,
                                          color: Color(0xff10b981),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(dep.timestamp),
                                          style: const TextStyle(
                                            color: Color(0xff475569),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "+${fmt.format(dep.amount)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xff020617),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String val;
  const _StatBlock({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          val,
          style: const TextStyle(
            color: Color(0xff020617),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 6. ACTIVE GOALS LIST VIEW
// ==========================================

class ActiveGoalsView extends StatelessWidget {
  const ActiveGoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Active Operations Detail List Engine"));
  }
}

// ==========================================
// 7. CUSTOM VISUALIZATION PAINTERS
// ==========================================

class _GlobalProgressPainter extends CustomPainter {
  final double progress;
  _GlobalProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = const Color(0xff38bdf8)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi,
      math.pi,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi,
      math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RadialGoalPainter extends CustomPainter {
  final double progress;
  final Color themeColor;
  _RadialGoalPainter({required this.progress, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xfff1f5f9)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = themeColor
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 8. PROCEDURAL CELEBRATION (CONFETTI)
// ==========================================

class ParticleCelebrationOverlay extends StatefulWidget {
  const ParticleCelebrationOverlay({super.key});

  @override
  State<ParticleCelebrationOverlay> createState() =>
      _ParticleCelebrationOverlayState();
}

class _ParticleCelebrationOverlayState extends State<ParticleCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    // Seed procedural particles
    final r = math.Random();
    for (int i = 0; i < 150; i++) {
      particles.add(
        _Particle(
          x: r.nextDouble(),
          y: -0.2 - r.nextDouble(), // start above screen
          vx: (r.nextDouble() - 0.5) * 0.5,
          vy: r.nextDouble() * 1.5 + 0.5,
          color: [
            Colors.blue,
            Colors.green,
            Colors.yellow,
            Colors.pink,
            Colors.orange,
          ][r.nextInt(5)],
          size: r.nextDouble() * 10 + 5,
          rot: r.nextDouble() * math.pi * 2,
          rotSpeed: (r.nextDouble() - 0.5) * 0.2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x, y, vx, vy, size, rot, rotSpeed;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rot,
    required this.rotSpeed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      double px = p.x * size.width + (p.vx * progress * size.width);
      double py =
          p.y * size.height +
          (p.vy * progress * size.height * 2) +
          (4.9 * math.pow(progress * 2, 2) * size.height); // basic gravity

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rot + (p.rotSpeed * progress * 100));

      final paint = Paint()..color = p.color;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
