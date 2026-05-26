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

enum MuscleGroup { chest, back, legs, arms, shoulders, core, cardio, fullBody }

enum Difficulty { beginner, intermediate, advanced }

enum WorkoutStatus { notStarted, active, paused, resting, completed }

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700

  static const Color primary = Color(0xFF8B5CF6); // Violet 500
  static const Color primaryDark = Color(0xFF6D28D9); // Violet 700

  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Activity Ring Colors
  static const Color ringMove = Color(0xFFEF4444); // Red
  static const Color ringExercise = Color(0xFF10B981); // Green
  static const Color ringStand = Color(0xFF3B82F6); // Blue

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color gold = Color(0xFFFBBF24);
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
}

// ============================================================================
// 2. EXCEPTIONS & UTILS
// ============================================================================

abstract class FitnessException implements Exception {
  final String message;
  FitnessException(this.message);
  @override
  String toString() => message;
}

class AuthException extends FitnessException {
  AuthException([String m = "Authentication failed."]) : super(m);
}

class WorkoutException extends FitnessException {
  WorkoutException([String m = "Workout state error."]) : super(m);
}

class DateUtilsFormatter {
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static String formatShort(DateTime d) => '${d.month}/${d.day}';
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String avatarUrl;

  // Daily Goals
  final int dailyCalorieGoal;
  final int dailyExerciseMinutesGoal;
  final int dailyWorkoutsGoal;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.dailyCalorieGoal = 500,
    this.dailyExerciseMinutesGoal = 45,
    this.dailyWorkoutsGoal = 1,
  });
}

class Exercise {
  final String id;
  final String name;
  final MuscleGroup targetMuscle;
  final int sets;
  final int reps;
  final int restSeconds;
  final String instructions;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.instructions,
  });
}

class WorkoutPlan {
  final String id;
  final String title;
  final String description;
  final Difficulty difficulty;
  final int estimatedMinutes;
  final int estimatedCalories;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.estimatedCalories,
    required this.exercises,
  });
}

class WorkoutLog {
  final String id;
  final String planId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int caloriesBurned;
  final int totalVolume; // kg lifted

  WorkoutLog({
    required this.id,
    required this.planId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.caloriesBurned,
    required this.totalVolume,
  });

  int get durationSeconds => endTime.difference(startTime).inSeconds;
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.unlockedAt,
  });

  Achievement copyWith({DateTime? unlockedAt}) => Achievement(
    id: id,
    title: title,
    description: description,
    icon: icon,
    color: color,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
  bool get isUnlocked => unlockedAt != null;
}

// ============================================================================
// 4. MOCK BACKEND ENGINE & ALGORITHMS
// ============================================================================

class MockFitnessEngine {
  static final MockFitnessEngine _instance = MockFitnessEngine._internal();
  factory MockFitnessEngine() => _instance;
  MockFitnessEngine._internal() {
    _seedData();
  }

  final math.Random _random = math.Random();

  final List<WorkoutPlan> _catalog = [];
  final List<WorkoutLog> _history = [];
  List<Achievement> _badges = [];

  // Default constructor removed — singleton factory used

