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
  runApp(const InfantTelemetryApp());
}

class InfantTelemetryApp extends StatelessWidget {
  const InfantTelemetryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const BabyStateProvider(
      child: MaterialApp(
        title: 'NurtureIntel: Infant Telemetry Suite',
        debugShowCheckedModeBanner: false,
        home: MasterTelemetryShell(),
      ),
    );
  }
}

// ==========================================
// 1. DATA PATHWAYS & ONTOLOGY SCHEMAS
// ==========================================

enum AppSection { dashboard, activityLogger, analyticsMatrix, alertCenter }

enum LogType { feeding, sleep, diaper, metrics }

enum FeedingType { breast, bottle, solids }

enum DiaperState { wet, dirty, mixed, pristine }

class BabyProfile {
  final String id;
  final String name;
  final DateTime birthDate;
  final double weightKg;
  final Color themeColor;

  const BabyProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.weightKg,
    required this.themeColor,
  });

  int get ageInDays => DateTime.now().difference(birthDate).inDays;

  // Computes target fluid baseline using Holliday-Segar model
  double get targetFluidVolumeMl => weightKg * 100.0;
}

class CareEventLog {
  final String id;
  final String babyId;
  final DateTime timestamp;
  final LogType type;
  final String remarks;

  // Feeding Sub-payloads
  final FeedingType? feedingType;
  final double? volumeMl;
  final int? durationMinutes;

  // Sleep Sub-payloads
  final int? sleepDurationMinutes;

  // Diaper Sub-payloads
  final DiaperState? diaperState;

  const CareEventLog({
    required this.id,
    required this.babyId,
    required this.timestamp,
    required this.type,
    required this.remarks,
    this.feedingType,
    this.volumeMl,
    this.durationMinutes,
    this.sleepDurationMinutes,
    this.diaperState,
  });
}

class TelemetryReminder {
  final String id;
  final String label;
  final LogType targetedType;
  final Duration interval;
  final DateTime lastTriggeredTime;
  final bool isEnabled;

  const TelemetryReminder({
    required this.id,
    required this.label,
    required this.targetedType,
    required this.interval,
    required this.lastTriggeredTime,
    this.isEnabled = true,
  });

  bool isViolationOverdue(DateTime relativeTo) {
    if (!isEnabled) return false;
    return relativeTo.difference(lastTriggeredTime) > interval;
  }

  String get formattedRemaining {
    final nextTrigger = lastTriggeredTime.add(interval);
    final diff = nextTrigger.difference(DateTime.now());
    if (diff.isNegative) return "OVERDUE";
    return "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
  }

