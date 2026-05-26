import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
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

enum MedicationForm { pill, capsule, liquid, injection, drops, inhaler }

enum FrequencyType { daily, specificDays, asNeeded }

enum DoseStatus { pending, taken, skipped, missed }

class AppColors {
  static const Color primary = Color(0xFF0F766E); // Teal 600
  static const Color primaryDark = Color(0xFF134E4A); // Teal 900
  static const Color accent = Color(0xFF0EA5E9); // Light Blue 500

  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceHighlight = Color(0xFFF1F5F9); // Slate 100

  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  static const Color statusTaken = Color(0xFF10B981); // Emerald 500
  static const Color statusMissed = Color(0xFFEF4444); // Red 500
  static const Color statusSkipped = Color(0xFFF59E0B); // Amber 500
  static const Color statusPending = Color(0xFF94A3B8); // Slate 400
}

class AppStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textMain,
    letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
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
}

// ============================================================================
// 2. EXCEPTIONS & UTILITIES
// ============================================================================

abstract class MedException implements Exception {
  final String message;
  MedException(this.message);
  @override
  String toString() => message;
}

class ValidationException extends MedException {
  ValidationException([String m = "Invalid input data."]) : super(m);
}

class TimingException extends MedException {
  TimingException([String m = "Schedule conflict detected."]) : super(m);
}

class DateFormatters {
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

  static String dateShort(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  static String dateFull(DateTime d) =>
      '${_weekDays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';
  static String time(DateTime d) {
    int h = d.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h == 0)
      h = 12;
    else if (h > 12)
      h -= 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} $p';
  }

  static String timeOfDay(TimeOfDay t) {
    int h = t.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h == 0)
      h = 12;
    else if (h > 12)
      h -= 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} $p';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}

// ============================================================================
// 3. GLOBAL EVENT BUS (Simulates Push Notifications)
// ============================================================================

class AppEvent {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  AppEvent(
    this.title,
    this.message, {
    this.color = AppColors.primary,
    this.icon = Icons.notifications,
  });
}

class EventBus {
  static final StreamController<AppEvent> _bus =
      StreamController<AppEvent>.broadcast();
  static Stream<AppEvent> get stream => _bus.stream;
  static void emit(AppEvent event) => _bus.sink.add(event);
}

// ============================================================================
// 4. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String avatarUrl;
  User({required this.id, required this.name, required this.avatarUrl});
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final MedicationForm form;
  final String instructions;
  final Color color;

  // Schedule Rules
  final FrequencyType frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final List<TimeOfDay> times; // Times to take per day

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.form,
    required this.instructions,
    required this.color,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.times,
  });

  bool get isActive {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}

class DoseEvent {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  DateTime? actualTime;
  DoseStatus status;

  DoseEvent({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.actualTime,
    this.status = DoseStatus.pending,
  });

  DoseEvent copyWith({DateTime? actualTime, DoseStatus? status}) {
    return DoseEvent(
      id: id,
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
    );
  }
}

// ============================================================================
// 5. MOCK DATABASE & CRON ENGINE
// ============================================================================

class MockMedicationEngine {
  static final MockMedicationEngine _instance =
      MockMedicationEngine._internal();
  factory MockMedicationEngine() => _instance;
  MockMedicationEngine._internal() {
    _seedData();
    _startCronWorker();
  }

  final math.Random _rand = math.Random();
  final Map<String, Medication> _medications = {};
  final List<DoseEvent> _doses = []; // Relational table of specific events

  Timer? _cronTimer;
  Function? onDataChanged;

  void dispose() {
    _cronTimer?.cancel();
  }