  void _seedData() {
    // 1. Seed Exercises
    final e1 = Exercise(
      id: 'E1',
      name: 'Barbell Bench Press',
      targetMuscle: MuscleGroup.chest,
      sets: 4,
      reps: 10,
      restSeconds: 90,
      instructions: 'Keep back arched and feet flat.',
    );
    final e2 = Exercise(
      id: 'E2',
      name: 'Incline Dumbbell Press',
      targetMuscle: MuscleGroup.chest,
      sets: 3,
      reps: 12,
      restSeconds: 60,
      instructions: 'Control the eccentric portion.',
    );
    final e3 = Exercise(
      id: 'E3',
      name: 'Pull-ups',
      targetMuscle: MuscleGroup.back,
      sets: 4,
      reps: 8,
      restSeconds: 90,
      instructions: 'Full range of motion, chin over bar.',
    );
    final e4 = Exercise(
      id: 'E4',
      name: 'Barbell Squat',
      targetMuscle: MuscleGroup.legs,
      sets: 5,
      reps: 5,
      restSeconds: 120,
      instructions: 'Break parallel, keep chest up.',
    );
    final e5 = Exercise(
      id: 'E5',
      name: 'Plank',
      targetMuscle: MuscleGroup.core,
      sets: 3,
      reps: 60,
      restSeconds: 45,
      instructions: 'Hold for 60 seconds.',
    );

    // 2. Seed Plans
    _catalog.addAll([
      WorkoutPlan(
        id: 'WP1',
        title: 'Chest & Core Destroyer',
        description: 'Build upper body strength and core stability.',
        difficulty: Difficulty.intermediate,
        estimatedMinutes: 45,
        estimatedCalories: 350,
        exercises: [e1, e2, e5],
      ),
      WorkoutPlan(
        id: 'WP2',
        title: 'Heavy Leg Day',
        description: 'Focus on compound lower body movements.',
        difficulty: Difficulty.advanced,
        estimatedMinutes: 60,
        estimatedCalories: 500,
        exercises: [e4, e5],
      ),
      WorkoutPlan(
        id: 'WP3',
        title: 'Pull Day Fundamentals',
        description: 'Back and bicep targeted hypertrophy.',
        difficulty: Difficulty.beginner,
        estimatedMinutes: 40,
        estimatedCalories: 300,
        exercises: [e3],
      ),
    ]);

    // 3. Seed Badges
    _badges = [
      Achievement(
        id: 'A1',
        title: 'First Steps',
        description: 'Complete your first workout.',
        icon: Icons.directions_walk,
        color: AppColors.success,
      ),
      Achievement(
        id: 'A2',
        title: '3 Day Streak',
        description: 'Workout for 3 consecutive days.',
        icon: Icons.local_fire_department,
        color: AppColors.ringMove,
      ),
      Achievement(
        id: 'A3',
        title: '7 Day Streak',
        description: 'Workout for 7 consecutive days.',
        icon: Icons.whatshot,
        color: AppColors.ringMove,
      ),
      Achievement(
        id: 'A4',
        title: 'Iron Lifter',
        description: 'Lift over 5,000kg in volume.',
        icon: Icons.fitness_center,
        color: AppColors.textMuted,
      ),
      Achievement(
        id: 'A5',
        title: 'Calorie Burner',
        description: 'Burn over 10,000 calories total.',
        icon: Icons.bolt,
        color: AppColors.gold,
      ),
    ];

    // 4. Generate 90 Days of Historical Logs for Analytics & Heatmap
    final now = DateTime.now();
    for (int i = 90; i >= 1; i--) {
      // 60% chance to have worked out on any given past day
      if (_random.nextDouble() < 0.6) {
        final plan = _catalog[_random.nextInt(_catalog.length)];
        final date = now.subtract(
          Duration(days: i, hours: _random.nextInt(12)),
        );

        _history.add(
          WorkoutLog(
            id: 'LOG_${date.millisecondsSinceEpoch}',
            planId: plan.id,
            title: plan.title,
            startTime: date,
            endTime: date.add(
              Duration(minutes: plan.estimatedMinutes + _random.nextInt(10)),
            ),
            caloriesBurned: plan.estimatedCalories + _random.nextInt(50),
            totalVolume: 1000 + _random.nextInt(3000),
          ),
        );
      }
    }

    // Evaluate historical badges
    _evaluateAchievements(isHistorical: true);
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(300)));

  // --- API Methods ---
  Future<User> login() async {
    await _latency(800);
    return User(
      id: 'U1',
      name: 'Alex Fitness',
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
      dailyCalorieGoal: 600,
      dailyExerciseMinutesGoal: 45,
    );
  }

  Future<List<WorkoutPlan>> getCatalog() async {
    await _latency();
    return _catalog;
  }

  Future<List<WorkoutLog>> getHistory() async {
    await _latency();
    return _history.reversed.toList();
  }

  Future<List<Achievement>> getBadges() async {
    await _latency();
    return _badges;
  }

  /// Core Engine: Saves workout and triggers analytics updates
  Future<List<Achievement>> saveWorkout(WorkoutLog log) async {
    await _latency(600);
    _history.add(log);

    // Evaluate if new badges were unlocked right now
    final newlyUnlocked = _evaluateAchievements(isHistorical: false);
    return newlyUnlocked;
  }

  // --- Algorithms ---

  /// Calculates the current consecutive day streak
  int calculateCurrentStreak() {
    if (_history.isEmpty) return 0;

    final sortedDates =
        _history
            .map((l) => DateUtilsFormatter.startOfDay(l.startTime))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    final today = DateUtilsFormatter.startOfDay(DateTime.now());

    int streak = 0;
    DateTime checkDate = today;

    // If no workout today, check if yesterday was the last one (streak still alive)
    if (!sortedDates.contains(today)) {
      if (sortedDates.contains(today.subtract(const Duration(days: 1)))) {
        checkDate = today.subtract(const Duration(days: 1));
      } else {
        return 0; // Streak broken
      }
    }

    for (var date in sortedDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculates the longest streak ever achieved
  int calculateBestStreak() {
    if (_history.isEmpty) return 0;
    final sortedDates =
        _history
            .map((l) => DateUtilsFormatter.startOfDay(l.startTime))
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));

    int best = 0;
    int current = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      if (sortedDates[i].difference(sortedDates[i - 1]).inDays == 1) {
        current++;
      } else {
        if (current > best) best = current;
        current = 1;
      }
    }
    if (current > best) best = current;
    return best;
  }

  /// Evaluates all conditions for unlocking badges.
  /// Returns a list of newly unlocked badges if [isHistorical] is false.
  List<Achievement> _evaluateAchievements({bool isHistorical = false}) {
    List<Achievement> newlyUnlocked = [];
    final currentStreak = calculateCurrentStreak();
    final totalVol = _history.fold<int>(0, (sum, l) => sum + l.totalVolume);
    final totalCal = _history.fold<int>(0, (sum, l) => sum + l.caloriesBurned);

    void unlock(String id) {
      final idx = _badges.indexWhere((b) => b.id == id);
      if (idx != -1 && !_badges[idx].isUnlocked) {
        _badges[idx] = _badges[idx].copyWith(unlockedAt: DateTime.now());
        if (!isHistorical) newlyUnlocked.add(_badges[idx]);
      }
    }

    if (_history.isNotEmpty) unlock('A1'); // First Steps
    if (currentStreak >= 3) unlock('A2'); // 3 Day Streak
    if (currentStreak >= 7) unlock('A3'); // 7 Day Streak
    if (totalVol >= 5000) unlock('A4'); // Iron Lifter
    if (totalCal >= 10000) unlock('A5'); // Calorie Burner

    return newlyUnlocked;
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockFitnessEngine _api = MockFitnessEngine();

  User? currentUser;
  bool isGlobalLoading = true;
  String? globalError;

  // Data Store
  List<WorkoutPlan> catalog = [];
  List<WorkoutLog> history = [];
  List<Achievement> badges = [];

  int currentStreak = 0;
  int bestStreak = 0;

  // Event stream for overlays (Confetti/Rewards)
  final StreamController<Achievement> _rewardBus =
      StreamController<Achievement>.broadcast();
  Stream<Achievement> get rewardStream => _rewardBus.stream;

  AppState() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      currentUser = await _api.login();
      catalog = await _api.getCatalog();
      await _syncUserData();
    } catch (e) {
      globalError = "Failed to load application data.";
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncUserData() async {
    history = await _api.getHistory();
    badges = await _api.getBadges();
    currentStreak = _api.calculateCurrentStreak();
    bestStreak = _api.calculateBestStreak();
    notifyListeners();
  }

  // --- Analytics Getters ---
  List<WorkoutLog> get todayLogs {
    final now = DateTime.now();
    return history
        .where((l) => DateUtilsFormatter.isSameDay(l.startTime, now))
        .toList();
  }

  int get todayCalories =>
      todayLogs.fold(0, (sum, l) => sum + l.caloriesBurned);
  int get todayMinutes =>
      todayLogs.fold(0, (sum, l) => sum + (l.durationSeconds ~/ 60));

  Map<DateTime, int> get heatmapData {
    final map = <DateTime, int>{};
    for (var l in history) {
      final day = DateUtilsFormatter.startOfDay(l.startTime);
      map[day] = (map[day] ?? 0) + 1; // Count workouts per day
    }
    return map;
  }

  // --- Actions ---
  Future<void> logWorkout(WorkoutLog log) async {
    isGlobalLoading = true;
    notifyListeners();
    try {
      final newBadges = await _api.saveWorkout(log);
      await _syncUserData(); // Refresh local state

      // Fire rewards
      for (var b in newBadges) {
        _rewardBus.sink.add(b);
      }
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
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
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Fitness',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
          ),
          cardColor: AppColors.surface,
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return const MainScaffold();
  }
}

