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
// 1. CONSTANTS, ENUMS & THEME CONFIGURATION
// ============================================================================

enum HabitCategory { health, productivity, mindfulness, fitness, finance }

enum HabitFrequency { daily, weekly, customDays }

class AppColors {
  static const Color background = Color(0xFF0B0F19); // Deep Midnight
  static const Color surface = Color(0xFF161F30); // Dark Slate Blue
  static const Color surfaceHighlight = Color(0xFF24324A); // Lighter Slate Blue

  static const Color primary = Color(0xFF6366F1); // Vivid Indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color accent = Color(0xFF06B6D4); // Cyan

  static const Color textMain = Color(0xFFF8FAFC); // Off-White
  static const Color textMuted = Color(0xFF64748B); // Cool Grey

  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color gold = Color(0xFFFBBF24);

  static Color getCategoryColor(HabitCategory cat) {
    switch (cat) {
      case HabitCategory.health:
        return const Color(0xFF10B981);
      case HabitCategory.productivity:
        return const Color(0xFFF59E0B);
      case HabitCategory.mindfulness:
        return const Color(0xFF8B5CF6);
      case HabitCategory.fitness:
        return const Color(0xFFEF4444);
      case HabitCategory.finance:
        return const Color(0xFF0EA5E9);
    }
  }
}

class AppStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.textMain,
    letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
    letterSpacing: -0.3,
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
// 2. EXCEPTIONS & CUSTOM DATE UTILITIES
// ============================================================================

abstract class HabitException implements Exception {
  final String message;
  HabitException(this.message);
  @override
  String toString() => message;
}

class ValidationException extends HabitException {
  ValidationException(String m) : super(m);
}

class ExecutionException extends HabitException {
  ExecutionException(String m) : super(m);
}

class HabitDateUtils {
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

  static String dayName(DateTime d) => _weekDays[d.weekday - 1];

  static String formatShort(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  static String formatFull(DateTime d) =>
      '${_weekDays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  static String formatTimeOfDay(TimeOfDay t) {
    final h = t.hour == 0 || t.hour == 12 ? 12 : t.hour % 12;
    final p = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:${t.minute.toString().padLeft(2, '0')} $p';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}

// ============================================================================
// 3. INTERNAL BUS (Real-time Event Messaging Engine)
// ============================================================================

class AppNudgeEvent {
  final String title;
  final String message;
  final Color baseColor;
  final IconData displayIcon;
  AppNudgeEvent(
    this.title,
    this.message, {
    this.baseColor = AppColors.primary,
    this.displayIcon = Icons.notifications_active,
  });
}

class BehaviorEventBus {
  static final StreamController<AppNudgeEvent> _controller =
      StreamController<AppNudgeEvent>.broadcast();
  static Stream<AppNudgeEvent> get stream => _controller.stream;
  static void dispatch(AppNudgeEvent event) => _controller.sink.add(event);
  static void close() => _controller.close();
}

// ============================================================================
// 4. DOMAIN MODELS
// ============================================================================

class Habit {
  final String id;
  String title;
  String targetDescription;
  HabitCategory category;
  HabitFrequency frequency;
  List<int> selectedWeekdays; // 1 = Monday, 7 = Sunday
  TimeOfDay reminderTime;
  DateTime createdAt;
  bool isArchived;

  Habit({
    required this.id,
    required this.title,
    required this.targetDescription,
    required this.category,
    required this.frequency,
    required this.selectedWeekdays,
    required this.reminderTime,
    required this.createdAt,
    this.isArchived = false,
  });
}

class HabitLog {
  final String id;
  final String habitId;
  final DateTime executionDate;
  final DateTime logTimestamp;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.executionDate,
    required this.logTimestamp,
  });
}

class UserProfile {
  final String username;
  int currentStreakScore;
  int performancePoints;
  UserProfile({
    required this.username,
    this.currentStreakScore = 0,
    this.performancePoints = 0,
  });
}

// ============================================================================
// 5. MOCK DATABASE ENGINE & BACKGROUND PROCESSOR
// ============================================================================

