import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// Per-file Color compatibility shim (replaces deprecated `withOpacity` usage)
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
  runApp(const TaxOptimaApp());
}

class TaxOptimaApp extends StatelessWidget {
  const TaxOptimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaxStateProvider(
      child: MaterialApp(
        title: 'TaxOptima: Enterprise Suite 2026',
        debugShowCheckedModeBanner: false,
        home: MasterTaxDashboard(),
      ),
    );
  }
}

// ==========================================
// 1. DATA PARADIGMS & STRUCTURES
// ==========================================

enum AppSection { estimator, deductionManager, documentLocker, dataExport }

enum FilingStatus { single, marriedFilingJointly, headOfHousehold }

enum DeductionCategory {
  professional,
  charitable,
  medical,
  education,
  realEstate,
}

class TaxBracket {
  final double floor;
  final double ceiling;
  final double rate;

  const TaxBracket({
    required this.floor,
    required this.ceiling,
    required this.rate,
  });
}

class DeductionItem {
  final String id;
  final String title;
  final DeductionCategory category;
  final double amount;
  final DateTime date;
  final String? linkedDocId;

  const DeductionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.linkedDocId,
  });
}

class TaxDocument {
  final String id;
  final String filename;
  final String extension;
  final double sizeKb;
  final DateTime uploadedAt;

  const TaxDocument({
    required this.id,
    required this.filename,
    required this.extension,
    required this.sizeKb,
    required this.uploadedAt,
  });
}

// ==========================================
// 2. STATE MANAGEMENT & ARCHITECTURE
// ==========================================

class TaxEngineController extends ChangeNotifier {
  AppSection currentSection = AppSection.estimator;

  // Active Income Stream
  double annualGrossIncome = 145000;
  double preTaxAdjustments = 6500;
  FilingStatus selectedStatus = FilingStatus.single;

  // Ledger Registries
  final List<DeductionItem> _deductions = [];
  final List<TaxDocument> _documents = [];

  TaxEngineController() {
    _seedEnterpriseProfiles();
  }

  void _seedEnterpriseProfiles() {
    _documents.addAll([
      TaxDocument(
        id: 'DOC-901',
        filename: 'W2_Statement_2026',
        extension: 'pdf',
        sizeKb: 1240,
        uploadedAt: DateTime.now(),
      ),
      TaxDocument(
        id: 'DOC-902',
        filename: 'Charity_Receipt_Unicef',
        extension: 'jpg',
        sizeKb: 450,
        uploadedAt: DateTime.now(),
      ),
    ]);

    _deductions.addAll([
      DeductionItem(
        id: 'DED-001',
        title: 'Silicon Valley Tech Summit Travel',
        category: DeductionCategory.professional,
        amount: 2450,
        date: DateTime.now(),
        linkedDocId: 'DOC-901',
      ),
      DeductionItem(
        id: 'DED-002',
        title: 'UNICEF Annual Gala Contribution',
        category: DeductionCategory.charitable,
        amount: 1200,
        date: DateTime.now(),
        linkedDocId: 'DOC-902',
      ),
      DeductionItem(
        id: 'DED-003',
        title: 'Stanford Extension Deep Learning Course',
        category: DeductionCategory.education,
        amount: 3500,
        date: DateTime.now(),
      ),
    ]);
  }

  // Statutory Constants for 2026 Fiscal Framework
  double get standardDeduction {
    switch (selectedStatus) {
      case FilingStatus.single:
        return 15400;
      case FilingStatus.marriedFilingJointly:
        return 30800;
      case FilingStatus.headOfHousehold:
        return 23100;
    }
  }

  List<TaxBracket> get progressiveBrackets {
    // Standard progressive framework mapped for 2026 models
    return [
      const TaxBracket(floor: 0, ceiling: 11600, rate: 0.10),
      const TaxBracket(floor: 11600, ceiling: 47150, rate: 0.12),
      const TaxBracket(floor: 47150, ceiling: 100525, rate: 0.22),
      const TaxBracket(floor: 100525, ceiling: 191950, rate: 0.24),
      const TaxBracket(floor: 191950, ceiling: 243725, rate: 0.32),
      const TaxBracket(floor: 243725, ceiling: 609350, rate: 0.35),
      const TaxBracket(floor: 609350, ceiling: double.infinity, rate: 0.37),
    ];
  }

  // Reactive Property Calculations
  List<DeductionItem> get itemizedDeductions => List.unmodifiable(_deductions);
  List<TaxDocument> get secureVault => List.unmodifiable(_documents);