  void _seedData() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final m1 = Medication(
      id: 'M1',
      name: 'Lisinopril',
      dosage: '10mg',
      form: MedicationForm.pill,
      instructions: 'Take with water after breakfast.',
      color: Colors.blue,
      frequency: FrequencyType.daily,
      startDate: thirtyDaysAgo,
      times: [const TimeOfDay(hour: 8, minute: 0)],
    );
    final m2 = Medication(
      id: 'M2',
      name: 'Metformin',
      dosage: '20mg',
      form: MedicationForm.pill,
      instructions: 'Take with evening meal.',
      color: Colors.purple,
      frequency: FrequencyType.daily,
      startDate: thirtyDaysAgo,
      times: [const TimeOfDay(hour: 19, minute: 0)],
    );
    final m3 = Medication(
      id: 'M3',
      name: 'Vitamin D3',
      dosage: '2000 IU',
      form: MedicationForm.capsule,
      instructions: 'Take with a fatty meal for absorption.',
      color: Colors.orange,
      frequency: FrequencyType.daily,
      startDate: thirtyDaysAgo,
      times: [const TimeOfDay(hour: 12, minute: 0)],
    );

    _medications.addAll({m1.id: m1, m2.id: m2, m3.id: m3});

    // Generate historical dose events for the last 30 days
    for (int i = 30; i >= 0; i--) {
      final targetDate = DateFormatters.startOfDay(
        now.subtract(Duration(days: i)),
      );

      for (var med in _medications.values) {
        for (var time in med.times) {
          final scheduled = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            time.hour,
            time.minute,
          );

          DoseStatus status;
          DateTime? actual;

          if (scheduled.isAfter(now)) {
            status = DoseStatus.pending;
          } else {
            // Determine historical status: 80% taken, 10% missed, 10% skipped
            double chance = _rand.nextDouble();
            if (chance < 0.8) {
              status = DoseStatus.taken;
              // Actual time varies by +/- 45 mins
              actual = scheduled.add(Duration(minutes: _rand.nextInt(90) - 45));
            } else if (chance < 0.9) {
              status = DoseStatus.missed;
            } else {
              status = DoseStatus.skipped;
            }
          }

          _doses.add(
            DoseEvent(
              id: 'D_${med.id}_${scheduled.millisecondsSinceEpoch}',
              medicationId: med.id,
              scheduledTime: scheduled,
              actualTime: actual,
              status: status,
            ),
          );
        }
      }
    }
  }

  /// CRON WORKER: Checks every second if a pending dose is due or missed
  void _startCronWorker() {
    _cronTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      bool stateMutated = false;

      for (int i = 0; i < _doses.length; i++) {
        final dose = _doses[i];
        if (dose.status == DoseStatus.pending) {
          // Trigger Alert when exactly due (simulation window)
          if (now.difference(dose.scheduledTime).inSeconds.abs() < 1) {
            final med = _medications[dose.medicationId]!;
            EventBus.emit(
              AppEvent(
                'Dose Reminder',
                'It is time to take ${med.name} (${med.dosage}).',
                color: AppColors.primary,
              ),
            );
          }

          // Mark as missed if 30 minutes past due
          if (now.isAfter(
            dose.scheduledTime.add(const Duration(minutes: 30)),
          )) {
            _doses[i] = dose.copyWith(status: DoseStatus.missed);
            stateMutated = true;

            final med = _medications[dose.medicationId]!;
            EventBus.emit(
              AppEvent(
                'Missed Dose',
                'You missed your ${DateFormatters.time(dose.scheduledTime)} dose of ${med.name}.',
                color: AppColors.statusMissed,
                icon: Icons.warning,
              ),
            );
          }
        }
      }

      if (stateMutated && onDataChanged != null) {
        onDataChanged!();
      }
    });
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _rand.nextInt(300)));

  // --- Read Operations ---
  Future<User> getUser() async {
    await _latency();
    return User(
      id: 'U1',
      name: 'Alex Patient',
      avatarUrl: 'https://i.pravatar.cc/150?u=1',
    );
  }

  Future<List<Medication>> getMedications() async {
    await _latency();
    return _medications.values.toList();
  }

  Future<List<DoseEvent>> getDosesForDate(DateTime date) async {
    await _latency();
    return _doses
        .where((d) => DateFormatters.isSameDay(d.scheduledTime, date))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<List<DoseEvent>> getAllHistoricalDoses() async {
    await _latency();
    return List.unmodifiable(_doses);
  }

  // --- Write Operations ---
  Future<void> addMedication(Medication med) async {
    await _latency(800);
    _medications[med.id] = med;

    // Generate doses for the next 30 days based on the schedule
    final now = DateFormatters.startOfDay(DateTime.now());
    for (int i = 0; i < 30; i++) {
      final targetDate = now.add(Duration(days: i));
      if (targetDate.isBefore(med.startDate)) continue;
      if (med.endDate != null && targetDate.isAfter(med.endDate!)) continue;

      for (var time in med.times) {
        final scheduled = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          time.hour,
          time.minute,
        );
        _doses.add(
          DoseEvent(
            id: 'D_${med.id}_${scheduled.millisecondsSinceEpoch}',
            medicationId: med.id,
            scheduledTime: scheduled,
          ),
        );
      }
    }
  }

  Future<void> updateDoseStatus(String doseId, DoseStatus status) async {
    await _latency(300); // Fast local update
    final idx = _doses.indexWhere((d) => d.id == doseId);
    if (idx != -1) {
      _doses[idx] = _doses[idx].copyWith(
        status: status,
        actualTime: DateTime.now(),
      );
    }
  }

  Medication getMedicationLocal(String id) => _medications[id]!;
}

