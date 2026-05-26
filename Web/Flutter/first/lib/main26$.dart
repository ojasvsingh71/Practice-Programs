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

enum GameState { idle, countdown, playing, evaluating, gameOver }

enum Category { general, science, history, technology, popCulture }

enum Difficulty { easy, medium, hard }

enum PowerUpType { fiftyFifty, timeFreeze, skip }

class AppColors {
  static const Color background = Color(0xFF1E1B4B); // Deep Purple
  static const Color surface = Color(0xFF312E81); // Purple 800
  static const Color surfaceHighlight = Color(0xFF4338CA); // Purple 700

  static const Color primary = Color(0xFF8B5CF6); // Violet 500
  static const Color accent = Color(0xFFF43F5E); // Rose 500

  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color info = Color(0xFF06B6D4);

  static const Color correct = Color(0xFF10B981); // Emerald 500
  static const Color incorrect = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color gold = Color(0xFFFBBF24); // Leaderboard Gold
}

class AppStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: AppColors.textMain,
    letterSpacing: -1,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textMain,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );
  static const TextStyle score = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: AppColors.gold,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class GameConfig {
  static const int questionDurationSeconds = 15;
  static const int evaluationDurationSeconds = 3;
  static const int countdownDurationSeconds = 3;
  static const int maxLives = 3;
  static const int basePoints = 1000;
}

// ============================================================================
// 2. EXCEPTIONS & UTILS
// ============================================================================

abstract class QuizException implements Exception {
  final String message;
  QuizException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends QuizException {
  NetworkException([String m = "Network timeout."]) : super(m);
}

class AuthException extends QuizException {
  AuthException([String m = "Authentication failed."]) : super(m);
}

class Formatters {
  static String number(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String username;
  final String avatarUrl;
  int highestScore;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    this.highestScore = 0,
  });
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final Category category;
  final Difficulty difficulty;
  final String explanation;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.difficulty,
    required this.explanation,
  });
}

class LeaderboardEntry {
  final String id;
  final String username;
  final String avatarUrl;
  final int score;
  final DateTime date;

  LeaderboardEntry({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.score,
    required this.date,
  });
}

// ============================================================================
// 4. MOCK BACKEND ENGINE (Database & Sync)
// ============================================================================

class MockQuizEngine {
  static final MockQuizEngine _instance = MockQuizEngine._internal();
  factory MockQuizEngine() => _instance;

  final math.Random _random = math.Random();
  final List<Question> _database = [];
  final List<LeaderboardEntry> _leaderboard = [];

  MockQuizEngine._internal() {
    _seedData();
  }
  // Public unnamed constructor removed; singleton uses factory above.