// ============================================================================
// 7. MAIN SCAFFOLD & REWARD OVERLAY
// ============================================================================

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final _screens = [
    const DashboardScreen(),
    const CatalogScreen(),
    const ProgressScreen(),
  ];
  StreamSubscription? _rewardSub;

  @override
  void initState() {
    super.initState();
    // Listen for Badge Unlocks
    Future.microtask(() {
      _rewardSub = AppStore.of(context, listen: false).rewardStream.listen((
        badge,
      ) {
        _showRewardOverlay(badge);
      });
    });
  }

  @override
  void dispose() {
    _rewardSub?.cancel();
    super.dispose();
  }

  void _showRewardOverlay(Achievement badge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RewardDialog(badge: badge),
    );
  }

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
            icon: Icon(Icons.dashboard),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. DASHBOARD (Activity Rings & Streaks)
// ============================================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser!;

    double calProgress = math.min(
      1.0,
      state.todayCalories / user.dailyCalorieGoal,
    );
    double minProgress = math.min(
      1.0,
      state.todayMinutes / user.dailyExerciseMinutesGoal,
    );
    double wktProgress = math.min(
      1.0,
      state.todayLogs.length / user.dailyWorkoutsGoal,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: AppColors.ringMove),
            const SizedBox(width: 4),
            Text(
              '${state.currentStreak} Day Streak',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Activity Rings
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
              ],
            ),
            child: Column(
              children: [
                const Text('Daily Activity', style: AppStyles.h2),
                const SizedBox(height: 32),
                SizedBox(
                  width: 220,
                  height: 220,
                  // Implicit animation wrapper for the rings
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return CustomPaint(
                        painter: _ActivityRingsPainter(
                          calProgress: calProgress * val,
                          minProgress: minProgress * val,
                          wktProgress: wktProgress * val,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RingLegend(
                      color: AppColors.ringMove,
                      label: 'Move',
                      value: '${state.todayCalories}/${user.dailyCalorieGoal}',
                    ),
                    _RingLegend(
                      color: AppColors.ringExercise,
                      label: 'Exercise',
                      value:
                          '${state.todayMinutes}/${user.dailyExerciseMinutesGoal}m',
                    ),
                    _RingLegend(
                      color: AppColors.ringStand,
                      label: 'Workouts',
                      value:
                          '${state.todayLogs.length}/${user.dailyWorkoutsGoal}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text('Today\'s Log', style: AppStyles.h2),
          const SizedBox(height: 16),

          if (state.todayLogs.isEmpty)
            const Text(
              'You haven\'t logged a workout today. Head to the Workouts tab to get started!',
              style: AppStyles.body,
            )
          else
            ...state.todayLogs
                .map(
                  (l) => Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        l.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${DateUtilsFormatter.formatDuration(l.durationSeconds)} • ${l.caloriesBurned} kcal',
                      ),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _RingLegend({
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: AppStyles.caption),
      ],
    );
  }
}

// ============================================================================
// 9. WORKOUT CATALOG
// ============================================================================

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Programs')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: state.catalog.length,
        itemBuilder: (context, index) {
          final plan = state.catalog[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plan.difficulty.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          '${plan.estimatedMinutes} Min',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(plan.title, style: AppStyles.h2),
                    const SizedBox(height: 8),
                    Text(plan.description, style: AppStyles.caption),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.format_list_numbered,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${plan.exercises.length} Exercises',
                          style: AppStyles.caption,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppColors.ringMove,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${plan.estimatedCalories} kcal',
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlanDetailScreen extends StatelessWidget {
  final WorkoutPlan plan;
  const PlanDetailScreen({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plan.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Routine Overview', style: AppStyles.h2),
          const SizedBox(height: 16),
          ...plan.exercises
              .map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: Text('${plan.exercises.indexOf(e) + 1}'),
                  ),
                  title: Text(
                    e.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${e.sets} Sets x ${e.reps} Reps'),
                  trailing: Text(
                    e.targetMuscle.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(plan: plan)),
        ),
        label: const Text(
          'START WORKOUT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.play_arrow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ============================================================================
// 10. ACTIVE WORKOUT RUNNER (Complex State Machine)
// ============================================================================

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutPlan plan;
  const ActiveWorkoutScreen({Key? key, required this.plan}) : super(key: key);

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late DateTime _startTime;
  WorkoutStatus _status = WorkoutStatus.active;

  int _currentExIdx = 0;
  int _currentSet = 1;

  // Timers
  Timer? _globalTimer;
  int _elapsedSeconds = 0;

  Timer? _restTimer;
  int _restSecondsRemaining = 0;

  // Logging Data
  int _totalVolume = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != WorkoutStatus.paused) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Exercise get _currentEx => widget.plan.exercises[_currentExIdx];

  void _finishSet() {
    // For simulation, arbitrarily add volume per set
    _totalVolume += (_currentEx.reps * 20); // assume 20kg average lift

    if (_currentSet < _currentEx.sets) {
      // Enter Rest State
      _currentSet++;
      _startRest(_currentEx.restSeconds);
    } else {
      // Next Exercise
      if (_currentExIdx < widget.plan.exercises.length - 1) {
        _currentExIdx++;
        _currentSet = 1;
        _startRest(60); // 60s transition rest
      } else {
        // Finish Workout
        _finishWorkout();
      }
    }
  }

  void _startRest(int seconds) {
    setState(() {
      _status = WorkoutStatus.resting;
      _restSecondsRemaining = seconds;
    });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
        } else {
          _skipRest();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _status = WorkoutStatus.active);
  }

  void _finishWorkout() async {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    setState(() => _status = WorkoutStatus.completed);

    final state = AppStore.of(context, listen: false);
    final log = WorkoutLog(
      id: 'LOG_${DateTime.now().millisecondsSinceEpoch}',
      planId: widget.plan.id,
      title: widget.plan.title,
      startTime: _startTime,
      endTime: DateTime.now(),
      // Simple formula based on time and plan base
      caloriesBurned: widget.plan.estimatedCalories + (_elapsedSeconds ~/ 60),
      totalVolume: _totalVolume,
    );

    await state.logWorkout(log);
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _confirmExit() async {
    if (_status == WorkoutStatus.completed) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmExit()) Navigator.pop(context);
            },
          ),
          title: Text(
            DateUtilsFormatter.formatDuration(_elapsedSeconds),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _status == WorkoutStatus.paused
                    ? Icons.play_arrow
                    : Icons.pause,
              ),
              onPressed: () => setState(
                () => _status = _status == WorkoutStatus.paused
                    ? WorkoutStatus.active
                    : WorkoutStatus.paused,
              ),
            ),
          ],
        ),
        body: _status == WorkoutStatus.resting
            ? _buildRestUI()
            : _buildActiveUI(),
      ),
    );
  }

  Widget _buildActiveUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exercise ${_currentExIdx + 1} of ${widget.plan.exercises.length}',
            style: AppStyles.caption.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(_currentEx.name, style: AppStyles.h1),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BigMetric(
                      label: 'Set',
                      value: '$_currentSet / ${_currentEx.sets}',
                    ),
                    _BigMetric(
                      label: 'Target Reps',
                      value: '${_currentEx.reps}',
                    ),
                  ],
                ),
                const Divider(height: 48),
                Text('Instructions', style: AppStyles.caption),
                const SizedBox(height: 8),
                Text(
                  _currentEx.instructions,
                  textAlign: TextAlign.center,
                  style: AppStyles.body,
                ),
              ],
            ),
          ),

          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _status == WorkoutStatus.paused ? null : _finishSet,
            child: Text(
              _currentSet == _currentEx.sets &&
                      _currentExIdx == widget.plan.exercises.length - 1
                  ? 'FINISH WORKOUT'
                  : 'COMPLETE SET',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestUI() {
    return Container(
      color: AppColors.primaryDark.withOpacity(0.2),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'REST',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateUtilsFormatter.formatDuration(_restSecondsRemaining),
            style: const TextStyle(
              fontSize: 84,
              fontWeight: FontWeight.w200,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 48),
          Text('Up next: ${_currentEx.name}', style: AppStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Set $_currentSet of ${_currentEx.sets}',
            style: AppStyles.caption,
          ),
          const SizedBox(height: 64),
          OutlinedButton(
            onPressed: _skipRest,
            child: const Text(
              'SKIP REST',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  final String label;
  final String value;
  const _BigMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppStyles.caption),
      ],
    );
  }
}

