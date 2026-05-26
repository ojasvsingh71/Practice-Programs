import 'dart:async';
import 'dart:math';
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
// ENTRY POINT
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const LinguaApp());
}

// ============================================================================
// STATE MANAGEMENT & GLOBAL APP STATE
// ============================================================================

/// We use a central AppState with ChangeNotifier to act as our global store,
/// avoiding the need for external packages like Provider or Riverpod.
class AppState extends ChangeNotifier {
  // User Profile Data
  String userName = "Polyglot Student";
  int totalXp = 0;
  int currentStreak = 12;
  int dailyGoalXp = 50;
  int xpToday = 0;

  // Language Data
  String targetLanguage = "Spanish";
  String baseLanguage = "English";

  // Data Collections
  List<Lesson> lessons = MockData.getLessons();
  List<VocabularyWord> vocabularyDatabase = MockData.getVocabulary();
  List<Quiz> quizzes = MockData.getQuizzes();

  // Progress Tracking
  Set<String> completedLessonIds = {};
  Set<String> completedQuizIds = {};

  // Initialization
  AppState() {
    _calculateInitialSRS();
  }

  // --- Methods ---

  void addXp(int amount) {
    totalXp += amount;
    xpToday += amount;
    notifyListeners();
  }

  void markLessonComplete(String lessonId) {
    if (!completedLessonIds.contains(lessonId)) {
      completedLessonIds.add(lessonId);
      addXp(20); // 20 XP for a lesson
    }
  }

  void markQuizComplete(String quizId, int score) {
    if (!completedQuizIds.contains(quizId)) {
      completedQuizIds.add(quizId);
      addXp(score * 10); // XP based on score
    }
  }

  // --- Spaced Repetition System (SRS) Logic ---

  /// Simulates existing progress on app load
  void _calculateInitialSRS() {
    final now = DateTime.now();
    for (var i = 0; i < vocabularyDatabase.length; i++) {
      // Artificially make some cards due for review today
      if (i % 3 == 0) {
        vocabularyDatabase[i].nextReviewDate = now.subtract(
          const Duration(days: 1),
        );
        vocabularyDatabase[i].srsStage = 1;
      }
    }
  }

  /// Get list of words that are due for review
  List<VocabularyWord> getDueReviews() {
    final now = DateTime.now();
    return vocabularyDatabase
        .where((word) => word.nextReviewDate.isBefore(now))
        .toList();
  }

  /// Process an SRS review using a modified SuperMemo-2 algorithm
  /// Quality: 0 (Complete blackout) to 5 (Perfect response)
  void processSRSReview(VocabularyWord word, int quality) {
    // SM-2 Algorithm Implementation
    if (quality >= 3) {
      if (word.repetitionCount == 0) {
        word.intervalDays = 1;
      } else if (word.repetitionCount == 1) {
        word.intervalDays = 6;
      } else {
        word.intervalDays = (word.intervalDays * word.easeFactor).round();
      }
      word.repetitionCount++;
    } else {
      word.repetitionCount = 0;
      word.intervalDays = 1;
    }

    word.easeFactor =
        word.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (word.easeFactor < 1.3) {
      word.easeFactor = 1.3; // Minimum bounds
    }

    // Set next review date
    word.nextReviewDate = DateTime.now().add(Duration(days: word.intervalDays));
    word.srsStage = _calculateStage(word.intervalDays);

    // Reward XP for reviewing
    addXp(2);
    notifyListeners();
  }

  int _calculateStage(int intervalDays) {
    if (intervalDays <= 1) return 1; // Apprentice
    if (intervalDays <= 6) return 2; // Guru
    if (intervalDays <= 21) return 3; // Master
    if (intervalDays <= 60) return 4; // Enlightened
    return 5; // Burned
  }
}

// Global instance for simplistic state injection in this single-file structure
final AppState globalState = AppState();

// ============================================================================
// DATA MODELS
// ============================================================================

class Lesson {
  final String id;
  final String title;
  final String description;
  final String content;
  final String difficulty;
  final int estimatedMinutes;
  final List<String> introducedVocabularyIds;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.introducedVocabularyIds,
  });
}

