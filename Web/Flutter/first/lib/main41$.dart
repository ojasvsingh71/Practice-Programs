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

enum Mood { awful, bad, okay, good, excellent }

enum ActivityTag {
  work,
  family,
  friends,
  exercise,
  reading,
  gaming,
  nature,
  sleep,
  travel,
  chores,
}

class AppColors {
  // Wellness-oriented soft palette
  static const Color background = Color(0xFFF8FAFC); // Soft Slate
  static const Color surface = Colors.white;
  static const Color surfaceHighlight = Color(0xFFF1F5F9);

  static const Color primary = Color(0xFF8B5CF6); // Soft Violet
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color accent = Color(0xFF0EA5E9); // Calm Cyan

  static const Color textMain = Color(0xFF1E293B); // Deep Slate
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Common utility colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500

  // Mood Colors
  static Color getMoodColor(Mood mood) {
    switch (mood) {
      case Mood.awful:
        return const Color(0xFFEF4444); // Red
      case Mood.bad:
        return const Color(0xFFF59E0B); // Orange
      case Mood.okay:
        return const Color(0xFF8B5CF6); // Violet
      case Mood.good:
        return const Color(0xFF10B981); // Emerald
      case Mood.excellent:
        return const Color(0xFF0EA5E9); // Cyan
    }
  }

  static IconData getMoodIcon(Mood mood) {
    switch (mood) {
      case Mood.awful:
        return Icons.sentiment_very_dissatisfied;
      case Mood.bad:
        return Icons.sentiment_dissatisfied;
      case Mood.okay:
        return Icons.sentiment_neutral;
      case Mood.good:
        return Icons.sentiment_satisfied;
      case Mood.excellent:
        return Icons.sentiment_very_satisfied;
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
    fontSize: 16,
    color: AppColors.textMain,
    height: 1.6,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );
}

// ============================================================================
// 2. EXCEPTIONS & UTILITIES
// ============================================================================

abstract class JournalException implements Exception {
  final String message;
  JournalException(this.message);
  @override
  String toString() => message;
}

class AuthException extends JournalException {
  AuthException([String m = "Invalid PIN."]) : super(m);
}

class ValidationException extends JournalException {
  ValidationException([String m = "Required fields missing."]) : super(m);
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

  static String dateFull(DateTime d) =>
      '${_weekDays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';
  static String dateShort(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  static String dayName(DateTime d) => _weekDays[d.weekday - 1];
  static String time(DateTime d) {
    int h = d.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h == 0)
      h = 12;
    else if (h > 12)
      h -= 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} $p';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String hashedPin; // Simulated secure storage

  User({required this.id, required this.name, required this.hashedPin});
}

class JournalEntry {
  final String id;
  final DateTime timestamp;
  final Mood mood;
  final Set<ActivityTag> activities;
  final String privateNote;
  final List<String> dailyPrompts; // e.g., "What made you smile?"

  JournalEntry({
    required this.id,
    required this.timestamp,
    required this.mood,
    required this.activities,
    required this.privateNote,
    this.dailyPrompts = const [],
  });

  int get moodScore => mood.index + 1; // 1 to 5
}

class InsightSummary {
  final int currentStreak;
  final int bestStreak;
  final Map<Mood, int> moodDistribution;
  final List<ActivityTag>
  positiveCorrelations; // Activities common on "Excellent/Good" days
  final List<ActivityTag>
  negativeCorrelations; // Activities common on "Awful/Bad" days

  InsightSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.moodDistribution,
    required this.positiveCorrelations,
    required this.negativeCorrelations,
  });
}

// ============================================================================
// 4. MOCK LOCAL DATABASE & ANALYTICS ENGINE
// ============================================================================

class MockJournalDatabase {
  static final MockJournalDatabase _instance = MockJournalDatabase._internal();
  factory MockJournalDatabase() => _instance;
  MockJournalDatabase._internal() {
    _seedData();
  }

  final math.Random _rand = math.Random();
  final List<JournalEntry> _entries = [];
  User? _mockUser;

  void dispose() {}

