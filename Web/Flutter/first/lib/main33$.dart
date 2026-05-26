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
// Supports NumberFormat.currency(), NumberFormat.decimalPattern(), and simple DateFormat patterns used here.
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
  runApp(const FinCalcApp());
}

class FinCalcApp extends StatelessWidget {
  const FinCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoanStateProvider(
      child: MaterialApp(
        title: 'FinCalc: Enterprise Loan Engine',
        debugShowCheckedModeBanner: false,
        home: MasterLoanDashboard(),
      ),
    );
  }
}

// ==========================================
// 1. DATA MODELS & FINANCIAL MATH
// ==========================================

enum AppSection { emiCalculator, amortization, prepayment, comparison }

class AmortizationRow {
  final int month;
  final double payment;
  final double principalComponent;
  final double interestComponent;
  final double remainingBalance;
  final double totalInterestPaid;

  AmortizationRow({
    required this.month,
    required this.payment,
    required this.principalComponent,
    required this.interestComponent,
    required this.remainingBalance,
    required this.totalInterestPaid,
  });
}

class LoanProfile {
  final String id;
  final double principal;
  final double annualInterestRate;
  final int tenureMonths;
  final double extraMonthlyPayment;
  final double oneTimePrepayment;
  final int prepaymentMonth;

  LoanProfile({
    required this.id,
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    this.extraMonthlyPayment = 0,
    this.oneTimePrepayment = 0,
    this.prepaymentMonth = 0,
  });

  double get monthlyInterestRate => (annualInterestRate / 100) / 12;

  double get baseEMI {
    if (annualInterestRate == 0) return principal / tenureMonths;
    double r = monthlyInterestRate;
    return (principal * r * math.pow(1 + r, tenureMonths)) /
        (math.pow(1 + r, tenureMonths) - 1);
  }

  List<AmortizationRow> generateSchedule() {
    List<AmortizationRow> schedule = [];
    double balance = principal;
    double totalInterest = 0;
    double r = monthlyInterestRate;
    double emi = baseEMI;

    for (int m = 1; m <= tenureMonths; m++) {
      if (balance <= 0) break;

      double interestForMonth = balance * r;

      // Apply extra payments
      double currentPayment = emi + extraMonthlyPayment;
      if (m == prepaymentMonth) {
        currentPayment += oneTimePrepayment;
      }

      // Final payment edge case
      if (currentPayment > (balance + interestForMonth)) {
        currentPayment = balance + interestForMonth;
      }

      double principalForMonth = currentPayment - interestForMonth;
      balance -= principalForMonth;
      if (balance < 0) balance = 0;

      totalInterest += interestForMonth;

      schedule.add(
        AmortizationRow(
          month: m,
          payment: currentPayment,
          principalComponent: principalForMonth,
          interestComponent: interestForMonth,
          remainingBalance: balance,
          totalInterestPaid: totalInterest,
        ),
      );
    }
    return schedule;
  }

  double get totalInterest => generateSchedule().last.totalInterestPaid;
  double get totalPayment => principal + totalInterest;
  int get actualTenure => generateSchedule().length;
}

// ==========================================
// 2. ENTERPRISE STATE MANAGEMENT
// ==========================================

class LoanEngineController extends ChangeNotifier {
  // Navigation
  AppSection currentSection = AppSection.emiCalculator;

  // Active Loan State (Profile 1)
  double p1Principal = 250000;
  double p1Rate = 5.5;
  int p1Tenure = 360; // 30 years

  // Prepayment Variables
  double p1ExtraMonthly = 0;
  double p1LumpSum = 0;
  int p1LumpSumMonth = 12;

  // Comparison State (Profile 2)
  double p2Principal = 250000;
  double p2Rate = 4.5;
  int p2Tenure = 180; // 15 years

  void navigateTo(AppSection section) {
    currentSection = section;
    notifyListeners();
  }

  void updateP1(double p, double r, int t) {
    p1Principal = p;
    p1Rate = r;
    p1Tenure = t;
    notifyListeners();
  }

  void updatePrepayments(double extraM, double lump, int month) {
    p1ExtraMonthly = extraM;
    p1LumpSum = lump;
    p1LumpSumMonth = month;
    notifyListeners();
  }