  double get adjustedGrossIncome =>
      math.max(0, annualGrossIncome - preTaxAdjustments);

  double get totalItemizedDeductions =>
      _deductions.fold(0, (sum, item) => sum + item.amount);

  double get effectiveDeductionPool =>
      math.max(standardDeduction, totalItemizedDeductions);

  double get taxableIncome =>
      math.max(0, adjustedGrossIncome - effectiveDeductionPool);

  double get calculatedTaxLiability {
    double ti = taxableIncome;
    double calculatedTax = 0;

    for (var bracket in progressiveBrackets) {
      if (ti > bracket.floor) {
        double width = math.min(ti, bracket.ceiling) - bracket.floor;
        calculatedTax += width * bracket.rate;
      } else {
        break;
      }
    }
    return calculatedTax;
  }

  double get effectiveTaxRate => annualGrossIncome == 0
      ? 0
      : (calculatedTaxLiability / annualGrossIncome) * 100;

  // --- CONTROLLER MUTATORS ---
  void switchSection(AppSection section) {
    currentSection = section;
    notifyListeners();
  }

  void patchParameters(double gross, double adj, FilingStatus status) {
    annualGrossIncome = gross;
    preTaxAdjustments = adj;
    selectedStatus = status;
    notifyListeners();
  }

  void injectDeduction(
    String title,
    DeductionCategory category,
    double amount,
    String? docId,
  ) {
    _deductions.add(
      DeductionItem(
        id: 'DED-${math.Random().nextInt(90000) + 10000}',
        title: title,
        category: category,
        amount: amount,
        date: DateTime.now(),
        linkedDocId: docId,
      ),
    );
    notifyListeners();
  }

