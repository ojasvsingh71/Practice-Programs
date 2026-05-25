import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEMING
// ============================================================================

enum UserRole { student, professor, admin }

enum CourseStatus { open, waitlisted, closed }

enum RegistrationStatus { enrolled, dropped, completed, failed }

enum Grade { A, B, C, D, F, none }

class AppColors {
  static const Color primary = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color primaryDark = Color(0xFF172554);
  static const Color accent = Color(0xFFF59E0B); // University Gold
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

class AppTypography {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
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
// 2. EXCEPTIONS & UTILS
// ============================================================================

abstract class PortalException implements Exception {
  final String message;
  PortalException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends PortalException {
  NetworkException([String m = "Network timeout. Connection lost."]) : super(m);
}

class AuthException extends PortalException {
  AuthException([String m = "Invalid credentials."]) : super(m);
}

class PrerequisiteException extends PortalException {
  PrerequisiteException(String m) : super(m);
}

class CapacityException extends PortalException {
  CapacityException([String m = "Course is at maximum capacity."]) : super(m);
}

class ConflictException extends PortalException {
  ConflictException([String m = "Schedule conflict detected."]) : super(m);
}

class DateFormatter {
  static String format(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

abstract class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });
  String get fullName => '$firstName $lastName';
}

class Student extends User {
  final String major;
  final int enrollmentYear;
  final double gpa;

  Student({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required this.major,
    required this.enrollmentYear,
    required this.gpa,
  }) : super(
         id: id,
         firstName: firstName,
         lastName: lastName,
         email: email,
         role: UserRole.student,
       );
}

class Professor extends User {
  final String department;
  final String title;

  Professor({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required this.department,
    required this.title,
  }) : super(
         id: id,
         firstName: firstName,
         lastName: lastName,
         email: email,
         role: UserRole.professor,
       );
}

class Course {
  final String id;
  final String code; // e.g., CS101
  final String title;
  final String description;
  final String professorId;
  final int credits;
  final int capacity;
  int enrolledCount;
  final List<String> prerequisites; // Course IDs
  final String schedule; // e.g., "Mon/Wed 10:00 AM"

  Course({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.professorId,
    required this.credits,
    required this.capacity,
    this.enrolledCount = 0,
    this.prerequisites = const [],
    required this.schedule,
  });

  CourseStatus get status {
    if (enrolledCount >= capacity) return CourseStatus.closed;
    if (enrolledCount >= capacity * 0.9) return CourseStatus.waitlisted;
    return CourseStatus.open;
  }
}

class RegistrationRecord {
  final String id;
  final String studentId;
  final String courseId;
  RegistrationStatus status;
  Grade grade;
  final DateTime timestamp;

  RegistrationRecord({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.status = RegistrationStatus.enrolled,
    this.grade = Grade.none,
    required this.timestamp,
  });
}

class AttendanceRecord {
  final String id;
  final String courseId;
  final String studentId;
  final DateTime date;
  bool isPresent;

  AttendanceRecord({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.date,
    this.isPresent = false,
  });
}

// ============================================================================
// 4. MOCK BACKEND ENGINE & ASYNC LOGIC
// ============================================================================

class MockUniversityBackend {
  static final MockUniversityBackend _instance =
      MockUniversityBackend._internal();
  factory MockUniversityBackend() => _instance;
  MockUniversityBackend._internal() {
    _seedDatabase();
  }

  final math.Random _random = math.Random();

  // Simulated Database Tables
  final Map<String, User> _users = {};
  final Map<String, Course> _courses = {};
  final List<RegistrationRecord> _registrations = [];
  final List<AttendanceRecord> _attendance = [];

  bool simulateNetworkDrops = true; // Toggle for testing retry logic

  // Public unnamed constructor removed; seeding moved to `_internal()`.

