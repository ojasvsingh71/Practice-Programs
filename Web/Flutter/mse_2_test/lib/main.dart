import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SmartStudentApp());
}

// ==========================================
// 1. DATA MODELS & MOCK STATE
// ==========================================

enum Priority { low, medium, high }

enum Category { study, personal, health, work }

class Task {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  Priority priority;
  Category category;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = Priority.medium,
    this.category = Category.study,
  });
}

class Schedule {
  final String id;
  final String subject;
  final String time;
  final String room;
  final String professor;
  final String details;
  final Color color;

  Schedule({
    required this.id,
    required this.subject,
    required this.time,
    this.room = 'TBD',
    this.professor = 'Faculty',
    this.details = '',
    this.color = Colors.indigo,
  });
}

class Note {
  final String id;
  String text;
  DateTime date;
  Color color;
  bool isPinned;

  Note({
    required this.id,
    required this.text,
    required this.date,
    this.color = Colors.white,
    this.isPinned = false,
  });
}

class AppData {
  static List<Task> tasks = [
    Task(
      id: '1',
      title: 'Advance Calculus',
      description: 'Complete practice set 4.2',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      priority: Priority.high,
      category: Category.study,
    ),
    Task(
      id: '2',
      title: 'Lab Supplies',
      description: 'Buy chemicals for chemistry lab',
      dueDate: DateTime.now(),
      isCompleted: true,
      priority: Priority.low,
      category: Category.work,
    ),
    Task(
      id: '3',
      title: 'Gym Session',
      description: 'Leg day workout',
      dueDate: DateTime.now().add(const Duration(hours: 5)),
      priority: Priority.medium,
      category: Category.health,
    ),
  ];

  static List<Schedule> schedule = [
    Schedule(
      id: '1',
      subject: 'Mathematics',
      time: '09:00 AM',
      room: 'Room 101',
      professor: 'Prof. Smith',
      details: 'Topic: Triple Integrals',
      color: Colors.blueAccent,
    ),
    Schedule(
      id: '2',
      subject: 'Physics Lab',
      time: '11:00 AM',
      room: 'Lab 3',
      professor: 'Dr. Alan',
      details: 'Optics and Prisms',
      color: Colors.orangeAccent,
    ),
    Schedule(
      id: '3',
      subject: 'Computer Sci',
      time: '01:30 PM',
      room: 'Room 204',
      professor: 'Prof. Turing',
      details: 'Algorithm Design',
      color: Colors.deepPurpleAccent,
    ),
  ];

  static List<Note> notes = [
    Note(
      id: '1',
      text: 'Project Deadline: April 25th. Need to submit the initial draft.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      color: Colors.amber.shade100,
      isPinned: true,
    ),
    Note(
      id: '2',
      text: 'Meeting with Prof. Alan regarding internship opportunities.',
      date: DateTime.now(),
      color: Colors.lightBlue.shade100,
    ),
  ];
}

// ==========================================
// 2. THEME & DESIGN CONSTANTS
// ==========================================

class AppColors {
  static const primary = Color(0xFF6366F1); // Indigo
  static const secondary = Color(0xFFF59E0B); // Amber/Orange
  static const accent = Color(0xFF10B981); // Emerald
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const grey = Color(0xFF94A3B8);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);

  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppStyles {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static TextStyle heading = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle subheading = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}

// ==========================================
// 3. MAIN APPLICATION
// ==========================================

class SmartStudentApp extends StatelessWidget {
  const SmartStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Student',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: AppColors.surface,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
      },
    );
  }
}

// ==========================================
// 4. MAIN SCREEN & NAVIGATION
// ==========================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const ScheduleTab(),
    const NotesTab(),
    const FocusTimerTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Home'),
                _buildNavItem(1, Icons.calendar_today_rounded, 'Schedule'),
                _buildNavItem(2, Icons.description_rounded, 'Notes'),
                _buildNavItem(3, Icons.timer_rounded, 'Focus'),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _tabs[_currentIndex],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.grey,
              size: 24,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. DASHBOARD TAB
