import 'dart:async';
import 'dart:math' as math;
// removed unused import 'dart:ui'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Local DateUtilsFormatter (file-scoped) to avoid external helpers
class DateUtilsFormatter {
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
  static String format(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';
}

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum CourseLevel { beginner, intermediate, advanced }

enum LessonType { video, reading, quiz }

enum ProgressStatus { locked, notStarted, inProgress, completed }

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700

  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color accent = Color(0xFF06B6D4); // Cyan 500

  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color gold = Color(0xFFFBBF24); // Certificate Gold
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
// 2. EXCEPTIONS & UTILITIES
// ============================================================================

abstract class LmsException implements Exception {
  final String message;
  LmsException(this.message);
  @override
  String toString() => message;
}

class PrerequisiteException extends LmsException {
  PrerequisiteException([String m = "Complete previous lessons first."])
    : super(m);
}

class NetworkException extends LmsException {
  NetworkException([String m = "Network timeout."]) : super(m);
}

class FormatUtils {
  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
}

class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}

class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final LessonType type;
  final int durationMinutes;
  final String contentUrl; // Video URL or Reading text body
  final List<QuizQuestion> quizQuestions;
  final String? prerequisiteLessonId;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.type,
    required this.durationMinutes,
    required this.contentUrl,
    this.quizQuestions = const [],
    this.prerequisiteLessonId,
  });
}

class Module {
  final String id;
  final String courseId;
  final String title;
  final int orderIndex;
  final List<Lesson> lessons;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
    required this.lessons,
  });
}

class Course {
  final String id;
  final String title;
  final String instructor;
  final String description;
  final String thumbnailUrl;
  final CourseLevel level;
  final List<Module> modules;

  Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.description,
    required this.thumbnailUrl,
    required this.level,
    required this.modules,
  });

  int get totalLessons => modules.fold(0, (sum, m) => sum + m.lessons.length);
  int get totalMinutes => modules.fold(
    0,
    (sum, m) => sum + m.lessons.fold(0, (s, l) => s + l.durationMinutes),
  );
}

class CourseProgress {
  final String userId;
  final String courseId;
  final Map<String, ProgressStatus> lessonStatuses; // LessonID -> Status
  final Map<String, int> quizScores; // LessonID -> Score (%)
  final DateTime startedAt;
  DateTime? completedAt;

  CourseProgress({
    required this.userId,
    required this.courseId,
    required this.lessonStatuses,
    required this.quizScores,
    required this.startedAt,
    this.completedAt,
  });

  double get overallProgress {
    if (lessonStatuses.isEmpty) return 0.0;
    int completed = lessonStatuses.values
        .where((s) => s == ProgressStatus.completed)
        .length;
    return completed / lessonStatuses.length;
  }

  bool get isCourseComplete => overallProgress == 1.0;
}

// ============================================================================
// 4. MOCK BACKEND ENGINE & ALGORITHMS
// ============================================================================

class MockLmsEngine {
  static final MockLmsEngine _instance = MockLmsEngine._internal();
  factory MockLmsEngine() => _instance;

  final math.Random _random = math.Random();
  final List<Course> _courses = [];
  final Map<String, CourseProgress> _progressDb = {}; // Key: "UserID_CourseID"

  MockLmsEngine._internal() {
    _seedData();
  }