  void updateP2(double p, double r, int t) {
    p2Principal = p;
    p2Rate = r;
    p2Tenure = t;
    notifyListeners();
  }

  LoanProfile get activeProfile => LoanProfile(
    id: 'P1',
    principal: p1Principal,
    annualInterestRate: p1Rate,
    tenureMonths: p1Tenure,
    extraMonthlyPayment: p1ExtraMonthly,
    oneTimePrepayment: p1LumpSum,
    prepaymentMonth: p1LumpSumMonth,
  );

  LoanProfile get baselineProfile => LoanProfile(
    id: 'P1_BASE',
    principal: p1Principal,
    annualInterestRate: p1Rate,
    tenureMonths: p1Tenure,
  );

  LoanProfile get compareProfile => LoanProfile(
    id: 'P2',
    principal: p2Principal,
    annualInterestRate: p2Rate,
    tenureMonths: p2Tenure,
  );
}

// State Injector
class LoanStateProvider extends StatefulWidget {
  final Widget child;
  const LoanStateProvider({super.key, required this.child});

  static LoanEngineController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedLoanProvider>();
    return result!.controller;
  }

  @override
  State<LoanStateProvider> createState() => _LoanStateProviderState();
}

class _LoanStateProviderState extends State<LoanStateProvider> {
  late LoanEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = LoanEngineController();
    controller.addListener(_onStateChange);
  }

  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_onStateChange);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedLoanProvider(controller: controller, child: widget.child);
  }
}

class _InheritedLoanProvider extends InheritedWidget {
  final LoanEngineController controller;
  const _InheritedLoanProvider({
    required this.controller,
    required super.child,
  });
  @override
  bool updateShouldNotify(covariant _InheritedLoanProvider oldWidget) => true;
}

// ==========================================
// 3. MAIN LAYOUT HUB (SHELL)
// ==========================================

class MasterLoanDashboard extends StatelessWidget {
  const MasterLoanDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LoanStateProvider.of(context);

    Widget activeView;
    switch (controller.currentSection) {
      case AppSection.emiCalculator:
        activeView = const EmiCalculatorView();
        break;
      case AppSection.amortization:
        activeView = const AmortizationView();
        break;
      case AppSection.prepayment:
        activeView = const PrepaymentAnalyzerView();
        break;
      case AppSection.comparison:
        activeView = const LoanComparisonView();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff1f5f9),
      body: Row(
        children: [
          // Left Side Rail Navigation
          Container(
            width: 260,
            color: const Color(0xff0f172a),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const Icon(
                  Icons.account_balance,
                  color: Color(0xff10b981),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "FinCalc",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  "ENTERPRISE LOAN ENGINE",
                  style: TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 64),
                _NavButton(
                  icon: Icons.calculate,
                  label: "EMI Calculator",
                  isActive:
                      controller.currentSection == AppSection.emiCalculator,
                  onTap: () => controller.navigateTo(AppSection.emiCalculator),
                ),
                _NavButton(
                  icon: Icons.table_chart,
                  label: "Amortization",
                  isActive:
                      controller.currentSection == AppSection.amortization,
                  onTap: () => controller.navigateTo(AppSection.amortization),
                ),
                _NavButton(
                  icon: Icons.speed,
                  label: "Prepayment Impact",
                  isActive: controller.currentSection == AppSection.prepayment,
                  onTap: () => controller.navigateTo(AppSection.prepayment),
                ),
                _NavButton(
                  icon: Icons.compare_arrows,
                  label: "Compare Loans",
                  isActive: controller.currentSection == AppSection.comparison,
                  onTap: () => controller.navigateTo(AppSection.comparison),
                ),
              ],
            ),
          ),
          // Dynamic Content Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: activeView,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isActive ? const Color(0xff10b981) : Colors.transparent,
              width: 4,
            ),
          ),
          color: isActive ? const Color(0xff1e293b) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xff10b981)
                  : const Color(0xff64748b),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xff94a3b8),
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. VIEW 1: QUICK EMI CALCULATOR
// ==========================================

class EmiCalculatorView extends StatefulWidget {
  const EmiCalculatorView({super.key});

  @override
  State<EmiCalculatorView> createState() => _EmiCalculatorViewState();
}