class VocabularyWord {
  final String id;
  final String targetWord;
  final String translation;
  final String pos; // Part of speech
  final String exampleSentenceTarget;
  final String exampleSentenceBase;

  // SRS Properties
  DateTime nextReviewDate;
  int repetitionCount;
  double easeFactor;
  int intervalDays;
  int
  srsStage; // 0: New, 1: Apprentice, 2: Guru, 3: Master, 4: Enlightened, 5: Burned

  VocabularyWord({
    required this.id,
    required this.targetWord,
    required this.translation,
    required this.pos,
    required this.exampleSentenceTarget,
    required this.exampleSentenceBase,
    DateTime? nextReviewDate,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now(),
       repetitionCount = 0,
       easeFactor = 2.5,
       intervalDays = 0,
       srsStage = 0;
}

class Quiz {
  final String id;
  final String title;
  final String associatedLessonId;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.associatedLessonId,
    required this.questions,
  });
}

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

// ============================================================================
// MOCK DATA GENERATOR
// ============================================================================

class MockData {
  static List<VocabularyWord> getVocabulary() {
    return [
      VocabularyWord(
        id: "v1",
        targetWord: "Hola",
        translation: "Hello",
        pos: "Greeting",
        exampleSentenceTarget: "¡Hola! ¿Cómo estás?",
        exampleSentenceBase: "Hello! How are you?",
      ),
      VocabularyWord(
        id: "v2",
        targetWord: "Adiós",
        translation: "Goodbye",
        pos: "Greeting",
        exampleSentenceTarget: "Me tengo que ir, ¡adiós!",
        exampleSentenceBase: "I have to go, goodbye!",
      ),
      VocabularyWord(
        id: "v3",
        targetWord: "Gracias",
        translation: "Thank you",
        pos: "Expression",
        exampleSentenceTarget: "Gracias por tu ayuda.",
        exampleSentenceBase: "Thank you for your help.",
      ),
      VocabularyWord(
        id: "v4",
        targetWord: "Por favor",
        translation: "Please",
        pos: "Expression",
        exampleSentenceTarget: "Un café, por favor.",
        exampleSentenceBase: "A coffee, please.",
      ),
      VocabularyWord(
        id: "v5",
        targetWord: "Perdón",
        translation: "Excuse me / Sorry",
        pos: "Expression",
        exampleSentenceTarget: "Perdón, no te escuché.",
        exampleSentenceBase: "Sorry, I didn't hear you.",
      ),
      VocabularyWord(
        id: "v6",
        targetWord: "Agua",
        translation: "Water",
        pos: "Noun",
        exampleSentenceTarget: "Necesito beber agua.",
        exampleSentenceBase: "I need to drink water.",
      ),
      VocabularyWord(
        id: "v7",
        targetWord: "Comida",
        translation: "Food",
        pos: "Noun",
        exampleSentenceTarget: "La comida está deliciosa.",
        exampleSentenceBase: "The food is delicious.",
      ),
      VocabularyWord(
        id: "v8",
        targetWord: "Gato",
        translation: "Cat",
        pos: "Noun",
        exampleSentenceTarget: "Mi gato es negro.",
        exampleSentenceBase: "My cat is black.",
      ),
      VocabularyWord(
        id: "v9",
        targetWord: "Perro",
        translation: "Dog",
        pos: "Noun",
        exampleSentenceTarget: "El perro ladra mucho.",
        exampleSentenceBase: "The dog barks a lot.",
      ),
      VocabularyWord(
        id: "v10",
        targetWord: "Casa",
        translation: "House",
        pos: "Noun",
        exampleSentenceTarget: "Mi casa es tu casa.",
        exampleSentenceBase: "My house is your house.",
      ),
      VocabularyWord(
        id: "v11",
        targetWord: "Libro",
        translation: "Book",
        pos: "Noun",
        exampleSentenceTarget: "Estoy leyendo un libro interesante.",
        exampleSentenceBase: "I am reading an interesting book.",
      ),
      VocabularyWord(
        id: "v12",
        targetWord: "Tiempo",
        translation: "Time / Weather",
        pos: "Noun",
        exampleSentenceTarget: "¿Qué tiempo hace hoy?",
        exampleSentenceBase: "What is the weather like today?",
      ),
    ];
  }

