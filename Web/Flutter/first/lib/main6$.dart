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

enum TaskStatus { todo, inProgress, inReview, done }

enum TaskPriority { lowest, low, medium, high, critical }

enum UserRole { admin, manager, member, viewer }

enum ActivityType { created, statusChanged, assigned, commented, fileAttached }

class AppColors {
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color background = Color(0xFFF1F5F9); // Slate 100
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800

  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  static const Color kanbanTodo = Color(0xFFCBD5E1);
  static const Color kanbanInProgress = Color(0xFF60A5FA);
  static const Color kanbanInReview = Color(0xFFF472B6);
  static const Color kanbanDone = Color(0xFF34D399);
}

class AppStyles {
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

abstract class PMException implements Exception {
  final String message;
  PMException(this.message);
  @override
  String toString() => message;
}

class AuthException extends PMException {
  AuthException([String m = "Authentication failed"]) : super(m);
}

class PermissionException extends PMException {
  PermissionException([String m = "Access denied"]) : super(m);
}

class NetworkException extends PMException {
  NetworkException([String m = "Network timeout"]) : super(m);
}

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
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
  });
}

class Comment {
  final String id;
  final String authorId;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.timestamp,
  });
}

class ActivityLog {
  final String id;
  final String taskId;
  final String actorId;
  final ActivityType type;
  final String description;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.taskId,
    required this.actorId,
    required this.type,
    required this.description,
    required this.timestamp,
  });
}

class Subtask {
  final String id;
  final String title;
  bool isCompleted;

  Subtask({required this.id, required this.title, this.isCompleted = false});
}

class Task {
  final String id;
  final String projectId;
  final String title;
  final String description;
  TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final String reporterId;
  final DateTime createdAt;
  final DateTime dueDate;
  final int estimatedHours;
  int loggedHours;
  final List<String> tags;
  final List<Subtask> subtasks;
  final List<Comment> comments;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    required this.reporterId,
    required this.createdAt,
    required this.dueDate,
    required this.estimatedHours,
    this.loggedHours = 0,
    required this.tags,
    required this.subtasks,
    required this.comments,
  });

  double get progress {
    if (subtasks.isEmpty) return status == TaskStatus.done ? 1.0 : 0.0;
    int completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }
}

class Project {
  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final String colorCode;
  final DateTime targetDate;

  Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.colorCode,
    required this.targetDate,
  });
}

// ============================================================================
// 4. MOCK BACKEND ENGINE (Database Simulation)
// ============================================================================

class MockBackendEngine {
  static final MockBackendEngine _instance = MockBackendEngine._internal();
  factory MockBackendEngine() => _instance;
  MockBackendEngine._internal() {
    _seedData();
  }

  final math.Random _random = math.Random();

  // In-Memory DB
  final Map<String, User> _users = {};
  final List<Project> _projects = [];
  final List<Task> _tasks = [];
  final List<ActivityLog> _activityLogs = [];

  // Public constructor removed; seeding happens in `_internal()`.

