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
// 1. CONSTANTS, ENUMS, & THEME
// ============================================================================

enum UserRole { student, teacher }

enum QuestionType { multipleChoice, essay, boolean }

enum ExamStatus { notStarted, inProgress, submitted, graded }

enum EvaluationStatus { pending, autoGrading, awaitingManualReview, completed }

class AppTheme {
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryDark = Color(0xFF1E3A8A); // Blue 900
  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color background = Color(0xFFF3F4F6); // Gray 100
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF1F2937); // Gray 800
  static const Color textMuted = Color(0xFF6B7280); // Gray 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      cardColor: surface,
    );
  }
}

// ============================================================================
// 2. DOMAIN MODELS (POLYMORPHIC QUESTIONS)
// ============================================================================

class User {
  final String id;
  final String name;
  final UserRole role;
  User({required this.id, required this.name, required this.role});
}

/// Base class for all questions. Encapsulates common metadata.
abstract class Question {
  final String id;
  final String text;
  final double maxPoints;
  final QuestionType type;

  Question({
    required this.id,
    required this.text,
    required this.maxPoints,
    required this.type,
  });

  /// Abstract method: determines if this question can be graded instantly by the engine
  bool get isAutoGradable;

  /// Abstract method: performs the evaluation. Returns points earned.
  double evaluate(dynamic studentAnswer);
}

class MultipleChoiceQuestion extends Question {
  final List<String> options;
  final int correctOptionIndex;

  MultipleChoiceQuestion({
    required String id,
    required String text,
    required double maxPoints,
    required this.options,
    required this.correctOptionIndex,
  }) : super(
         id: id,
         text: text,
         maxPoints: maxPoints,
         type: QuestionType.multipleChoice,
       );

  @override
  bool get isAutoGradable => true;

  @override
  double evaluate(dynamic studentAnswer) {
    if (studentAnswer == null || studentAnswer is! int) return 0.0;
    return studentAnswer == correctOptionIndex ? maxPoints : 0.0;
  }
}

class EssayQuestion extends Question {
  final String gradingRubric;

  EssayQuestion({
    required String id,
    required String text,
    required double maxPoints,
    required this.gradingRubric,
  }) : super(
         id: id,
         text: text,
         maxPoints: maxPoints,
         type: QuestionType.essay,
       );

  @override
  bool get isAutoGradable => false;

  @override
  double evaluate(dynamic studentAnswer) {
    // Essays cannot be auto-graded in this system. Always return 0 during auto-pass.
    // They rely on manual teacher override.
    return 0.0;
  }
}

class Exam {
  final String id;
  final String title;
  final String description;
  final Duration timeLimit;
  final List<Question> questions;

  Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLimit,
    required this.questions,
  });

  double get totalPossiblePoints =>
      questions.fold(0, (sum, q) => sum + q.maxPoints);
}

class ExamSubmission {
  final String id;
  final String examId;
  final String studentId;
  final Map<String, dynamic> answers; // QuestionID -> Answer
  final DateTime submittedAt;

  ExamSubmission({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.answers,
    required this.submittedAt,
  });
}

class EvaluationResult {
  final String submissionId;
  EvaluationStatus status;
  double score;
  Map<String, double> questionScores; // QuestionID -> Score Earned
  String? teacherFeedback;

  EvaluationResult({
    required this.submissionId,
    required this.status,
    required this.score,
    required this.questionScores,
    this.teacherFeedback,
  });
}

// ============================================================================
// 3. MOCK BACKEND ENGINE (CALLBACKS & EVALUATION LOGIC)
// ============================================================================

/// Simulates a backend processing engine with delayed callbacks
class MockExamEngine {
  static final MockExamEngine _instance = MockExamEngine._internal();
  factory MockExamEngine() => _instance;
  MockExamEngine._internal() {
    _seedDatabase();
  }

  // Random generator removed (unused)

  // Database Mocks
  final List<Exam> _exams = [];
  final Map<String, ExamSubmission> _submissions = {};
  final Map<String, EvaluationResult> _results = {};

  // Public unnamed constructor removed; seeding occurs in `_internal()`.