// ==========================================

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    int totalTasks = AppData.tasks.length;
    int completedTasks = AppData.tasks.where((t) => t.isCompleted).length;
    double progress = totalTasks == 0 ? 0 : completedTasks / totalTasks;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back, Student!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have ${totalTasks - completedTasks} tasks remaining for today.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(progress, completedTasks, totalTasks),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ongoing Tasks', style: AppStyles.heading.copyWith(fontSize: 20)),
                    IconButton(
                      onPressed: _showAddTask,
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = AppData.tasks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _TaskCard(
                  task: task,
                  onChanged: (val) => setState(() => task.isCompleted = val!),
                  onDelete: () => setState(() => AppData.tasks.removeAt(index)),
                ),
              );
            },
            childCount: AppData.tasks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showAddTask() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    Priority selectedPriority = Priority.medium;
    Category selectedCategory = Category.study;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Create New Task', style: AppStyles.heading.copyWith(fontSize: 22)),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Task Title',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: Priority.values.map((p) {
                    bool isSelected = selectedPriority == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) => setModalState(() => selectedPriority = p),
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: Category.values.map((c) {
                    bool isSelected = selectedCategory == c;
                    return ChoiceChip(
                      label: Text(c.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (val) => setModalState(() => selectedCategory = c),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontSize: 10),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        setState(() {
                          AppData.tasks.insert(0, Task(
                            id: DateTime.now().toString(),
                            title: titleController.text,
                            description: descController.text,
                            dueDate: DateTime.now().add(const Duration(days: 1)),
                            priority: selectedPriority,
                            category: selectedCategory,
                          ));
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('CREATE TASK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(double progress, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration.copyWith(
        color: AppColors.primary,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of $total tasks completed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (task.priority) {
      case Priority.high:
        priorityColor = Colors.redAccent;
        break;
      case Priority.medium:
        priorityColor = Colors.orangeAccent;
        break;
      case Priority.low:
        priorityColor = Colors.blueAccent;
        break;
    }

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppStyles.cardDecoration,
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? AppColors.grey : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${task.dueDate.day}/${task.dueDate.month}',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                      const SizedBox(width: 12),
                      _buildTag(task.category.name.toUpperCase(), AppColors.grey.withOpacity(0.1), AppColors.grey),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ==========================================
// 6. SCHEDULE TAB
// ==========================================

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Schedule', style: AppStyles.heading),
              IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: AppData.schedule.length,
            itemBuilder: (context, index) {
              final item = AppData.schedule[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(
                          item.time.split(' ')[0],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          item.time.split(' ')[1],
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppStyles.cardDecoration.copyWith(
                          border: Border(left: BorderSide(color: item.color, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subject,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.room} • ${item.professor}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (item.details.isNotEmpty) ...[
                              const Divider(height: 20),
                              Text(item.details, style: const TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 7. NOTES TAB
// ==========================================

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Study Notes', style: AppStyles.heading),
              FloatingActionButton.small(
                onPressed: _showAddNote,
                elevation: 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: AppData.notes.length,
            itemBuilder: (context, index) {
              final note = AppData.notes[index];
              return GestureDetector(
                onLongPress: () => setState(() => AppData.notes.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppStyles.cardDecoration.copyWith(color: note.color),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.isPinned)
                        const Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.push_pin_rounded, size: 16, color: AppColors.textSecondary),
                        ),
                      Expanded(
                        child: Text(
                          note.text,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${note.date.day}/${note.date.month}/${note.date.year}',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddNote() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Quick Note', style: AppStyles.heading.copyWith(fontSize: 22)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 6,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      AppData.notes.insert(0, Note(
                        id: DateTime.now().toString(),
                        text: controller.text,
                        date: DateTime.now(),
                        color: Colors.primaries[AppData.notes.length % Colors.primaries.length].shade50,
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('SAVE NOTE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. FOCUS TIMER TAB (POMODORO)
// ==========================================

class FocusTimerTab extends StatefulWidget {
  const FocusTimerTab({super.key});

  @override
  State<FocusTimerTab> createState() => _FocusTimerTabState();
}

class _FocusTimerTabState extends State<FocusTimerTab> {
  int _seconds = 1500; // 25 minutes
  Timer? _timer;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            _timer?.cancel();
            _isRunning = false;
          }
        });
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 1500;
      _isRunning = false;
    });
  }

  String _formatTime(int sec) {
    int min = sec ~/ 60;
    int s = sec % 60;
    return '${min.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = 1 - (_seconds / 1500);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Focus Session',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Stay away from distractions',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 250,
                  width: 250,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 8,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                SizedBox(
                  height: 250,
                  width: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    color: Colors.white,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  _formatTime(_seconds),
                  style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerButton(
                  onTap: _resetTimer,
                  icon: Icons.refresh_rounded,
                  label: 'Reset',
                ),
                const SizedBox(width: 32),
                _buildTimerButton(
                  onTap: _toggleTimer,
                  icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  label: _isRunning ? 'Pause' : 'Start',
                  isMain: true,
                ),
                const SizedBox(width: 32),
                _buildTimerButton(
                  onTap: () {},
                  icon: Icons.settings_rounded,
                  label: 'Config',
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerButton({required VoidCallback onTap, required IconData icon, required String label, bool isMain = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMain ? 24 : 16),
            decoration: BoxDecoration(
              color: isMain ? Colors.white : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isMain ? AppColors.primary : Colors.white,
              size: isMain ? 32 : 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