  void _seedData() {
    // 1. Seed Users
    final u1 = User(
      id: 'U1',
      name: 'Alice Admin',
      email: 'alice@nexus.co',
      avatarUrl: 'https://i.pravatar.cc/150?u=alice',
      role: UserRole.admin,
    );
    final u2 = User(
      id: 'U2',
      name: 'Bob Builder',
      email: 'bob@nexus.co',
      avatarUrl: 'https://i.pravatar.cc/150?u=bob',
      role: UserRole.manager,
    );
    final u3 = User(
      id: 'U3',
      name: 'Charlie Code',
      email: 'charlie@nexus.co',
      avatarUrl: 'https://i.pravatar.cc/150?u=charlie',
      role: UserRole.member,
    );
    _users.addAll({'U1': u1, 'U2': u2, 'U3': u3});

    // 2. Seed Projects
    final p1 = Project(
      id: 'P1',
      workspaceId: 'W1',
      name: 'Mobile App Redesign',
      description: 'Overhauling the user interface for V2.0',
      colorCode: '0xFF6366F1',
      targetDate: DateTime.now().add(const Duration(days: 30)),
    );
    final p2 = Project(
      id: 'P2',
      workspaceId: 'W1',
      name: 'Backend Migration',
      description: 'Moving from REST to GraphQL',
      colorCode: '0xFF10B981',
      targetDate: DateTime.now().add(const Duration(days: 45)),
    );
    _projects.addAll([p1, p2]);

    // 3. Seed Tasks (Massive Generation for Kanban realism)
    final tagsPool = [
      'Frontend',
      'Backend',
      'Design',
      'Bug',
      'Feature',
      'Urgent',
    ];

    for (int i = 1; i <= 25; i++) {
      final isDone = _random.nextDouble() > 0.7;
      final status = isDone
          ? TaskStatus.done
          : TaskStatus.values[_random.nextInt(3)];

      final t = Task(
        id: 'TASK-$i',
        projectId: _random.nextBool() ? 'P1' : 'P2',
        title: 'Task Title $i - ${_generateLorem(3)}',
        description: 'Detailed description for task $i. ${_generateLorem(15)}',
        status: status,
        priority:
            TaskPriority.values[_random.nextInt(TaskPriority.values.length)],
        assigneeId: _random.nextBool() ? 'U${_random.nextInt(3) + 1}' : null,
        reporterId: 'U1',
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(20))),
        dueDate: DateTime.now().add(Duration(days: _random.nextInt(15) - 5)),
        estimatedHours: 4 + _random.nextInt(16),
        loggedHours: isDone ? 4 + _random.nextInt(16) : _random.nextInt(8),
        tags: [
          tagsPool[_random.nextInt(tagsPool.length)],
          tagsPool[_random.nextInt(tagsPool.length)],
        ].toSet().toList(),
        subtasks: [
          Subtask(
            id: 'ST1_$i',
            title: 'Design mockup',
            isCompleted: _random.nextBool() || isDone,
          ),
          Subtask(
            id: 'ST2_$i',
            title: 'Implement API',
            isCompleted: _random.nextBool() || isDone,
          ),
          Subtask(id: 'ST3_$i', title: 'Write tests', isCompleted: isDone),
        ],
        comments: [
          Comment(
            id: 'C1',
            authorId: 'U2',
            text: 'Looking good so far.',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      );
      _tasks.add(t);

      // Seed Activity
      _activityLogs.add(
        ActivityLog(
          id: 'AL_$i',
          taskId: t.id,
          actorId: 'U1',
          type: ActivityType.created,
          description: 'Created the task',
          timestamp: t.createdAt,
        ),
      );
    }
  }

  String _generateLorem(int wordCount) {
    const words = [
      'lorem',
      'ipsum',
      'dolor',
      'sit',
      'amet',
      'consectetur',
      'adipiscing',
      'elit',
      'sed',
      'do',
      'eiusmod',
      'tempor',
      'incididunt',
      'ut',
      'labore',
      'et',
      'dolore',
      'magna',
      'aliqua',
    ];
    return List.generate(
      wordCount,
      (i) => words[_random.nextInt(words.length)],
    ).join(' ');
  }