  void purgeDeduction(String id) {
    _deductions.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  void ingestDocument(String name, String ext, double kbSize) {
    _documents.add(
      TaxDocument(
        id: 'DOC-${math.Random().nextInt(900) + 100}',
        filename: name.replaceAll(' ', '_'),
        extension: ext,
        sizeKb: kbSize,
        uploadedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

// Inherited Architecture Lifecycle Bindings
class TaxStateProvider extends StatefulWidget {
  final Widget child;
  const TaxStateProvider({super.key, required this.child});

  static TaxEngineController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedTaxProvider>();
    assert(result != null, 'TaxStateProvider Context Exception');
    return result!.controller;
  }

  @override
  State<TaxStateProvider> createState() => _TaxStateProviderState();
}

class _TaxStateProviderState extends State<TaxStateProvider> {
  late TaxEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = TaxEngineController()..addListener(_stateListener);
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
    return _InheritedTaxProvider(controller: controller, child: widget.child);
  }
}

class _InheritedTaxProvider extends InheritedWidget {
  final TaxEngineController controller;
  const _InheritedTaxProvider({required this.controller, required super.child});
  @override
  bool updateShouldNotify(covariant _InheritedTaxProvider oldWidget) => true;
}

// ==========================================
// 3. MASTER INDUSTRIAL USER INTERFACE SHELL
// ==========================================

class MasterTaxDashboard extends StatelessWidget {
  const MasterTaxDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TaxStateProvider.of(context);

    Widget interfaceView;
    switch (controller.currentSection) {
      case AppSection.estimator:
        interfaceView = const YieldEstimatorView();
        break;
      case AppSection.deductionManager:
        interfaceView = const DeductionManagerView();
        break;
      case AppSection.documentLocker:
        interfaceView = const DocumentLockerView();
        break;
      case AppSection.dataExport:
        interfaceView = const ExportCompilationView();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Row(
        children: [
          // Navigational Workspace Rail
          Container(
            width: 280,
            color: const Color(0xff090d16),
            child: Column(
              children: [
                const SizedBox(height: 54),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.polyline_sharp,
                      color: Color(0xff38bdf8),
                      size: 36,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "TaxOptima",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "FINANCIAL ARCHITECTURE ENGINE",
                  style: TextStyle(
                    color: Color(0xff334155),
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 54),
                _SidebarNavButton(
                  icon: Icons.analytics_outlined,
                  label: "Yield Estimator",
                  target: AppSection.estimator,
                ),
                _SidebarNavButton(
                  icon: Icons.pie_chart_outline_sharp,
                  label: "Deduction Manager",
                  target: AppSection.deductionManager,
                ),
                _SidebarNavButton(
                  icon: Icons.folder_zip_outlined,
                  label: "Secure Vault",
                  target: AppSection.documentLocker,
                ),
                _SidebarNavButton(
                  icon: Icons.output_rounded,
                  label: "Export Portal",
                  target: AppSection.dataExport,
                ),
                const Spacer(),
                const Text(
                  "Fiscal Period: 2026",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: interfaceView,
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
    final controller = TaxStateProvider.of(context);
    bool selected = controller.currentSection == target;

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
          color: selected ? const Color(0xff111827) : Colors.transparent,
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
// 4. MODULE 1: TAX METRIC & ESTIMATOR VIEW
// ==========================================

class YieldEstimatorView extends StatelessWidget {
  const YieldEstimatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TaxStateProvider.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tax Engine Estimator",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const Text(
            "Real-time parsing framework utilizing progressive thresholds.",
            style: TextStyle(fontSize: 15, color: Color(0xff64748b)),
          ),
          const SizedBox(height: 42),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matrix Control Sliders
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Parametric Matrix",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1e293b),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _ParametricSlider(
                        title: "Annual Gross Ingestion",
                        value: controller.annualGrossIncome,
                        min: 10000,
                        max: 500000,
                        step: 5000,
                        onChanged: (val) => controller.patchParameters(
                          val,
                          controller.preTaxAdjustments,
                          controller.selectedStatus,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ParametricSlider(
                        title: "Pre-Tax Above-Line Adjustments",
                        value: controller.preTaxAdjustments,
                        min: 0,
                        max: 30000,
                        step: 500,
                        onChanged: (val) => controller.patchParameters(
                          controller.annualGrossIncome,
                          val,
                          controller.selectedStatus,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "Filing Jurisdiction Matrix Status",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff64748b),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<FilingStatus>(
                        value: controller.selectedStatus,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: FilingStatus.values
                            .map(
                              (st) => DropdownMenuItem(
                                value: st,
                                child: Text(
                                  st.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => controller.patchParameters(
                          controller.annualGrossIncome,
                          controller.preTaxAdjustments,
                          val!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 42),
              // Micro Analytics Panel Output
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: const Color(0xff0f172a),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PROJECTIONS LIABILITY",
                            style: TextStyle(
                              color: Color(0xff38bdf8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fmt.format(controller.calculatedTaxLiability),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 36),
                          _MetricRow(
                            label: "Adjusted Gross (AGI)",
                            val: fmt.format(controller.adjustedGrossIncome),
                          ),
                          _MetricRow(
                            label: "Deduction Cushion Applied",
                            val: fmt.format(controller.effectiveDeductionPool),
                          ),
                          _MetricRow(
                            label: "Net Taxable Liquidity",
                            val: fmt.format(controller.taxableIncome),
                          ),
                          const SizedBox(height: 16),
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
                                  "Effective Premium Load",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "${controller.effectiveTaxRate.toStringAsFixed(2)}%",
                                  style: const TextStyle(
                                    color: Color(0xff4ade80),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Live Progressive Vector Graph Bar
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffe2e8f0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Dynamic Bracket Saturation Spectrum",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff334155),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 24,
                            child: CustomPaint(
                              size: const Size(double.infinity, 24),
                              painter: _BracketSpectrumPainter(
                                taxableIncome: controller.taxableIncome,
                                brackets: controller.progressiveBrackets,
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

class _ParametricSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const _ParametricSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff475569),
                fontSize: 14,
              ),
            ),
            Text(
              NumberFormat.currency(
                symbol: '\$',
                decimalDigits: 0,
              ).format(value),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                color: Color(0xff0f172a),
                fontSize: 16,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / step).toInt(),
          activeColor: const Color(0xff0284c7),
          inactiveColor: const Color(0xffe2e8f0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String val;
  const _MetricRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xff94a3b8), fontSize: 13),
          ),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _BracketSpectrumPainter extends CustomPainter {
  final double taxableIncome;
  final List<TaxBracket> brackets;

  _BracketSpectrumPainter({
    required this.taxableIncome,
    required this.brackets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    double maxScaleVal = 250000; // Visual normalized indexing ceiling

    // Background Track Bounds
    paint.color = const Color(0xfff1f5f9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      paint,
    );

    // Render continuous vector metric for current profile income volume
    double pct = math.min(taxableIncome / maxScaleVal, 1.0);
    if (pct > 0) {
      paint.color = const Color(0xff0ea5e9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width * pct, size.height),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 5. MODULE 2: DEDUCTION MANAGER ENGINE
// ==========================================

class DeductionManagerView extends StatefulWidget {
  const DeductionManagerView({super.key});

  @override
  State<DeductionManagerView> createState() => _DeductionManagerViewState();
}

class _DeductionManagerViewState extends State<DeductionManagerView> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DeductionCategory _selectedCategory = DeductionCategory.professional;

  @override
  Widget build(BuildContext context) {
    final controller = TaxStateProvider.of(context);
    final list = controller.itemizedDeductions;
    final fmt = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Input Execution Form Panel
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Log Write-off Asset",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Description Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Audited Financial Sum (\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<DeductionCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Regulatory Domain Category',
                    ),
                    items: DeductionCategory.values
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0f172a),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_titleController.text.isNotEmpty &&
                            _amountController.text.isNotEmpty) {
                          double parsedAmount =
                              double.tryParse(_amountController.text) ?? 0.0;
                          controller.injectDeduction(
                            _titleController.text,
                            _selectedCategory,
                            parsedAmount,
                            null,
                          );
                          _titleController.clear();
                          _amountController.clear();
                        }
                      },
                      child: const Text(
                        "COMMIT ITEM TO ARCHIVE",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 42),
          // Right Active Ledger Registry Real-time List
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Active Write-off Registry Ledger",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Total: ${fmt.format(controller.totalItemizedDeductions)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xff0ea5e9),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xffe2e8f0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xfff0fdf4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Color(0xff16a34a),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Domain Category: ${item.category.name.toUpperCase()}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                fmt.format(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xff1e293b),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xffef4444),
                                ),
                                onPressed: () =>
                                    controller.purgeDeduction(item.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

// ==========================================
// 6. MODULE 3: SECURE ASSET & DOCUMENT VAULT
// ==========================================

class DocumentLockerView extends StatelessWidget {
  const DocumentLockerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TaxStateProvider.of(context);
    final docs = controller.secureVault;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Secure Document Crypt",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    "Encrypted proof repository context for IRS verification audits (${docs.length} assets registered).",
                    style: const TextStyle(color: Color(0xff64748b)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0ea5e9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text("INGEST EXTERNAL PROOF"),
                onPressed: () {
                  controller.ingestDocument(
                    "1099_DIV_Brokerage_Statement",
                    "pdf",
                    890,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 42),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.3,
              ),
              itemCount: docs.length,
              itemBuilder: (context, idx) {
                final d = docs[idx];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xfff0f9ff),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.article_outlined,
                              color: Color(0xff0284c7),
                            ),
                          ),
                          Text(
                            ".${d.extension.toUpperCase()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        d.filename,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${d.sizeKb} KB",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            d.id,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. MODULE 4: EXPORT REPORT GENERATOR
// ==========================================

class ExportCompilationView extends StatefulWidget {
  const ExportCompilationView({super.key});

  @override
  State<ExportCompilationView> createState() => _ExportCompilationViewState();
}

class _ExportCompilationViewState extends State<ExportCompilationView> {
  bool _isCompiling = false;

  @override
  Widget build(BuildContext context) {
    final controller = TaxStateProvider.of(context);
    final fmt = NumberFormat.currency(symbol: '\$');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.terminal_sharp,
                size: 64,
                color: Color(0xff0f172a),
              ),
              const SizedBox(height: 24),
              const Text(
                "Compile Comprehensive Manifest",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Assembles dynamic data parameters, system audit ledgers, and proof assets into a verified standard regulatory archive transmission package.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff64748b)),
              ),
              const Divider(height: 48),
              _SummaryDataRow(
                label: "Est. Core Tax Liability",
                val: fmt.format(controller.calculatedTaxLiability),
              ),
              _SummaryDataRow(
                label: "Verified Proof Deductions",
                val: fmt.format(controller.totalItemizedDeductions),
              ),
              _SummaryDataRow(
                label: "Aggregated Vault Footprint",
                val: "${controller.secureVault.length} Registered Nodes",
              ),
              const SizedBox(height: 36),
              if (_isCompiling) ...[
                const CircularProgressIndicator(color: Color(0xff0ea5e9)),
                const SizedBox(height: 16),
                const Text(
                  "Generating cryptographically bound package manifest...",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0ea5e9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      setState(() => _isCompiling = true);
                      await Future.delayed(const Duration(seconds: 3));
                      if (!mounted) return;
                      setState(() => _isCompiling = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Audit-ready report exported successfully to systemic disk workspace.",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text(
                      "GENERATE AUDIT MANIFEST ARCHIVE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryDataRow extends StatelessWidget {
  final String label;
  final String val;
  const _SummaryDataRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff475569),
            ),
          ),
          Text(
            val,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
        ],
      ),
    );
  }
}