  void _seedData() {
    _mockUser = User(
      id: 'USR_1',
      name: 'Alex',
      hashedPin: '1234',
    ); // Simple PIN for demo

    final now = DateTime.now();

    // Generate 90 days of historical data for rich analytics
    for (int i = 90; i >= 1; i--) {
      // 80% chance of logging on any given past day
      if (_rand.nextDouble() < 0.8) {
        final date = now.subtract(Duration(days: i, hours: _rand.nextInt(12)));

        // Bias mood slightly positive
        final moodVal = _rand.nextDouble();
        Mood mood;
        if (moodVal < 0.1)
          mood = Mood.awful;
        else if (moodVal < 0.25)
          mood = Mood.bad;
        else if (moodVal < 0.6)
          mood = Mood.okay;
        else if (moodVal < 0.85)
          mood = Mood.good;
        else
          mood = Mood.excellent;

        // Generate random tags based on mood to simulate correlation
        Set<ActivityTag> tags = {};
        if (mood == Mood.excellent || mood == Mood.good) {
          if (_rand.nextBool()) tags.add(ActivityTag.exercise);
          if (_rand.nextBool()) tags.add(ActivityTag.nature);
          if (_rand.nextBool()) tags.add(ActivityTag.friends);
        } else if (mood == Mood.awful || mood == Mood.bad) {
          if (_rand.nextBool()) tags.add(ActivityTag.work);
          if (_rand.nextDouble() < 0.3)
            tags.add(ActivityTag.sleep); // Poor sleep
        }
        // Random noise
        if (_rand.nextBool()) tags.add(ActivityTag.reading);
        if (_rand.nextBool()) tags.add(ActivityTag.chores);

        _entries.add(
          JournalEntry(
            id: 'JNL_${date.millisecondsSinceEpoch}',
            timestamp: date,
            mood: mood,
            activities: tags,
            privateNote:
                'Encrypted journal content simulation... Day $i was eventful.',
          ),
        );
      }
    }
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _rand.nextInt(300)));

  // --- Core API ---
  Future<User> unlock(String pin) async {
    await _latency(600);
    if (pin != _mockUser?.hashedPin) throw AuthException();
    return _mockUser!;
  }

  Future<List<JournalEntry>> getEntries() async {
    await _latency();
    return List.from(_entries.reversed); // Newest first
  }

  Future<JournalEntry> saveEntry(JournalEntry entry) async {
    await _latency(800);
    _entries.add(entry);
    return entry;
  }

  // --- Analytics Engine ---
  Future<InsightSummary> generateInsights() async {
    await _latency(500);

    // 1. Calculate Streaks
    final dates =
        _entries
            .map((e) => DateFormatters.startOfDay(e.timestamp))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    int bestStreak = 0;

    if (dates.isNotEmpty) {
      final today = DateFormatters.startOfDay(DateTime.now());
      DateTime checkDate = today;

      // If no entry today, check if yesterday exists
      if (!dates.contains(today)) {
        if (dates.contains(today.subtract(const Duration(days: 1)))) {
          checkDate = today.subtract(const Duration(days: 1));
        }
      }

      for (var date in dates) {
        if (date == checkDate) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      // Best Streak
      int tempStreak = 1;
      final ascDates = List<DateTime>.from(dates)
        ..sort((a, b) => a.compareTo(b));
      for (int i = 1; i < ascDates.length; i++) {
        if (ascDates[i].difference(ascDates[i - 1]).inDays == 1) {
          tempStreak++;
        } else {
          if (tempStreak > bestStreak) bestStreak = tempStreak;
          tempStreak = 1;
        }
      }
      if (tempStreak > bestStreak) bestStreak = tempStreak;
      if (currentStreak > bestStreak)
        bestStreak = currentStreak; // Edge case safety
    }

    // 2. Mood Distribution
    Map<Mood, int> dist = {for (var m in Mood.values) m: 0};
    for (var e in _entries) {
      dist[e.mood] = dist[e.mood]! + 1;
    }

    // 3. Correlations (Simplified Naive Bayes approach)
    Map<ActivityTag, int> positiveOccurrences = {};
    Map<ActivityTag, int> negativeOccurrences = {};
    int posDays = 0, negDays = 0;

    for (var e in _entries) {
      if (e.mood == Mood.excellent || e.mood == Mood.good) {
        posDays++;
        for (var t in e.activities) {
          positiveOccurrences[t] = (positiveOccurrences[t] ?? 0) + 1;
        }
      } else if (e.mood == Mood.awful || e.mood == Mood.bad) {
        negDays++;
        for (var t in e.activities) {
          negativeOccurrences[t] = (negativeOccurrences[t] ?? 0) + 1;
        }
      }
    }

    List<ActivityTag> getTopCorrelations(
      Map<ActivityTag, int> occurrences,
      int totalDays,
    ) {
      if (totalDays == 0) return [];
      var sorted = occurrences.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(3).map((e) => e.key).toList();
    }

    return InsightSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      moodDistribution: dist,
      positiveCorrelations: getTopCorrelations(positiveOccurrences, posDays),
      negativeCorrelations: getTopCorrelations(negativeOccurrences, negDays),
    );
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockJournalDatabase _db = MockJournalDatabase();

  bool isGlobalLoading = false;
  String? globalError;
  bool isAuthenticated = false;
  User? currentUser;

  List<JournalEntry> entries = [];
  InsightSummary? insights;

  // Filter State
  Mood? filterMood;

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  Future<bool> unlockApp(String pin) async {
    _setLoading(true);
    _setError(null);
    try {
      currentUser = await _db.unlock(pin);
      isAuthenticated = true;
      await _loadData();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void lockApp() {
    isAuthenticated = false;
    entries.clear();
    insights = null;
    notifyListeners();
  }

  Future<void> _loadData() async {
    final futures = await Future.wait([
      _db.getEntries(),
      _db.generateInsights(),
    ]);
    entries = futures[0] as List<JournalEntry>;
    insights = futures[1] as InsightSummary;
    notifyListeners();
  }

  Future<bool> saveEntry(Mood mood, Set<ActivityTag> tags, String note) async {
    _setLoading(true);
    _setError(null);
    try {
      if (note.trim().isEmpty)
        throw ValidationException("Journal note cannot be empty.");

      final entry = JournalEntry(
        id: 'JNL_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        mood: mood,
        activities: tags,
        privateNote: note,
      );

      await _db.saveEntry(entry);
      await _loadData(); // Re-sync analytics and lists
      return true;
    } on JournalException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setFilter(Mood? mood) {
    filterMood = mood;
    notifyListeners();
  }

  List<JournalEntry> get filteredEntries {
    if (filterMood == null) return entries;
    return entries.where((e) => e.mood == filterMood).toList();
  }

  bool get hasLoggedToday {
    final today = DateFormatters.startOfDay(DateTime.now());
    return entries.any((e) => DateFormatters.startOfDay(e.timestamp) == today);
  }
}

class AppStore extends InheritedNotifier<AppState> {
  const AppStore({Key? key, required AppState state, required Widget child})
    : super(key: key, notifier: state, child: child);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStore>()!.notifier!;
}

// ============================================================================
// 6. MAIN APP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const WellnessJournalApp());
}

class WellnessJournalApp extends StatelessWidget {
  const WellnessJournalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Wellness',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Inter', // Fallback standard
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
    if (!state.isAuthenticated) return const PinLockScreen();
    return const MainScaffold();
  }
}

// ============================================================================
// 7. SECURE PIN LOCK SCREEN (Custom Numpad)
// ============================================================================

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({Key? key}) : super(key: key);
  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';

  void _onKeyPress(String key, AppState state) async {
    if (state.isGlobalLoading) return;

    setState(() {
      if (key == '<') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < 4) _pin += key;
      }
    });

    if (_pin.length == 4) {
      final success = await state.unlockApp(_pin);
      if (!success) {
        setState(() => _pin = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.spa, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'NEXUS JOURNAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Private Safe Space',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 48),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? Colors.white : Colors.white24,
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (state.globalError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  state.globalError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (state.isGlobalLoading)
              const CircularProgressIndicator(color: Colors.white),

            const Spacer(),

            // Custom Numpad
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', '<'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row
                          .map(
                            (k) => _NumpadKey(
                              val: k,
                              onTap: () =>
                                  k.isNotEmpty ? _onKeyPress(k, state) : null,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String val;
  final VoidCallback onTap;
  const _NumpadKey({required this.val, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (val.isEmpty) return const SizedBox(width: 80, height: 80);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: val == '<'
            ? const Icon(Icons.backspace, color: AppColors.textMain)
            : Text(
                val,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
      ),
    );
  }
}

// ============================================================================
// 8. MAIN SCAFFOLD
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
    const TimelineScreen(),
    const InsightsScreen(),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda, color: AppColors.primary),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppColors.primary),
            label: 'Insights',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EntryEditorScreen(),
            fullscreenDialog: true,
          ),
        ),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// ============================================================================