// ============================================================================
// 6. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockMedicationEngine _api = MockMedicationEngine();

  User? currentUser;
  bool isGlobalLoading = true;
  String? globalError;

  // Selected Date State
  DateTime selectedDate = DateTime.now();
  List<DoseEvent> activeDoses = [];
  List<Medication> activeMeds = [];

  // Analytics Data
  List<DoseEvent> allHistory = [];

  AppState() {
    _api.onDataChanged = _onBackgroundDataMutated;
    _boot();
  }

  Future<void> _boot() async {
    try {
      currentUser = await _api.getUser();
      await fetchDateData(selectedDate);
      allHistory = await _api.getAllHistoricalDoses();
    } catch (e) {
      globalError = "Failed to load health data.";
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  void _onBackgroundDataMutated() {
    // Re-fetch doses quietly when CRON mutates a record (e.g. pending -> missed)
    _fetchDosesQuietly();
  }

  Future<void> _fetchDosesQuietly() async {
    activeDoses = await _api.getDosesForDate(selectedDate);
    allHistory = await _api.getAllHistoricalDoses();
    notifyListeners();
  }

  void _setError(String? e) {
    globalError = e;
    notifyListeners();
  }

  Future<void> fetchDateData(DateTime date) async {
    selectedDate = date;
    isGlobalLoading = true;
    notifyListeners();
    try {
      activeDoses = await _api.getDosesForDate(date);
      activeMeds = await _api.getMedications(); // Cache meds list
    } catch (e) {
      _setError("Failed to fetch schedule.");
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMedication(Medication m) async {
    _setError(null);
    isGlobalLoading = true;
    notifyListeners();
    try {
      await _api.addMedication(m);
      await fetchDateData(selectedDate); // Re-sync
      allHistory = await _api.getAllHistoricalDoses();
      return true;
    } catch (e) {
      _setError("Failed to save medication.");
      return false;
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  void markDose(String doseId, DoseStatus status) async {
    // Optimistic UI Update
    final idx = activeDoses.indexWhere((d) => d.id == doseId);
    if (idx == -1) return;

    final oldDose = activeDoses[idx];
    activeDoses[idx] = oldDose.copyWith(
      status: status,
      actualTime: DateTime.now(),
    );
    notifyListeners();

    try {
      await _api.updateDoseStatus(doseId, status);
      allHistory = await _api.getAllHistoricalDoses(); // update analytics
    } catch (e) {
      activeDoses[idx] = oldDose; // Revert
      _setError("Failed to update status.");
      notifyListeners();
    }
  }

  Medication getMed(String id) => _api.getMedicationLocal(id);
}

class AppStore extends InheritedNotifier<AppState> {
  const AppStore({Key? key, required AppState state, required Widget child})
    : super(key: key, notifier: state, child: child);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStore>()!.notifier!;
}

// ============================================================================
// 7. MAIN APP BOOTSTRAP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MedReminderApp());
}

class MedReminderApp extends StatefulWidget {
  const MedReminderApp({Key? key}) : super(key: key);
  @override
  State<MedReminderApp> createState() => _MedReminderAppState();
}

class _MedReminderAppState extends State<MedReminderApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    // Intercept global notifications from the background Engine
    _eventSub = EventBus.stream.listen((event) {
      if (mounted) _showInAppNotification(event);
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _showInAppNotification(AppEvent event) {
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: event.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Health',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _scaffoldKey,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textMain,
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
    if (state.isGlobalLoading && state.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'NEXUS HEALTH',
                style: AppStyles.h1.copyWith(
                  letterSpacing: 2,
                  color: AppColors.primaryDark,
                ),
              ),
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
    const TodayScreen(),
    const MedicationsScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppColors.primary),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication, color: AppColors.primary),
            label: 'Medications',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppColors.primary),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. TODAY/SCHEDULE SCREEN (Timeline & Calendar Strip)
// ============================================================================

class TodayScreen extends StatelessWidget {
  const TodayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    // Group active doses by time block
    final Map<String, List<DoseEvent>> groupedDoses = {};
    for (var d in state.activeDoses) {
      final key = DateFormatters.time(d.scheduledTime);
      groupedDoses.putIfAbsent(key, () => []).add(d);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(state.currentUser!.avatarUrl),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello,',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  state.currentUser!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddMedicationWizard(),
                fullscreenDialog: true,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Horizontal Calendar Strip
          _CalendarStrip(
            selectedDate: state.selectedDate,
            onDateSelected: (d) => state.fetchDateData(d),
          ),

          const Divider(height: 1, color: AppColors.surfaceHighlight),

          Expanded(
            child: state.isGlobalLoading
                ? const Center(child: CircularProgressIndicator())
                : groupedDoses.isEmpty
                ? const Center(
                    child: Text(
                      'No medications scheduled for this day.',
                      style: AppStyles.body,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    itemCount: groupedDoses.keys.length,
                    itemBuilder: (ctx, i) {
                      final timeKey = groupedDoses.keys.elementAt(i);
                      final doses = groupedDoses[timeKey]!;
                      return _TimelineBlock(
                        timeLabel: timeKey,
                        doses: doses,
                        isLast: i == groupedDoses.keys.length - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  const _CalendarStrip({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Generate dates -3 to +7 days from now
    final dates = List.generate(
      11,
      (i) => now.subtract(const Duration(days: 3)).add(Duration(days: i)),
    );

    return Container(
      height: 90,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (ctx, i) {
          final d = dates[i];
          final isSelected = DateFormatters.isSameDay(d, selectedDate);
          final isToday = DateFormatters.isSameDay(d, now);

          return GestureDetector(
            onTap: () => onDateSelected(d),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceHighlight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1],
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  final String timeLabel;
  final List<DoseEvent> doses;
  final bool isLast;
  const _TimelineBlock({
    required this.timeLabel,
    required this.doses,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Axis
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Timeline Graphic
          SizedBox(
            width: 30,
            child: CustomPaint(painter: _TimelineNodePainter(isLast: isLast)),
          ),

          // Content Cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                children: doses.map((d) => _DoseCard(dose: d)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineNodePainter extends CustomPainter {
  final bool isLast;
  _TimelineNodePainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.surfaceHighlight
      ..strokeWidth = 2;
    final paintCircle = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    if (!isLast)
      canvas.drawLine(
        Offset(size.width / 2, 20),
        Offset(size.width / 2, size.height),
        paintLine,
      );
    canvas.drawCircle(Offset(size.width / 2, 10), 8, paintCircle);
    canvas.drawCircle(Offset(size.width / 2, 10), 8, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DoseCard extends StatelessWidget {
  final DoseEvent dose;
  const _DoseCard({required this.dose});

  void _showActionSheet(BuildContext context, AppState state) {
    if (dose.status == DoseStatus.taken || dose.status == DoseStatus.skipped)
      return; // Immutable for demo

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update Dose Status', style: AppStyles.h2),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusTaken,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'MARK AS TAKEN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                state.markDose(dose.id, DoseStatus.taken);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusSkipped,
                side: const BorderSide(color: AppColors.statusSkipped),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.next_plan),
              label: const Text(
                'SKIP DOSE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                state.markDose(dose.id, DoseStatus.skipped);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final med = state.getMed(dose.medicationId);

    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (dose.status) {
      case DoseStatus.pending:
        statusColor = AppColors.statusPending;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
      case DoseStatus.taken:
        statusColor = AppColors.statusTaken;
        statusIcon = Icons.check_circle;
        statusText = 'Taken';
        break;
      case DoseStatus.skipped:
        statusColor = AppColors.statusSkipped;
        statusIcon = Icons.next_plan;
        statusText = 'Skipped';
        break;
      case DoseStatus.missed:
        statusColor = AppColors.statusMissed;
        statusIcon = Icons.error;
        statusText = 'Missed';
        break;
    }

    return GestureDetector(
      onTap: () => _showActionSheet(context, state),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 100,
              decoration: BoxDecoration(
                color: med.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: AppStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${med.dosage} • ${med.form.name}',
                      style: AppStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            med.instructions,
                            style: AppStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }
}

// ============================================================================
// 9. MEDICATIONS LIST SCREEN
// ============================================================================

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final meds = state.activeMeds;

    return Scaffold(
      appBar: AppBar(title: const Text('My Medications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: meds.length,
        itemBuilder: (ctx, i) {
          final med = meds[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: med.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.medication, color: med.color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name, style: AppStyles.h3),
                            Text(
                              '${med.dosage} • ${med.form.name}',
                              style: AppStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: med.isActive,
                        activeColor: AppColors.primary,
                        onChanged: (v) {},
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.surfaceHighlight),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Frequency', style: AppStyles.caption),
                          const SizedBox(height: 4),
                          Text(
                            med.frequency.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Times / Day', style: AppStyles.caption),
                          const SizedBox(height: 4),
                          Text(
                            '${med.times.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 10. ANALYTICS / HISTORY SCREEN (Custom Painters)
// ============================================================================

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final history = state.allHistory;

    // Analytics Calculation
    int total = history.length;
    int taken = history.where((d) => d.status == DoseStatus.taken).length;
    int missed = history.where((d) => d.status == DoseStatus.missed).length;
    double adherenceRate = total == 0 ? 0.0 : taken / total;

    // Prepare weekly data for Bar Chart
    final now = DateFormatters.startOfDay(DateTime.now());
    List<double> weeklyRates = [];
    for (int i = 6; i >= 0; i--) {
      final target = now.subtract(Duration(days: i));
      final dayDoses = history
          .where((d) => DateFormatters.isSameDay(d.scheduledTime, target))
          .toList();
      if (dayDoses.isEmpty) {
        weeklyRates.add(0.0);
      } else {
        int t = dayDoses.where((d) => d.status == DoseStatus.taken).length;
        weeklyRates.add(t / dayDoses.length);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Health Insights')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '30-Day Adherence Score',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _AdherenceRingPainter(rate: adherenceRate),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBadge(
                      label: 'Taken',
                      value: '$taken',
                      color: AppColors.statusTaken,
                    ),
                    _StatBadge(
                      label: 'Missed',
                      value: '$missed',
                      color: AppColors.statusMissed,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('7-Day Trend', style: AppStyles.h2),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: CustomPaint(
              painter: _WeeklyBarChartPainter(rates: weeklyRates),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: AppStyles.caption),
      ],
    );
  }
}

class _AdherenceRingPainter extends CustomPainter {
  final double rate;
  _AdherenceRingPainter({required this.rate});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const stroke = 20.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    Color activeC = rate >= 0.8
        ? AppColors.statusTaken
        : (rate >= 0.5 ? AppColors.statusSkipped : AppColors.statusMissed);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * rate,
      false,
      Paint()
        ..color = activeC
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '${(rate * 100).toInt()}%\n',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: activeC,
        ),
        children: [TextSpan(text: 'Adherence', style: AppStyles.caption)],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<double> rates;
  _WeeklyBarChartPainter({required this.rates});

  @override
  void paint(Canvas canvas, Size size) {
    final barW = size.width / 14;
    final maxH = size.height;

    for (int i = 0; i < rates.length; i++) {
      double h = rates[i] * maxH;
      if (h == 0) h = 5; // Min visibility

      double xCenter = (i * (size.width / 7)) + (size.width / 14);
      Color c = rates[i] >= 0.8
          ? AppColors.statusTaken
          : AppColors.statusMissed;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xCenter - barW / 2, size.height - h, barW, h),
          const Radius.circular(6),
        ),
        Paint()..color = c,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ============================================================================
// 11. ADD MEDICATION WIZARD (Complex Multi-Step Form Validation)
// ============================================================================

class AddMedicationWizard extends StatefulWidget {
  const AddMedicationWizard({Key? key}) : super(key: key);
  @override
  State<AddMedicationWizard> createState() => _AddMedicationWizardState();
}

class _AddMedicationWizardState extends State<AddMedicationWizard> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _instCtrl = TextEditingController();
  MedicationForm _form = MedicationForm.pill;

  FrequencyType _freq = FrequencyType.daily;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

  void _save(AppState state) async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date.'),
          backgroundColor: AppColors.statusMissed,
        ),
      );
      return;
    }

    final med = Medication(
      id: 'M_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text,
      dosage: _doseCtrl.text,
      form: _form,
      instructions: _instCtrl.text,
      color: Colors.blueAccent,
      frequency: _freq,
      startDate: _startDate,
      endDate: _endDate,
      times: List.from(_times),
    );

    final success = await state.createMedication(med);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _instCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0) {
            if (_formKey.currentState!.validate()) setState(() => _step++);
          } else if (_step == 1)
            setState(() => _step++);
          else
            _save(state);
        },
        onStepCancel: () {
          if (_step > 0)
            setState(() => _step--);
          else
            Navigator.pop(context);
        },
        controlsBuilder: (c, d) => Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: d.onStepContinue,
                  child: Text(_step == 2 ? 'SAVE' : 'NEXT'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: d.onStepCancel,
                  child: const Text('BACK'),
                ),
              ),
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Basic Info'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.editing,
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _doseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosage (e.g., 10mg)',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MedicationForm>(
                    value: _form,
                    decoration: const InputDecoration(labelText: 'Form'),
                    items: MedicationForm.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _form = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Instructions (Optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Schedule'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.editing,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<FrequencyType>(
                  value: _freq,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: FrequencyType.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _freq = v!),
                ),
                const SizedBox(height: 24),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormatters.dateFull(_startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  tileColor: AppColors.surface,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('End Date (Optional)'),
                  subtitle: Text(
                    _endDate == null
                        ? 'Continuous'
                        : DateFormatters.dateFull(_endDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  tileColor: AppColors.surface,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate:
                          _endDate ?? _startDate.add(const Duration(days: 30)),
                      firstDate: _startDate,
                      lastDate: DateTime.now().add(const Duration(days: 1000)),
                    );
                    if (d != null) setState(() => _endDate = d);
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Times'),
            isActive: _step >= 2,
            content: Column(
              children: [
                ..._times
                    .asMap()
                    .entries
                    .map(
                      (e) => ListTile(
                        title: Text('Dose ${e.key + 1}'),
                        trailing: Text(
                          DateFormatters.timeOfDay(e.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: e.value,
                          );
                          if (t != null) setState(() => _times[e.key] = t);
                        },
                      ),
                    )
                    .toList(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _times.add(const TimeOfDay(hour: 12, minute: 0)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