  Future<void> _simulateLatency([int ms = 600]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(400)));

  // --- Auth API ---
  Future<User> authenticate(String email, String password) async {
    await _simulateLatency(1000);
    if (email.isEmpty) throw AuthException('Email is required');
    final user = _users.values.firstWhere(
      (u) => u.email == email,
      orElse: () => throw AuthException('User not found'),
    );
    return user;
  }

  // --- Project API ---
  Future<List<Project>> getProjects() async {
    await _simulateLatency();
    return List.from(_projects);
  }

  // --- Task API ---
  Future<List<Task>> getTasks(String projectId) async {
    await _simulateLatency(800);
    return _tasks.where((t) => t.projectId == projectId).toList();
  }

  Future<void> updateTaskStatus(
    String taskId,
    TaskStatus newStatus,
    String actorId,
  ) async {
    await _simulateLatency(300); // Fast response for drag-and-drop
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final oldStatus = task.status;
    task.status = newStatus;

    // Log Activity
    _activityLogs.insert(
      0,
      ActivityLog(
        id: 'AL_${DateTime.now().millisecondsSinceEpoch}',
        taskId: taskId,
        actorId: actorId,
        type: ActivityType.statusChanged,
        description: 'Moved from ${oldStatus.name} to ${newStatus.name}',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<List<User>> getWorkspaceUsers() async {
    await _simulateLatency(200);
    return _users.values.toList();
  }

  User getUserById(String id) =>
      _users[id] ??
      User(
        id: 'UNKNOWN',
        name: 'Unknown',
        email: '',
        avatarUrl: '',
        role: UserRole.viewer,
      );

  List<ActivityLog> getTaskActivity(String taskId) {
    final logs = _activityLogs.where((l) => l.taskId == taskId).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockBackendEngine _api = MockBackendEngine();

  User? currentUser;
  bool isGlobalLoading = false;
  String? globalError;

  // Workspace Data
  List<Project> projects = [];
  List<User> teamMembers = [];

  // Current Project State
  Project? activeProject;
  List<Task> currentTasks = [];
  bool isLoadingTasks = false;

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      currentUser = await _api.authenticate(email, password);
      projects = await _api.getProjects();
      teamMembers = await _api.getWorkspaceUsers();
      if (projects.isNotEmpty) {
        await selectProject(projects.first);
      }
    } on PMException catch (e) {
      _setError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectProject(Project p) async {
    activeProject = p;
    isLoadingTasks = true;
    notifyListeners();
    try {
      currentTasks = await _api.getTasks(p.id);
    } finally {
      isLoadingTasks = false;
      notifyListeners();
    }
  }

  // --- Kanban Operations ---
  void moveTask(String taskId, TaskStatus newStatus) async {
    // Optimistic UI Update
    final idx = currentTasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final oldStatus = currentTasks[idx].status;
    if (oldStatus == newStatus) return;

    currentTasks[idx].status = newStatus;
    notifyListeners();

    // Background API Sync
    try {
      await _api.updateTaskStatus(taskId, newStatus, currentUser!.id);
    } catch (e) {
      // Revert on failure
      currentTasks[idx].status = oldStatus;
      _setError("Failed to move task. Reverted.");
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    projects.clear();
    currentTasks.clear();
    activeProject = null;
    notifyListeners();
  }

  User getUser(String id) => _api.getUserById(id);
  List<ActivityLog> getLogs(String taskId) => _api.getTaskActivity(taskId);
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
// 6. MAIN & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PMSApp());
}

class PMSApp extends StatelessWidget {
  const PMSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus PM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Inter', // Fallback standard
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textMain,
            elevation: 1,
            shadowColor: Colors.black12,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
    if (state.currentUser == null) return const AuthScreen();
    return const MainScaffold();
  }
}

// ============================================================================
// 7. AUTHENTICATION SCREEN
// ============================================================================

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final emailCtrl = TextEditingController(text: 'alice@nexus.co');
    final passCtrl = TextEditingController(text: 'password123');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.layers_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Nexus Suite',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'Enterprise Project Management',
                textAlign: TextAlign.center,
                style: AppStyles.caption,
              ),
              const SizedBox(height: 64),

              if (state.globalError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.globalError!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              _CustomTextField(
                label: 'Work Email',
                controller: emailCtrl,
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _CustomTextField(
                label: 'Password',
                controller: passCtrl,
                icon: Icons.lock,
                isObscure: true,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: state.isGlobalLoading
                    ? null
                    : () => state.login(emailCtrl.text, passCtrl.text),
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
                        'SECURE LOGIN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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

class _CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isObscure;

  const _CustomTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.isObscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 8. MAIN SCAFFOLD & ROUTING (Bottom Nav + Drawer)
// ============================================================================

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const KanbanBoardScreen(),
    const ProjectListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser!;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryDark),
              accountName: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user.email),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Support'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => state.logout(),
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surface,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_kanban),
            label: 'Board',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Projects'),
        ],
      ),
    );
  }
}