  void _seedDatabase() {
    _exams.add(
      Exam(
        id: 'EXAM_001',
        title: 'Advanced Computer Science',
        description:
            'Covers Algorithms, Data Structures, and System Architecture.',
        timeLimit: const Duration(minutes: 60), // Set to 60 mins for realism
        questions: [
          MultipleChoiceQuestion(
            id: 'Q1',
            text:
                'What is the time complexity of a binary search tree lookup in the worst case?',
            maxPoints: 10,
            options: ['O(1)', 'O(log n)', 'O(n)', 'O(n^2)'],
            correctOptionIndex: 2,
          ),
          MultipleChoiceQuestion(
            id: 'Q2',
            text: 'Which data structure uses LIFO (Last In First Out)?',
            maxPoints: 10,
            options: ['Queue', 'Stack', 'Tree', 'Graph'],
            correctOptionIndex: 1,
          ),
          EssayQuestion(
            id: 'Q3',
            text:
                'Explain the CAP theorem and its implications in distributed systems.',
            maxPoints: 30,
            gradingRubric:
                'Look for Consistency, Availability, Partition Tolerance definitions.',
          ),
          MultipleChoiceQuestion(
            id: 'Q4',
            text:
                'In Flutter, what widget is used to build flexible layouts in a row or column?',
            maxPoints: 10,
            options: ['Container', 'Expanded', 'SizedBox', 'Align'],
            correctOptionIndex: 1,
          ),
        ],
      ),
    );

    _exams.add(
      Exam(
        id: 'EXAM_002',
        title: 'History Standardized Test',
        description: 'World history general knowledge exam.',
        timeLimit: const Duration(minutes: 30),
        questions: [
          MultipleChoiceQuestion(
            id: 'Q1',
            text: 'In what year did World War II end?',
            maxPoints: 10,
            options: ['1943', '1945', '1948', '1950'],
            correctOptionIndex: 1,
          ),
          EssayQuestion(
            id: 'Q2',
            text: 'Describe the economic impact of the Industrial Revolution.',
            maxPoints: 40,
            gradingRubric:
                'Analyze urbanization, factory system, and wealth disparity.',
          ),
        ],
      ),
    );
  }

  Future<List<Exam>> fetchAvailableExams() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.unmodifiable(_exams);
  }

  Future<Exam> fetchExamDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _exams.firstWhere((e) => e.id == id);
  }

  /// SUBMIT EXAM WITH CALLBACK-BASED EVALUATION
  /// This simulates a server accepting a payload, placing it in a worker queue,
  /// and firing a callback when the initial grading pass is complete.
  void submitExam(
    ExamSubmission submission, {
    required Function(EvaluationResult) onResultUpdate,
  }) async {
    _submissions[submission.id] = submission;

    // Initial status: Pending in queue
    final result = EvaluationResult(
      submissionId: submission.id,
      status: EvaluationStatus.pending,
      score: 0.0,
      questionScores: {},
    );
    _results[submission.id] = result;

    onResultUpdate(result); // Callback: Pending

    // Simulate network latency / queue waiting time
    await Future.delayed(const Duration(seconds: 2));

    result.status = EvaluationStatus.autoGrading;
    onResultUpdate(result); // Callback: AutoGrading started

    // Simulate compute time for auto-grading
    await Future.delayed(const Duration(seconds: 2));

    final exam = _exams.firstWhere((e) => e.id == submission.examId);
    bool requiresManualReview = false;
    double currentScore = 0.0;

    for (var question in exam.questions) {
      final answer = submission.answers[question.id];
      if (question.isAutoGradable) {
        final earned = question.evaluate(answer);
        result.questionScores[question.id] = earned;
        currentScore += earned;
      } else {
        // Essay questions are flagged for manual review
        requiresManualReview = true;
        result.questionScores[question.id] = 0.0; // Place holder
      }
    }

    result.score = currentScore;
    result.status = requiresManualReview
        ? EvaluationStatus.awaitingManualReview
        : EvaluationStatus.completed;

    // Final callback for this phase
    onResultUpdate(result);
  }

  // --- Teacher Operations ---

  Future<List<ExamSubmission>> fetchPendingSubmissions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Return submissions that are awaiting manual review
    return _submissions.values.where((sub) {
      final res = _results[sub.id];
      return res != null && res.status == EvaluationStatus.awaitingManualReview;
    }).toList();
  }

  Future<void> submitManualGrade({
    required String submissionId,
    required Map<String, double> manualScores,
    required String feedback,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final result = _results[submissionId];
    if (result == null) throw Exception("Result not found");

    // Apply manual scores and sum up
    manualScores.forEach((qId, score) {
      result.questionScores[qId] = score;
    });

    double totalScore = result.questionScores.values.fold(0.0, (a, b) => a + b);

    result.score = totalScore;
    result.teacherFeedback = feedback;
    result.status = EvaluationStatus.completed;
  }
}