  void _seedData() {
    // Seed Leaderboard
    final now = DateTime.now();
    _leaderboard.addAll([
      LeaderboardEntry(
        id: 'L1',
        username: 'TriviaMaster',
        avatarUrl: 'https://i.pravatar.cc/150?u=1',
        score: 45200,
        date: now.subtract(const Duration(days: 1)),
      ),
      LeaderboardEntry(
        id: 'L2',
        username: 'QuizWhiz',
        avatarUrl: 'https://i.pravatar.cc/150?u=2',
        score: 41000,
        date: now.subtract(const Duration(hours: 5)),
      ),
      LeaderboardEntry(
        id: 'L3',
        username: 'AlexD',
        avatarUrl: 'https://i.pravatar.cc/150?u=3',
        score: 38500,
        date: now.subtract(const Duration(days: 2)),
      ),
      LeaderboardEntry(
        id: 'L4',
        username: 'SmartyPants',
        avatarUrl: 'https://i.pravatar.cc/150?u=4',
        score: 35000,
        date: now,
      ),
      LeaderboardEntry(
        id: 'L5',
        username: 'Brainiac99',
        avatarUrl: 'https://i.pravatar.cc/150?u=5',
        score: 32450,
        date: now.subtract(const Duration(minutes: 30)),
      ),
    ]);

    // Seed Questions (Tech & Science for demo)
    _database.addAll([
      Question(
        id: 'Q1',
        category: Category.technology,
        difficulty: Difficulty.medium,
        text: 'In what year was the first iPhone released?',
        options: ['2005', '2007', '2008', '2010'],
        correctIndex: 1,
        explanation:
            'Steve Jobs unveiled the original iPhone on January 9, 2007.',
      ),
      Question(
        id: 'Q2',
        category: Category.science,
        difficulty: Difficulty.hard,
        text: 'What is the most abundant gas in the Earth\'s atmosphere?',
        options: ['Oxygen', 'Carbon Dioxide', 'Nitrogen', 'Hydrogen'],
        correctIndex: 2,
        explanation: 'Nitrogen makes up about 78% of the Earth\'s atmosphere.',
      ),
      Question(
        id: 'Q3',
        category: Category.technology,
        difficulty: Difficulty.easy,
        text: 'What does "HTTP" stand for?',
        options: [
          'HyperText Transfer Protocol',
          'HyperText Transmission Process',
          'Hyper Transfer Text Protocol',
          'Hyperlink Transfer Technology',
        ],
        correctIndex: 0,
        explanation:
            'HTTP is the foundation of data communication for the World Wide Web.',
      ),
      Question(
        id: 'Q4',
        category: Category.general,
        difficulty: Difficulty.medium,
        text: 'Which planet is known as the Red Planet?',
        options: ['Venus', 'Jupiter', 'Mars', 'Saturn'],
        correctIndex: 2,
        explanation:
            'Mars appears red due to iron oxide (rust) on its surface.',
      ),
      Question(
        id: 'Q5',
        category: Category.history,
        difficulty: Difficulty.hard,
        text: 'Who was the first Emperor of Rome?',
        options: ['Julius Caesar', 'Augustus', 'Nero', 'Caligula'],
        correctIndex: 1,
        explanation:
            'Augustus founded the Roman Empire and was its first emperor in 27 BC.',
      ),
      Question(
        id: 'Q6',
        category: Category.science,
        difficulty: Difficulty.medium,
        text: 'What is the chemical symbol for Gold?',
        options: ['Go', 'Ag', 'Au', 'Gd'],
        correctIndex: 2,
        explanation: 'Au comes from the Latin word "aurum", meaning gold.',
      ),
      Question(
        id: 'Q7',
        category: Category.popCulture,
        difficulty: Difficulty.easy,
        text: 'Who directed the movie "Inception"?',
        options: [
          'Steven Spielberg',
          'Christopher Nolan',
          'Quentin Tarantino',
          'James Cameron',
        ],
        correctIndex: 1,
        explanation: 'Christopher Nolan directed Inception, released in 2010.',
      ),
      Question(
        id: 'Q8',
        category: Category.technology,
        difficulty: Difficulty.hard,
        text: 'Which programming language was created by Brendan Eich?',
        options: ['Python', 'Java', 'JavaScript', 'C++'],
        correctIndex: 2,
        explanation: 'JavaScript was created by Brendan Eich in 1995.',
      ),
    ]);
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(400)));

  Future<User> login() async {
    await _latency(800);
    return User(
      id: 'U_ME',
      username: 'PlayerOne',
      avatarUrl: 'https://i.pravatar.cc/150?u=me',
      highestScore: 28000,
    );
  }

  Future<List<Question>> fetchQuestions(Category? category, int count) async {
    await _latency(600);
    List<Question> pool = category == null
        ? List.from(_database)
        : _database.where((q) => q.category == category).toList();
    pool.shuffle(_random);
    return pool.take(count).toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    await _latency();
    _leaderboard.sort((a, b) => b.score.compareTo(a.score));
    return List.unmodifiable(_leaderboard);
  }

  Future<void> submitScore(User user, int score) async {
    await _latency(1000);
    if (_random.nextDouble() < 0.1)
      throw NetworkException("Failed to sync score."); // 10% failure chance

    _leaderboard.add(
      LeaderboardEntry(
        id: 'L_${DateTime.now().millisecondsSinceEpoch}',
        username: user.username,
        avatarUrl: user.avatarUrl,
        score: score,
        date: DateTime.now(),
      ),
    );

    if (score > user.highestScore) user.highestScore = score;
  }
}