// ============================================================================
// 9. DASHBOARD & CUSTOM ANALYTICS PAINTERS
// ============================================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final project = state.activeProject;

    if (project == null)
      return const Scaffold(body: Center(child: Text('No Project Selected')));
    if (state.isLoadingTasks)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final totalTasks = state.currentTasks.length;
    final completedTasks = state.currentTasks
        .where((t) => t.status == TaskStatus.done)
        .length;
    // progress calculation kept for reference (unused)

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Overview', style: AppStyles.h2),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Tasks',
                    value: '$totalTasks',
                    icon: Icons.assignment,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: '$completedTasks',
                    icon: Icons.check_circle,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Burndown Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sprint Burndown', style: AppStyles.h3),
                  const SizedBox(height: 4),
                  const Text(
                    'Remaining tasks over the last 14 days',
                    style: AppStyles.caption,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _BurndownChartPainter(
                        // Generate dummy curve data based on completion
                        dataPoints: List.generate(
                          14,
                          (i) => math.max(
                            0,
                            totalTasks -
                                (i * (completedTasks / 14)) +
                                (math.Random().nextInt(3) - 1),
                          ),
                        ),
                        idealLine: List.generate(
                          14,
                          (i) =>
                              math.max(0, totalTasks - (i * (totalTasks / 14))),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Task Distribution & Team
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donut Chart
                Expanded(
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Distribution', style: AppStyles.h3),
                        const SizedBox(height: 16),
                        Expanded(
                          child: CustomPaint(
                            size: const Size.square(120),
                            painter: _DonutChartPainter(
                              todo: state.currentTasks
                                  .where((t) => t.status == TaskStatus.todo)
                                  .length,
                              inProg: state.currentTasks
                                  .where(
                                    (t) => t.status == TaskStatus.inProgress,
                                  )
                                  .length,
                              inRev: state.currentTasks
                                  .where((t) => t.status == TaskStatus.inReview)
                                  .length,
                              done: completedTasks,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Team Members
                Expanded(
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Team', style: AppStyles.h3),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: state.teamMembers.length,
                            separatorBuilder: (c, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (c, i) {
                              final u = state.teamMembers[i];
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(u.avatarUrl),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      u.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(value, style: AppStyles.h2),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BurndownChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<double> idealLine;

  _BurndownChartPainter({required this.dataPoints, required this.idealLine});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final double maxVal = math.max(
      dataPoints.reduce(math.max),
      idealLine.reduce(math.max),
    );
    final double stepX = size.width / (dataPoints.length - 1);

    Offset getCanvasOffset(int index, double val) {
      double normalizedY = maxVal == 0 ? 0 : val / maxVal;
      return Offset(index * stepX, size.height - (normalizedY * size.height));
    }

    // 1. Draw Grid Lines
    final gridPaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.1)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      double y = size.height - (i * (size.height / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Ideal Line (Dashed straight line)
    final idealPaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final idealPath = Path()
      ..moveTo(
        getCanvasOffset(0, idealLine[0]).dx,
        getCanvasOffset(0, idealLine[0]).dy,
      );
    for (int i = 1; i < idealLine.length; i++) {
      idealPath.lineTo(
        getCanvasOffset(i, idealLine[i]).dx,
        getCanvasOffset(i, idealLine[i]).dy,
      );
    }
    // Very basic dash simulation
    canvas.drawPath(idealPath, idealPaint);

    // 3. Draw Actual Data Line (Smooth Bezier)
    final dataPath = Path();
    final fillPath = Path();
    final startOffset = getCanvasOffset(0, dataPoints[0]);

    dataPath.moveTo(startOffset.dx, startOffset.dy);
    fillPath.moveTo(startOffset.dx, size.height);
    fillPath.lineTo(startOffset.dx, startOffset.dy);

    for (int i = 0; i < dataPoints.length - 1; i++) {
      final p0 = getCanvasOffset(i, dataPoints[i]);
      final p1 = getCanvasOffset(i + 1, dataPoints[i + 1]);

      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      dataPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill Gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [
          AppColors.primary.withOpacity(0.3),
          AppColors.primary.withOpacity(0.0),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, linePaint);

    // Data Points Circles
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < dataPoints.length; i++) {
      final pt = getCanvasOffset(i, dataPoints[i]);
      canvas.drawCircle(pt, 4, pointPaint);
      canvas.drawCircle(pt, 4, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutChartPainter extends CustomPainter {
  final int todo, inProg, inRev, done;
  _DonutChartPainter({
    required this.todo,
    required this.inProg,
    required this.inRev,
    required this.done,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final total = todo + inProg + inRev + done;

    if (total == 0) {
      final paint = Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16;
      canvas.drawCircle(center, radius - 8, paint);
      return;
    }

    double startAngle = -math.pi / 2;

    void drawSegment(int count, Color color) {
      if (count == 0) return;
      final sweepAngle = (count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(todo, AppColors.kanbanTodo);
    drawSegment(inProg, AppColors.kanbanInProgress);
    drawSegment(inRev, AppColors.kanbanInReview);
    drawSegment(done, AppColors.kanbanDone);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 10. DRAG & DROP KANBAN BOARD
// ============================================================================

class KanbanBoardScreen extends StatelessWidget {
  const KanbanBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final project = state.activeProject;

    if (project == null)
      return const Scaffold(body: Center(child: Text('No Project Selected')));
    if (state.isLoadingTasks)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search / Filter Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // Kanban Lanes (Horizontal Scroll)
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _KanbanColumn(
                    title: 'TO DO',
                    status: TaskStatus.todo,
                    color: AppColors.kanbanTodo,
                  ),
                  _KanbanColumn(
                    title: 'IN PROGRESS',
                    status: TaskStatus.inProgress,
                    color: AppColors.kanbanInProgress,
                  ),
                  _KanbanColumn(
                    title: 'IN REVIEW',
                    status: TaskStatus.inReview,
                    color: AppColors.kanbanInReview,
                  ),
                  _KanbanColumn(
                    title: 'DONE',
                    status: TaskStatus.done,
                    color: AppColors.kanbanDone,
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

class _KanbanColumn extends StatelessWidget {
  final String title;
  final TaskStatus status;
  final Color color;

  const _KanbanColumn({
    required this.title,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final columnTasks = state.currentTasks
        .where((t) => t.status == status)
        .toList();

    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${columnTasks.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drag Target Area
          Expanded(
            child: DragTarget<String>(
              onWillAccept: (taskId) => true,
              onAccept: (taskId) => state.moveTask(taskId, status),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: candidateData.isNotEmpty
                      ? color.withOpacity(0.1)
                      : Colors.transparent,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: columnTasks.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = columnTasks[index];
                      return Draggable<String>(
                        data: task.id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.8,
                            child: SizedBox(
                              width: 280,
                              child: _KanbanCard(task: task),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _KanbanCard(task: task),
                        ),
                        child: _KanbanCard(task: task),
                      );
                    },
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

class _KanbanCard extends StatelessWidget {
  final Task task;
  const _KanbanCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context, listen: false);
    final assignee = task.assigneeId != null
        ? state.getUser(task.assigneeId!)
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.id,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _PriorityIcon(priority: task.priority),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Progress Bar
            if (task.subtasks.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.check_box_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                    style: AppStyles.caption,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: AppColors.background,
                      color: AppColors.success,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Footer (Tags & Avatar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: task.tags
                        .take(2)
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (assignee != null)
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(assignee.avatarUrl),
                  )
                else
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.background,
                    child: Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textMuted,
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

class _PriorityIcon extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityIcon({required this.priority});
  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (priority) {
      case TaskPriority.lowest:
        icon = Icons.keyboard_double_arrow_down;
        color = AppColors.textMuted;
        break;
      case TaskPriority.low:
        icon = Icons.keyboard_arrow_down;
        color = AppColors.info;
        break;
      case TaskPriority.medium:
        icon = Icons.drag_handle;
        color = AppColors.warning;
        break;
      case TaskPriority.high:
        icon = Icons.keyboard_arrow_up;
        color = AppColors.error;
        break;
      case TaskPriority.critical:
        icon = Icons.keyboard_double_arrow_up;
        color = AppColors.error;
        break;
    }
    return Icon(icon, size: 16, color: color);
  }
}

// ============================================================================
// 11. TASK DETAIL SCREEN (Complex sliver layout + Tabs)
// ============================================================================

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final assignee = task.assigneeId != null
        ? state.getUser(task.assigneeId!)
        : null;
    final reporter = state.getUser(task.reporterId);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: DefaultTabController(
        length: 2,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textMain,
              elevation: 1,
              title: Text(task.id, style: const TextStyle(fontSize: 16)),
              actions: [
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.only(
                    top: 80.0,
                    left: 16,
                    right: 16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        _StatusBadge(status: task.status),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PriorityIcon(priority: task.priority),
                              const SizedBox(width: 4),
                              Text(
                                task.priority.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Activity'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  _buildDetailsTab(context, state, assignee, reporter),
                  _buildActivityTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(
    BuildContext context,
    AppState state,
    User? assignee,
    User reporter,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(task.title, style: AppStyles.h1),
        const SizedBox(height: 24),

        // Meta Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _MetaRow(
                label: 'Assignee',
                widget: _UserChip(user: assignee),
              ),
              const Divider(height: 24),
              _MetaRow(
                label: 'Reporter',
                widget: _UserChip(user: reporter),
              ),
              const Divider(height: 24),
              _MetaRow(
                label: 'Due Date',
                widget: Text(
                  DateUtilsFormatter.format(task.dueDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              const Divider(height: 24),
              _MetaRow(
                label: 'Time Logged',
                widget: Text(
                  '${task.loggedHours}h / ${task.estimatedHours}h',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Text('Description', style: AppStyles.h3),
        const SizedBox(height: 12),
        Text(task.description, style: AppStyles.body),

        const SizedBox(height: 32),
        const Text('Subtasks', style: AppStyles.h3),
        const SizedBox(height: 12),
        ...task.subtasks
            .map(
              (st) => CheckboxListTile(
                value: st.isCompleted,
                title: Text(
                  st.title,
                  style: TextStyle(
                    decoration: st.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: st.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textMain,
                  ),
                ),
                onChanged: (v) {},
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),
            )
            .toList(),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildActivityTab(AppState state) {
    final logs = state.getLogs(task.id);
    if (logs.isEmpty) return const Center(child: Text('No activity yet.'));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final actor = state.getUser(log.actorId);

        IconData icon;
        Color color;
        switch (log.type) {
          case ActivityType.created:
            icon = Icons.add_circle;
            color = AppColors.success;
            break;
          case ActivityType.statusChanged:
            icon = Icons.sync_alt;
            color = AppColors.info;
            break;
          case ActivityType.commented:
            icon = Icons.comment;
            color = AppColors.warning;
            break;
          default:
            icon = Icons.local_activity;
            color = AppColors.textMuted;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(actor.avatarUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          actor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateUtilsFormatter.format(log.timestamp),
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.description,
                            style: const TextStyle(color: AppColors.textMain),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final Widget widget;
  const _MetaRow({required this.label, required this.widget});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: widget),
        ),
      ],
    );
  }
}

class _UserChip extends StatelessWidget {
  final User? user;
  const _UserChip({this.user});
  @override
  Widget build(BuildContext context) {
    if (user == null)
      return const Text(
        'Unassigned',
        style: TextStyle(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundImage: NetworkImage(user!.avatarUrl),
        ),
        const SizedBox(width: 8),
        Text(user!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (status) {
      case TaskStatus.todo:
        label = 'TO DO';
        color = AppColors.kanbanTodo;
        break;
      case TaskStatus.inProgress:
        label = 'IN PROGRESS';
        color = AppColors.kanbanInProgress;
        break;
      case TaskStatus.inReview:
        label = 'IN REVIEW';
        color = AppColors.kanbanInReview;
        break;
      case TaskStatus.done:
        label = 'DONE';
        color = AppColors.kanbanDone;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ============================================================================
// 12. PROJECT LIST SCREEN (Additional Tab)
// ============================================================================

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspaces & Projects'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: state.projects.length,
        itemBuilder: (context, index) {
          final p = state.projects[index];
          final isActive = state.activeProject?.id == p.id;
          final color = Color(int.parse(p.colorCode));

          return GestureDetector(
            onTap: () {
              state.selectProject(p);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to ${p.name}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isActive
                    ? Border.all(color: AppColors.primary, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.folder, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: AppStyles.h3),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${DateUtilsFormatter.format(p.targetDate)}',
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