// 9. DASHBOARD SCREEN (Breathing & Quick Check-in)
// ============================================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser!;
    final insights = state.insights;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormatters.dateFull(DateTime.now()),
          style: const TextStyle(fontSize: 16),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              user.name[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => state.lockApp(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning, ${user.name}', style: AppStyles.h1),
            const SizedBox(height: 8),
            Text(
              state.hasLoggedToday
                  ? 'You have checked in today. Great job!'
                  : 'How are you feeling right now?',
              style: AppStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),

            // Streak & Progress UI
            if (insights != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: _StreakRingPainter(
                          streak: insights.currentStreak,
                          max: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Streak',
                            style: AppStyles.caption,
                          ),
                          Text(
                            '${insights.currentStreak} Days',
                            style: AppStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Best: ${insights.bestStreak} days',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.accent,
                      size: 32,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Breathing Exercise Widget
            const _BreathingWidget(),

            const SizedBox(height: 32),
            if (!state.hasLoggedToday)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EntryEditorScreen(),
                      fullscreenDialog: true,
                    ),
                  ),
                  child: const Text(
                    'LOG YOUR MOOD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: Text(
                  "All caught up for today! You can still add more notes.",
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _StreakRingPainter extends CustomPainter {
  final int streak;
  final int max;
  _StreakRingPainter({required this.streak, required this.max});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final bgPaint = Paint()
      ..color = AppColors.surfaceHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    final progress = (streak / max).clamp(0.0, 1.0);
    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '🔥\n$streak',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
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
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BreathingWidget extends StatefulWidget {
  const _BreathingWidget();
  @override
  State<_BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<_BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    // 4s in, 4s out
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed)
              _ctrl.reverse();
            else if (status == AnimationStatus.dismissed && _isActive)
              _ctrl.forward();
          });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isActive = !_isActive);
    if (_isActive)
      _ctrl.forward();
    else
      _ctrl.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Take a Breath', style: AppStyles.h2),
              IconButton(
                icon: Icon(
                  _isActive ? Icons.stop_circle : Icons.play_circle,
                  color: AppColors.accent,
                  size: 32,
                ),
                onPressed: _toggle,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (ctx, child) {
                final val = _ctrl.value; // 0 to 1
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80 + (70 * val),
                      height: 80 + (70 * val),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withOpacity(0.2),
                      ),
                    ),
                    Container(
                      width: 60 + (40 * val),
                      height: 60 + (40 * val),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withOpacity(0.4),
                      ),
                    ),
                    Text(
                      _isActive ? (val > 0.5 ? 'EXHALE' : 'INHALE') : 'READY',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. JOURNAL EDITOR SCREEN (Multi-Step Wizard)
// ============================================================================

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({Key? key}) : super(key: key);
  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final _noteCtrl = TextEditingController();
  Mood? _selectedMood;
  final Set<ActivityTag> _selectedTags = {};

  void _save(AppState state) async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await state.saveEntry(
      _selectedMood!,
      _selectedTags,
      _noteCtrl.text,
    );
    if (success && mounted)
      Navigator.pop(context);
    else if (mounted && state.globalError != null)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.globalError!),
          backgroundColor: AppColors.error,
        ),
      );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final bgColor = _selectedMood != null
        ? AppColors.getMoodColor(_selectedMood!).withOpacity(0.05)
        : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Entry'),
        actions: [
          TextButton(
            onPressed: state.isGlobalLoading ? null : () => _save(state),
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('How are you feeling?', style: AppStyles.h2),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: Mood.values
                    .map(
                      (m) => GestureDetector(
                        onTap: () => setState(() => _selectedMood = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedMood == m
                                ? AppColors.getMoodColor(m).withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedMood == m
                                  ? AppColors.getMoodColor(m)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            AppColors.getMoodIcon(m),
                            size: 40,
                            color: AppColors.getMoodColor(m),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 48),
              const Text('What affected your mood?', style: AppStyles.h2),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ActivityTag.values.map((t) {
                  final isSelected = _selectedTags.contains(t);
                  return FilterChip(
                    label: Text(t.name.toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) => setState(
                      () =>
                          val ? _selectedTags.add(t) : _selectedTags.remove(t),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 48),
              const Text('Private Notes', style: AppStyles.h2),
              const SizedBox(height: 16),
              TextField(
                controller: _noteCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText:
                      'Write your thoughts here. They are securely encrypted...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          if (state.isGlobalLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 11. TIMELINE SCREEN
// ============================================================================

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final entries = state.filteredEntries;

    return Scaffold(
      appBar: AppBar(title: const Text('Journal History')),
      body: Column(
        children: [
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MoodFilterChip(
                  label: 'All',
                  isSelected: state.filterMood == null,
                  onTap: () => state.setFilter(null),
                  color: AppColors.textMuted,
                ),
                ...Mood.values
                    .map(
                      (m) => _MoodFilterChip(
                        label: m.name.toUpperCase(),
                        isSelected: state.filterMood == m,
                        color: AppColors.getMoodColor(m),
                        onTap: () => state.setFilter(m),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),

          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'No journal entries found.',
                      style: AppStyles.body,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) => _JournalCard(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoodFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _MoodFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceHighlight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  const _JournalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final mColor = AppColors.getMoodColor(entry.mood);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: mColor, width: 6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppColors.getMoodIcon(entry.mood), color: mColor),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatters.dateFull(entry.timestamp),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  DateFormatters.time(entry.timestamp),
                  style: AppStyles.caption,
                ),
              ],
            ),
            if (entry.activities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.activities
                    .map(
                      (a) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              entry.privateNote,
              style: AppStyles.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 12. INSIGHTS & ANALYTICS SCREEN (Custom Charts)
// ============================================================================

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final insights = state.insights;
    if (insights == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Prepare data for the 7-day trend chart
    final List<JournalEntry> recent = state.entries
        .take(7)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Insights')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Mood Trend (Last 7 Entries)', style: AppStyles.h2),
          const SizedBox(height: 24),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceHighlight),
            ),
            child: CustomPaint(painter: _MoodTrendPainter(entries: recent)),
          ),
          const SizedBox(height: 48),

          const Text('What influences your mood?', style: AppStyles.h2),
          const SizedBox(height: 8),
          const Text('Based on your 90-day history', style: AppStyles.caption),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CorrelationCard(
                  title: 'Lifts you up',
                  icon: Icons.arrow_upward,
                  color: AppColors.success,
                  tags: insights.positiveCorrelations,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CorrelationCard(
                  title: 'Brings you down',
                  icon: Icons.arrow_downward,
                  color: AppColors.error,
                  tags: insights.negativeCorrelations,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          const Text('Mood Distribution', style: AppStyles.h2),
          const SizedBox(height: 24),
          ...Mood.values.reversed.map((m) {
            int count = insights.moodDistribution[m] ?? 0;
            int total = state.entries.length;
            double pct = total == 0 ? 0 : count / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(
                    AppColors.getMoodIcon(m),
                    color: AppColors.getMoodColor(m),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.surfaceHighlight,
                      color: AppColors.getMoodColor(m),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

class _CorrelationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<ActivityTag> tags;
  const _CorrelationCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tags.isEmpty)
            const Text('Not enough data.', style: AppStyles.caption)
          else
            ...tags
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.name.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}

// --- CUSTOM MOOD TREND CHART PAINTER ---

class _MoodTrendPainter extends CustomPainter {
  final List<JournalEntry> entries;
  _MoodTrendPainter({required this.entries});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    // Y Axis: Mood 1-5
    final double stepX =
        size.width / (entries.length == 1 ? 1 : entries.length - 1);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = AppColors.surfaceHighlight
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      double y = i * (size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    List<Offset> points = [];

    for (int i = 0; i < entries.length; i++) {
      double x = i * stepX;
      // Mood is 1-5. 5 is top (Y=0), 1 is bottom (Y=height)
      double normalizedY = (5 - entries[i].moodScore) / 4.0;
      double y = normalizedY * size.height;
      points.add(Offset(x, y));
    }

    // Bezier Curves
    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(size.width, points[0].dy);
    } else {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }
    }

    // Line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Points
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points.length; i++) {
      dotPaint.color = AppColors.getMoodColor(entries[i].mood);
      canvas.drawCircle(points[i], 8, dotPaint);
      canvas.drawCircle(points[i], 8, strokePaint);

      // X-Axis Date labels
      tp.text = TextSpan(
        text: DateFormatters.dayName(entries[i].timestamp).substring(0, 3),
        style: AppStyles.caption.copyWith(fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height + 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