  void _seedDatabase() {
    // 1. Seed Users
    final prof1 = Professor(
      id: 'P_1',
      firstName: 'Alan',
      lastName: 'Turing',
      email: 'aturing@univ.edu',
      department: 'Computer Science',
      title: 'Dr.',
    );
    final prof2 = Professor(
      id: 'P_2',
      firstName: 'Marie',
      lastName: 'Curie',
      email: 'mcurie@univ.edu',
      department: 'Physics',
      title: 'Prof.',
    );

    final stud1 = Student(
      id: 'S_1',
      firstName: 'Alex',
      lastName: 'Student',
      email: 'alex@univ.edu',
      major: 'Software Engineering',
      enrollmentYear: 2024,
      gpa: 3.8,
    );

    _users.addAll({prof1.id: prof1, prof2.id: prof2, stud1.id: stud1});

    // 2. Seed Courses
    final c1 = Course(
      id: 'C_1',
      code: 'CS101',
      title: 'Introduction to Programming',
      description: 'Fundamentals of logic and syntax.',
      professorId: 'P_1',
      credits: 3,
      capacity: 50,
      enrolledCount: 45,
      schedule: 'Mon/Wed 09:00 AM',
    );
    final c2 = Course(
      id: 'C_2',
      code: 'CS201',
      title: 'Data Structures',
      description: 'Advanced memory management and algorithms.',
      professorId: 'P_1',
      credits: 4,
      capacity: 30,
      enrolledCount: 12,
      prerequisites: ['C_1'],
      schedule: 'Tue/Thu 11:00 AM',
    );
    final c3 = Course(
      id: 'C_3',
      code: 'CS301',
      title: 'Operating Systems',
      description: 'Kernel architecture and concurrency.',
      professorId: 'P_1',
      credits: 4,
      capacity: 5,
      enrolledCount: 5,
      prerequisites: ['C_2'],
      schedule: 'Mon/Wed 02:00 PM',
    ); // Full capacity
    final c4 = Course(
      id: 'C_4',
      code: 'PHY101',
      title: 'Quantum Mechanics I',
      description: 'Wave functions and probability.',
      professorId: 'P_2',
      credits: 3,
      capacity: 40,
      enrolledCount: 38,
      schedule: 'Fri 10:00 AM',
    );

    _courses.addAll({c1.id: c1, c2.id: c2, c3.id: c3, c4.id: c4});

    // 3. Seed Historical Registrations (to satisfy prerequisites)
    _registrations.add(
      RegistrationRecord(
        id: 'REG_OLD1',
        studentId: 'S_1',
        courseId: 'C_1',
        status: RegistrationStatus.completed,
        grade: Grade.A,
        timestamp: DateTime.now().subtract(const Duration(days: 180)),
      ),
    );
  }

  /// Simulates network latency and random drops
  Future<void> _simulateNetwork([int ms = 800]) async {
    await Future.delayed(Duration(milliseconds: ms + _random.nextInt(500)));
    if (simulateNetworkDrops && _random.nextDouble() < 0.35) {
      throw NetworkException();
    }
  }

  // --- Auth API ---
  Future<User> login(String email, String password) async {
    await _simulateNetwork(1000);
    if (email.isEmpty) throw AuthException();
    final user = _users.values.firstWhere(
      (u) => u.email == email,
      orElse: () => throw AuthException('User not found in system.'),
    );
    return user;
  }

  // --- Data Fetching API ---
  Future<List<Course>> getAvailableCourses() async {
    await _simulateNetwork();
    return _courses.values.toList();
  }

  Future<List<RegistrationRecord>> getStudentRegistrations(
    String studentId,
  ) async {
    await _simulateNetwork();
    return _registrations.where((r) => r.studentId == studentId).toList();
  }

  Future<List<Course>> getProfessorCourses(String profId) async {
    await _simulateNetwork();
    return _courses.values.where((c) => c.professorId == profId).toList();
  }

  Future<List<Student>> getEnrolledStudents(String courseId) async {
    await _simulateNetwork();
    final studentIds = _registrations
        .where(
          (r) =>
              r.courseId == courseId && r.status == RegistrationStatus.enrolled,
        )
        .map((r) => r.studentId)
        .toSet();
    return _users.values
        .whereType<Student>()
        .where((s) => studentIds.contains(s.id))
        .toList();
  }