class MockHabitEngine {
  static final MockHabitEngine _instance = MockHabitEngine._internal();
  factory MockHabitEngine() => _instance;
  MockHabitEngine._internal() {
    _initializeDatabase();
    _activateBackgroundCron();
  }

  final math.Random _random = math.Random();
  final Map<String, Habit> _habitsTable = {};
  final List<HabitLog> _logsLedger = [];
  late UserProfile _profile;

  Timer? _cronTimer;
  Function? onCronMutation;

  void dispose() {
    _cronTimer?.cancel();
  }

  void _initializeDatabase() {
    _profile = UserProfile(
      username: 'Alex Cooper',
      currentStreakScore: 5,
      performancePoints: 3400,
    );

    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    // Seed Core Habits
    final h1 = Habit(
      id: 'H1',
      title: 'Morning Mindfulness',
      targetDescription: 'Meditation before screening devices.',
      category: HabitCategory.mindfulness,
      frequency: HabitFrequency.daily,
      selectedWeekdays: [1, 2, 3, 4, 5, 6, 7],
      reminderTime: const TimeOfDay(hour: 7, minute: 30),
      createdAt: ninetyDaysAgo,
    );
    final h2 = Habit(
      id: 'H2',
      title: 'Hydration Target',
      targetDescription: 'Consume 3 Liters of water daily.',
      category: HabitCategory.health,
      frequency: HabitFrequency.daily,
      selectedWeekdays: [1, 2, 3, 4, 5, 6, 7],
      reminderTime: const TimeOfDay(hour: 12, minute: 0),
      createdAt: ninetyDaysAgo,
    );
    final h3 = Habit(
      id: 'H3',
      title: 'Gym Workout Routine',
      targetDescription: 'Weight lifting or cardio workout.',
      category: HabitCategory.fitness,
      frequency: HabitFrequency.customDays,
      selectedWeekdays: [1, 3, 5],
      reminderTime: const TimeOfDay(hour: 18, minute: 0),
      createdAt: ninetyDaysAgo,
    );
    final h4 = Habit(
      id: 'H4',
      title: 'Review Personal Ledger',
      targetDescription: 'Log outlays and evaluate savings metrics.',
      category: HabitCategory.finance,
      frequency: HabitFrequency.weekly,
      selectedWeekdays: [7],
      reminderTime: const TimeOfDay(hour: 20, minute: 0),
      createdAt: ninetyDaysAgo,
    );

    _habitsTable.addAll({h1.id: h1, h2.id: h2, h3.id: h3, h4.id: h4});

    // Generate 90 Days of Historical Logs
    for (int i = 90; i >= 1; i--) {
      final pastDate = HabitDateUtils.startOfDay(
        now.subtract(Duration(days: i)),
      );

      _habitsTable.forEach((id, habit) {
        if (habit.selectedWeekdays.contains(pastDate.weekday)) {
          // Simulate standard 70% completion variance pattern
          if (_random.nextDouble() < 0.73) {
            _logsLedger.add(
              HabitLog(
                id: 'L_${id}_${pastDate.millisecondsSinceEpoch}',
                habitId: id,
                executionDate: pastDate,
                logTimestamp: pastDate.add(const Duration(hours: 12)),
              ),
            );
          }
        }
      });
    }

    _activateBackgroundCron();
  }