// ============================================================================
// 11. PROGRESS & ANALYTICS SCREEN
// ============================================================================

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final history = state.history;

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Badges Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Achievements', style: AppStyles.h2),
              Text(
                '${state.badges.where((b) => b.isUnlocked).length}/${state.badges.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.badges.length,
              itemBuilder: (ctx, i) {
                final b = state.badges[i];
                return Tooltip(
                  message: b.description,
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: b.isUnlocked
                          ? b.color.withOpacity(0.2)
                          : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: b.isUnlocked ? b.color : AppColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      b.icon,
                      color: b.isUnlocked ? b.color : AppColors.textMuted,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 48),
          const Text('Workout Consistency', style: AppStyles.h2),
          const SizedBox(height: 8),
          const Text('Last 90 days of activity', style: AppStyles.caption),
          const SizedBox(height: 24),

          // Heatmap
          Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: HeatmapPainter(data: state.heatmapData, daysToShow: 90),
            ),
          ),

          const SizedBox(height: 48),
          const Text('Recent History', style: AppStyles.h2),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Text('No past workouts found.')
          else
            ...history
                .take(5)
                .map(
                  (l) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateUtilsFormatter.formatShort(l.startTime)} • ${l.caloriesBurned} kcal',
                    ),
                    trailing: Text(
                      '${l.totalVolume} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}

// ============================================================================
// 12. CUSTOM PAINTERS & ANIMATIONS
// ============================================================================

/// Renders concentric rings (Move, Exercise, Stand/Workout)
class _ActivityRingsPainter extends CustomPainter {
  final double calProgress;
  final double minProgress;
  final double wktProgress;

  _ActivityRingsPainter({
    required this.calProgress,
    required this.minProgress,
    required this.wktProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    const strokeW = 18.0;
    const gap = 4.0;

    void drawRing(double r, double p, Color c) {
      // Track
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = c.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      // Progress Arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        2 * math.pi * p,
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    drawRing(maxRadius - (strokeW / 2), calProgress, AppColors.ringMove);
    drawRing(
      maxRadius - (strokeW * 1.5) - gap,
      minProgress,
      AppColors.ringExercise,
    );
    drawRing(
      maxRadius - (strokeW * 2.5) - (gap * 2),
      wktProgress,
      AppColors.ringStand,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter old) =>
      old.calProgress != calProgress ||
      old.minProgress != minProgress ||
      old.wktProgress != wktProgress;
}

/// Renders a GitHub-style Contribution Heatmap
class HeatmapPainter extends CustomPainter {
  final Map<DateTime, int> data;
  final int daysToShow;

  HeatmapPainter({required this.data, required this.daysToShow});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateUtilsFormatter.startOfDay(DateTime.now());

    // Calculate columns needed (weeks)
    int cols = (daysToShow / 7).ceil();
    double boxSize = (size.width - (cols - 1) * 4) / cols;
    if (boxSize > (size.height - 6 * 4) / 7)
      boxSize = (size.height - 6 * 4) / 7; // constrain by height

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < daysToShow; i++) {
      final date = now.subtract(Duration(days: i));

      // Map index to col/row going right to left, top to bottom
      int col = cols - 1 - (i ~/ 7);
      int row = date.weekday % 7; // Sunday=0, Monday=1...

      int count = data[date] ?? 0;

      if (count == 0)
        paint.color = AppColors.surfaceLight;
      else if (count == 1)
        paint.color = AppColors.primary.withOpacity(0.4);
      else if (count == 2)
        paint.color = AppColors.primary.withOpacity(0.7);
      else
        paint.color = AppColors.primary;

      double x = col * (boxSize + 4);
      double y = row * (boxSize + 4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, boxSize, boxSize),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Simplified for demo
}

// --- CONFETTI OVERLAY ANIMATION ---

class _RewardDialog extends StatefulWidget {
  final Achievement badge;
  const _RewardDialog({required this.badge});

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    // Auto dismiss
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (c, _) =>
                  CustomPaint(painter: _ConfettiPainter(progress: _ctrl.value)),
            ),
          ),
          // Badge UI
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _ctrl,
              curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.badge.color.withOpacity(0.5),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ACHIEVEMENT UNLOCKED',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Icon(widget.badge.icon, size: 80, color: widget.badge.color),
                  const SizedBox(height: 24),
                  Text(widget.badge.title, style: AppStyles.h1),
                  const SizedBox(height: 8),
                  Text(widget.badge.description, style: AppStyles.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final math.Random rand = math.Random(
      42,
    ); // Seeded so particles follow deterministic paths per frame
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
    ];

    for (int i = 0; i < 100; i++) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final dist =
          rand.nextDouble() *
          size.height *
          progress; // Expand outward based on progress

      // Add gravity
      final gravity = math.pow(progress, 2) * 500;

      final dx = center.dx + math.cos(angle) * dist;
      final dy = center.dy + math.sin(angle) * dist + gravity;

      final paint = Paint()
        ..color = colors[rand.nextInt(colors.length)]
        ..style = PaintingStyle.fill;

      // Fade out
      paint.color = paint.color.withOpacity((1.0 - progress).clamp(0.0, 1.0));

      canvas.drawCircle(Offset(dx, dy), 4 + rand.nextDouble() * 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