  static List<Lesson> getLessons() {
    return [
      Lesson(
        id: "l1",
        title: "Basics 1: Greetings",
        description: "Learn how to say hello, goodbye, and basic courtesies.",
        difficulty: "Beginner",
        estimatedMinutes: 5,
        introducedVocabularyIds: ["v1", "v2", "v3", "v4", "v5"],
        content: """
Welcome to your first Spanish lesson!

In Spanish, greetings are essential. The most common way to say hello is **Hola**. The 'H' is silent, so it's pronounced 'oh-la'.

When leaving, you can say **Adiós**.

To be polite, always use **Por favor** (please) and **Gracias** (thank you). If you bump into someone or need to apologize, say **Perdón**.

Practice these out loud. In the next section, you will be tested on these five essential phrases.
        """,
      ),
      Lesson(
        id: "l2",
        title: "Food & Drink",
        description:
            "Essential vocabulary for survival: ordering water and food.",
        difficulty: "Beginner",
        estimatedMinutes: 8,
        introducedVocabularyIds: ["v6", "v7"],
        content: """
Let's talk about sustenance.

**Agua** means water. It's a feminine noun, but takes the masculine article 'el' in the singular to avoid clashing sounds: *El agua*.

**Comida** refers to food or a meal. 

When you go to a restaurant, you might say: "Agua y comida, por favor" (Water and food, please). Combine what you learned in Lesson 1!
        """,
      ),
      Lesson(
        id: "l3",
        title: "Animals & Home",
        description:
            "Expand your noun vocabulary with common household items and pets.",
        difficulty: "Intermediate",
        estimatedMinutes: 10,
        introducedVocabularyIds: ["v8", "v9", "v10", "v11", "v12"],
        content: """
Vocabulary expansion!

Pets are common in the Spanish-speaking world. A cat is a **Gato** and a dog is a **Perro**. Note the rolled 'rr' in perro. If you say 'pero' with a single 'r', it means 'but'!

You live in a **Casa** (house). When relaxing at home, you might read a **Libro** (book).

Finally, **Tiempo** can mean both 'time' (Do you have time?) and 'weather' (The weather is nice). Context is key.
        """,
      ),
    ];
  }

  static List<Quiz> getQuizzes() {
    return [
      Quiz(
        id: "q1",
        title: "Greetings Knowledge Check",
        associatedLessonId: "l1",
        questions: [
          QuizQuestion(
            questionText: "How do you say 'Hello' in Spanish?",
            options: ["Adiós", "Hola", "Gracias", "Perdón"],
            correctOptionIndex: 1,
            explanation: "'Hola' is the standard greeting. The 'H' is silent.",
          ),
          QuizQuestion(
            questionText: "If someone helps you, what should you say?",
            options: ["Por favor", "Agua", "Gracias", "Hola"],
            correctOptionIndex: 2,
            explanation: "'Gracias' means thank you.",
          ),
          QuizQuestion(
            questionText: "Which word means 'Please'?",
            options: ["Perdón", "Por favor", "Adiós", "Gato"],
            correctOptionIndex: 1,
            explanation:
                "'Por favor' translates directly to 'by favor', meaning please.",
          ),
        ],
      ),
      Quiz(
        id: "q2",
        title: "Survival Nouns",
        associatedLessonId: "l2",
        questions: [
          QuizQuestion(
            questionText: "Translate: 'I need water'",
            options: [
              "Necesito comida",
              "Necesito agua",
              "Necesito gato",
              "Necesito tiempo",
            ],
            correctOptionIndex: 1,
            explanation: "'Agua' is water.",
          ),
          QuizQuestion(
            questionText: "What does 'Comida' mean?",
            options: ["Water", "Please", "Food", "Dog"],
            correctOptionIndex: 2,
            explanation: "Comida means food or meal.",
          ),
        ],
      ),
    ];
  }
}

// ============================================================================
// APP ROOT & THEME
// ============================================================================