  void _activateBackgroundCron() {
    _cronTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final currentLocalTime = TimeOfDay.fromDateTime(DateTime.now());
      bool mutationTriggered = false;

      // Scan for pending notifications or nudge interventions
      _habitsTable.forEach((id, habit) {
        if (!habit.isArchived &&
            habit.reminderTime.hour == currentLocalTime.hour) {
          final today = HabitDateUtils.startOfDay(DateTime.now());
          final completedToday = _logsLedger.any(
            (l) =>
                l.habitId == id &&
                HabitDateUtils.isSameDay(l.executionDate, today),
          );

          if (!completedToday && _random.nextDouble() < 0.3) {
            BehaviorEventBus.dispatch(
              AppNudgeEvent(
                'Habit Nudge',
                'Do not lose your progress! Complete "${habit.title}" today.',
                baseColor: AppColors.warning,
                displayIcon: Icons.bolt,
              ),
            );
            mutationTriggered = true;
          }
        }
      });

      if (mutationTriggered && onCronMutation != null) {
        onCronMutation!();
      }
    });
  }

  Future<void> _mockIOLatency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(200)));

  // --- External Data Processing Protocol API ---
  Future<UserProfile> fetchProfile() async {
    await _mockIOLatency();
    return _profile;
  }

  Future<List<Habit>> fetchHabits() async {
    await _mockIOLatency();
    return _habitsTable.values.toList();
  }

  Future<List<HabitLog>> fetchLogs() async {
    await _mockIOLatency();
    return List.unmodifiable(_logsLedger);
  }

  Future<void> writeLog(String habitId, DateTime targetDate) async {
    await _mockIOLatency(200);
    final normalizedDate = HabitDateUtils.startOfDay(targetDate);

    final existingIndex = _logsLedger.indexWhere(
      (l) =>
          l.habitId == habitId &&
          HabitDateUtils.isSameDay(l.executionDate, normalizedDate),
    );
    if (existingIndex != -1) {
      _logsLedger.removeAt(existingIndex); // Untoggle log mapping
      _profile.performancePoints = math.max(0, _profile.performancePoints - 50);
    } else {
      _logsLedger.add(
        HabitLog(
          id: 'L_${habitId}_${normalizedDate.millisecondsSinceEpoch}',
          habitId: habitId,
          executionDate: normalizedDate,
          logTimestamp: DateTime.now(),
        ),
      );
      _profile.performancePoints += 50;
    }
  }

  Future<Habit> insertHabit(Habit h) async {
    await _mockIOLatency(600);
    _habitsTable[h.id] = h;
    return h;
  }

  // --- Algorithmic Processing Helpers ---
  int calculateStreak(String habitId) {
    final relevantLogs = _logsLedger
        .where((l) => l.habitId == habitId)
        .map((l) => HabitDateUtils.startOfDay(l.executionDate))
        .toSet()
        .toList();
    if (relevantLogs.isEmpty) return 0;
    relevantLogs.sort(
      (a, b) => b.compareTo(a),
    ); // Reverse chronological sequence

    final habit = _habitsTable[habitId]!;
    final today = HabitDateUtils.startOfDay(DateTime.now());
    int streak = 0;
    DateTime iterator = today;

    // Check if habit requires completion today, if not evaluated yet, back-step anchor
    if (!relevantLogs.contains(today)) {
      if (!habit.selectedWeekdays.contains(today.weekday)) {
        iterator = iterator.subtract(const Duration(days: 1));
      } else {
        // Evaluate if completed yesterday to sustain operational calculation
        final yesterday = today.subtract(const Duration(days: 1));
        if (!relevantLogs.contains(yesterday)) return 0;
        iterator = yesterday;
      }
    }

    while (true) {
      if (habit.selectedWeekdays.contains(iterator.weekday)) {
        if (relevantLogs.contains(iterator)) {
          streak++;
        } else {
          break; // Broken baseline pipeline chain
        }
      }
      iterator = iterator.subtract(const Duration(days: 1));
      // Max historical boundary limiter execution lock
      if (today.difference(iterator).inDays > 100) break;
    }
    return streak;
  }
}

// ============================================================================
// 6. SYSTEM STATE ROUTING STATE MANAGEMENT
// ============================================================================

class HabitAppState extends ChangeNotifier {
  final MockHabitEngine _api = MockHabitEngine();

  bool isGlobalSyncing = true;
  String? operationalFault;

  UserProfile? user;
  List<Habit> operationalHabits = [];
  List<HabitLog> masterLogsLedger = [];

  DateTime targetTimelineAnchor = DateTime.now();

  HabitAppState() {
    _api.onCronMutation = _handleCronRefresh;
    _bootStateManagement();
  }

  Future<void> _bootStateManagement() async {
    try {
      user = await _api.fetchProfile();
      operationalHabits = await _api.fetchHabits();
      masterLogsLedger = await _api.fetchLogs();
    } catch (e) {
      operationalFault = "State pipeline synchronization fault.";
    } finally {
      isGlobalSyncing = false;
      notifyListeners();
    }
  }