// ============================================================================
// 4. STATE MANAGEMENT (AppStore & ExamStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockExamEngine _api = MockExamEngine();

  // Global Auth
  User? currentUser;

  // Student State
  List<Exam> availableExams = [];
  Map<String, EvaluationResult> studentResults = {}; // ExamID -> Result

  // Teacher State
  List<ExamSubmission> pendingSubmissions = [];

  bool isLoading = false;
  String? error;

  Future<void> login(String username, UserRole role) async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1)); // Auth latency
    currentUser = User(
      id: 'USR_${math.Random().nextInt(9999)}',
      name: username,
      role: role,
    );

    if (role == UserRole.student) {
      availableExams = await _api.fetchAvailableExams();
    } else {
      pendingSubmissions = await _api.fetchPendingSubmissions();
    }

    isLoading = false;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    availableExams.clear();
    studentResults.clear();
    pendingSubmissions.clear();
    notifyListeners();
  }

  // --- Student Methods ---
  void registerSubmissionResult(String examId, EvaluationResult result) {
    studentResults[examId] = result;
    notifyListeners();
  }

  // --- Teacher Methods ---
  Future<void> refreshPendingSubmissions() async {
    isLoading = true;
    notifyListeners();
    pendingSubmissions = await _api.fetchPendingSubmissions();
    isLoading = false;
    notifyListeners();
  }

  Future<void> gradeSubmission(
    String submissionId,
    Map<String, double> scores,
    String feedback,
  ) async {
    isLoading = true;
    notifyListeners();
    await _api.submitManualGrade(
      submissionId: submissionId,
      manualScores: scores,
      feedback: feedback,
    );
    await refreshPendingSubmissions();
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
// 5. MAIN ROUTER & APP ROOT
// ============================================================================

void main() {
  runApp(const ExamPlatformApp());
}

class ExamPlatformApp extends StatelessWidget {
  const ExamPlatformApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Exam Platform',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthRouter(),
      ),
    );
  }
}

class AuthRouter extends StatelessWidget {
  const AuthRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.currentUser == null) {
      return const LoginScreen();
    } else if (state.currentUser!.role == UserRole.student) {
      return const StudentDashboard();
    } else {
      return const TeacherDashboard();
    }
  }
}

// ============================================================================
// 6. LOGIN / AUTH SCREEN
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController(text: 'Alex Student');
  UserRole _selectedRole = UserRole.student;

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nexus Evaluator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Secure Online Examination System',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.student,
                      label: Text('Student'),
                      icon: Icon(Icons.face),
                    ),
                    ButtonSegment(
                      value: UserRole.teacher,
                      label: Text('Teacher'),
                      icon: Icon(Icons.menu_book),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (Set<UserRole> newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                      _nameCtrl.text = _selectedRole == UserRole.student
                          ? 'Alex Student'
                          : 'Prof. Anderson';
                    });
                  },
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => state.login(_nameCtrl.text, _selectedRole),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SECURE LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. STUDENT DASHBOARD
// ============================================================================

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: state.availableExams.isEmpty
          ? const Center(child: Text("No exams assigned."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.availableExams.length,
              itemBuilder: (context, index) {
                final exam = state.availableExams[index];
                final result = state.studentResults[exam.id];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exam.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMain,
                                ),
                              ),
                            ),
                            if (result != null)
                              _buildStatusBadge(result.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exam.description,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${exam.timeLimit.inMinutes} Minutes',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.format_list_numbered,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${exam.questions.length} Questions',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionBtn(context, exam, result),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(EvaluationStatus status) {
    Color color;
    String text;
    switch (status) {
      case EvaluationStatus.pending:
      case EvaluationStatus.autoGrading:
        color = AppTheme.warning;
        text = 'EVALUATING';
        break;
      case EvaluationStatus.awaitingManualReview:
        color = AppTheme.primary;
        text = 'AWAITING GRADE';
        break;
      case EvaluationStatus.completed:
        color = AppTheme.success;
        text = 'GRADED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    Exam exam,
    EvaluationResult? result,
  ) {
    if (result == null) {
      return ElevatedButton(
        onPressed: () => _startExamProtocol(context, exam),
        child: const Text('START EXAM'),
      );
    } else if (result.status == EvaluationStatus.completed) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.success,
          side: const BorderSide(color: AppTheme.success),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamResultScreen(exam: exam, result: result),
          ),
        ),
        child: const Text('VIEW RESULTS'),
      );
    } else {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.warning,
          side: const BorderSide(color: AppTheme.warning),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamResultScreen(exam: exam, result: result),
          ),
        ),
        child: const Text('CHECK STATUS'),
      );
    }
  }

  void _startExamProtocol(BuildContext context, Exam exam) async {
    // Show secure entry warning
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Exam Protocol'),
        content: const Text(
          'You are about to start a timed exam. Once started, the timer cannot be paused. Ensure you have a stable connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Begin Exam'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExamRunnerScreen(exam: exam)),
      );
    }
  }
}