class LinguaApp extends StatelessWidget {
  const LinguaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: globalState,
      builder: (context, child) {
        return MaterialApp(
          title: 'LinguaApp',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF6C63FF),
            scaffoldBackgroundColor: const Color(0xFFF4F6F9),
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: const Color(0xFF6C63FF),
              secondary: const Color(0xFFFF6584),
              surface: Colors.white,
              background: const Color(0xFFF4F6F9),
              error: const Color(0xFFE53935),
            ),
            fontFamily:
                'Roboto', // Using default font but establishing family structure
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              displayMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF4F5D75)),
              bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4F5D75)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 2,
              ),
            ),
            cardColor: Colors.white,
          ),
          home: const MainWrapper(),
        );
      },
    );
  }
}

// ============================================================================
// MAIN NAVIGATION WRAPPER
// ============================================================================

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LearnScreen(),
    const PronunciationHubScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: "Learn",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_rounded),
              label: "Speak",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. HOME SCREEN (Dashboard & SRS Entry)
// ============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dueReviews = globalState.getDueReviews();
    final reviewCount = dueReviews.length;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Hola, ${globalState.userName}!",
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ready to learn Spanish?",
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${globalState.currentStreak}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Daily Goal Progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.yellowAccent),
                      SizedBox(width: 8),
                      Text(
                        "Daily Goal",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${globalState.xpToday} / ${globalState.dailyGoalXp} XP",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${((globalState.xpToday / globalState.dailyGoalXp) * 100).clamp(0, 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (globalState.xpToday / globalState.dailyGoalXp)
                          .clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.yellowAccent,
                      ),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // SRS Review Banner
            Text(
              "Spaced Repetition",
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: reviewCount > 0
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SRSReviewScreen(wordsToReview: dueReviews),
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: reviewCount > 0
                        ? theme.colorScheme.secondary
                        : Colors.grey.shade300,
                    width: 2,
                  ),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: reviewCount > 0
                            ? theme.colorScheme.secondary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.style_rounded,
                        color: reviewCount > 0
                            ? theme.colorScheme.secondary
                            : Colors.grey,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewCount > 0 ? "Reviews Due!" : "All caught up!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: reviewCount > 0
                                  ? theme.colorScheme.secondary
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reviewCount > 0
                                ? "You have $reviewCount cards to review to strengthen your memory."
                                : "Great job! Check back tomorrow for more reviews.",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (reviewCount > 0)
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              "Quick Actions",
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    title: "Take a Quiz",
                    icon: Icons.quiz_rounded,
                    color: Colors.blueAccent,
                    onTap: () {
                      // Just open the first quiz for quick action
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              QuizScreen(quiz: globalState.quizzes.first),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    title: "Speak",
                    icon: Icons.mic_rounded,
                    color: Colors.teal,
                    onTap: () {
                      // Navigate to pronunciation tab (hacky via replacement since it's bottom nav usually)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const Scaffold(body: PronunciationHubScreen()),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. LEARN SCREEN (Lesson List)
// ============================================================================

class LearnScreen extends StatelessWidget {
  const LearnScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Lessons",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: globalState.lessons.length,
          itemBuilder: (context, index) {
            final lesson = globalState.lessons[index];
            final isCompleted = globalState.completedLessonIds.contains(
              lesson.id,
            );
            // Lock logic: first lesson always unlocked. Others unlocked if previous is completed.
            final isLocked =
                index > 0 &&
                !globalState.completedLessonIds.contains(
                  globalState.lessons[index - 1].id,
                );

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                onTap: isLocked
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Complete the previous lesson to unlock this one.",
                            ),
                          ),
                        );
                      }
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonDetailScreen(lesson: lesson),
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(20),
                child: Opacity(
                  opacity: isLocked ? 0.6 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted ? Colors.green : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.withOpacity(0.1)
                                      : Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted
                                          ? Colors.green
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lesson.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${lesson.estimatedMinutes} min",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.bar_chart_rounded,
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          lesson.difficulty,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLocked)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        if (isCompleted)
                          const Positioned(
                            top: 16,
                            right: 16,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
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

// ============================================================================
// 3. LESSON DETAIL SCREEN
// ============================================================================

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vocabList = globalState.vocabularyDatabase
        .where((v) => lesson.introducedVocabularyIds.contains(v.id))
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                lesson.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lesson Content",
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      lesson.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "New Vocabulary",
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...vocabList
                      .map((word) => _buildVocabCard(word, theme))
                      .toList(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        globalState.markLessonComplete(lesson.id);

                        // Look for associated quiz
                        final associatedQuiz = globalState.quizzes
                            .where((q) => q.associatedLessonId == lesson.id)
                            .toList();

                        if (associatedQuiz.isNotEmpty) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuizScreen(quiz: associatedQuiz.first),
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lesson completed! +20 XP"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Complete Lesson",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabCard(VocabularyWord word, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              word.pos,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.targetWord,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  word.translation,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.blueAccent),
            onPressed: () {
              // Mock Audio playback
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. QUIZ SCREEN
// ============================================================================

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({Key? key, required this.quiz}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _hasAnswered = false;
  int? _selectedOptionIndex;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _updateProgress();
  }

  void _updateProgress() {
    double target = (_currentQuestionIndex) / widget.quiz.questions.length;
    _progressAnimation =
        Tween<double>(begin: _progressController.value, end: target).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );
    _progressController.forward(from: 0);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _submitAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedOptionIndex = index;
      _hasAnswered = true;
      if (index ==
          widget.quiz.questions[_currentQuestionIndex].correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _hasAnswered = false;
        _selectedOptionIndex = null;
        _updateProgress();
      });
    } else {
      // Quiz Finished
      globalState.markQuizComplete(widget.quiz.id, _score);
      _showResultsDialog();
    }
  }

  void _showResultsDialog() {
    final double percentage = _score / widget.quiz.questions.length;
    String feedback = percentage == 1.0
        ? "Perfect!"
        : percentage > 0.5
        ? "Good Job!"
        : "Keep Practicing!";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            feedback,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage > 0.5 ? Icons.emoji_events : Icons.refresh_rounded,
              size: 80,
              color: percentage > 0.5 ? Colors.amber : Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            Text(
              "You scored $_score out of ${widget.quiz.questions.length}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "+${_score * 10} XP Earned!",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to lesson/list
              },
              child: const Text("Continue"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedOptionIndex == index;
                    final isCorrect = index == question.correctOptionIndex;

                    Color tileColor = Colors.white;
                    Color borderColor = Colors.grey.shade300;
                    IconData? iconData;
                    Color iconColor = Colors.transparent;

                    if (_hasAnswered) {
                      if (isCorrect) {
                        tileColor = Colors.green.shade50;
                        borderColor = Colors.green;
                        iconData = Icons.check_circle_rounded;
                        iconColor = Colors.green;
                      } else if (isSelected && !isCorrect) {
                        tileColor = Colors.red.shade50;
                        borderColor = Colors.red;
                        iconData = Icons.cancel_rounded;
                        iconColor = Colors.red;
                      }
                    } else if (isSelected) {
                      borderColor = theme.primaryColor;
                      tileColor = theme.primaryColor.withOpacity(0.05);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () => _submitAnswer(index),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        isSelected ||
                                            (_hasAnswered && isCorrect)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (iconData != null)
                                Icon(iconData, color: iconColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_hasAnswered) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.explanation,
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedOptionIndex == question.correctOptionIndex
                          ? Colors.green
                          : theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentQuestionIndex == widget.quiz.questions.length - 1
                          ? "Finish Quiz"
                          : "Next Question",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. PRONUNCIATION HUB (Mock Speech to Text & Scoring)
// ============================================================================

class PronunciationHubScreen extends StatefulWidget {
  const PronunciationHubScreen({Key? key}) : super(key: key);

  @override
  State<PronunciationHubScreen> createState() => _PronunciationHubScreenState();
}

class _PronunciationHubScreenState extends State<PronunciationHubScreen>
    with TickerProviderStateMixin {
  final List<VocabularyWord> _practiceWords = globalState.vocabularyDatabase
      .take(5)
      .toList();
  int _currentIndex = 0;

  bool _isRecording = false;
  bool _hasResult = false;
  int _score = 0;

  late AnimationController _waveController;
  late AnimationController _scoreController;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _hasResult = false;
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _simulateScoring();
  }

  void _simulateScoring() {
    // Generate a random score mostly skewed high for positive reinforcement
    final random = Random();
    int targetScore = 70 + random.nextInt(31); // 70 to 100

    setState(() {
      _hasResult = true;
      _score = targetScore;
    });

    _scoreAnimation = IntTween(begin: 0, end: targetScore).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );
    _scoreController.forward(from: 0);

    if (targetScore > 80) {
      globalState.addXp(5); // Add XP for good pronunciation
    }
  }

  void _nextWord() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _practiceWords.length;
      _hasResult = false;
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = _practiceWords[_currentIndex];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pronunciation Practice",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Tap and hold to read the text below",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Target Word Display
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      word.targetWord,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      word.translation,
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Audio Waveform Visualization
              SizedBox(
                height: 80,
                child: _isRecording
                    ? AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: AudioWaveformPainter(
                              animationValue: _waveController.value,
                              color: theme.colorScheme.secondary,
                            ),
                            size: const Size(double.infinity, 80),
                          );
                        },
                      )
                    : _hasResult
                    ? AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (context, child) {
                          Color scoreColor = _score > 80
                              ? Colors.green
                              : (_score > 50 ? Colors.orange : Colors.red);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${_scoreAnimation.value}%",
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                              Text(
                                _score > 80 ? "Excellent!" : "Needs Work",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: scoreColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : const SizedBox(height: 80), // Empty placeholder
              ),

              const Spacer(),

              // Controls
              if (_hasResult)
                ElevatedButton.icon(
                  onPressed: _nextWord,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text("Next Word"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Record Button
              GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                onTapCancel: () => _stopRecording(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isRecording ? 100 : 80,
                  width: _isRecording ? 100 : 80,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? theme.colorScheme.secondary
                        : theme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isRecording
                                    ? theme.colorScheme.secondary
                                    : theme.primaryColor)
                                .withOpacity(0.4),
                        blurRadius: _isRecording ? 30 : 15,
                        spreadRadius: _isRecording ? 10 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: _isRecording ? 48 : 36,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for a fake audio waveform
class AudioWaveformPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  AudioWaveformPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final spacing = size.width / 20;

    for (int i = 0; i < 20; i++) {
      final x = i * spacing;
      // Generate a pseudo-random wave based on sine function and animation
      final noise =
          sin(i + animationValue * 2 * pi) * cos(i * 0.5 - animationValue * pi);
      final height = (noise.abs() * size.height * 0.8) + 10;

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ============================================================================
// 6. SPACED REPETITION (SRS) REVIEW SCREEN
// ============================================================================

class SRSReviewScreen extends StatefulWidget {
  final List<VocabularyWord> wordsToReview;

  const SRSReviewScreen({Key? key, required this.wordsToReview})
    : super(key: key);

  @override
  State<SRSReviewScreen> createState() => _SRSReviewScreenState();
}

class _SRSReviewScreenState extends State<SRSReviewScreen>
    with SingleTickerProviderStateMixin {
  late List<VocabularyWord> _queue;
  int _currentIndex = 0;
  bool _isFlipped = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.wordsToReview);
    _queue.shuffle(); // Randomize order

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (!_isFlipped) {
      _flipController.forward();
      setState(() {
        _isFlipped = true;
      });
    }
  }

  void _submitReview(int quality) {
    final currentWord = _queue[_currentIndex];
    globalState.processSRSReview(currentWord, quality);

    if (_currentIndex < _queue.length - 1) {
      _flipController.reverse().then((_) {
        setState(() {
          _currentIndex++;
          _isFlipped = false;
        });
      });
    } else {
      // Done with reviews
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review session complete!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No reviews due!")),
      );
    }

    final word = _queue[_currentIndex];
    final progress = (_currentIndex + 1) / _queue.length;

    return Scaffold(
      backgroundColor: const Color(0xFF2D3142), // Darker background for focus
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Review ${_currentIndex + 1}/${_queue.length}",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      // 3D Matrix flip math
                      final angle = _flipAnimation.value * pi;
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle);

                      // Handle showing front or back based on rotation > 90 deg
                      Widget cardChild = angle < pi / 2
                          ? _buildCardFront(word)
                          : _buildCardBack(word);

                      // If past 90 degrees, we need to flip the mirror image back
                      if (angle >= pi / 2) {
                        transform.rotateY(pi);
                      }

                      return Transform(
                        alignment: Alignment.center,
                        transform: transform,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: cardChild,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Grading Buttons (Only show when flipped)
              AnimatedOpacity(
                opacity: _isFlipped ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_isFlipped,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGradeButton(
                        context,
                        "Again\n(1m)",
                        Colors.redAccent,
                        0,
                      ),
                      _buildGradeButton(
                        context,
                        "Hard\n(1d)",
                        Colors.orange,
                        2,
                      ),
                      _buildGradeButton(context, "Good\n(3d)", Colors.blue, 4),
                      _buildGradeButton(context, "Easy\n(7d)", Colors.green, 5),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(VocabularyWord word) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Translate",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Text(
            word.targetWord,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          const Icon(Icons.touch_app_rounded, color: Colors.grey, size: 32),
          const SizedBox(height: 8),
          const Text("Tap to flip", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCardBack(VocabularyWord word) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.translation,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C63FF),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 24),
          Text(
            word.exampleSentenceTarget,
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Color(0xFF2D3142),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            word.exampleSentenceBase,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "SRS Stage: ${word.srsStage}",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeButton(
    BuildContext context,
    String text,
    Color color,
    int quality,
  ) {
    return InkWell(
      onTap: () => _submitReview(quality),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. PROFILE & STATS SCREEN
// ============================================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate vocab stats
    int totalVocab = globalState.vocabularyDatabase.length;
    int learnedVocab = globalState.vocabularyDatabase
        .where((v) => v.repetitionCount > 0)
        .length;
    int masteredVocab = globalState.vocabularyDatabase
        .where((v) => v.srsStage >= 3)
        .length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        globalState.userName,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Learning ${globalState.targetLanguage}",
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Top Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total XP",
                    "${globalState.totalXp}",
                    Icons.flash_on_rounded,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    "Day Streak",
                    "${globalState.currentStreak}",
                    Icons.local_fire_department,
                    Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Vocabulary Progress Chart
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Vocabulary Retention",
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: BarChartPainter(
                        newWords: totalVocab - learnedVocab,
                        learning: learnedVocab - masteredVocab,
                        mastered: masteredVocab,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem("New", Colors.grey.shade300),
                      _buildLegendItem("Learning", Colors.blueAccent),
                      _buildLegendItem("Mastered", Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // App Settings / Extras Mock
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Settings",
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              Icons.notifications_active_rounded,
              "Reminders",
              "Daily at 8:00 PM",
            ),
            _buildSettingsTile(
              Icons.language_rounded,
              "Courses",
              "Spanish (Active)",
            ),
            _buildSettingsTile(Icons.help_rounded, "Help & Feedback", ""),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}

// Custom Painter to build a simple bar chart from scratch
class BarChartPainter extends CustomPainter {
  final int newWords;
  final int learning;
  final int mastered;

  BarChartPainter({
    required this.newWords,
    required this.learning,
    required this.mastered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int total = newWords + learning + mastered;
    if (total == 0) return;

    final double maxBarHeight = size.height - 30; // Leave room for labels
    final double barWidth = 40.0;
    final double spacing = (size.width - (3 * barWidth)) / 4;

    final Paint paint = Paint()..style = PaintingStyle.fill;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    void drawBar(int index, int value, Color color, String label) {
      final double x = spacing + (index * (barWidth + spacing));
      final double barHeight = (value / total) * maxBarHeight;
      final double y = maxBarHeight - barHeight + 10; // Top offset

      // Draw Bar
      paint.color = color;
      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          y,
          barWidth,
          barHeight == 0 ? 5 : barHeight,
        ), // min height 5
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      // Draw Value Text
      textPainter.text = TextSpan(
        text: value.toString(),
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth / 2) - (textPainter.width / 2), y - 20),
      );

      // Draw Label Below
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth / 2) - (textPainter.width / 2), maxBarHeight + 15),
      );
    }

    drawBar(0, newWords, Colors.grey.shade300, "New");
    drawBar(1, learning, Colors.blueAccent, "Learning");
    drawBar(2, mastered, Colors.green, "Mastered");
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.newWords != newWords ||
        oldDelegate.learning != learning ||
        oldDelegate.mastered != mastered;
  }
}