class _EmiCalculatorViewState extends State<EmiCalculatorView> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final controller = LoanStateProvider.of(context);
    final profile = controller.baselineProfile;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Loan Overview",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inputs
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SliderInput(
                        label: "Principal Amount",
                        value: controller.p1Principal,
                        min: 5000,
                        max: 2000000,
                        isCurrency: true,
                        onChanged: (v) => controller.updateP1(
                          v,
                          controller.p1Rate,
                          controller.p1Tenure,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SliderInput(
                        label: "Interest Rate (Yearly %)",
                        value: controller.p1Rate,
                        min: 0.1,
                        max: 25.0,
                        isCurrency: false,
                        onChanged: (v) => controller.updateP1(
                          controller.p1Principal,
                          v,
                          controller.p1Tenure,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SliderInput(
                        label: "Loan Tenure (Months)",
                        value: controller.p1Tenure.toDouble(),
                        min: 12,
                        max: 360,
                        isCurrency: false,
                        onChanged: (v) => controller.updateP1(
                          controller.p1Principal,
                          controller.p1Rate,
                          v.toInt(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
              // Outputs
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Equated Monthly Installment (EMI)",
                            style: TextStyle(
                              color: Color(0xff94a3b8),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(profile.baseEMI),
                            style: const TextStyle(
                              color: Color(0xff10b981),
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Total Principal",
                                    style: TextStyle(color: Color(0xff94a3b8)),
                                  ),
                                  Text(
                                    _currencyFormat.format(profile.principal),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Total Interest",
                                    style: TextStyle(color: Color(0xff94a3b8)),
                                  ),
                                  Text(
                                    _currencyFormat.format(
                                      profile.totalInterest,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Payment",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(profile.totalPayment),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Visual Pie Chart
                    SizedBox(
                      height: 250,
                      child: CustomPaint(
                        size: const Size(double.infinity, 250),
                        painter: _PieChartPainter(
                          principal: profile.principal,
                          interest: profile.totalInterest,
                        ),
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

class _SliderInput extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final bool isCurrency;
  final ValueChanged<double> onChanged;

  const _SliderInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.isCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final format = isCurrency
        ? NumberFormat.currency(symbol: '\$', decimalDigits: 0)
        : NumberFormat.decimalPattern();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff475569),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xfff1f5f9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCurrency
                    ? format.format(value)
                    : (label.contains("%")
                          ? "${value.toStringAsFixed(2)}%"
                          : value.toInt().toString()),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xff0f172a),
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xff10b981),
          inactiveColor: const Color(0xffe2e8f0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// PROCEDURAL PIE CHART
class _PieChartPainter extends CustomPainter {
  final double principal;
  final double interest;

  _PieChartPainter({required this.principal, required this.interest});

  @override
  void paint(Canvas canvas, Size size) {
    double total = principal + interest;
    double startAngle = -math.pi / 2;
    double principalSweep = (principal / total) * 2 * math.pi;
    double interestSweep = (interest / total) * 2 * math.pi;

    Rect rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.height * 0.8,
      height: size.height * 0.8,
    );

    // Principal Arc (Teal)
    final pPaint = Paint()
      ..color = const Color(0xff14b8a6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;
    canvas.drawArc(rect, startAngle, principalSweep, false, pPaint);

    // Interest Arc (Coral)
    final iPaint = Paint()
      ..color = const Color(0xfff43f5e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;
    canvas.drawArc(
      rect,
      startAngle + principalSweep,
      interestSweep,
      false,
      iPaint,
    );

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: "Principal\n${((principal / total) * 100).toStringAsFixed(1)}%",
      style: const TextStyle(
        color: Color(0xff14b8a6),
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(20, size.height / 2 - 20));

    textPainter.text = TextSpan(
      text: "Interest\n${((interest / total) * 100).toStringAsFixed(1)}%",
      style: const TextStyle(
        color: Color(0xfff43f5e),
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 80, size.height / 2 - 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 5. VIEW 2: AMORTIZATION SCHEDULE
// ==========================================

class AmortizationView extends StatelessWidget {
  const AmortizationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LoanStateProvider.of(context);
    final profile = controller.baselineProfile;
    final schedule = profile.generateSchedule();
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Amortization Schedule",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "A month-by-month breakdown of how your payments are applied.",
            style: TextStyle(fontSize: 16, color: Color(0xff64748b)),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xfff8fafc),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "Month",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Payment",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Principal",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Interest",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Remaining Balance",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Table Body
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: schedule.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Color(0xfff1f5f9)),
                      itemBuilder: (context, index) {
                        final row = schedule[index];
                        return Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                row.month.toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(format.format(row.payment)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                format.format(row.principalComponent),
                                style: const TextStyle(
                                  color: Color(0xff14b8a6),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                format.format(row.interestComponent),
                                style: const TextStyle(
                                  color: Color(0xfff43f5e),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                format.format(row.remainingBalance),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
}

// ==========================================
// 6. VIEW 3: PREPAYMENT IMPACT ANALYZER
// ==========================================

class PrepaymentAnalyzerView extends StatelessWidget {
  const PrepaymentAnalyzerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LoanStateProvider.of(context);
    final baseProfile = controller.baselineProfile;
    final activeProfile = controller.activeProfile;
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    double interestSaved =
        baseProfile.totalInterest - activeProfile.totalInterest;
    int monthsSaved = baseProfile.actualTenure - activeProfile.actualTenure;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Prepayment Analyzer",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "See how extra payments can drastically reduce your tenure and interest payload.",
            style: TextStyle(fontSize: 16, color: Color(0xff64748b)),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Container(
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
                        "Injection Strategies",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SliderInput(
                        label: "Extra Monthly Payment",
                        value: controller.p1ExtraMonthly,
                        min: 0,
                        max: baseProfile.baseEMI * 2,
                        isCurrency: true,
                        onChanged: (v) => controller.updatePrepayments(
                          v,
                          controller.p1LumpSum,
                          controller.p1LumpSumMonth,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SliderInput(
                        label: "One-Time Lump Sum",
                        value: controller.p1LumpSum,
                        min: 0,
                        max: baseProfile.principal * 0.5,
                        isCurrency: true,
                        onChanged: (v) => controller.updatePrepayments(
                          controller.p1ExtraMonthly,
                          v,
                          controller.p1LumpSumMonth,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SliderInput(
                        label: "Lump Sum Month (When applied)",
                        value: controller.p1LumpSumMonth.toDouble(),
                        min: 1,
                        max: baseProfile.tenureMonths.toDouble(),
                        isCurrency: false,
                        onChanged: (v) => controller.updatePrepayments(
                          controller.p1ExtraMonthly,
                          controller.p1LumpSum,
                          v.toInt(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ImpactCard(
                            title: "Interest Saved",
                            value: format.format(interestSaved),
                            icon: Icons.savings,
                            color: const Color(0xff10b981),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ImpactCard(
                            title: "Tenure Reduced",
                            value: "$monthsSaved Months",
                            icon: Icons.timelapse,
                            color: const Color(0xff3b82f6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Balance Burn-Down",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _BurnDownChartPainter(
                                baseSchedule: baseProfile.generateSchedule(),
                                activeSchedule: activeProfile
                                    .generateSchedule(),
                                maxBalance: baseProfile.principal,
                                maxMonths: baseProfile.tenureMonths,
                              ),
                            ),
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

class _ImpactCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ImpactCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// PROCEDURAL BURN DOWN CHART
class _BurnDownChartPainter extends CustomPainter {
  final List<AmortizationRow> baseSchedule;
  final List<AmortizationRow> activeSchedule;
  final double maxBalance;
  final int maxMonths;

  _BurnDownChartPainter({
    required this.baseSchedule,
    required this.activeSchedule,
    required this.maxBalance,
    required this.maxMonths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (maxBalance == 0 || maxMonths == 0) return;

    final bgPaint = Paint()
      ..color = const Color(0xfff1f5f9)
      ..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      double y = size.height - (size.height * (i / 5));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bgPaint);
    }

    Path _createPath(List<AmortizationRow> schedule) {
      Path path = Path();
      path.moveTo(
        0,
        0,
      ); // start top left relative to chart max? No, mathematically mapped.

      for (int i = 0; i < schedule.length; i++) {
        double x = (schedule[i].month / maxMonths) * size.width;
        double y =
            size.height -
            ((schedule[i].remainingBalance / maxBalance) * size.height);
        if (i == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      return path;
    }

    // Base Profile Line (Grey)
    final basePaint = Paint()
      ..color = const Color(0xff94a3b8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(_createPath(baseSchedule), basePaint);

    // Active (Prepayment) Profile Line (Green)
    final activePaint = Paint()
      ..color = const Color(0xff10b981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(_createPath(activeSchedule), activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 7. VIEW 4: LOAN COMPARISON
// ==========================================

class LoanComparisonView extends StatefulWidget {
  const LoanComparisonView({super.key});

  @override
  State<LoanComparisonView> createState() => _LoanComparisonViewState();
}

class _LoanComparisonViewState extends State<LoanComparisonView> {
  @override
  Widget build(BuildContext context) {
    final controller = LoanStateProvider.of(context);
    final loanA = controller.baselineProfile; // P1 without prepayments
    final loanB = controller.compareProfile;
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    bool aWins = loanA.totalInterest < loanB.totalInterest;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Scenario Comparison",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              // Loan A Inputs
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: aWins
                          ? const Color(0xff10b981)
                          : const Color(0xffe2e8f0),
                      width: aWins ? 3 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Option A",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (aWins)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff10b981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "LOWEST COST",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SliderInput(
                        label: "Principal",
                        value: controller.p1Principal,
                        min: 5000,
                        max: 2000000,
                        isCurrency: true,
                        onChanged: (v) => controller.updateP1(
                          v,
                          controller.p1Rate,
                          controller.p1Tenure,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SliderInput(
                        label: "Rate",
                        value: controller.p1Rate,
                        min: 0.1,
                        max: 25.0,
                        isCurrency: false,
                        onChanged: (v) => controller.updateP1(
                          controller.p1Principal,
                          v,
                          controller.p1Tenure,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SliderInput(
                        label: "Tenure",
                        value: controller.p1Tenure.toDouble(),
                        min: 12,
                        max: 360,
                        isCurrency: false,
                        onChanged: (v) => controller.updateP1(
                          controller.p1Principal,
                          controller.p1Rate,
                          v.toInt(),
                        ),
                      ),
                      const Divider(height: 48),
                      _CompMetric(
                        label: "Monthly EMI",
                        value: format.format(loanA.baseEMI),
                      ),
                      _CompMetric(
                        label: "Total Interest",
                        value: format.format(loanA.totalInterest),
                        isWinner: aWins,
                      ),
                      _CompMetric(
                        label: "Total Outflow",
                        value: format.format(loanA.totalPayment),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Loan B Inputs
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: !aWins
                          ? const Color(0xff10b981)
                          : const Color(0xffe2e8f0),
                      width: !aWins ? 3 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Option B",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!aWins)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff10b981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "LOWEST COST",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SliderInput(
                        label: "Principal",
                        value: controller.p2Principal,
                        min: 5000,
                        max: 2000000,
                        isCurrency: true,
                        onChanged: (v) => controller.updateP2(
                          v,
                          controller.p2Rate,
                          controller.p2Tenure,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SliderInput(
                        label: "Rate",
                        value: controller.p2Rate,
                        min: 0.1,
                        max: 25.0,
                        isCurrency: false,
                        onChanged: (v) => controller.updateP2(
                          controller.p2Principal,
                          v,
                          controller.p2Tenure,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SliderInput(
                        label: "Tenure",
                        value: controller.p2Tenure.toDouble(),
                        min: 12,
                        max: 360,
                        isCurrency: false,
                        onChanged: (v) => controller.updateP2(
                          controller.p2Principal,
                          controller.p2Rate,
                          v.toInt(),
                        ),
                      ),
                      const Divider(height: 48),
                      _CompMetric(
                        label: "Monthly EMI",
                        value: format.format(loanB.baseEMI),
                      ),
                      _CompMetric(
                        label: "Total Interest",
                        value: format.format(loanB.totalInterest),
                        isWinner: !aWins,
                      ),
                      _CompMetric(
                        label: "Total Outflow",
                        value: format.format(loanB.totalPayment),
                      ),
                    ],
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

class _CompMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isWinner;

  const _CompMetric({
    required this.label,
    required this.value,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isWinner
                  ? const Color(0xff10b981)
                  : const Color(0xff0f172a),
            ),
          ),
        ],
      ),
    );
  }
}