  // --- Registration Engine with Strict Validation ---
  Future<RegistrationRecord> registerForCourse(
    String studentId,
    String courseId,
  ) async {
    await _simulateNetwork(1500); // Heavy transaction

    final course = _courses[courseId];
    if (course == null) throw Exception("Course does not exist.");

    // 1. Capacity Check
    if (course.enrolledCount >= course.capacity) {
      throw CapacityException();
    }

    // 2. Duplicate Check
    final alreadyEnrolled = _registrations.any(
      (r) =>
          r.studentId == studentId &&
          r.courseId == courseId &&
          r.status == RegistrationStatus.enrolled,
    );
    if (alreadyEnrolled)
      throw Exception("You are already enrolled in this course.");

    // 3. Prerequisite Validation
    if (course.prerequisites.isNotEmpty) {
      for (final prereqId in course.prerequisites) {
        final passed = _registrations.any(
          (r) =>
              r.studentId == studentId &&
              r.courseId == prereqId &&
              r.status == RegistrationStatus.completed &&
              (r.grade == Grade.A || r.grade == Grade.B || r.grade == Grade.C),
        );
        if (!passed) {
          final prereqCourse = _courses[prereqId];
          throw PrerequisiteException(
            "Missing prerequisite: ${prereqCourse?.code ?? 'Unknown Course'}. Grade C or higher required.",
          );
        }
      }
    }

    // Process Transaction
    course.enrolledCount++;
    final record = RegistrationRecord(
      id: 'REG_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      courseId: courseId,
      status: RegistrationStatus.enrolled,
      timestamp: DateTime.now(),
    );
    _registrations.add(record);

    return record;
  }

  // --- Attendance Engine ---
  Future<List<AttendanceRecord>> getAttendanceForDate(
    String courseId,
    DateTime date,
  ) async {
    await _simulateNetwork();
    return _attendance
        .where(
          (a) =>
              a.courseId == courseId &&
              a.date.year == date.year &&
              a.date.month == date.month &&
              a.date.day == date.day,
        )
        .toList();
  }

  Future<void> submitAttendance(List<AttendanceRecord> records) async {
    await _simulateNetwork(1200); // Batch insert simulation
    for (var r in records) {
      final existingIdx = _attendance.indexWhere(
        (a) =>
            a.courseId == r.courseId &&
            a.studentId == r.studentId &&
            a.date.day == r.date.day,
      );
      if (existingIdx >= 0) {
        _attendance[existingIdx] = r;
      } else {
        _attendance.add(r);
      }
    }
  }

  User getUserById(String id) => _users[id]!;
  Course getCourseById(String id) => _courses[id]!;
}

// ============================================================================
// 5. STATE MANAGEMENT & RETRY WRAPPER
// ============================================================================

class AppState extends ChangeNotifier {
  final MockUniversityBackend _api = MockUniversityBackend();

  User? currentUser;
  bool isGlobalLoading = false;
  String? globalError;
  String? retryMessage; // Status for retry UI

  // Student State
  List<Course> availableCourses = [];
  List<RegistrationRecord> myRegistrations = [];

  // Professor State
  List<Course> teachingCourses = [];

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  void _setRetryMsg(String? msg) {
    retryMessage = msg;
    notifyListeners();
  }

  void toggleNetworkDrops(bool val) {
    _api.simulateNetworkDrops = val;
    notifyListeners();
  }

  bool get isSimulatingDrops => _api.simulateNetworkDrops;