// ============================================================================
// 5. STATE MANAGEMENT & GAME LOOP ENGINE
// ============================================================================

class QuizState extends ChangeNotifier {
  final MockQuizEngine _api = MockQuizEngine();

  User? currentUser;
  bool isGlobalLoading = true;
  String? globalError;

  // Game Loop State
  GameState gameState = GameState.idle;
  List<Question> currentSessionQuestions = [];
  int currentQuestionIndex = 0;

  // Real-time Variables
  int score = 0;
  int comboStreak = 0;
  int lives = GameConfig.maxLives;
  int _timeRemaining = 0;
  Timer? _timer;

  // Power-Ups Inventory
  Map<PowerUpType, int> powerUps = {
    PowerUpType.fiftyFifty: 2,
    PowerUpType.timeFreeze: 1,
    PowerUpType.skip: 1,
  };

  // Active Question Transient State
  int? selectedOptionIndex;
  bool timeFrozen = false;
  List<int> hiddenOptions = []; // For 50/50

  // Leaderboard
  List<LeaderboardEntry> leaderboard = [];

  QuizState() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      currentUser = await _api.login();
      await fetchLeaderboard();
    } catch (e) {
      globalError = "Failed to initialize game.";
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaderboard() async {
    leaderboard = await _api.getLeaderboard();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- GAME LOOP ENGINE ---

  Future<void> startGame(Category? category) async {
    isGlobalLoading = true;
    notifyListeners();
    try {
      currentSessionQuestions = await _api.fetchQuestions(
        category,
        5,
      ); // 5 questions for demo
      if (currentSessionQuestions.isEmpty)
        throw Exception("No questions available.");

      // Reset State
      score = 0;
      comboStreak = 0;
      lives = GameConfig.maxLives;
      currentQuestionIndex = 0;

      _startCountdown();
    } on QuizException catch (e) {
      globalError = e.message;
      gameState = GameState.idle;
      notifyListeners();
    } finally {
      isGlobalLoading = false;
    }
  }

  void _startCountdown() {
    gameState = GameState.countdown;
    _timeRemaining = GameConfig.countdownDurationSeconds;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 1) {
        _timeRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        _presentQuestion();
      }
    });
  }

  void _presentQuestion() {
    gameState = GameState.playing;
    selectedOptionIndex = null;
    timeFrozen = false;
    hiddenOptions.clear();
    _timeRemaining = GameConfig.questionDurationSeconds;
    notifyListeners();

    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeFrozen) return;

      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        submitAnswer(null); // Time out
      }
    });
  }

  void submitAnswer(int? index) {
    if (gameState != GameState.playing) return;
    _timer?.cancel();
    selectedOptionIndex = index;
    gameState = GameState.evaluating;

    final currentQ = currentSessionQuestions[currentQuestionIndex];
    final isCorrect = index == currentQ.correctIndex;

    if (isCorrect) {
      comboStreak++;
      // Score calculation: Base + (TimeRemaining * 10) * ComboMultiplier
      double comboMultiplier = 1.0 + (comboStreak * 0.1);
      int pointsEarned =
          ((GameConfig.basePoints + (_timeRemaining * 50)) * comboMultiplier)
              .toInt();
      score += pointsEarned;
    } else {
      comboStreak = 0;
      lives--;
    }

    notifyListeners();

    // Evaluation Delay
    Timer(const Duration(seconds: GameConfig.evaluationDurationSeconds), () {
      if (lives <= 0 ||
          currentQuestionIndex >= currentSessionQuestions.length - 1) {
        _endGame();
      } else {
        currentQuestionIndex++;
        _presentQuestion();
      }
    });
  }

  void _endGame() async {
    gameState = GameState.gameOver;
    notifyListeners();

    try {
      await _api.submitScore(currentUser!, score);
      await fetchLeaderboard();
    } catch (e) {
      globalError = "Score submitted offline. Will sync later.";
      notifyListeners();
    }
  }

  void exitToMenu() {
    _timer?.cancel();
    gameState = GameState.idle;
    notifyListeners();
  }

  // --- POWER UPS ---
  void usePowerUp(PowerUpType type) {
    if (gameState != GameState.playing || (powerUps[type] ?? 0) <= 0) return;

    powerUps[type] = powerUps[type]! - 1;

    final q = currentSessionQuestions[currentQuestionIndex];

    switch (type) {
      case PowerUpType.fiftyFifty:
        // Hide two incorrect options
        List<int> wrongIndices = [0, 1, 2, 3]..remove(q.correctIndex);
        wrongIndices.shuffle();
        hiddenOptions = [wrongIndices[0], wrongIndices[1]];
        break;
      case PowerUpType.timeFreeze:
        timeFrozen = true;
        break;
      case PowerUpType.skip:
        _timer?.cancel();
        // Grant base points, no combo increase, move to next
        score += GameConfig.basePoints;
        if (currentQuestionIndex >= currentSessionQuestions.length - 1) {
          _endGame();
        } else {
          currentQuestionIndex++;
          _presentQuestion();
        }
        break;
    }
    notifyListeners();
  }

  // Getters
  Question get currentQuestion => currentSessionQuestions[currentQuestionIndex];
  double get timerProgress =>
      _timeRemaining / GameConfig.questionDurationSeconds;
}