  void _handleCronRefresh() {
    _syncLedgerQuietly();
  }

  Future<void> _syncLedgerQuietly() async {
    masterLogsLedger = await _api.fetchLogs();
    notifyListeners();
  }

  Future<void> syncTimelineFocus(DateTime date) async {
    targetTimelineAnchor = date;
    isGlobalSyncing = true;
    notifyListeners();
    masterLogsLedger = await _api.fetchLogs();
    isGlobalSyncing = false;
    notifyListeners();
  }

  Future<void> toggleHabitState(String habitId, DateTime date) async {
    final oldLogs = List<HabitLog>.from(masterLogsLedger);
    final targetDay = HabitDateUtils.startOfDay(date);

    // Optimistic UI state execution mapping rendering block
    final existingIdx = masterLogsLedger.indexWhere(
      (l) =>
          l.habitId == habitId &&
          HabitDateUtils.isSameDay(l.executionDate, targetDay),
    );
    if (existingIdx != -1) {
      masterLogsLedger.removeAt(existingIdx);
    } else {
      masterLogsLedger.add(
        HabitLog(
          id: 'TMP',
          habitId: habitId,
          executionDate: targetDay,
          logTimestamp: DateTime.now(),
        ),
      );
    }
    notifyListeners();

    try {
      await _api.writeLog(habitId, date);
      user = await _api
          .fetchProfile(); // Re-sync transaction performance metrics scores
      masterLogsLedger = await _api.fetchLogs();
    } catch (e) {
      masterLogsLedger =
          oldLogs; // Invalidation rollback handler chain injection
      notifyListeners();
    }
  }

  Future<bool> registerNewHabit(
    String title,
    String desc,
    HabitCategory category,
    HabitFrequency freq,
    List<int> days,
    TimeOfDay time,
  ) async {
    isGlobalSyncing = true;
    notifyListeners();
    try {
      if (title.trim().isEmpty)
        throw ValidationException("Habit name configuration parameter empty.");

      final habit = Habit(
        id: 'H_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        targetDescription: desc,
        category: category,
        frequency: freq,
        selectedWeekdays: days,
        reminderTime: time,
        createdAt: DateTime.now(),
      );

      await _api.insertHabit(habit);
      operationalHabits = await _api.fetchHabits();
      masterLogsLedger = await _api.fetchLogs();
      return true;
    } catch (e) {
      operationalFault = "Failed to finalize structural entity write.";
      return false;
    } finally {
      isGlobalSyncing = false;
      notifyListeners();
    }
  }

  // --- Architectural Domain Getters ---
  List<Habit> get focusedTimelineHabitSet {
    return operationalHabits.where((h) {
      if (h.isArchived) return false;
      return h.selectedWeekdays.contains(targetTimelineAnchor.weekday);
    }).toList();
  }

  bool isHabitCompletedOnDate(String habitId, DateTime d) {
    return masterLogsLedger.any(
      (l) =>
          l.habitId == habitId && HabitDateUtils.isSameDay(l.executionDate, d),
    );
  }

  int fetchHabitStreak(String habitId) => _api.calculateStreak(habitId);

  Map<DateTime, int> fetchAggregatedHeatmap() {
    final Map<DateTime, int> map = {};
    for (var log in masterLogsLedger) {
      final day = HabitDateUtils.startOfDay(log.executionDate);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }
}

class AppStore extends InheritedNotifier<HabitAppState> {
  const AppStore({
    Key? key,
    required HabitAppState state,
    required Widget child,
  }) : super(key: key, notifier: state, child: child);
  static HabitAppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStore>()!.notifier!;
}

// ============================================================================
// 7. CORE RUNTIME ENGINE OVERLAYS
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const HabitBuilderFrameworkApp());
}

class HabitBuilderFrameworkApp extends StatefulWidget {
  const HabitBuilderFrameworkApp({Key? key}) : super(key: key);
  @override
  State<HabitBuilderFrameworkApp> createState() =>
      _HabitBuilderFrameworkAppState();
}