  TelemetryReminder copyWith({DateTime? lastTriggeredTime, bool? isEnabled}) {
    return TelemetryReminder(
      id: id,
      label: label,
      targetedType: targetedType,
      interval: interval,
      lastTriggeredTime: lastTriggeredTime ?? this.lastTriggeredTime,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

// ==========================================
// 2. STATE INTERFACE ENGINE & MUTATORS
// ==========================================

class TelemetryEngineController extends ChangeNotifier {
  AppSection currentSection = AppSection.dashboard;
  String? activeBabyId;

  final List<BabyProfile> _babies = [];
  final List<CareEventLog> _logs = [];
  final List<TelemetryReminder> _reminders = [];

  TelemetryEngineController() {
    _executeSystemSeeding();
  }

  void _executeSystemSeeding() {
    final baseTime = DateTime.now();

    // Core Subject Seeding
    final activeBaby = BabyProfile(
      id: 'INF-009',
      name: 'Alexander',
      birthDate: baseTime.subtract(const Duration(days: 45)),
      weightKg: 4.8,
      themeColor: const Color(0xff0284c7),
    );
    _babies.add(activeBaby);
    activeBabyId = activeBaby.id;

    // Historical Logs Seeding
    _logs.addAll([
      CareEventLog(
        id: 'L-701',
        babyId: 'INF-009',
        timestamp: baseTime.subtract(const Duration(hours: 6)),
        type: LogType.feeding,
        feedingType: FeedingType.bottle,
        volumeMl: 120,
        remarks: 'Consumed efficiently',
      ),
      CareEventLog(
        id: 'L-702',
        babyId: 'INF-009',
        timestamp: baseTime.subtract(const Duration(hours: 5)),
        type: LogType.diaper,
        diaperState: DiaperState.wet,
        remarks: 'Routine validation check',
      ),
      CareEventLog(
        id: 'L-703',
        babyId: 'INF-009',
        timestamp: baseTime.subtract(const Duration(hours: 4)),
        type: LogType.sleep,
        sleepDurationMinutes: 90,
        remarks: 'Spontaneous waking cycle',
      ),
      CareEventLog(
        id: 'L-704',
        babyId: 'INF-009',
        timestamp: baseTime.subtract(const Duration(hours: 1)),
        type: LogType.feeding,
        feedingType: FeedingType.breast,
        durationMinutes: 20,
        volumeMl: 90,
        remarks: 'Regulated latching',
      ),
    ]);

    // Safety Threshold Matrix Configuration Reminders
    _reminders.addAll([
      TelemetryReminder(
        id: 'R-01',
        label: 'Nutrition Repopulation Interval',
        targetedType: LogType.feeding,
        interval: const Duration(hours: 3),
        lastTriggeredTime: baseTime.subtract(const Duration(hours: 1)),
      ),
      TelemetryReminder(
        id: 'R-02',
        label: 'Circadian Sleep Windows Tracker',
        targetedType: LogType.sleep,
        interval: const Duration(hours: 4),
        lastTriggeredTime: baseTime.subtract(const Duration(hours: 4)),
      ),
      TelemetryReminder(
        id: 'R-03',
        label: 'Excretory Elimination Check',
        targetedType: LogType.diaper,
        interval: const Duration(hours: 2, minutes: 30),
        lastTriggeredTime: baseTime.subtract(const Duration(hours: 5)),
      ),
    ]);
  }

  // Derived Telemetry Accessors
  List<BabyProfile> get babies => List.unmodifiable(_babies);
  List<CareEventLog> get logs =>
      _logs.where((l) => l.babyId == activeBabyId).toList();
  List<TelemetryReminder> get reminders => List.unmodifiable(_reminders);

  BabyProfile get currentBaby =>
      _babies.firstWhere((b) => b.id == activeBabyId);

  double get aggregateFluidIntakeToday {
    final today = DateTime.now();
    return _logs
        .where(
          (l) =>
              l.babyId == activeBabyId &&
              l.type == LogType.feeding &&
              l.timestamp.day == today.day &&
              l.volumeMl != null,
        )
        .fold(0.0, (sum, item) => sum + item.volumeMl!);
  }

  int get aggregateSleepMinutesToday {
    final today = DateTime.now();
    return _logs
        .where(
          (l) =>
              l.babyId == activeBabyId &&
              l.type == LogType.sleep &&
              l.timestamp.day == today.day &&
              l.sleepDurationMinutes != null,
        )
        .fold(0, (sum, item) => sum + item.sleepDurationMinutes!);
  }

  // Mutation Pipeline Channels
  void changeSection(AppSection target) {
    currentSection = target;
    notifyListeners();
  }

  void appendLog(CareEventLog record) {
    _logs.add(record);

    // Direct link to clear corresponding routing timer parameters
    final remIdx = _reminders.indexWhere((r) => r.targetedType == record.type);
    if (remIdx != -1) {
      _reminders[remIdx] = _reminders[remIdx].copyWith(
        lastTriggeredTime: DateTime.now(),
      );
    }

    notifyListeners();
  }

  void toggleReminderState(String id) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(
        isEnabled: !_reminders[idx].isEnabled,
      );
      notifyListeners();
    }
  }
}

// Global Context Architecture Container
class BabyStateProvider extends StatefulWidget {
  final Widget child;
  const BabyStateProvider({super.key, required this.child});

  static TelemetryEngineController of(BuildContext context) {
    final state = context
        .dependOnInheritedWidgetOfExactType<_InheritedEngineScope>();
    return state!.controller;
  }

  @override
  State<BabyStateProvider> createState() => _BabyStateProviderState();
}

class _BabyStateProviderState extends State<BabyStateProvider> {
  late TelemetryEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = TelemetryEngineController()..addListener(_bubbleStateUpdate);
  }

  void _bubbleStateUpdate() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_bubbleStateUpdate);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedEngineScope(controller: controller, child: widget.child);
  }
}

class _InheritedEngineScope extends InheritedWidget {
  final TelemetryEngineController controller;
  const _InheritedEngineScope({required this.controller, required super.child});
  @override
  bool updateShouldNotify(covariant _InheritedEngineScope oldWidget) => true;
}