  void _seedData() {
    // Seed Flutter Course
    final m1l1 = Lesson(
      id: 'FL_M1_L1',
      moduleId: 'FL_M1',
      title: 'Introduction to Flutter',
      type: LessonType.video,
      durationMinutes: 12,
      contentUrl: 'https://example.com/vid1',
    );
    final m1l2 = Lesson(
      id: 'FL_M1_L2',
      moduleId: 'FL_M1',
      title: 'Setting up the Environment',
      type: LessonType.reading,
      durationMinutes: 15,
      contentUrl: 'To setup Flutter, you need the SDK...',
      prerequisiteLessonId: 'FL_M1_L1',
    );
    final m1l3 = Lesson(
      id: 'FL_M1_L3',
      moduleId: 'FL_M1',
      title: 'Module 1 Quiz',
      type: LessonType.quiz,
      durationMinutes: 10,
      contentUrl: '',
      prerequisiteLessonId: 'FL_M1_L2',
      quizQuestions: [
        QuizQuestion(
          id: 'Q1',
          questionText: 'Which language does Flutter use?',
          options: ['Java', 'Dart', 'Kotlin', 'Swift'],
          correctOptionIndex: 1,
        ),
        QuizQuestion(
          id: 'Q2',
          questionText: 'What is the command to create a new project?',
          options: [
            'flutter start',
            'flutter init',
            'flutter create',
            'flutter new',
          ],
          correctOptionIndex: 2,
        ),
      ],
    );
    final m1 = Module(
      id: 'FL_M1',
      courseId: 'C_FL',
      title: 'Getting Started',
      orderIndex: 1,
      lessons: [m1l1, m1l2, m1l3],
    );

    final m2l1 = Lesson(
      id: 'FL_M2_L1',
      moduleId: 'FL_M2',
      title: 'Everything is a Widget',
      type: LessonType.video,
      durationMinutes: 20,
      contentUrl: 'https://example.com/vid2',
      prerequisiteLessonId: 'FL_M1_L3',
    );
    final m2 = Module(
      id: 'FL_M2',
      courseId: 'C_FL',
      title: 'Core Concepts',
      orderIndex: 2,
      lessons: [m2l1],
    );

    final c1 = Course(
      id: 'C_FL',
      title: 'Flutter & Dart Masterclass',
      instructor: 'Dr. Angela Yu',
      description:
          'A complete guide to the Flutter SDK and Dart programming language for building beautiful iOS and Android apps.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1617042375876-a13e36732a04?auto=format&fit=crop&w=800&q=80',
      level: CourseLevel.beginner,
      modules: [m1, m2],
    );

    // Seed UI/UX Course
    final ux1 = Lesson(
      id: 'UX_M1_L1',
      moduleId: 'UX_M1',
      title: 'Color Theory Basics',
      type: LessonType.reading,
      durationMinutes: 25,
      contentUrl: 'Colors evoke emotion...',
    );
    final uxm1 = Module(
      id: 'UX_M1',
      courseId: 'C_UX',
      title: 'Foundations',
      orderIndex: 1,
      lessons: [ux1],
    );
    final c2 = Course(
      id: 'C_UX',
      title: 'Advanced UI/UX Principles',
      instructor: 'Gary Simon',
      description: 'Learn how to design systems that scale.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1561070791-2526d30994b5?auto=format&fit=crop&w=800&q=80',
      level: CourseLevel.advanced,
      modules: [uxm1],
    );

    _courses.addAll([c1, c2]);
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(300)));

  // --- API Methods ---
  Future<User> login() async {
    await _latency(800);
    return User(
      id: 'U_1',
      name: 'Alex Student',
      email: 'alex@learning.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=u1',
    );
  }

  Future<List<Course>> getCourses() async {
    await _latency();
    return List.from(_courses);
  }

  Future<CourseProgress> getProgress(String userId, String courseId) async {
    await _latency(200);
    final key = '${userId}_$courseId';
    if (!_progressDb.containsKey(key)) {
      // Initialize fresh progress
      final course = _courses.firstWhere((c) => c.id == courseId);
      final statuses = <String, ProgressStatus>{};
      for (var m in course.modules) {
        for (var l in m.lessons) {
          // Unlocked if no prereq, else locked
          statuses[l.id] = l.prerequisiteLessonId == null
              ? ProgressStatus.notStarted
              : ProgressStatus.locked;
        }
      }
      _progressDb[key] = CourseProgress(
        userId: userId,
        courseId: courseId,
        lessonStatuses: statuses,
        quizScores: {},
        startedAt: DateTime.now(),
      );
    }
    return _progressDb[key]!;
  }

  /// Atomic update engine that cascades unlocks based on prerequisites
  Future<void> completeLesson(
    String userId,
    String courseId,
    String lessonId, {
    int? quizScore,
  }) async {
    await _latency(600);
    final key = '${userId}_$courseId';
    final prog = _progressDb[key];
    if (prog == null) throw Exception("Progress record not found.");
    // Check if it's already complete
    if (prog.lessonStatuses[lessonId] == ProgressStatus.completed) return;

    // Save Score if Quiz
    if (quizScore != null) {
      if (quizScore < 80) {
        throw Exception(
          "You scored $quizScore%. A minimum of 80% is required to pass.",
        );
      }
      prog.quizScores[lessonId] = quizScore;
    }

    // Mark Complete
    prog.lessonStatuses[lessonId] = ProgressStatus.completed;

    // Cascading Unlock Logic
    final course = _courses.firstWhere((c) => c.id == courseId);
    for (var m in course.modules) {
      for (var l in m.lessons) {
        if (l.prerequisiteLessonId == lessonId &&
            prog.lessonStatuses[l.id] == ProgressStatus.locked) {
          prog.lessonStatuses[l.id] = ProgressStatus.notStarted; // Unlock!
        }
      }
    }

    // Check Course Completion
    if (prog.overallProgress == 1.0 && prog.completedAt == null) {
      prog.completedAt = DateTime.now();
    }
  }

  Future<List<Course>> getMyCourses(String userId) async {
    await _latency();
    final activeIds = _progressDb.values
        .where((p) => p.userId == userId)
        .map((p) => p.courseId)
        .toSet();
    return _courses.where((c) => activeIds.contains(c.id)).toList();
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockLmsEngine _api = MockLmsEngine();

  User? currentUser;
  bool isGlobalLoading = true;
  String? globalError;

  List<Course> allCourses = [];
  List<Course> myCourses = [];

  // Active View State
  Course? activeCourse;
  CourseProgress? activeProgress;

  AppState() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      currentUser = await _api.login();
      allCourses = await _api.getCourses();
      myCourses = await _api.getMyCourses(currentUser!.id);
    } catch (e) {
      globalError = "Failed to load platform data.";
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  void _setError(String? e) {
    globalError = e;
    notifyListeners();
  }

  Future<void> enrollAndOpen(Course c) async {
    isGlobalLoading = true;
    notifyListeners();
    try {
      activeCourse = c;
      activeProgress = await _api.getProgress(currentUser!.id, c.id);
      // Refresh My Courses if new enrollment
      if (!myCourses.any((mc) => mc.id == c.id)) {
        myCourses = await _api.getMyCourses(currentUser!.id);
      }
    } catch (e) {
      _setError("Failed to open course.");
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeLesson(String lessonId, {int? score}) async {
    if (activeCourse == null || activeProgress == null) return false;
    _setError(null);
    try {
      await _api.completeLesson(
        currentUser!.id,
        activeCourse!.id,
        lessonId,
        quizScore: score,
      );
      // Re-fetch progress to get new unlocks
      activeProgress = await _api.getProgress(
        currentUser!.id,
        activeCourse!.id,
      );
      notifyListeners();
      return true;
    } on LmsException catch (e) {
      _setError(e.message);
      return false;
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
  runApp(const LearningApp());
}

class LearningApp extends StatelessWidget {
  const LearningApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus LMS',
        debugShowCheckedModeBanner: false,
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
    if (state.isGlobalLoading && state.currentUser == null)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
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
    const CatalogScreen(),
    const MyLearningScreen(),
    const SettingsScreen(),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'My Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. CATALOG / DISCOVER SCREEN
// ============================================================================

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'N E X U S',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(state.currentUser!.avatarUrl),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'What do you want to learn today, ${state.currentUser!.name.split(' ')[0]}?',
            style: AppStyles.h2,
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search courses, skills, instructors...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Featured Courses', style: AppStyles.h3),
          const SizedBox(height: 16),
          ...state.allCourses.map((c) => _CourseCard(course: c)).toList(),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context, listen: false);

    return GestureDetector(
      onTap: () async {
        await state.enrollAndOpen(course);
        if (context.mounted)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CourseViewerScreen()),
          );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                course.thumbnailUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.level.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Text(
                        '${FormatUtils.duration(course.totalMinutes)} • ${course.totalLessons} Lessons',
                        style: AppStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(course.title, style: AppStyles.h3),
                  const SizedBox(height: 4),
                  Text('By ${course.instructor}', style: AppStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. MY LEARNING DASHBOARD
// ============================================================================

class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Learning')),
      body: state.myCourses.isEmpty
          ? const Center(
              child: Text(
                'You are not enrolled in any courses yet.',
                style: AppStyles.body,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: state.myCourses.length,
              itemBuilder: (ctx, i) {
                final course = state.myCourses[i];
                return _CourseCard(
                  course: course,
                ); // Reuse card, in prod we'd show a progress bar version
              },
            ),
    );
  }
}

// ============================================================================
// 9. COURSE VIEWER (Progress, Modules, Lessons)
// ============================================================================

class CourseViewerScreen extends StatelessWidget {
  const CourseViewerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final course = state.activeCourse!;
    final prog = state.activeProgress!;

    return Scaffold(
      appBar: AppBar(title: const Text('Course Content')),
      body: state.isGlobalLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(course.title, style: AppStyles.h2),
                const SizedBox(height: 16),

                // Overall Progress Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Overall Progress', style: AppStyles.h3),
                          Text(
                            '${(prog.overallProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: prog.overallProgress,
                          backgroundColor: AppColors.background,
                          color: prog.isCourseComplete
                              ? AppColors.success
                              : AppColors.primary,
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Modules List
                ...course.modules
                    .map((m) => _ModuleExpansionTile(module: m, progress: prog))
                    .toList(),
                const SizedBox(height: 48),

                // Certificate Action
                if (prog.isCourseComplete)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CertificateScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text(
                        'VIEW CERTIFICATE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ModuleExpansionTile extends StatelessWidget {
  final Module module;
  final CourseProgress progress;
  const _ModuleExpansionTile({required this.module, required this.progress});

  @override
  Widget build(BuildContext context) {
    int completedInMod = module.lessons
        .where((l) => progress.lessonStatuses[l.id] == ProgressStatus.completed)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            'Module ${module.orderIndex}: ${module.title}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            '$completedInMod / ${module.lessons.length} Completed',
            style: AppStyles.caption,
          ),
          children: module.lessons
              .map(
                (l) => _LessonTile(
                  lesson: l,
                  status: progress.lessonStatuses[l.id]!,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final ProgressStatus status;
  const _LessonTile({required this.lesson, required this.status});

  void _handleTap(BuildContext context) {
    if (status == ProgressStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete prerequisites first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (lesson.type == LessonType.quiz) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizEngineScreen(lesson: lesson)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ContentPlayerScreen(lesson: lesson)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData ic;
    Color c;
    if (status == ProgressStatus.locked) {
      ic = Icons.lock;
      c = AppColors.textMuted;
    } else if (status == ProgressStatus.completed) {
      ic = Icons.check_circle;
      c = AppColors.success;
    } else {
      c = AppColors.primary;
      ic = lesson.type == LessonType.video
          ? Icons.play_circle
          : (lesson.type == LessonType.reading
                ? Icons.article
                : Icons.assignment);
    }

    return ListTile(
      onTap: () => _handleTap(context),
      leading: Icon(ic, color: c),
      title: Text(
        lesson.title,
        style: TextStyle(
          color: status == ProgressStatus.locked
              ? AppColors.textMuted
              : AppColors.textMain,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            FormatUtils.duration(lesson.durationMinutes),
            style: AppStyles.caption,
          ),
          const SizedBox(width: 12),
          Text(
            lesson.type.name.toUpperCase(),
            style: AppStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. CONTENT PLAYER (Video/Reading)
// ============================================================================

class ContentPlayerScreen extends StatelessWidget {
  final Lesson lesson;
  const ContentPlayerScreen({Key? key, required this.lesson}) : super(key: key);

  void _markComplete(BuildContext context, AppState state) async {
    final success = await state.completeLesson(lesson.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completed: ${lesson.title}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final isCompleted =
        state.activeProgress!.lessonStatuses[lesson.id] ==
        ProgressStatus.completed;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: Column(
        children: [
          // Mock Video Player / Content Header
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: Icon(
              lesson.type == LessonType.video
                  ? Icons.play_circle_outline
                  : Icons.menu_book,
              size: 80,
              color: Colors.white54,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lesson Overview', style: AppStyles.h2),
                  const SizedBox(height: 16),
                  Text(
                    'In this lesson we will cover: ${lesson.title}. Pay close attention to the concepts as they build upon each other in future modules.',
                    style: AppStyles.body,
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? AppColors.surfaceHighlight
                        : AppColors.success,
                  ),
                  onPressed: isCompleted || state.isGlobalLoading
                      ? null
                      : () => _markComplete(context, state),
                  icon: Icon(isCompleted ? Icons.check : Icons.done_all),
                  label: Text(
                    isCompleted ? 'ALREADY COMPLETED' : 'MARK AS COMPLETE',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

// ============================================================================
// 11. QUIZ ENGINE SCREEN
// ============================================================================

class QuizEngineScreen extends StatefulWidget {
  final Lesson lesson;
  const QuizEngineScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuizEngineScreen> createState() => _QuizEngineScreenState();
}

class _QuizEngineScreenState extends State<QuizEngineScreen> {
  int _currentIndex = 0;
  final Map<String, int> _selectedAnswers = {}; // QuestionId -> OptionIndex
  bool _isSubmitted = false;

  void _submitQuiz(AppState state) async {
    // Grade it
    int correctCount = 0;
    for (var q in widget.lesson.quizQuestions) {
      if (_selectedAnswers[q.id] == q.correctOptionIndex) correctCount++;
    }
    int score = ((correctCount / widget.lesson.quizQuestions.length) * 100)
        .toInt();

    setState(() => _isSubmitted = true);

    if (score >= 80) {
      final success = await state.completeLesson(
        widget.lesson.id,
        score: score,
      );
      if (success && mounted) {
        _showResultDialog(true, score);
      }
    } else {
      if (mounted) _showResultDialog(false, score);
    }
  }

  void _showResultDialog(bool passed, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(passed ? 'Quiz Passed!' : 'Quiz Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.cancel,
              size: 80,
              color: passed ? AppColors.gold : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text('You scored $score%.', style: AppStyles.h2),
            const SizedBox(height: 8),
            Text(
              passed
                  ? 'Great job! You may proceed to the next lesson.'
                  : 'A minimum of 80% is required. Please review the material and try again.',
              textAlign: TextAlign.center,
              style: AppStyles.body,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to course viewer
            },
            child: Text(passed ? 'CONTINUE' : 'RETURN TO COURSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final questions = widget.lesson.quizQuestions;
    final currentQ = questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Assessment'),
        automaticallyImplyLeading: !_isSubmitted,
      ),
      body: _isSubmitted
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / questions.length,
                    backgroundColor: AppColors.surfaceHighlight,
                    color: AppColors.primary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Question ${_currentIndex + 1} of ${questions.length}',
                    style: AppStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(currentQ.questionText, style: AppStyles.h2),
                  const SizedBox(height: 48),

                  ...List.generate(currentQ.options.length, (idx) {
                    final isSelected = _selectedAnswers[currentQ.id] == idx;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedAnswers[currentQ.id] = idx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceHighlight,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                currentQ.options[idx],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex > 0)
                        OutlinedButton(
                          onPressed: () => setState(() => _currentIndex--),
                          child: const Text('PREVIOUS'),
                        )
                      else
                        const SizedBox(),
                      ElevatedButton(
                        onPressed:
                            !_selectedAnswers.containsKey(currentQ.id) ||
                                state.isGlobalLoading
                            ? null
                            : () {
                                if (_currentIndex < questions.length - 1) {
                                  setState(() => _currentIndex++);
                                } else {
                                  _submitQuiz(state);
                                }
                              },
                        child: Text(
                          _currentIndex < questions.length - 1
                              ? 'NEXT'
                              : 'SUBMIT QUIZ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
// 12. CERTIFICATE GENERATOR (Custom Painter)
// ============================================================================

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser!;
    final course = state.activeCourse!;
    final date = state.activeProgress!.completedAt ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Certificate')),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 1.414, // Standard certificate landscape ratio
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _CertificatePainter(
                    studentName: user.name,
                    courseName: course.title,
                    date: DateUtilsFormatter.format(date),
                    instructor: course.instructor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton.icon(
            onPressed: () {}, // In prod: export to PDF logic
            icon: const Icon(Icons.download),
            label: const Text('DOWNLOAD PDF'),
          ),
        ),
      ),
    );
  }
}

class _CertificatePainter extends CustomPainter {
  final String studentName;
  final String courseName;
  final String date;
  final String instructor;

  _CertificatePainter({
    required this.studentName,
    required this.courseName,
    required this.date,
    required this.instructor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Paper
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(bgRect, Paint()..color = const Color(0xFFF9FAFB));

    // 2. Ornate Border
    final borderPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawRect(bgRect.deflate(20), borderPaint);
    final innerBorder = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(bgRect.deflate(26), innerBorder);

    // 3. Corner Decorations (Triangles)
    final decoPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(20, 20)
        ..lineTo(60, 20)
        ..lineTo(20, 60)
        ..close(),
      decoPaint,
    ); // TL
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 20, 20)
        ..lineTo(size.width - 60, 20)
        ..lineTo(size.width - 20, 60)
        ..close(),
      decoPaint,
    ); // TR
    canvas.drawPath(
      Path()
        ..moveTo(20, size.height - 20)
        ..lineTo(60, size.height - 20)
        ..lineTo(20, size.height - 60)
        ..close(),
      decoPaint,
    ); // BL
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 20, size.height - 20)
        ..lineTo(size.width - 60, size.height - 20)
        ..lineTo(size.width - 20, size.height - 60)
        ..close(),
      decoPaint,
    ); // BR

    // 4. Texts
    final centerX = size.width / 2;

    _drawText(
      canvas,
      "CERTIFICATE OF COMPLETION",
      Offset(centerX, size.height * 0.15),
      fontSize: size.height * 0.08,
      color: AppColors.primaryDark,
      isBold: true,
    );
    _drawText(
      canvas,
      "THIS IS PROUDLY PRESENTED TO",
      Offset(centerX, size.height * 0.3),
      fontSize: size.height * 0.04,
      color: Colors.grey.shade700,
    );

    // Student Name
    _drawText(
      canvas,
      studentName.toUpperCase(),
      Offset(centerX, size.height * 0.45),
      fontSize: size.height * 0.1,
      color: AppColors.textMain,
      isBold: true,
      isSerif: true,
    );
    canvas.drawLine(
      Offset(centerX - size.width * 0.3, size.height * 0.52),
      Offset(centerX + size.width * 0.3, size.height * 0.52),
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 2,
    );

    _drawText(
      canvas,
      "For successfully completing the course",
      Offset(centerX, size.height * 0.6),
      fontSize: size.height * 0.04,
      color: Colors.grey.shade700,
    );
    _drawText(
      canvas,
      courseName,
      Offset(centerX, size.height * 0.7),
      fontSize: size.height * 0.06,
      color: AppColors.primaryDark,
      isBold: true,
    );

    // 5. Signatures & Dates (Bottom)
    final leftSigX = size.width * 0.25;
    final rightSigX = size.width * 0.75;
    final sigY = size.height * 0.85;

    _drawText(
      canvas,
      date,
      Offset(leftSigX, sigY),
      fontSize: size.height * 0.04,
      color: AppColors.textMain,
    );
    canvas.drawLine(
      Offset(leftSigX - 60, sigY + 10),
      Offset(leftSigX + 60, sigY + 10),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 1,
    );
    _drawText(
      canvas,
      "Date Completed",
      Offset(leftSigX, sigY + 25),
      fontSize: size.height * 0.03,
      color: Colors.grey.shade600,
    );

    // Fake cursive signature
    _drawText(
      canvas,
      instructor,
      Offset(rightSigX, sigY),
      fontSize: size.height * 0.05,
      color: Colors.blue.shade900,
      isSerif: true,
      isItalic: true,
    );
    canvas.drawLine(
      Offset(rightSigX - 80, sigY + 10),
      Offset(rightSigX + 80, sigY + 10),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 1,
    );
    _drawText(
      canvas,
      "Instructor Signature",
      Offset(rightSigX, sigY + 25),
      fontSize: size.height * 0.03,
      color: Colors.grey.shade600,
    );

    // 6. Wax Seal (Center Bottom)
    final sealCenter = Offset(centerX, size.height * 0.88);
    canvas.drawCircle(
      sealCenter,
      40,
      Paint()
        ..color = AppColors.gold
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );
    canvas.drawCircle(sealCenter, 30, Paint()..color = Colors.amber.shade600);
    _drawText(
      canvas,
      "★\nNEXUS\n★",
      sealCenter,
      fontSize: 10,
      color: Colors.white,
      isBold: true,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    bool isBold = false,
    bool isSerif = false,
    bool isItalic = false,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      fontFamily: isSerif
          ? 'Times New Roman'
          : 'Roboto', // Fallbacks handled by Flutter
    );
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 13. SETTINGS PLACEHOLDER
// ============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: const Center(child: Text('User Profile & Preferences')),
    );
  }
}