class _HabitBuilderFrameworkAppState extends State<HabitBuilderFrameworkApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _eventSubscriptionChannel;

  @override
  void initState() {
    super.initState();
    _eventSubscriptionChannel = BehaviorEventBus.stream.listen((event) {
      if (mounted) _injectGlobalSystemSnackbar(event);
    });
  }

  @override
  void dispose() {
    _eventSubscriptionChannel?.cancel();
    BehaviorEventBus.close();
    super.dispose();
  }

  void _injectGlobalSystemSnackbar(AppNudgeEvent event) {
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(event.displayIcon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    event.message,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: event.baseColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: HabitAppState(),
      child: MaterialApp(
        title: 'Nexus Habits',
        scaffoldMessengerKey: _messengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          cardColor: AppColors.surface,
        ),
        home: const AppNavigationShellRouter(),
      ),
    );
  }
}

class AppNavigationShellRouter extends StatelessWidget {
  const AppNavigationShellRouter({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.isGlobalSyncing && state.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return const MainNavigationShellScaffold();
  }
}

class MainNavigationShellScaffold extends StatefulWidget {
  const MainNavigationShellScaffold({Key? key}) : super(key: key);
  @override
  State<MainNavigationShellScaffold> createState() =>
      _MainNavigationShellScaffoldState();
}

class _MainNavigationShellScaffoldState
    extends State<MainNavigationShellScaffold> {
  int _activeDisplayIndex = 0;
  final _screensList = [
    const TimelineFocusScreen(),
    const HabitsManagementScreen(),
    const MetricalAnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screensList[_activeDisplayIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeDisplayIndex,
        onDestinationSelected: (i) => setState(() => _activeDisplayIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today, color: AppColors.primary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Metrics',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. TIMELINE SCREEN MODULE
// ============================================================================

class TimelineFocusScreen extends StatelessWidget {
  const TimelineFocusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.user!;
    final timelineItems = state.focusedTimelineHabitSet;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surfaceHighlight,
              child: Text(
                user.username[0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${user.performancePoints} pts',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NewHabitCreationWizard(),
                fullscreenDialog: true,
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _HorizontalCalendarRibbon(
            selectedDay: state.targetTimelineAnchor,
            onDaySelected: (d) => state.syncTimelineFocus(d),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: state.isGlobalSyncing
                ? const Center(child: CircularProgressIndicator())
                : timelineItems.isEmpty
                ? const Center(
                    child: Text(
                      'No parameters tracked for this cyclical day.',
                      style: AppStyles.caption,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: timelineItems.length,
                    itemBuilder: (ctx, i) {
                      final item = timelineItems[i];
                      final complete = state.isHabitCompletedOnDate(
                        item.id,
                        state.targetTimelineAnchor,
                      );
                      return _InteractiveHabitCard(
                        habit: item,
                        isCompleted: complete,
                        timelineAnchor: state.targetTimelineAnchor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalCalendarRibbon extends StatelessWidget {
  final DateTime selectedDay;
  final Function(DateTime) onDaySelected;
  const _HorizontalCalendarRibbon({
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final baseNow = DateTime.now();
    final timelineRange = List.generate(
      7,
      (i) => baseNow.subtract(const Duration(days: 4)).add(Duration(days: i)),
    );

    return Container(
      height: 85,
      color: AppColors.surface.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: timelineRange.length,
        itemBuilder: (ctx, i) {
          final date = timelineRange[i];
          final isActive = HabitDateUtils.isSameDay(date, selectedDay);
          return GestureDetector(
            onTap: () => onDaySelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? AppColors.primary : Colors.white12,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    HabitDateUtils.dayName(date).substring(0, 1),
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.white70 : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      color: isActive ? Colors.white : AppColors.textMain,
                      fontWeight: FontWeight.bold,
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

class _InteractiveHabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final DateTime timelineAnchor;
  const _InteractiveHabitCard({
    required this.habit,
    required this.isCompleted,
    required this.timelineAnchor,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final themeColor = AppColors.getCategoryColor(habit.category);
    final metricStreak = state.fetchHabitStreak(habit.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => state.toggleHabitState(habit.id, timelineAnchor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? themeColor : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? themeColor : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: AppStyles.h3.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted
                          ? AppColors.textMuted
                          : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.targetDescription,
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
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$metricStreak',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  HabitDateUtils.formatTimeOfDay(habit.reminderTime),
                  style: AppStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 9. MANAGEMENT & CONFIGURATION DIALOG SYSTEM
// ============================================================================

class HabitsManagementScreen extends StatelessWidget {
  const HabitsManagementScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Structural Inventory Matrix'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: state.operationalHabits.length,
        itemBuilder: (ctx, i) {
          final habit = state.operationalHabits[i];
          final color = AppColors.getCategoryColor(habit.category);
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              title: Text(habit.title, style: AppStyles.h3),
              subtitle: Text(
                'Frequency Strategy: ${habit.frequency.name.toUpperCase()}',
                style: AppStyles.caption,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NewHabitCreationWizard extends StatefulWidget {
  const NewHabitCreationWizard({Key? key}) : super(key: key);
  @override
  State<NewHabitCreationWizard> createState() => _NewHabitCreationWizardState();
}

class _NewHabitCreationWizardState extends State<NewHabitCreationWizard> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  HabitCategory _activeCategorySelection = HabitCategory.health;
  HabitFrequency _frequencySelection = HabitFrequency.daily;
  List<int> _activeWeekdaysSet = [1, 2, 3, 4, 5, 6, 7];
  TimeOfDay _reminderAnchor = const TimeOfDay(hour: 8, minute: 0);

  void _processSubmission(HabitAppState state) async {
    if (!_formKey.currentState!.validate()) return;

    final executionSuccess = await state.registerNewHabit(
      _titleController.text,
      _descController.text,
      _activeCategorySelection,
      _frequencySelection,
      _activeWeekdaysSet,
      _reminderAnchor,
    );

    if (executionSuccess && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Structural Behavior'),
        actions: [
          TextButton(
            onPressed: () => _processSubmission(state),
            child: const Text(
              'CREATE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Habit Title Designation *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty
                  ? 'Identifier parameter declaration required'
                  : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Target Objective Strategy Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Functional Category Domain Spec', style: AppStyles.h3),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: HabitCategory.values.map((cat) {
                final active = _activeCategorySelection == cat;
                return ChoiceChip(
                  label: Text(cat.name.toUpperCase()),
                  selected: active,
                  selectedColor: AppColors.getCategoryColor(
                    cat,
                  ).withOpacity(0.3),
                  onSelected: (selected) {
                    if (selected)
                      setState(() => _activeCategorySelection = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Frequency Interval Processing Plan',
              style: AppStyles.h3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HabitFrequency>(
              value: _frequencySelection,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: HabitFrequency.values
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _frequencySelection = val;
                    if (val == HabitFrequency.daily)
                      _activeWeekdaysSet = [1, 2, 3, 4, 5, 6, 7];
                    else if (val == HabitFrequency.weekly)
                      _activeWeekdaysSet = [7];
                  });
                }
              },
            ),
            const SizedBox(height: 32),
            ListTile(
              title: const Text('Nudge Notification Temporal Target'),
              subtitle: Text(
                HabitDateUtils.formatTimeOfDay(_reminderAnchor),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              trailing: const Icon(
                Icons.access_time,
                color: AppColors.textMuted,
              ),
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _reminderAnchor,
                );
                if (time != null) setState(() => _reminderAnchor = time);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 10. METRICAL ANALYTICS MODULE & CANVAS VISUALS
// ============================================================================

class MetricalAnalyticsScreen extends StatelessWidget {
  const MetricalAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final operationalDataMap = state.fetchAggregatedHeatmap();

    // Group structural density calculations by sector
    final Map<HabitCategory, int> structureSectorGrid = {
      for (var c in HabitCategory.values) c: 0,
    };
    for (var log in state.masterLogsLedger) {
      final match = state.operationalHabits.firstWhere(
        (h) => h.id == log.habitId,
        orElse: () => Habit(
          id: '',
          title: '',
          targetDescription: '',
          category: HabitCategory.health,
          frequency: HabitFrequency.daily,
          selectedWeekdays: [],
          reminderTime: const TimeOfDay(hour: 0, minute: 0),
          createdAt: DateTime.now(),
        ),
      );
      if (match.id.isNotEmpty) {
        structureSectorGrid[match.category] =
            structureSectorGrid[match.category]! + 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Matrix Telemetry'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('90-Day Structural Execution Grids', style: AppStyles.h2),
          const SizedBox(height: 16),
          Container(
            height: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomPaint(
              painter: HabitContributionHeatmap(
                dataMatrix: operationalDataMap,
                deepEvaluationBoundary: 90,
              ),
            ),
          ),
          const SizedBox(height: 36),
          const Text('Sector Consistency Vector', style: AppStyles.h2),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomPaint(
              painter: CategoryPerformanceBarChart(
                sectorGridMap: structureSectorGrid,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class HabitContributionHeatmap extends CustomPainter {
  final Map<DateTime, int> dataMatrix;
  final int deepEvaluationBoundary;

  HabitContributionHeatmap({
    required this.dataMatrix,
    required this.deepEvaluationBoundary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midnightAnchor = HabitDateUtils.startOfDay(DateTime.now());
    final matrixColumnsCount = (deepEvaluationBoundary / 7).ceil();

    double dimensionBox =
        (size.width - (matrixColumnsCount - 1) * 3) / matrixColumnsCount;
    if (dimensionBox > (size.height - 6 * 3) / 7) {
      dimensionBox = (size.height - 6 * 3) / 7;
    }

    final drawingPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < deepEvaluationBoundary; i++) {
      final calendarDate = midnightAnchor.subtract(Duration(days: i));

      int visualCol = matrixColumnsCount - 1 - (i ~/ 7);
      int visualRow = calendarDate.weekday % 7;

      int metricsValueCount = dataMatrix[calendarDate] ?? 0;

      if (metricsValueCount == 0)
        drawingPaint.color = AppColors.surfaceHighlight;
      else if (metricsValueCount == 1)
        drawingPaint.color = AppColors.primary.withOpacity(0.4);
      else if (metricsValueCount == 2)
        drawingPaint.color = AppColors.primary.withOpacity(0.7);
      else
        drawingPaint.color = AppColors.primary;

      double targetX = visualCol * (dimensionBox + 3);
      double targetY = visualRow * (dimensionBox + 3);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(targetX, targetY, dimensionBox, dimensionBox),
          const Radius.circular(2.5),
        ),
        drawingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CategoryPerformanceBarChart extends CustomPainter {
  final Map<HabitCategory, int> sectorGridMap;
  CategoryPerformanceBarChart({required this.sectorGridMap});

  @override
  void paint(Canvas canvas, Size size) {
    final valuesList = sectorGridMap.values.toList();
    int highMetricScale = valuesList.reduce(math.max);
    if (highMetricScale == 0) highMetricScale = 1;

    final double thicknessBar = size.width / (HabitCategory.values.length * 2);
    final double standardHeightBounds = size.height - 25;

    for (int i = 0; i < HabitCategory.values.length; i++) {
      final category = HabitCategory.values[i];
      final rawValue = sectorGridMap[category] ?? 0;
      final color = AppColors.getCategoryColor(category);

      double scaleCalculatedHeight =
          (rawValue / highMetricScale) * standardHeightBounds;
      if (scaleCalculatedHeight == 0)
        scaleCalculatedHeight = 6; // Baseline parameter tracking layout mask

      double layoutX = (i * thicknessBar * 2) + (thicknessBar / 2);

      // Rendering structural path profiles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            layoutX,
            standardHeightBounds - scaleCalculatedHeight,
            thicknessBar,
            scaleCalculatedHeight,
          ),
          const Radius.circular(5),
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // Metrical character text paint bounds injection layer
      final elementPainter = TextPainter(
        text: TextSpan(
          text: category.name.substring(0, 2).toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      elementPainter.paint(
        canvas,
        Offset(
          layoutX + (thicknessBar / 2) - (elementPainter.width / 2),
          standardHeightBounds + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