// ==========================================
// 3. MASTER INTERFACE VIEWPORT HIERARCHY
// ==========================================

class MasterTelemetryShell extends StatelessWidget {
  const MasterTelemetryShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = BabyStateProvider.of(context);

    Widget renderLayer;
    switch (state.currentSection) {
      case AppSection.dashboard:
        renderLayer = const CoreDashboardViewport();
        break;
      case AppSection.activityLogger:
        renderLayer = const InteractiveLoggingConsole();
        break;
      case AppSection.analyticsMatrix:
        renderLayer = const DataMetricsMatrixView();
        break;
      case AppSection.alertCenter:
        renderLayer = const TelemetryAlertCenterView();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff1f5f9),
      body: Row(
        children: [
          Container(
            width: 280,
            color: const Color(0xff0f172a),
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Color(0xff38bdf8),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "NURTURE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "INFANT METRIC TELEMETRY",
                  style: TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 48),
                _SidebarControlRow(
                  label: 'Realtime Metrics Dashboard',
                  icon: Icons.insights_rounded,
                  target: AppSection.dashboard,
                ),
                _SidebarControlRow(
                  label: 'Telemetry Capture Console',
                  icon: Icons.add_chart_sharp,
                  target: AppSection.activityLogger,
                ),
                _SidebarControlRow(
                  label: 'Chronological Analytics',
                  icon: Icons.waves_outlined,
                  target: AppSection.analyticsMatrix,
                ),
                _SidebarControlRow(
                  label: 'Critical Threshold Timers',
                  icon: Icons.shutter_speed_outlined,
                  target: AppSection.alertCenter,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e293b),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: state.currentBaby.themeColor,
                        radius: 16,
                        child: const Icon(
                          Icons.child_care,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.currentBaby.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Age: ${state.currentBaby.ageInDays} Days Old",
                            style: const TextStyle(
                              color: Color(0xff94a3b8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: renderLayer,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarControlRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppSection target;

  const _SidebarControlRow({
    required this.label,
    required this.icon,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final state = BabyStateProvider.of(context);
    final isSelected = state.currentSection == target;

    return InkWell(
      onTap: () => state.changeSection(target),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1e293b) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xff38bdf8) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xff38bdf8)
                  : const Color(0xff64748b),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xff94a3b8),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. MODULE 1: CONTROL DASHBOARD
// ==========================================

class CoreDashboardViewport extends StatelessWidget {
  const CoreDashboardViewport({super.key});

  @override
  Widget build(BuildContext context) {
    final state = BabyStateProvider.of(context);
    final targetFluid = state.currentBaby.targetFluidVolumeMl;
    final currentFluid = state.aggregateFluidIntakeToday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Diagnostic Telemetry Matrix",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const Text(
            "Live clinical feeds mapping metabolic, neurological, and physiological trends.",
            style: TextStyle(fontSize: 14, color: Color(0xff64748b)),
          ),
          const SizedBox(height: 36),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  headline: "FLUID RETENTION BALANCE",
                  primaryValue:
                      "${currentFluid.toInt()} / ${targetFluid.toInt()} mL",
                  subtext: "Holliday-Segar baseline target",
                  indicatorProgress: (currentFluid / targetFluid).clamp(
                    0.0,
                    1.0,
                  ),
                  accentColor: const Color(0xff0ea5e9),
                  icon: Icons.opacity,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _MetricCard(
                  headline: "SLEEP ARCHITECTURE DURATION",
                  primaryValue:
                      "${(state.aggregateSleepMinutesToday / 60).toStringAsFixed(1)} Hours",
                  subtext: "24h circadian logging accumulation",
                  indicatorProgress: (state.aggregateSleepMinutesToday / 840)
                      .clamp(0.0, 1.0),
                  accentColor: const Color(0xff8b5cf6),
                  icon: Icons.bedtime_outlined,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _MetricCard(
                  headline: "ELIMINATION HISTOGRAM CYCLES",
                  primaryValue:
                      "${state.logs.where((l) => l.type == LogType.diaper).length} Events",
                  subtext: "Gastrointestinal cycles logged today",
                  indicatorProgress: 0.7,
                  accentColor: const Color(0xfff59e0b),
                  icon: Icons.layers_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Chronological Telemetry Feed Sequence",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: math.min(state.logs.length, 4),
                        separatorBuilder: (_, __) => const Divider(height: 20),
                        itemBuilder: (context, idx) {
                          final event = state.logs.reversed.toList()[idx];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _buildLogIconBadge(event.type),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.remarks,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xff1e293b),
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'hh:mm a — MMM dd',
                                        ).format(event.timestamp),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              _buildPayloadStringBadge(event),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Metabolic Absorption Curve",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 180,
                        child: CustomPaint(
                          size: const Size(double.infinity, 180),
                          painter: _TelemetryDynamicPainter(logs: state.logs),
                        ),
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

  Widget _buildLogIconBadge(LogType type) {
    IconData icon;
    Color col;
    switch (type) {
      case LogType.feeding:
        icon = Icons.opacity;
        col = const Color(0xff0ea5e9);
        break;
      case LogType.sleep:
        icon = Icons.bedtime_outlined;
        col = const Color(0xff8b5cf6);
        break;
      case LogType.diaper:
        icon = Icons.layers_outlined;
        col = const Color(0xfff59e0b);
        break;
      case LogType.metrics:
        icon = Icons.monitor_weight_outlined;
        col = const Color(0xff10b981);
        break;
    }
    return CircleAvatar(
      backgroundColor: col.withOpacity(0.1),
      child: Icon(icon, color: col, size: 18),
    );
  }

  Widget _buildPayloadStringBadge(CareEventLog log) {
    String out = '';
    if (log.type == LogType.feeding) out = "${log.volumeMl?.toInt()} mL";
    if (log.type == LogType.sleep) out = "${log.sleepDurationMinutes} min";
    if (log.type == LogType.diaper)
      out = log.diaperState?.name.toUpperCase() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        out,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Color(0xff475569),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String headline;
  final String primaryValue;
  final String subtext;
  final double indicatorProgress;
  final Color accentColor;
  final IconData icon;

  const _MetricCard({
    required this.headline,
    required this.primaryValue,
    required this.subtext,
    required this.indicatorProgress,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                headline,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff64748b),
                  letterSpacing: 1,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            primaryValue,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: indicatorProgress,
            backgroundColor: const Color(0xfff1f5f9),
            color: accentColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. MODULE 2: INTERACTIVE LOGGING CONSOLE
// ==========================================

class InteractiveLoggingConsole extends StatefulWidget {
  const InteractiveLoggingConsole({super.key});

  @override
  State<InteractiveLoggingConsole> createState() =>
      _InteractiveLoggingConsoleState();
}

class _InteractiveLoggingConsoleState extends State<InteractiveLoggingConsole> {
  final _remarksController = TextEditingController();
  final _volumeController = TextEditingController();
  final _durationController = TextEditingController();

  LogType _activeType = LogType.feeding;
  FeedingType _feedingType = FeedingType.bottle;
  DiaperState _diaperState = DiaperState.wet;

  @override
  Widget build(BuildContext context) {
    final state = BabyStateProvider.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Initialize Telemetry Event Entry",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0f172a),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Category Segment Picker
                  Row(
                    children: LogType.values.map((type) {
                      final active = _activeType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(type.name.toUpperCase()),
                            selected: active,
                            selectedColor: const Color(0xff0f172a),
                            labelStyle: TextStyle(
                              color: active ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _activeType = type);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Tailored Context Inputs
                  if (_activeType == LogType.feeding) ...[
                    DropdownButtonFormField<FeedingType>(
                      value: _feedingType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Delivery Mechanism Vector",
                      ),
                      items: FeedingType.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _feedingType = v!),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _volumeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Volumetric Quantitative Payload (mL)",
                      ),
                    ),
                  ],

                  if (_activeType == LogType.sleep) ...[
                    TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Interval Temporal Duration (Minutes)",
                      ),
                    ),
                  ],

                  if (_activeType == LogType.diaper) ...[
                    DropdownButtonFormField<DiaperState>(
                      value: _diaperState,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Excretory Diagnosis Vector",
                      ),
                      items: DiaperState.values
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _diaperState = v!),
                    ),
                  ],

                  const SizedBox(height: 20),
                  TextField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Qualitative Context/Diagnostics",
                    ),
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0f172a),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_remarksController.text.isNotEmpty) {
                          state.appendLog(
                            CareEventLog(
                              id: 'L-${math.Random().nextInt(90000)}',
                              babyId: state.currentBaby.id,
                              timestamp: DateTime.now(),
                              type: _activeType,
                              remarks: _remarksController.text,
                              feedingType: _activeType == LogType.feeding
                                  ? _feedingType
                                  : null,
                              volumeMl: double.tryParse(_volumeController.text),
                              sleepDurationMinutes: int.tryParse(
                                _durationController.text,
                              ),
                              diaperState: _activeType == LogType.diaper
                                  ? _diaperState
                                  : null,
                            ),
                          );
                          _remarksController.clear();
                          _volumeController.clear();
                          _durationController.clear();
                        }
                      },
                      child: const Text(
                        "COMMIT CAPTURE TO TIME-SERIES LEDGER",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Console Audit Ledger",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Displaying active tracking logs for transaction domain ${state.currentBaby.id}.",
                  ),
                  const Divider(height: 32),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: math.min(state.logs.length, 5),
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final item = state.logs[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.remarks,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('HH:mm:ss').format(item.timestamp),
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          item.type.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
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
// 6. MODULE 3: CHRONOLOGICAL ANALYTICS
// ==========================================

class DataMetricsMatrixView extends StatelessWidget {
  const DataMetricsMatrixView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = BabyStateProvider.of(context);

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chronological Analytics Matrix",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const Text(
            "Complete historic validation matrix mapping all categorical vectors.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("IDENTIFIER TIMESTAMP")),
                      DataColumn(label: Text("VECTOR CLASS")),
                      DataColumn(label: Text("METRIC ANALYSIS")),
                      DataColumn(label: Text("QUALITATIVE NOTES")),
                    ],
                    rows: state.logs.map((log) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(log.timestamp),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          DataCell(
                            Text(
                              log.type.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              log.type == LogType.feeding
                                  ? "${log.volumeMl?.toInt()} mL"
                                  : (log.type == LogType.sleep
                                        ? "${log.sleepDurationMinutes} min"
                                        : log.diaperState?.name ?? "N/A"),
                            ),
                          ),
                          DataCell(Text(log.remarks)),
                        ],
                      );
                    }).toList(),
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

// ==========================================
// 7. MODULE 4: CRITICAL THRESHOLD TIMERS
// ==========================================

class TelemetryAlertCenterView extends StatelessWidget {
  const TelemetryAlertCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = BabyStateProvider.of(context);

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Critical Threshold Configuration Center",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const Text(
            "Non-overlapping safety monitors mapping metabolic repetition constraints.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.25,
              ),
              itemCount: state.reminders.length,
              itemBuilder: (context, idx) {
                final target = state.reminders[idx];
                final isOverdue = target.isViolationOverdue(DateTime.now());

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isOverdue
                          ? Colors.red.withOpacity(0.5)
                          : const Color(0xffe2e8f0),
                      width: isOverdue ? 2 : 1,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? const Color(0xfffef2f2)
                                  : const Color(0xfff0fdf4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOverdue
                                  ? "VIOLATION OVERDUE"
                                  : "MONITOR ACTIVE",
                              style: TextStyle(
                                color: isOverdue ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Switch(
                            value: target.isEnabled,
                            onChanged: (_) =>
                                state.toggleReminderState(target.id),
                          ),
                        ],
                      ),
                      Text(
                        target.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PROXIMITY STATUS",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            target.formattedRemaining,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isOverdue
                                  ? Colors.red
                                  : const Color(0xff0f172a),
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
// 8. CUSTOM TIME-SERIES VECTOR PAINTER
// ==========================================

class _TelemetryDynamicPainter extends CustomPainter {
  final List<CareEventLog> logs;
  _TelemetryDynamicPainter({required this.logs});

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xffcbd5e1)
      ..strokeWidth = 2;
    final linePaint = Paint()
      ..color = const Color(0xff0ea5e9)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()
      ..color = const Color(0xff0f172a)
      ..style = PaintingStyle.fill;

    // Draw reference frame coordinates
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

    final absorptionPoints = logs
        .where((l) => l.type == LogType.feeding && l.volumeMl != null)
        .toList();
    if (absorptionPoints.isEmpty) return;

    final double stepX = size.width / math.max(1, absorptionPoints.length - 1);
    final maxVol = absorptionPoints.map((e) => e.volumeMl!).reduce(math.max);

    final Path path = Path();
    for (int i = 0; i < absorptionPoints.length; i++) {
      double x = stepX * i;
      double normalizedY =
          (absorptionPoints[i].volumeMl! / maxVol) * (size.height * 0.7);
      double y = size.height - normalizedY;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