// ============================================================================
// 8. EXAM RUNNER ENGINE (Timer, PageView, UI)
// ============================================================================

class ExamRunnerScreen extends StatefulWidget {
  final Exam exam;
  const ExamRunnerScreen({Key? key, required this.exam}) : super(key: key);

  @override
  State<ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends State<ExamRunnerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // State for student answers
  final Map<String, dynamic> _answers = {};

  // Timer State
  Timer? _timer;
  late int _remainingSeconds;

  // Submission Lock
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _remainingSeconds = widget.exam.timeLimit.inSeconds;
    _startTimer();
  }

  void _startTimer() {
    // For demo purposes, speed up the timer significantly if it's 60 minutes
    // Just to make it testable, we cap it at 120 seconds if it's huge,
    // BUT we requested realism, so let's keep it real but tick normally.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _forceSubmit();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _saveAnswer(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _forceSubmit() {
    if (_isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time is up! Auto-submitting exam.'),
        backgroundColor: AppTheme.error,
      ),
    );
    _executeSubmission();
  }

  Future<void> _attemptManualSubmit() async {
    final answeredCount = _answers.keys.length;
    final total = widget.exam.questions.length;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Text(
          'You have answered $answeredCount out of $total questions.\nAre you sure you want to submit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Return to Exam'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _executeSubmission();
    }
  }

  void _executeSubmission() {
    setState(() => _isSubmitting = true);
    _timer?.cancel();
    final state = AppStore.of(context, listen: false);

    final submission = ExamSubmission(
      id: 'SUB_${DateTime.now().millisecondsSinceEpoch}',
      examId: widget.exam.id,
      studentId: state.currentUser!.id,
      answers: Map.from(_answers), // deep copy
      submittedAt: DateTime.now(),
    );

    // Call the engine with the callback for delayed results
    MockExamEngine().submitExam(
      submission,
      onResultUpdate: (EvaluationResult res) {
        // Update global state whenever callback fires
        state.registerSubmissionResult(widget.exam.id, res);
      },
    );

    // Immediately route to the result screen (which will listen to status updates)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ExamResultScreen(
          exam: widget.exam,
          result: state.studentResults[widget.exam.id]!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.exam.title, style: const TextStyle(fontSize: 16)),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _TimerDisplay(remainingSeconds: _remainingSeconds),
              ),
            ),
          ],
        ),
        body: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildQuestionPalette(),
                  const LinearProgressIndicator(
                    value: 1.0,
                    color: AppTheme.background,
                  ), // divider
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics:
                          const NeverScrollableScrollPhysics(), // Force UI buttons to navigate
                      itemCount: widget.exam.questions.length,
                      onPageChanged: (idx) =>
                          setState(() => _currentIndex = idx),
                      itemBuilder: (context, index) {
                        final q = widget.exam.questions[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildQuestionInterface(q, index),
                        );
                      },
                    ),
                  ),
                  _buildNavigationFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestionPalette() {
    return Container(
      height: 70,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: widget.exam.questions.length,
        itemBuilder: (context, index) {
          final qId = widget.exam.questions[index].id;
          final isAnswered = _answers.containsKey(qId);
          final isCurrent = index == _currentIndex;

          return GestureDetector(
            onTap: () => _pageController.jumpToPage(index),
            child: Container(
              width: 46,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.primary
                    : (isAnswered
                          ? AppTheme.success.withOpacity(0.2)
                          : AppTheme.background),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.primaryDark
                      : (isAnswered ? AppTheme.success : Colors.transparent),
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent
                        ? Colors.white
                        : (isAnswered ? AppTheme.success : AppTheme.textMuted),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionInterface(Question q, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${q.maxPoints} pts',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          q.text,
          style: const TextStyle(
            fontSize: 20,
            color: AppTheme.textMain,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        if (q is MultipleChoiceQuestion) _buildMCQInterface(q),
        if (q is EssayQuestion) _buildEssayInterface(q),
      ],
    );
  }

  Widget _buildMCQInterface(MultipleChoiceQuestion q) {
    final currentAnswer = _answers[q.id]; // int?
    return Column(
      children: List.generate(q.options.length, (optIndex) {
        final isSelected = currentAnswer == optIndex;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () => _saveAnswer(q.id, optIndex),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.1)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.background,
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
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      q.options[optIndex],
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected
                            ? AppTheme.primaryDark
                            : AppTheme.textMain,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEssayInterface(EssayQuestion q) {
    final currentAnswer = _answers[q.id] ?? '';
    return TextField(
      controller: TextEditingController(text: currentAnswer)
        ..selection = TextSelection.collapsed(offset: currentAnswer.length),
      maxLines: 10,
      onChanged: (val) => _saveAnswer(q.id, val),
      decoration: InputDecoration(
        hintText: 'Type your detailed answer here...',
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.textMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildNavigationFooter() {
    final isLast = _currentIndex == widget.exam.questions.length - 1;
    final isFirst = _currentIndex == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!isFirst)
              OutlinedButton.icon(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              )
            else
              const SizedBox(width: 100), // Placeholder to keep alignment

            if (!isLast)
              ElevatedButton.icon(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                label: const Text('Next'),
                icon: const Icon(Icons.arrow_forward),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                ),
                onPressed: _attemptManualSubmit,
                label: const Text('Submit Exam'),
                icon: const Icon(Icons.send),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final int remainingSeconds;
  const _TimerDisplay({required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final isCritical = remainingSeconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCritical ? AppTheme.error : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: isCritical ? Colors.white : Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 9. EXAM RESULTS & DELAYED PROCESSING UI
// ============================================================================

class ExamResultScreen extends StatelessWidget {
  final Exam exam;
  final EvaluationResult
  result; // Note: passed by reference, updates via AppStore

  const ExamResultScreen({Key? key, required this.exam, required this.result})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We wrap in Consumer/AppStore to listen to callback updates from Engine
    final state = AppStore.of(context);
    // Fetch latest instance of result from global state to ensure reactivity to callbacks
    final liveResult = state.studentResults[exam.id] ?? result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: _buildBody(liveResult),
    );
  }

  Widget _buildBody(EvaluationResult res) {
    switch (res.status) {
      case EvaluationStatus.pending:
      case EvaluationStatus.autoGrading:
        return _buildProcessingUI(res);
      case EvaluationStatus.awaitingManualReview:
        return _buildAwaitingManualReviewUI();
      case EvaluationStatus.completed:
        return _buildFinalResultsUI(res);
    }
  }

  Widget _buildProcessingUI(EvaluationResult res) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Analyzing Submission',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            res.status == EvaluationStatus.pending
                ? 'Queueing for evaluation pipeline...'
                : 'Running auto-grading engine...',
            style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingManualReviewUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pending_actions_rounded,
              size: 100,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 32),
            const Text(
              'Manual Review Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your exam contains essay questions that require manual grading by a teacher. You will be notified when your final score is available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalResultsUI(EvaluationResult res) {
    final double maxScore = exam.totalPossiblePoints;
    final double percentage = (res.score / maxScore) * 100;
    final bool passed = percentage >= 60.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: passed
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: passed ? AppTheme.success : AppTheme.error,
                width: 4,
              ),
            ),
            child: Text(
              '${res.score.toStringAsFixed(1)}\n/ ${maxScore.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: passed ? AppTheme.success : AppTheme.error,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            passed ? 'Congratulations!' : 'Keep Practicing',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You scored ${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 18, color: AppTheme.textMuted),
          ),

          if (res.teacherFeedback != null &&
              res.teacherFeedback!.isNotEmpty) ...[
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.secondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.feedback, color: AppTheme.secondary),
                      SizedBox(width: 8),
                      Text(
                        'Instructor Feedback',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    res.teacherFeedback!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 48),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Question Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          ...exam.questions.map((q) {
            final earned = res.questionScores[q.id] ?? 0.0;
            final isFullPoints = earned == q.maxPoints;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isFullPoints
                        ? Icons.check_circle
                        : (earned > 0 ? Icons.remove_circle : Icons.cancel),
                    color: isFullPoints
                        ? AppTheme.success
                        : (earned > 0 ? AppTheme.warning : AppTheme.error),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      q.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${earned.toStringAsFixed(1)} / ${q.maxPoints.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. TEACHER DASHBOARD & MANUAL GRADING UI
// ============================================================================

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: AppTheme.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.refreshPendingSubmissions(),
        child: state.isLoading && state.pendingSubmissions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.pendingSubmissions.isEmpty
            ? const Center(child: Text('No submissions awaiting review!'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.pendingSubmissions.length,
                itemBuilder: (context, index) {
                  final sub = state.pendingSubmissions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.warning,
                        child: Icon(Icons.edit_note, color: Colors.white),
                      ),
                      title: Text(
                        'Submission: ${sub.id.substring(0, 8)}...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Requires manual grading for essay questions.\nSubmitted: ${sub.submittedAt.toString().split('.')[0]}',
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManualGradingScreen(submission: sub),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class ManualGradingScreen extends StatefulWidget {
  final ExamSubmission submission;
  const ManualGradingScreen({Key? key, required this.submission})
    : super(key: key);

  @override
  State<ManualGradingScreen> createState() => _ManualGradingScreenState();
}

class _ManualGradingScreenState extends State<ManualGradingScreen> {
  Exam? _exam;
  bool _loading = true;
  final Map<String, double> _manualScores = {};
  final TextEditingController _feedbackCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExamDetails();
  }

  Future<void> _fetchExamDetails() async {
    final api = MockExamEngine();
    final exam = await api.fetchExamDetails(widget.submission.examId);
    if (!mounted) return;
    setState(() {
      _exam = exam;
      _loading = false;
      // Pre-fill manual scores to 0 for essays
      for (var q in exam.questions.whereType<EssayQuestion>()) {
        _manualScores[q.id] = 0.0;
      }
    });
  }

  void _submitGrades() async {
    final state = AppStore.of(context, listen: false);
    await state.gradeSubmission(
      widget.submission.id,
      _manualScores,
      _feedbackCtrl.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grades submitted successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final essays = _exam!.questions.whereType<EssayQuestion>().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Submission'),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppTheme.warning),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Auto-gradable questions have already been processed. Please grade the following essay responses.',
                      style: TextStyle(color: AppTheme.textMain),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ...essays.map((q) => _buildEssayGradingWidget(q)).toList(),
            const Divider(height: 48),
            const Text(
              'Overall Feedback',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter constructive feedback for the student...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.surface,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                ),
                onPressed: _submitGrades,
                child: const Text(
                  'FINALIZE EVALUATION',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssayGradingWidget(EssayQuestion q) {
    final answer = widget.submission.answers[q.id] ?? 'No answer provided.';
    final currentScore = _manualScores[q.id] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 32),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Question Prompt',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Max: ${q.maxPoints} pts',
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              q.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Answer:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.secondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rule, color: AppTheme.secondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rubric: ${q.gradingRubric}',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Assign Points:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Expanded(
                  child: Slider(
                    value: currentScore,
                    min: 0,
                    max: q.maxPoints,
                    divisions: q.maxPoints.toInt(),
                    label: currentScore.toStringAsFixed(1),
                    activeColor: AppTheme.primaryDark,
                    onChanged: (val) {
                      setState(() {
                        _manualScores[q.id] = val;
                      });
                    },
                  ),
                ),
                Text(
                  currentScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
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