class AppStore extends InheritedNotifier<QuizState> {
  const AppStore({Key? key, required QuizState state, required Widget child})
    : super(key: key, notifier: state, child: child);
  static QuizState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStore>()!.notifier!;
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
  runApp(const QuizGameApp());
}

class QuizGameApp extends StatelessWidget {
  const QuizGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: QuizState(),
      child: MaterialApp(
        title: 'Nexus Trivia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto', // Fallback standard
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({Key? key}) : super(key: key);

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

    switch (state.gameState) {
      case GameState.idle:
        return const MainMenuScreen();
      case GameState.countdown:
        return const CountdownScreen();
      case GameState.playing:
      case GameState.evaluating:
        return const ActiveGameScreen();
      case GameState.gameOver:
        return const GameOverScreen();
    }
  }
}

// ============================================================================
// 7. MAIN MENU & LEADERBOARD
// ============================================================================

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: _tabIndex == 0
          ? _buildPlayTab(context, state)
          : _buildLeaderboardTab(state),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill),
            label: 'Play',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Rankings',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayTab(BuildContext context, QuizState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${state.currentUser!.username}',
                      style: AppStyles.h2,
                    ),
                    Text(
                      'High Score: ${Formatters.number(state.currentUser!.highestScore)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(state.currentUser!.avatarUrl),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.psychology, size: 120, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'NEXUS TRIVIA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const Text(
              'Test your knowledge. Top the global ranks.',
              textAlign: TextAlign.center,
              style: AppStyles.caption,
            ),
            const Spacer(),

            if (state.isGlobalLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => state.startGame(null),
                child: const Text(
                  'QUICK PLAY (MIXED)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMain,
                  side: const BorderSide(
                    color: AppColors.surfaceHighlight,
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _showCategorySelection(context, state),
                child: const Text(
                  'SELECT CATEGORY',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCategorySelection(BuildContext context, QuizState state) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Category', style: AppStyles.h2),
            const SizedBox(height: 16),
            ...Category.values
                .map(
                  (c) => ListTile(
                    leading: Icon(
                      _getCategoryIcon(c),
                      color: AppColors.primary,
                    ),
                    title: Text(
                      c.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.play_arrow,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      state.startGame(c);
                    },
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(Category c) {
    switch (c) {
      case Category.general:
        return Icons.public;
      case Category.science:
        return Icons.science;
      case Category.history:
        return Icons.account_balance;
      case Category.technology:
        return Icons.computer;
      case Category.popCulture:
        return Icons.movie;
    }
  }

  Widget _buildLeaderboardTab(QuizState state) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Global Top 50', style: AppStyles.h1),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: state.fetchLeaderboard,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.leaderboard.length,
                itemBuilder: (ctx, i) {
                  final entry = state.leaderboard[i];
                  final isMe = entry.username == state.currentUser!.username;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: isMe
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '#${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: i < 3
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            backgroundImage: NetworkImage(entry.avatarUrl),
                          ),
                        ],
                      ),
                      title: Text(
                        entry.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMe ? AppColors.primary : AppColors.textMain,
                        ),
                      ),
                      trailing: Text(
                        Formatters.number(entry.score),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. ACTIVE GAME UI (Timers, Options, Power-ups)
// ============================================================================

class CountdownScreen extends StatelessWidget {
  const CountdownScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(state._timeRemaining),
          tween: Tween<double>(begin: 0.5, end: 1.5),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (ctx, val, child) => Transform.scale(
            scale: val,
            child: Text(
              '${state._timeRemaining}',
              style: const TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveGameScreen extends StatelessWidget {
  const ActiveGameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final q = state.currentQuestion;
    final isEvaluating = state.gameState == GameState.evaluating;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context, state),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: AppColors.accent, size: 20),
            const SizedBox(width: 4),
            Text(
              '${state.lives}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                Formatters.number(state.score),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Meta Info & Combo
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Q ${state.currentQuestionIndex + 1}/${state.currentSessionQuestions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (state.comboStreak >= 2)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                      decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      '${state.comboStreak}x COMBO!',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Animated Timer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _TimerPainter(
                        progress: state.timerProgress,
                        isFrozen: state.timeFrozen,
                      ),
                    ),
                  ),
                  Text(
                    isEvaluating ? '...' : '${state._timeRemaining}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: state.timeFrozen
                          ? AppColors.info
                          : AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Question Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Text(
                  q.text,
                  textAlign: TextAlign.center,
                  style: AppStyles.h2.copyWith(height: 1.3),
                ),
              ),
            ),
          ),

          // Options Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: List.generate(4, (index) {
                if (state.hiddenOptions.contains(index)) {
                  return const SizedBox(
                    height: 60,
                    width: double.infinity,
                  ); // Empty space for 50/50
                }

                bool isSelected = state.selectedOptionIndex == index;
                bool isCorrectOption = index == q.correctIndex;

                Color bgColor = AppColors.surface;
                Color borderColor = AppColors.surfaceHighlight;

                    if (isEvaluating) {
                  if (isCorrectOption) {
                    bgColor = AppColors.correct.withOpacity(0.2);
                    borderColor = AppColors.correct;
                  } else if (isSelected && !isCorrectOption) {
                    bgColor = AppColors.incorrect.withOpacity(0.2);
                    borderColor = AppColors.incorrect;
                  }
                } else if (isSelected) {
                  bgColor = AppColors.primary.withOpacity(0.3);
                  borderColor = AppColors.primary;
                }

                return GestureDetector(
                  onTap: isEvaluating ? null : () => state.submitAnswer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        q.options[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Explanation (Visible during evaluation)
          if (isEvaluating)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                q.explanation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            const SizedBox(height: 50),

          // Power-ups Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PowerUpButton(
                    type: PowerUpType.fiftyFifty,
                    icon: Icons.exposure_minus_2,
                    label: '50/50',
                    count: state.powerUps[PowerUpType.fiftyFifty]!,
                    onPressed: () => state.usePowerUp(PowerUpType.fiftyFifty),
                    isEnabled: !isEvaluating && !state.hiddenOptions.isNotEmpty,
                  ),
                  _PowerUpButton(
                    type: PowerUpType.timeFreeze,
                    icon: Icons.ac_unit,
                    label: 'Freeze',
                    count: state.powerUps[PowerUpType.timeFreeze]!,
                    onPressed: () => state.usePowerUp(PowerUpType.timeFreeze),
                    isEnabled: !isEvaluating && !state.timeFrozen,
                  ),
                  _PowerUpButton(
                    type: PowerUpType.skip,
                    icon: Icons.fast_forward,
                    label: 'Skip',
                    count: state.powerUps[PowerUpType.skip]!,
                    onPressed: () => state.usePowerUp(PowerUpType.skip),
                    isEnabled: !isEvaluating,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context, QuizState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Quit Game?'),
        content: const Text(
          'You will lose all progress and score for this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.incorrect,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              state.exitToMenu();
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  final PowerUpType type;
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onPressed;
  final bool isEnabled;
  const _PowerUpButton({
    required this.type,
    required this.icon,
    required this.label,
    required this.count,
    required this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    bool canUse = isEnabled && count > 0;
    return Opacity(
      opacity: canUse ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: canUse ? onPressed : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final bool isFrozen;
  _TimerPainter({required this.progress, required this.isFrozen});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeW = 8.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    Color activeColor = AppColors.correct;
    if (isFrozen)
      activeColor = AppColors.info; // Cyan for frozen
    else if (progress < 0.25)
      activeColor = AppColors.incorrect;
    else if (progress < 0.5)
      activeColor = AppColors.warning;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter old) =>
      old.progress != progress || old.isFrozen != isFrozen;
}

// ============================================================================
// 9. GAME OVER SCREEN & CONFETTI
// ============================================================================

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final isNewHighScore = state.score > state.currentUser!.highestScore;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti Background
          Positioned.fill(
            child: _ConfettiWidget(
              isEmitting: state.lives > 0,
            ), // Only confetti if won/survived
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.lives > 0 ? 'QUIZ COMPLETED!' : 'GAME OVER',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: state.lives > 0
                          ? AppColors.correct
                          : AppColors.incorrect,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isNewHighScore && state.lives > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: const Text(
                        'NEW HIGH SCORE!',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 48),

                  const Text('Final Score', style: AppStyles.caption),
                  Text(
                    Formatters.number(state.score),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Stats Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        label: 'Questions',
                        value:
                            '${state.currentQuestionIndex + (state.lives > 0 ? 1 : 0)}',
                      ),
                      _StatColumn(
                        label: 'Lives Left',
                        value: '${math.max(0, state.lives)}',
                      ),
                    ],
                  ),

                  const Spacer(),
                  if (state.globalError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        state.globalError!,
                        style: const TextStyle(
                          color: AppColors.incorrect,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => state.exitToMenu(),
                      child: const Text(
                        'RETURN TO MENU',
                        style: TextStyle(
                          fontSize: 16,
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
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppStyles.caption),
      ],
    );
  }
}

// --- CONFETTI PARTICLE SYSTEM ---

class _ConfettiWidget extends StatefulWidget {
  final bool isEmitting;
  const _ConfettiWidget({required this.isEmitting});
  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final math.Random _rand = math.Random();

  @override
  void initState() {
    super.initState();
    if (widget.isEmitting) {
      _initParticles();
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      )..forward();
    } else {
      _ctrl = AnimationController(vsync: this);
    }
  }

  void _initParticles() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];
    for (int i = 0; i < 150; i++) {
      _particles.add(
        _Particle(
          x: _rand.nextDouble(), // relative 0-1
          y: -0.1 - _rand.nextDouble() * 0.5, // Start above screen
          vx: (_rand.nextDouble() - 0.5) * 0.5, // Velocity X
          vy: 0.5 + _rand.nextDouble() * 1.5, // Velocity Y
          color: colors[_rand.nextInt(colors.length)],
          size: 4 + _rand.nextDouble() * 6,
          rotation: _rand.nextDouble() * math.pi * 2,
          rotSpeed: (_rand.nextDouble() - 0.5) * 10,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEmitting) return const SizedBox();
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _ConfettiPainter(particles: _particles, progress: _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, size, rotation, rotSpeed;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    for (var p in particles) {
      // Calculate current position based on progress (time)
      double t = progress * 5; // Scale time
      double currentX = size.width * (p.x + p.vx * t);
      double currentY =
          size.height *
          (p.y + p.vy * t + 0.5 * 0.5 * t * t); // Add gravity (0.5 * g * t^2)

      if (currentY > size.height) continue; // Off screen

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + p.rotSpeed * t);

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
      // Draw small rectangle for confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true; // Constant animation
}
