import 'dart:async';
import 'dart:math' as math;
// removed unused dart:ui import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum PollStatus { active, closed, drafted }

enum PollType { singleChoice, multipleChoice }

enum VoteStatus { pending, submitting, success, failed }

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700

  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color secondary = Color(0xFFF43F5E); // Rose 500
  static const Color accent = Color(0xFF14B8A6); // Teal 500

  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500

  static const List<Color> chartPalette = [
    Color(0xFF6366F1),
    Color(0xFFF43F5E),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
  ];
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
// 2. EXCEPTIONS & FORMATTERS
// ============================================================================

abstract class PollException implements Exception {
  final String message;
  PollException(this.message);
  @override
  String toString() => message;
}

class DuplicateVoteException extends PollException {
  DuplicateVoteException([String m = "You have already voted on this poll."])
    : super(m);
}

class PollClosedException extends PollException {
  PollClosedException([String m = "This poll has been closed."]) : super(m);
}

class ValidationException extends PollException {
  ValidationException(String m) : super(m);
}

class NetworkException extends PollException {
  NetworkException([String m = "Network timeout."]) : super(m);
}

class TimeFormatter {
  static String timeRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays} days left';
    if (diff.inHours > 0) return '${diff.inHours} hours left';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins left';
    return '${diff.inSeconds} secs left';
  }

  static String formatDate(DateTime d) {
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

class User {
  final String id;
  final String username;
  final String avatarUrl;

  User({required this.id, required this.username, required this.avatarUrl});
}

class PollOption {
  final String id;
  String text;
  int voteCount;

  PollOption({required this.id, required this.text, this.voteCount = 0});
}

class Poll {
  final String id;
  final String creatorId;
  final String creatorName;
  String question;
  String description;
  List<PollOption> options;
  PollType type;
  PollStatus status;
  DateTime createdAt;
  DateTime deadline;
  int totalVotes;

  Poll({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.question,
    required this.description,
    required this.options,
    required this.type,
    this.status = PollStatus.active,
    required this.createdAt,
    required this.deadline,
    this.totalVotes = 0,
  });

  bool get isClosed =>
      status == PollStatus.closed || DateTime.now().isAfter(deadline);

  Poll copy() {
    return Poll(
      id: id,
      creatorId: creatorId,
      creatorName: creatorName,
      question: question,
      description: description,
      options: options
          .map(
            (o) => PollOption(id: o.id, text: o.text, voteCount: o.voteCount),
          )
          .toList(),
      type: type,
      status: status,
      createdAt: createdAt,
      deadline: deadline,
      totalVotes: totalVotes,
    );
  }
}

class VoteRecord {
  final String pollId;
  final String userId;
  final List<String> optionIds;
  final DateTime timestamp;

  VoteRecord({
    required this.pollId,
    required this.userId,
    required this.optionIds,
    required this.timestamp,
  });
}

// ============================================================================
// 4. MOCK BACKEND ENGINE (Live Streams, Bots, Data Integrity)
// ============================================================================

class MockPollEngine {
  static final MockPollEngine _instance = MockPollEngine._internal();
  factory MockPollEngine() => _instance;

  final math.Random _rand = math.Random();

  final Map<String, User> _users = {};
  final Map<String, Poll> _polls = {};
  final List<VoteRecord> _voteLedger =
      []; // Ground truth for duplicate checking

  // Real-time Event Broadcasters
  final StreamController<Poll> _livePollController =
      StreamController<Poll>.broadcast();
  Stream<Poll> get livePollStream => _livePollController.stream;

  Timer? _botTimer;

  MockPollEngine._internal() {
    _seedData();
  }
  // Public unnamed constructor removed; singleton uses factory above.

  void _seedData() {
    final now = DateTime.now();

    // Users
    final u1 = User(
      id: 'U1',
      username: 'Alex Admin',
      avatarUrl: 'https://i.pravatar.cc/150?u=a',
    );
    final u2 = User(
      id: 'U2',
      username: 'Sam Voter',
      avatarUrl: 'https://i.pravatar.cc/150?u=s',
    );
    _users.addAll({u1.id: u1, u2.id: u2});

    // Active Poll 1
    final p1 = Poll(
      id: 'P1',
      creatorId: 'U1',
      creatorName: 'Alex Admin',
      question: 'What is the best framework for cross-platform development?',
      description:
          'Looking to start a new enterprise project and need community input.',
      type: PollType.singleChoice,
      deadline: now.add(const Duration(days: 2)),
      createdAt: now,
      options: [
        PollOption(id: 'O1', text: 'Flutter', voteCount: 45),
        PollOption(id: 'O2', text: 'React Native', voteCount: 22),
        PollOption(id: 'O3', text: 'Kotlin Multiplatform', voteCount: 15),
        PollOption(id: 'O4', text: 'Ionic', voteCount: 5),
      ],
      totalVotes: 87,
    );

    // Active Poll 2
    final p2 = Poll(
      id: 'P2',
      creatorId: 'U2',
      creatorName: 'Sam Voter',
      question: 'Which features should we prioritize for Q4?',
      description: 'Select all that apply. Your feedback shapes our roadmap.',
      type: PollType.multipleChoice,
      deadline: now.add(const Duration(hours: 5)),
      createdAt: now.subtract(const Duration(days: 1)),
      options: [
        PollOption(id: 'O1', text: 'Dark Mode', voteCount: 120),
        PollOption(id: 'O2', text: 'Offline Support', voteCount: 85),
        PollOption(id: 'O3', text: 'Analytics Dashboard', voteCount: 40),
        PollOption(id: 'O4', text: 'Performance Optimization', voteCount: 150),
      ],
      totalVotes: 395,
    );

    // Closed Poll
    final p3 = Poll(
      id: 'P3',
      creatorId: 'U1',
      creatorName: 'Alex Admin',
      question: 'Where should we host the annual retreat?',
      description: 'Voting has concluded.',
      type: PollType.singleChoice,
      deadline: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 5)),
      status: PollStatus.closed,
      options: [
        PollOption(id: 'O1', text: 'Hawaii', voteCount: 40),
        PollOption(id: 'O2', text: 'Swiss Alps', voteCount: 65),
        PollOption(id: 'O3', text: 'Tokyo', voteCount: 80),
      ],
      totalVotes: 185,
    );

    _polls.addAll({p1.id: p1, p2.id: p2, p3.id: p3});

    // Seed some ledger records to prevent bot anomalies
    _voteLedger.add(
      VoteRecord(
        pollId: 'P3',
        userId: 'U1',
        optionIds: ['O3'],
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    );

    _startBotTraffic();
  }

  /// Autonomous engine that randomly casts votes to simulate active network traffic
  void _startBotTraffic() {
    _botTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final activePolls = _polls.values.where((p) => !p.isClosed).toList();
      if (activePolls.isEmpty) return;

      final targetPoll = activePolls[_rand.nextInt(activePolls.length)];
      final targetOption =
          targetPoll.options[_rand.nextInt(targetPoll.options.length)];

      // Mutate State
      targetOption.voteCount++;
      targetPoll.totalVotes++;

      // Broadcast update
      _livePollController.sink.add(targetPoll.copy());
    });
  }

  void dispose() {
    _botTimer?.cancel();
    _livePollController.close();
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _rand.nextInt(300)));

  // --- API Methods ---
  Future<User> login(String username) async {
    await _latency(600);
    return User(
      id: 'U_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      avatarUrl: 'https://i.pravatar.cc/150?u=$username',
    );
  }

  Future<List<Poll>> getFeed() async {
    await _latency();
    final list = _polls.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Poll> createPoll(Poll poll) async {
    await _latency(1000);
    _polls[poll.id] = poll;
    return poll;
  }

  /// Atomic Vote Transaction with duplicate prevention
  Future<void> submitVote(
    String userId,
    String pollId,
    List<String> selectedOptionIds,
  ) async {
    await _latency(800); // Network transit time

    final poll = _polls[pollId];
    if (poll == null) throw Exception("Poll not found.");
    if (poll.isClosed) throw PollClosedException();

    // Idempotency / Duplicate Check
    if (_voteLedger.any((v) => v.pollId == pollId && v.userId == userId)) {
      throw DuplicateVoteException();
    }

    // Validation
    if (poll.type == PollType.singleChoice && selectedOptionIds.length > 1) {
      throw ValidationException("This poll only allows a single choice.");
    }
    if (selectedOptionIds.isEmpty) {
      throw ValidationException("You must select at least one option.");
    }

    // Record Transaction
    _voteLedger.add(
      VoteRecord(
        pollId: pollId,
        userId: userId,
        optionIds: selectedOptionIds,
        timestamp: DateTime.now(),
      ),
    );

    // Mutate Counts
    for (String oid in selectedOptionIds) {
      final opt = poll.options.firstWhere((o) => o.id == oid);
      opt.voteCount++;
    }
    // For multiple choice, totalVotes could mean "total ballots" or "total individual selections". We use total ballots cast.
    poll.totalVotes++;

    // Broadcast live update to all connected clients
    _livePollController.sink.add(poll.copy());
  }

  bool hasUserVoted(String userId, String pollId) {
    return _voteLedger.any((v) => v.pollId == pollId && v.userId == userId);
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (Custom AppStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockPollEngine _api = MockPollEngine();

  bool isGlobalLoading = true;
  String? globalError;
  User? currentUser;

  List<Poll> feed = [];
  Set<String> votedPollIds = {}; // Local cache of polls the user has voted on

  AppState() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      currentUser = await _api.login("Demo User");
      await refreshFeed();
    } catch (e) {
      globalError = "System offline.";
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  void _setError(String? e) {
    globalError = e;
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    feed = await _api.getFeed();
    // Re-check voted status for all feed items
    if (currentUser != null) {
      for (var p in feed) {
        if (_api.hasUserVoted(currentUser!.id, p.id)) votedPollIds.add(p.id);
      }
    }
    notifyListeners();
  }

  Future<bool> castVote(String pollId, List<String> optionIds) async {
    _setError(null);
    try {
      await _api.submitVote(currentUser!.id, pollId, optionIds);
      votedPollIds.add(pollId); // Mark locally
      // Update local feed object immediately to reflect vote
      final idx = feed.indexWhere((p) => p.id == pollId);
      if (idx != -1) feed[idx] = _api._polls[pollId]!.copy();

      notifyListeners();
      return true;
    } on PollException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  Future<bool> publishPoll(
    String question,
    String desc,
    List<String> options,
    PollType type,
    int durationHours,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      if (options.length < 2)
        throw ValidationException("At least 2 options required.");

      final poll = Poll(
        id: 'P_${DateTime.now().millisecondsSinceEpoch}',
        creatorId: currentUser!.id,
        creatorName: currentUser!.username,
        question: question,
        description: desc,
        type: type,
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(Duration(hours: durationHours)),
        options: options
            .asMap()
            .entries
            .map((e) => PollOption(id: 'O_${e.key}', text: e.value))
            .toList(),
      );

      await _api.createPoll(poll);
      await refreshFeed();
      return true;
    } on PollException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  // Expose Live Stream Factory
  Stream<Poll> getLivePollStream(String pollId) {
    return _api.livePollStream.where((p) => p.id == pollId);
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
  runApp(const PollApp());
}

class PollApp extends StatelessWidget {
  const PollApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Polls',
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
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceHighlight.withOpacity(0.3),
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
    if (state.isGlobalLoading)
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
    const FeedScreen(),
    const CreatePollScreen(),
    const ProfileScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_chart), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. FEED SCREEN
// ============================================================================

class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trending Polls',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshFeed,
        backgroundColor: AppColors.surfaceHighlight,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.feed.length,
          itemBuilder: (context, index) {
            final poll = state.feed[index];
            final hasVoted = state.votedPollIds.contains(poll.id);
            return _PollCard(poll: poll, hasVoted: hasVoted);
          },
        ),
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  final bool hasVoted;

  const _PollCard({required this.poll, required this.hasVoted});

  @override
  Widget build(BuildContext context) {
    final bool isClosed = poll.isClosed;

    return GestureDetector(
      onTap: () {
        if (hasVoted || isClosed) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveResultsScreen(initialPoll: poll),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VotingScreen(poll: poll)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceHighlight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        poll.creatorName[0],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      poll.creatorName,
                      style: AppStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isClosed
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isClosed ? 'CLOSED' : 'ACTIVE',
                    style: TextStyle(
                      color: isClosed ? AppColors.error : AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(poll.question, style: AppStyles.h2),
            const SizedBox(height: 8),
            Text(
              poll.description,
              style: AppStyles.body.copyWith(color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
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
                    Text('${poll.totalVotes} Votes', style: AppStyles.caption),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isClosed ? AppColors.error : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TimeFormatter.timeRemaining(poll.deadline),
                      style: AppStyles.caption.copyWith(
                        color: isClosed ? AppColors.error : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (hasVoted || isClosed) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.surfaceHighlight),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null, // Tap handled by card
                  icon: const Icon(Icons.bar_chart, color: AppColors.primary),
                  label: const Text(
                    'VIEW RESULTS',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. VOTING SCREEN
// ============================================================================

class VotingScreen extends StatefulWidget {
  final Poll poll;
  const VotingScreen({Key? key, required this.poll}) : super(key: key);

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final Set<String> _selectedOptionIds = {};
  VoteStatus _status = VoteStatus.pending;

  void _toggleOption(String id) {
    setState(() {
      if (widget.poll.type == PollType.singleChoice) {
        _selectedOptionIds.clear();
        _selectedOptionIds.add(id);
      } else {
        if (_selectedOptionIds.contains(id))
          _selectedOptionIds.remove(id);
        else
          _selectedOptionIds.add(id);
      }
    });
  }

  void _submitVote(AppState state) async {
    if (_selectedOptionIds.isEmpty) return;
    setState(() => _status = VoteStatus.submitting);

    final success = await state.castVote(
      widget.poll.id,
      _selectedOptionIds.toList(),
    );

    if (success && mounted) {
      setState(() => _status = VoteStatus.success);
      // Wait for confetti/success state to show
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveResultsScreen(initialPoll: widget.poll),
          ),
        );
      }
    } else if (mounted) {
      setState(() => _status = VoteStatus.failed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.globalError ?? "Error"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final isSubmitting =
        _status == VoteStatus.submitting || _status == VoteStatus.success;

    return Scaffold(
      appBar: AppBar(title: const Text('Cast Your Vote')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.poll.type == PollType.singleChoice
                      ? 'SINGLE CHOICE'
                      : 'MULTIPLE CHOICE',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.poll.question, style: AppStyles.h1),
              const SizedBox(height: 8),
              Text(widget.poll.description, style: AppStyles.body),
              const SizedBox(height: 32),

              ...widget.poll.options.map((opt) {
                final isSelected = _selectedOptionIds.contains(opt.id);
                return GestureDetector(
                  onTap: isSubmitting ? null : () => _toggleOption(opt.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
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
                            shape: widget.poll.type == PollType.singleChoice
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            borderRadius:
                                widget.poll.type == PollType.multipleChoice
                                ? BorderRadius.circular(6)
                                : null,
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
                            opt.text,
                            style: AppStyles.h3.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 100), // FAB padding
            ],
          ),

          if (_status == VoteStatus.success)
            const Positioned.fill(child: _ConfettiOverlay()),
        ],
      ),
      floatingActionButton: _selectedOptionIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: isSubmitting ? null : () => _submitVote(state),
              label: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SUBMIT VOTE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
              icon: isSubmitting ? null : const Icon(Icons.how_to_vote),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ============================================================================
// 9. LIVE RESULTS DASHBOARD & CUSTOM CHARTS
// ============================================================================

class LiveResultsScreen extends StatefulWidget {
  final Poll initialPoll;
  const LiveResultsScreen({Key? key, required this.initialPoll})
    : super(key: key);

  @override
  State<LiveResultsScreen> createState() => _LiveResultsScreenState();
}

class _LiveResultsScreenState extends State<LiveResultsScreen> {
  int _chartType = 0; // 0 = Bar, 1 = Donut

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Results'),
        actions: [
          IconButton(
            icon: Icon(_chartType == 0 ? Icons.pie_chart : Icons.bar_chart),
            onPressed: () =>
                setState(() => _chartType = _chartType == 0 ? 1 : 0),
          ),
        ],
      ),
      body: StreamBuilder<Poll>(
        initialData: widget.initialPoll,
        stream: state.getLivePollStream(widget.initialPoll.id),
        builder: (context, snapshot) {
          final poll = snapshot.data!;
          // Sort options by vote count descending for display
          final sortedOptions = List<PollOption>.from(poll.options)
            ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        poll.isClosed
                            ? 'Poll Closed. Final Results.'
                            : 'Live updating from server...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(poll.question, style: AppStyles.h2),
              const SizedBox(height: 8),
              Text('${poll.totalVotes} Total Votes', style: AppStyles.caption),
              const SizedBox(height: 48),

              // Chart Container
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: TweenAnimationBuilder<double>(
                  // Drive re-animation when totalVotes change
                  key: ValueKey(poll.totalVotes),
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (ctx, anim, child) => CustomPaint(
                    painter: _chartType == 0
                        ? _BarChartPainter(
                            options: sortedOptions,
                            totalVotes: poll.totalVotes,
                            animProgress: anim,
                          )
                        : _DonutChartPainter(
                            options: sortedOptions,
                            totalVotes: poll.totalVotes,
                            animProgress: anim,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
              const Text('Detailed Breakdown', style: AppStyles.h3),
              const SizedBox(height: 16),

              ...sortedOptions.asMap().entries.map((e) {
                final idx = e.key;
                final opt = e.value;
                final color =
                    AppColors.chartPalette[idx % AppColors.chartPalette.length];
                final percentage = poll.totalVotes == 0
                    ? 0.0
                    : (opt.voteCount / poll.totalVotes) * 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          opt.text,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: AppStyles.caption,
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${opt.voteCount}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<PollOption> options;
  final int totalVotes;
  final double animProgress;
  _BarChartPainter({
    required this.options,
    required this.totalVotes,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (options.isEmpty || totalVotes == 0) return;

    final maxVotes = options.first.voteCount; // Assumes list is sorted desc
    final normMax = maxVotes == 0 ? 1 : maxVotes;
    final barHeight = (size.height - (options.length * 10)) / options.length;

    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final color = AppColors.chartPalette[i % AppColors.chartPalette.length];

      double y = i * (barHeight + 10);
      double targetWidth = (opt.voteCount / normMax) * size.width;
      double animatedWidth = targetWidth * animProgress;

      // Draw Background Track
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, size.width, barHeight),
          const Radius.circular(8),
        ),
        Paint()..color = AppColors.surfaceHighlight.withOpacity(0.3),
      );
      // Draw Fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, animatedWidth, barHeight),
          const Radius.circular(8),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.totalVotes != totalVotes || old.animProgress != animProgress;
}

class _DonutChartPainter extends CustomPainter {
  final List<PollOption> options;
  final int totalVotes;
  final double animProgress;
  _DonutChartPainter({
    required this.options,
    required this.totalVotes,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    if (totalVotes == 0) return;

    double startAngle = -math.pi / 2;
    const strokeW = 40.0;

    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      if (opt.voteCount == 0) continue;

      final color = AppColors.chartPalette[i % AppColors.chartPalette.length];
      // Target sweep based on actual ratio, then scaled by animation progress to "grow" in
      final targetSweep = (opt.voteCount / totalVotes) * 2 * math.pi;
      // To prevent gaps when animating, we apply animation to the radius/scale rather than the sweep angle,
      // or simply render full sweeps but scale the canvas. We'll animate the stroke width.

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * animProgress
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeW / 2)),
        startAngle,
        targetSweep - 0.02,
        false,
        paint,
      );
      startAngle += targetSweep;
    }

    // Center Text
    final tp = TextPainter(
      text: TextSpan(
        text: '$totalVotes\nVotes',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
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
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.totalVotes != totalVotes || old.animProgress != animProgress;
}

// ============================================================================
// 10. CREATE POLL WIZARD
// ============================================================================

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({Key? key}) : super(key: key);
  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<TextEditingController> _optCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  PollType _type = PollType.singleChoice;
  int _durationHours = 24;

  void _addOption() {
    if (_optCtrls.length < 10)
      setState(() => _optCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optCtrls.length > 2) setState(() => _optCtrls.removeAt(i));
  }

  void _publish(AppState state) async {
    if (!_formKey.currentState!.validate()) return;

    List<String> options = _optCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final success = await state.publishPoll(
      _questionCtrl.text,
      _descCtrl.text,
      options,
      _type,
      _durationHours,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poll published!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Reset form
      _questionCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _optCtrls.clear();
        _optCtrls.addAll([TextEditingController(), TextEditingController()]);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.globalError!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Poll')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Core Details', style: AppStyles.h3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _questionCtrl,
              decoration: const InputDecoration(
                hintText: 'What do you want to ask? *',
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add context or description...',
              ),
            ),
            const SizedBox(height: 32),

            const Text('Options', style: AppStyles.h3),
            const SizedBox(height: 16),
            ..._optCtrls
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: e.value,
                            decoration: InputDecoration(
                              hintText: 'Option ${e.key + 1} *',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        if (_optCtrls.length > 2)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: AppColors.error,
                            ),
                            onPressed: () => _removeOption(e.key),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
            if (_optCtrls.length < 10)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),

            const SizedBox(height: 32),
            const Text('Settings', style: AppStyles.h3),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Allow Multiple Answers'),
              trailing: Switch(
                value: _type == PollType.multipleChoice,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(
                  () => _type = v
                      ? PollType.multipleChoice
                      : PollType.singleChoice,
                ),
              ),
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Duration (Hours)'),
              trailing: Text(
                '$_durationHours hrs',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              subtitle: Slider(
                value: _durationHours.toDouble(),
                min: 1,
                max: 72,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _durationHours = v.toInt()),
              ),
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isGlobalLoading ? null : () => _publish(state),
                child: state.isGlobalLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'PUBLISH POLL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 11. PROFILE SCREEN
// ============================================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('User Profile & History goes here.')),
    );
  }
}

// ============================================================================
// 12. ANIMATION UTILITIES (Confetti Overlay)
// ============================================================================

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();
  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final math.Random _rand = math.Random();

  @override
  void initState() {
    super.initState();
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
    ];
    for (int i = 0; i < 80; i++) {
      _particles.add(
        _Particle(
          x: _rand.nextDouble(),
          y: -0.2 - _rand.nextDouble() * 0.5,
          vx: (_rand.nextDouble() - 0.5) * 0.5,
          vy: 0.5 + _rand.nextDouble() * 1.5,
          color: colors[_rand.nextInt(colors.length)],
          size: 4 + _rand.nextDouble() * 6,
          rotation: _rand.nextDouble() * math.pi * 2,
          rotSpeed: (_rand.nextDouble() - 0.5) * 10,
        ),
      );
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _ctrl.value,
          ),
          size: Size.infinite,
        ),
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
      double t = progress * 5;
      double cx = size.width * (p.x + p.vx * t);
      double cy = size.height * (p.y + p.vy * t + 0.5 * 0.5 * t * t);
      if (cy > size.height) continue;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation + p.rotSpeed * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        Paint()
          ..color = p.color.withOpacity((1.0 - progress).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