  /// Generic Retry Wrapper with Exponential Backoff
  Future<T> _withRetry<T>(
    Future<T> Function() task, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (attempt < maxAttempts) {
      try {
        if (attempt > 0)
          _setRetryMsg(
            'Network unstable. Retrying (${attempt}/${maxAttempts - 1})...',
          );
        final result = await task();
        _setRetryMsg(null);
        return result;
      } on NetworkException {
        attempt++;
        if (attempt >= maxAttempts) {
          _setRetryMsg(null);
          throw NetworkException(
            "Connection failed after $maxAttempts attempts. Please try again later.",
          );
        }
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }
    throw NetworkException(); // Should not reach here
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      currentUser = await _withRetry(() => _api.login(email, password));
      await refreshDashboard();
    } on PortalException catch (e) {
      _setError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    currentUser = null;
    availableCourses.clear();
    myRegistrations.clear();
    teachingCourses.clear();
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    if (currentUser == null) return;
    try {
      if (currentUser!.role == UserRole.student) {
        final futures = await Future.wait([
          _withRetry(() => _api.getAvailableCourses()),
          _withRetry(() => _api.getStudentRegistrations(currentUser!.id)),
        ]);
        availableCourses = futures[0] as List<Course>;
        myRegistrations = futures[1] as List<RegistrationRecord>;
      } else {
        teachingCourses = await _withRetry(
          () => _api.getProfessorCourses(currentUser!.id),
        );
      }
      notifyListeners();
    } catch (e) {
      _setError("Failed to sync latest data.");
    }
  }

  Future<bool> enrollInCourse(String courseId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _withRetry(() => _api.registerForCourse(currentUser!.id, courseId));
      await refreshDashboard(); // Re-sync data
      return true;
    } on PortalException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Proxies for UI components
  Course getCourseDetails(String id) => _api.getCourseById(id);
  User getProfessorDetails(String id) => _api.getUserById(id);

  Future<List<Student>> fetchEnrolledStudents(String courseId) =>
      _withRetry(() => _api.getEnrolledStudents(courseId));
  Future<List<AttendanceRecord>> fetchAttendance(
    String courseId,
    DateTime date,
  ) => _withRetry(() => _api.getAttendanceForDate(courseId, date));
  Future<void> submitAttendance(List<AttendanceRecord> records) =>
      _withRetry(() => _api.submitAttendance(records));
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
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const UniversityPortalApp());
}

class UniversityPortalApp extends StatelessWidget {
  const UniversityPortalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus University',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        home: const RootRouter(),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.currentUser == null) return const LoginScreen();
    if (state.currentUser!.role == UserRole.student)
      return const StudentScaffold();
    return const ProfessorScaffold();
  }
}

// ============================================================================
// 7. LOGIN SCREEN
// ============================================================================

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 80,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'NEXUS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  'UNIVERSITY PORTAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 64),

                if (state.globalError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.globalError!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (state.retryMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.retryMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.school),
                  label: const Text(
                    'STUDENT LOGIN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: state.isGlobalLoading
                      ? null
                      : () => state.login('alex@univ.edu', 'password'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.co_present),
                  label: const Text(
                    'FACULTY LOGIN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: state.isGlobalLoading
                      ? null
                      : () => state.login('aturing@univ.edu', 'password'),
                ),
                const SizedBox(height: 48),
                _NetworkToggleWidget(), // Dev tool to test retries
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkToggleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Simulate Network Instability',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Switch(
            value: state.isSimulatingDrops,
            activeColor: AppColors.accent,
            onChanged: (val) => state.toggleNetworkDrops(val),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. STUDENT FLOW (Dashboard & Registration)
// ============================================================================

class StudentScaffold extends StatefulWidget {
  const StudentScaffold({Key? key}) : super(key: key);

  @override
  State<StudentScaffold> createState() => _StudentScaffoldState();
}

class _StudentScaffoldState extends State<StudentScaffold> {
  int _currentIndex = 0;
  final _screens = [const StudentDashboard(), const CourseCatalogScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'My Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Registration',
          ),
        ],
      ),
    );
  }
}

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser as Student;
    final activeRegs = state.myRegistrations
        .where((r) => r.status == RegistrationStatus.enrolled)
        .toList();
    final totalCredits = activeRegs.fold<int>(
      0,
      (sum, r) => sum + state.getCourseDetails(r.courseId).credits,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text(
                      '${user.major} • Class of ${user.enrollmentYear + 4}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    user.gpa.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Term',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spring 2026',
                        style: AppTypography.h2.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Credits Enrolled',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCredits / 18',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('My Schedule', style: AppTypography.h3),
            const SizedBox(height: 16),
            if (activeRegs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'You are not enrolled in any courses.',
                    style: AppTypography.body,
                  ),
                ),
              )
            else
              ...activeRegs.map((r) {
                final course = state.getCourseDetails(r.courseId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(course.schedule, style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class CourseCatalogScreen extends StatelessWidget {
  const CourseCatalogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final myCourseIds = state.myRegistrations
        .where((r) => r.status == RegistrationStatus.enrolled)
        .map((r) => r.courseId)
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Registration Portal')),
      body: Column(
        children: [
          // Retry Banner
          if (state.retryMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.warning,
              child: Text(
                state.retryMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // Error Banner
          if (state.globalError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.error,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.globalError!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => state._setError(null),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.availableCourses.length,
              itemBuilder: (context, index) {
                final course = state.availableCourses[index];
                final isEnrolled = myCourseIds.contains(course.id);
                return _CourseCatalogCard(
                  course: course,
                  isEnrolled: isEnrolled,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCatalogCard extends StatelessWidget {
  final Course course;
  final bool isEnrolled;
  const _CourseCatalogCard({required this.course, required this.isEnrolled});

  void _handleRegistration(BuildContext context, AppState state) async {
    final success = await state.enrollInCourse(course.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered for ${course.code}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final prof = state.getProfessorDetails(course.professorId);

    // Status UI setup
    Color statusColor;
    String statusText;
    switch (course.status) {
      case CourseStatus.open:
        statusColor = AppColors.success;
        statusText = 'OPEN';
        break;
      case CourseStatus.waitlisted:
        statusColor = AppColors.warning;
        statusText = 'WAITLIST';
        break;
      case CourseStatus.closed:
        statusColor = AppColors.error;
        statusText = 'CLOSED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: AppTypography.h3),
                const SizedBox(height: 4),
                Text(
                  'By ${prof.fullName} • ${course.credits} Credits',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),
                Text(course.description, style: AppTypography.body),
                const SizedBox(height: 16),

                // Meta info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.enrolledCount} / ${course.capacity}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (course.prerequisites.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Prereq: ${state.getCourseDetails(course.prerequisites.first).code}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Action Bar
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: isEnrolled
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                      label: const Text(
                        'ENROLLED',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.success),
                      ),
                    )
                  : ElevatedButton(
                      onPressed:
                          (course.status == CourseStatus.closed ||
                              state.isGlobalLoading)
                          ? null
                          : () => _handleRegistration(context, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'REGISTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

// ============================================================================
// 9. PROFESSOR FLOW (Dashboard & Attendance)
// ============================================================================

class ProfessorScaffold extends StatelessWidget {
  const ProfessorScaffold({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final prof = state.currentUser as Professor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('${prof.title} ${prof.lastName}', style: AppTypography.h1),
            Text(prof.department, style: AppTypography.caption),
            const SizedBox(height: 32),
            const Text('My Courses', style: AppTypography.h2),
            const SizedBox(height: 16),
            if (state.teachingCourses.isEmpty)
              const Text('No courses assigned for this term.')
            else
              ...state.teachingCourses
                  .map((c) => _ProfessorCourseCard(course: c))
                  .toList(),
          ],
        ),
      ),
    );
  }
}

class _ProfessorCourseCard extends StatelessWidget {
  final Course course;
  const _ProfessorCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${course.enrolledCount} Students',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(course.title, style: AppTypography.h3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceTrackerScreen(course: course),
                  ),
                ),
                child: const Text('MANAGE ATTENDANCE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceTrackerScreen extends StatefulWidget {
  final Course course;
  const AttendanceTrackerScreen({Key? key, required this.course})
    : super(key: key);

  @override
  State<AttendanceTrackerScreen> createState() =>
      _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  bool _isLoading = true;
  List<Student> _students = [];
  Map<String, bool> _attendanceMap = {}; // studentId -> isPresent
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final state = AppStore.of(context, listen: false);
    try {
      final futures = await Future.wait([
        state.fetchEnrolledStudents(widget.course.id),
        state.fetchAttendance(widget.course.id, _today),
      ]);

      final students = futures[0] as List<Student>;
      final existingRecords = futures[1] as List<AttendanceRecord>;

      final map = <String, bool>{};
      for (var s in students) {
        final existing = existingRecords.firstWhere(
          (r) => r.studentId == s.id,
          orElse: () => AttendanceRecord(
            id: '',
            courseId: '',
            studentId: '',
            date: _today,
            isPresent: false,
          ),
        );
        map[s.id] = existing.isPresent;
      }

      if (mounted) {
        setState(() {
          _students = students;
          _attendanceMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveAttendance() async {
    final state = AppStore.of(context, listen: false);

    final records = _attendanceMap.entries
        .map(
          (e) => AttendanceRecord(
            id: 'ATT_${widget.course.id}_${e.key}_${_today.millisecondsSinceEpoch}',
            courseId: widget.course.id,
            studentId: e.key,
            date: _today,
            isPresent: e.value,
          ),
        )
        .toList();

    try {
      await state.submitAttendance(records);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save. Retries exhausted.'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(
      context,
    ); // to listen to global loading/retry states

    return Scaffold(
      appBar: AppBar(title: Text('Attendance: ${widget.course.code}')),
      body: Column(
        children: [
          // Retry Banner from generic wrapper
          if (state.retryMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.warning,
              child: Text(
                state.retryMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date:', style: AppTypography.h3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormatter.format(_today),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                ? const Center(child: Text('No students enrolled yet.'))
                : ListView.separated(
                    itemCount: _students.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final isPresent = _attendanceMap[student.id] ?? false;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            student.firstName[0],
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                        title: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('ID: ${student.id} • ${student.major}'),
                        trailing: Switch(
                          value: isPresent,
                          activeColor: AppColors.success,
                          onChanged: (val) =>
                              setState(() => _attendanceMap[student.id] = val),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || state.isGlobalLoading)
                      ? null
                      : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: state.isGlobalLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SAVE ATTENDANCE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
