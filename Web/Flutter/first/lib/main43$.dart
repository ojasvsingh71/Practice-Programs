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

enum PlaybackState { idle, buffering, playing, paused, completed, error }

enum DownloadState { notDownloaded, queued, downloading, downloaded, failed }

enum MeditationType { guided, unguidedTimer, breathing, sleepStory }

enum AmbientSound { none, rain, forest, ocean, fire, whiteNoise }

enum BreathingPhase { inhale, hold1, exhale, hold2 }

class AppColors {
  static const Color background = Color(0xFF0F172A); // Deep Slate
  static const Color surface = Color(0xFF1E293B); // Dark Slate
  static const Color surfaceHighlight = Color(0xFF334155);

  static const Color primary = Color(0xFF8B5CF6); // Soft Violet
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color accent = Color(0xFF2DD4BF); // Teal
  static const Color secondary = Color(0xFFF472B6); // Pink for lotus

  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const List<Color> lotusGradient = [
    Color(0xFF8B5CF6),
    Color(0xFFF472B6),
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

abstract class MindException implements Exception {
  final String message;
  MindException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends MindException {
  NetworkException([String m = "Network unavailable."]) : super(m);
}

class OfflineException extends MindException {
  OfflineException([String m = "Item not available offline."]) : super(m);
}

class TimeUtils {
  static String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  static String formatShortDate(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}';
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
  final String avatarUrl;
  User({required this.id, required this.name, required this.avatarUrl});
}

class BreathingPattern {
  final String name;
  final int inhale; // seconds
  final int hold1;
  final int exhale;
  final int hold2;
  const BreathingPattern(
    this.name,
    this.inhale,
    this.hold1,
    this.exhale,
    this.hold2,
  );
  int get totalCycle => inhale + hold1 + exhale + hold2;
}

class SessionLog {
  final String id;
  final String sessionId;
  final String sessionTitle;
  final MeditationType type;
  final DateTime timestamp;
  final int durationSeconds;

  SessionLog({
    required this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.type,
    required this.timestamp,
    required this.durationSeconds,
  });
}

class MeditationSession {
  final String id;
  final String packId;
  final String title;
  final String description;
  final MeditationType type;
  final Duration duration;
  final String author;
  final String coverUrl;

  MeditationSession({
    required this.id,
    required this.packId,
    required this.title,
    required this.description,
    required this.type,
    required this.duration,
    required this.author,
    required this.coverUrl,
  });
}

class MeditationPack {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<String> sessionIds;

  // Local State
  DownloadState downloadState;
  double downloadProgress;

  MeditationPack({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.sessionIds,
    this.downloadState = DownloadState.notDownloaded,
    this.downloadProgress = 0.0,
  });

  MeditationPack copyWith({
    DownloadState? downloadState,
    double? downloadProgress,
  }) {
    return MeditationPack(
      id: id,
      title: title,
      description: description,
      coverUrl: coverUrl,
      sessionIds: sessionIds,
      downloadState: downloadState ?? this.downloadState,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

// ============================================================================
// 4. MOCK AUDIO ENGINE (Simulates Streaming, Ambient Mixing, Timers)
// ============================================================================

class MockAudioService {
  final StreamController<PlaybackState> _stateCtrl =
      StreamController<PlaybackState>.broadcast();
  final StreamController<Duration> _positionCtrl =
      StreamController<Duration>.broadcast();

  Stream<PlaybackState> get stateStream => _stateCtrl.stream;
  Stream<Duration> get positionStream => _positionCtrl.stream;

  PlaybackState state = PlaybackState.idle;
  MeditationSession? currentSession;
  Duration currentPosition = Duration.zero;
  AmbientSound activeAmbient = AmbientSound.none;

  Timer? _playbackTimer;
  Function(SessionLog)? onSessionCompleted;

  void play(
    MeditationSession session,
    bool isOfflineMode,
    DownloadState packState,
  ) async {
    if (isOfflineMode && packState != DownloadState.downloaded) {
      throw OfflineException("Pack not downloaded for offline listening.");
    }

    if (currentSession?.id != session.id) {
      currentSession = session;
      currentPosition = Duration.zero;
      _positionCtrl.sink.add(currentPosition);

      _updateState(PlaybackState.buffering);
      await Future.delayed(
        Duration(milliseconds: isOfflineMode ? 200 : 1500),
      ); // Network delay
    }

    _updateState(PlaybackState.playing);
    _startTimer();
  }

  void pause() {
    _updateState(PlaybackState.paused);
    _playbackTimer?.cancel();
  }

  void togglePlayPause() {
    if (state == PlaybackState.playing)
      pause();
    else if (currentSession != null)
      _updateState(PlaybackState.playing);
    _startTimer();
  }

  void seek(Duration position) {
    if (currentSession == null) return;
    currentPosition = Duration(
      milliseconds: position.inMilliseconds.clamp(
        0,
        currentSession!.duration.inMilliseconds,
      ),
    );
    _positionCtrl.sink.add(currentPosition);
  }

  void setAmbient(AmbientSound sound) {
    activeAmbient = sound;
    // In production, this plays a looping background audio track mixed with main stream
  }

  void stop() {
    _playbackTimer?.cancel();
    currentSession = null;
    currentPosition = Duration.zero;
    _updateState(PlaybackState.idle);
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (currentSession == null) return;
      currentPosition += const Duration(milliseconds: 100);

      if (currentPosition >= currentSession!.duration) {
        currentPosition = currentSession!.duration;
        _updateState(PlaybackState.completed);
        timer.cancel();

        // Log completion
        if (onSessionCompleted != null) {
          onSessionCompleted!(
            SessionLog(
              id: 'LOG_${DateTime.now().millisecondsSinceEpoch}',
              sessionId: currentSession!.id,
              sessionTitle: currentSession!.title,
              type: currentSession!.type,
              timestamp: DateTime.now(),
              durationSeconds: currentSession!.duration.inSeconds,
            ),
          );
        }
      }
      _positionCtrl.sink.add(currentPosition);
    });
  }

  void _updateState(PlaybackState newState) {
    state = newState;
    _stateCtrl.sink.add(state);
  }

  void dispose() {
    _playbackTimer?.cancel();
    _stateCtrl.close();
    _positionCtrl.close();
  }
}

// ============================================================================
// 5. MOCK DATABASE & OFFLINE DOWNLOAD MANAGER
// ============================================================================

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal() {
    _seedData();
  }

  final math.Random _rand = math.Random();
  final Map<String, MeditationPack> _packs = {};
  final Map<String, MeditationSession> _sessions = {};
  final List<SessionLog> _history = [];

  void dispose() {}

  void _seedData() {
    final now = DateTime.now();

    // 1. Seed Sessions
    final s1 = MeditationSession(
      id: 'S1',
      packId: 'P1',
      title: 'Breath Awareness',
      description: 'Anchor your attention to the present moment.',
      type: MeditationType.guided,
      duration: const Duration(minutes: 10),
      author: 'Sarah Jenkins',
      coverUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=400&q=80',
    );
    final s2 = MeditationSession(
      id: 'S2',
      packId: 'P1',
      title: 'Body Scan',
      description: 'Release physical tension from head to toe.',
      type: MeditationType.guided,
      duration: const Duration(minutes: 15),
      author: 'Sarah Jenkins',
      coverUrl:
          'https://images.unsplash.com/photo-1518241353330-0f797f83693e?auto=format&fit=crop&w=400&q=80',
    );
    final s3 = MeditationSession(
      id: 'S3',
      packId: 'P2',
      title: 'Deep Sleep Release',
      description: 'Drift off to a restorative sleep.',
      type: MeditationType.sleepStory,
      duration: const Duration(minutes: 30),
      author: 'Dr. Alan Watts',
      coverUrl:
          'https://images.unsplash.com/photo-1515894203077-94dfeb3ce748?auto=format&fit=crop&w=400&q=80',
    );
    final s4 = MeditationSession(
      id: 'S4',
      packId: 'P2',
      title: 'Midnight Rain',
      description: 'Ambient sounds to mask background noise.',
      type: MeditationType.sleepStory,
      duration: const Duration(minutes: 60),
      author: 'Nature Sounds',
      coverUrl:
          'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?auto=format&fit=crop&w=400&q=80',
    );
    final s5 = MeditationSession(
      id: 'S5',
      packId: 'P3',
      title: 'Box Breathing',
      description: 'Regulate your nervous system.',
      type: MeditationType.breathing,
      duration: const Duration(minutes: 5),
      author: 'Nexus Core',
      coverUrl:
          'https://images.unsplash.com/photo-1528319725582-ddc096101511?auto=format&fit=crop&w=400&q=80',
    );

    _sessions.addAll({s1.id: s1, s2.id: s2, s3.id: s3, s4.id: s4, s5.id: s5});

    // 2. Seed Packs
    _packs['P1'] = MeditationPack(
      id: 'P1',
      title: 'Foundations of Mindfulness',
      description: 'A 7-day introductory course to mindful living.',
      coverUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80',
      sessionIds: ['S1', 'S2'],
    );
    _packs['P2'] = MeditationPack(
      id: 'P2',
      title: 'Deep Sleep Journey',
      description: 'Techniques to overcome insomnia.',
      coverUrl:
          'https://images.unsplash.com/photo-1515894203077-94dfeb3ce748?auto=format&fit=crop&w=800&q=80',
      sessionIds: ['S3', 'S4'],
    );
    _packs['P3'] = MeditationPack(
      id: 'P3',
      title: 'Anxiety Relief SOS',
      description: 'Quick exercises for panic and stress.',
      coverUrl:
          'https://images.unsplash.com/photo-1528319725582-ddc096101511?auto=format&fit=crop&w=800&q=80',
      sessionIds: ['S5'],
    );

    // 3. Seed 90 days of history
    for (int i = 90; i >= 1; i--) {
      if (_rand.nextDouble() < 0.65) {
        // 65% adherence
        final date = now.subtract(Duration(days: i, hours: _rand.nextInt(12)));
        final sesh = _sessions.values.elementAt(
          _rand.nextInt(_sessions.length),
        );
        _history.add(
          SessionLog(
            id: 'L_$i',
            sessionId: sesh.id,
            sessionTitle: sesh.title,
            type: sesh.type,
            timestamp: date,
            durationSeconds: sesh.duration.inSeconds,
          ),
        );
      }
    }
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _rand.nextInt(300)));

  Future<User> login() async {
    await _latency();
    return User(
      id: 'U1',
      name: 'Alex Mindful',
      avatarUrl: 'https://i.pravatar.cc/150?u=m',
    );
  }

  Future<List<MeditationPack>> getPacks() async {
    await _latency();
    return _packs.values.toList();
  }

  Future<List<SessionLog>> getHistory() async {
    await _latency();
    return List.unmodifiable(_history);
  }

  MeditationSession getSession(String id) => _sessions[id]!;
  MeditationPack getPack(String id) => _packs[id]!;

  void recordLog(SessionLog log) {
    _history.add(log);
  }

  /// Simulates chunked downloading of audio files
  Stream<double> downloadPack(String packId) async* {
    int chunks = 20;
    for (int i = 1; i <= chunks; i++) {
      await Future.delayed(Duration(milliseconds: 150 + _rand.nextInt(100)));
      yield i / chunks;
    }
  }
}

// ============================================================================
// 6. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockDatabase _db = MockDatabase();
  final MockAudioService audio = MockAudioService();

  bool isGlobalLoading = true;
  String? globalError;
  bool isOfflineMode = false;

  User? currentUser;
  List<MeditationPack> packs = [];
  List<SessionLog> history = [];

  final Map<String, StreamSubscription> _downloads = {};

  AppState() {
    audio.onSessionCompleted = _handleSessionCompletion;
    _boot();
  }

  Future<void> _boot() async {
    try {
      currentUser = await _db.login();
      packs = await _db.getPacks();
      history = await _db.getHistory();
    } catch (e) {
      globalError = "Failed to load sanctuary data.";
    } finally {
      isGlobalLoading = false;
      notifyListeners();

      // Force UI updates when audio state changes
      audio.stateStream.listen((_) => notifyListeners());
    }
  }

  void _handleSessionCompletion(SessionLog log) {
    _db.recordLog(log);
    _syncHistoryQuietly();
  }

  Future<void> _syncHistoryQuietly() async {
    history = await _db.getHistory();
    notifyListeners();
  }

  void toggleOfflineMode(bool val) {
    isOfflineMode = val;
    notifyListeners();
  }

  // --- Download Engine ---
  void togglePackDownload(String packId) {
    final idx = packs.indexWhere((p) => p.id == packId);
    if (idx == -1) return;
    final p = packs[idx];

    if (p.downloadState == DownloadState.downloaded) {
      packs[idx] = p.copyWith(
        downloadState: DownloadState.notDownloaded,
        downloadProgress: 0,
      );
      notifyListeners();
    } else if (p.downloadState == DownloadState.notDownloaded ||
        p.downloadState == DownloadState.failed) {
      _startDownload(packId);
    }
  }

  void _startDownload(String packId) {
    if (_downloads.containsKey(packId)) return;

    int idx = packs.indexWhere((p) => p.id == packId);
    packs[idx] = packs[idx].copyWith(
      downloadState: DownloadState.downloading,
      downloadProgress: 0.0,
    );
    notifyListeners();

    _downloads[packId] = _db
        .downloadPack(packId)
        .listen(
          (prog) {
            int i = packs.indexWhere((p) => p.id == packId);
            packs[i] = packs[i].copyWith(downloadProgress: prog);
            notifyListeners();
          },
          onDone: () {
            _downloads.remove(packId);
            int i = packs.indexWhere((p) => p.id == packId);
            packs[i] = packs[i].copyWith(
              downloadState: DownloadState.downloaded,
              downloadProgress: 1.0,
            );
            notifyListeners();
          },
          onError: (_) {
            _downloads.remove(packId);
            int i = packs.indexWhere((p) => p.id == packId);
            packs[i] = packs[i].copyWith(downloadState: DownloadState.failed);
            notifyListeners();
          },
        );
  }

  // --- Analytics Providers ---
  int get totalMindfulMinutes =>
      history.fold(0, (sum, l) => sum + (l.durationSeconds ~/ 60));
  int get currentStreak {
    if (history.isEmpty) return 0;
    final dates =
        history.map((l) => TimeUtils.startOfDay(l.timestamp)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime checkDate = TimeUtils.startOfDay(DateTime.now());

    if (!dates.contains(checkDate)) {
      if (dates.contains(checkDate.subtract(const Duration(days: 1)))) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else
        return 0;
    }
    for (var d in dates) {
      if (d == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else
        break;
    }
    return streak;
  }

  Map<DateTime, int> get heatmapData {
    final map = <DateTime, int>{};
    for (var l in history) {
      final day = TimeUtils.startOfDay(l.timestamp);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  // Proxies
  MeditationSession getSessionInfo(String id) => _db.getSession(id);
}

class AppStore extends InheritedNotifier<AppState> {
  const AppStore({Key? key, required AppState state, required Widget child})
    : super(key: key, notifier: state, child: child);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStore>()!.notifier!;
}

// ============================================================================
// 7. MAIN APP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MindfulnessApp());
}

class MindfulnessApp extends StatelessWidget {
  const MindfulnessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Sanctuary',
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
    const DiscoverScreen(),
    const OfflinePacksScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final hasAudio = state.audio.currentSession != null;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            bottom: hasAudio ? 140 : 80,
            child: _screens[_currentIndex],
          ),
          if (hasAudio)
            const Positioned(
              left: 8,
              right: 8,
              bottom: 90,
              child: _MiniPlayer(),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.surfaceHighlight),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                backgroundColor: AppColors.background,
                indicatorColor: AppColors.primary.withOpacity(0.2),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.spa_outlined),
                    selectedIcon: Icon(Icons.spa, color: AppColors.primary),
                    label: 'Discover',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.offline_pin_outlined),
                    selectedIcon: Icon(
                      Icons.offline_pin,
                      color: AppColors.primary,
                    ),
                    label: 'Offline',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person, color: AppColors.primary),
                    label: 'Profile',
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

// ============================================================================
// 8. DISCOVER SCREEN & PACK DETAILS
// ============================================================================

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sanctuary',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(state.currentUser!.avatarUrl),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Welcome back, ${state.currentUser!.name.split(' ')[0]}',
            style: AppStyles.h1,
          ),
          const SizedBox(height: 8),
          const Text('What do you need today?', style: AppStyles.body),
          const SizedBox(height: 32),

          const Text('Recommended for You', style: AppStyles.h3),
          const SizedBox(height: 16),
          ...state.packs.map((p) => _PackCard(pack: p)).toList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final MeditationPack pack;
  const _PackCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PackDetailScreen(pack: pack)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
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
            Hero(
              tag: 'cover_${pack.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  pack.coverUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.title, style: AppStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    pack.description,
                    style: AppStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.headphones,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pack.sessionIds.length} Sessions',
                        style: AppStyles.caption,
                      ),
                    ],
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

class PackDetailScreen extends StatelessWidget {
  final MeditationPack pack;
  const PackDetailScreen({Key? key, required this.pack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    // Find live instance for download progress updates
    final livePack = state.packs.firstWhere(
      (p) => p.id == pack.id,
      orElse: () => pack,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'cover_${pack.id}',
                    child: Image.network(pack.coverUrl, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.background, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (livePack.downloadState == DownloadState.downloading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    value: livePack.downloadProgress,
                    color: AppColors.accent,
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    livePack.downloadState == DownloadState.downloaded
                        ? Icons.offline_pin
                        : Icons.download,
                    color: livePack.downloadState == DownloadState.downloaded
                        ? AppColors.accent
                        : Colors.white,
                  ),
                  onPressed: () => state.togglePackDownload(pack.id),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.title, style: AppStyles.h1),
                  const SizedBox(height: 16),
                  Text(pack.description, style: AppStyles.body),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: AppColors.surfaceHighlight),
                  ),
                  const Text('Sessions', style: AppStyles.h3),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final sId = pack.sessionIds[index];
              final session = state.getSessionInfo(sId);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: AppColors.primary),
                ),
                title: Text(
                  session.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${TimeUtils.formatDuration(session.duration)} • ${session.type.name}',
                  style: AppStyles.caption,
                ),
                onTap: () async {
                  try {
                    state.audio.play(
                      session,
                      state.isOfflineMode,
                      livePack.downloadState,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImmersivePlayerScreen(),
                      ),
                    );
                  } on MindException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              );
            }, childCount: pack.sessionIds.length),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 9. IMMERSIVE PLAYER & CUSTOM PAINTERS (Waveform & Lotus)
// ============================================================================

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final engine = state.audio;
    final session = engine.currentSession;
    if (session == null) return const SizedBox.shrink();

    final isPlaying = engine.state == PlaybackState.playing;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ImmersivePlayerScreen(),
          fullscreenDialog: true,
        ),
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        session.coverUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            session.author,
                            style: AppStyles.caption,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => engine.togglePlayPause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => engine.stop(),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<Duration>(
              stream: engine.positionStream,
              builder: (ctx, snap) {
                final pos = snap.data ?? Duration.zero;
                return LinearProgressIndicator(
                  value: pos.inMilliseconds / session.duration.inMilliseconds,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                  minHeight: 2,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ImmersivePlayerScreen extends StatefulWidget {
  const ImmersivePlayerScreen({Key? key}) : super(key: key);
  @override
  State<ImmersivePlayerScreen> createState() => _ImmersivePlayerScreenState();
}

class _ImmersivePlayerScreenState extends State<ImmersivePlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _lotusCtrl;

  @override
  void initState() {
    super.initState();
    // Complex lotus animation mapped to 4-7-8 breathing
    _lotusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    )..repeat();
  }

  @override
  void dispose() {
    _lotusCtrl.dispose();
    super.dispose();
  }

  void _showAmbientMixer(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModal) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Background Sound', style: AppStyles.h2),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AmbientSound.values
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s.name.toUpperCase()),
                        selected: state.audio.activeAmbient == s,
                        selectedColor: AppColors.primary.withOpacity(0.3),
                        onSelected: (_) {
                          state.audio.setAmbient(s);
                          setModal(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final engine = state.audio;
    final session = engine.currentSession;

    if (session == null)
      return const Scaffold(body: Center(child: Text('No active session')));

    final isPlaying = engine.state == PlaybackState.playing;
    final isBreathing = session.type == MeditationType.breathing;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: Image.network(session.coverUrl, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withOpacity(0.8),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () => _showAmbientMixer(context, state),
                    ),
                  ],
                ),

                const Spacer(),

                // Visualizer (Lotus or Waveform)
                if (isBreathing)
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: AnimatedBuilder(
                      animation: _lotusCtrl,
                      builder: (c, _) => CustomPaint(
                        painter: _LotusBreathingPainter(
                          progress: _lotusCtrl.value,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _AudioWaveformPainter(isPlaying: isPlaying),
                    ),
                  ),

                const Spacer(),

                // Meta Info
                Text(
                  session.title,
                  style: AppStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  session.author,
                  style: AppStyles.h3.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: 48),

                // Scrubber & Controls
                StreamBuilder<Duration>(
                  stream: engine.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: pos.inMilliseconds.toDouble(),
                              min: 0,
                              max: session.duration.inMilliseconds.toDouble(),
                              onChanged: (v) => engine.seek(
                                Duration(milliseconds: v.toInt()),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TimeUtils.formatDuration(pos),
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                TimeUtils.formatDuration(session.duration),
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, size: 36),
                      onPressed: () => engine.seek(
                        engine.currentPosition - const Duration(seconds: 10),
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => engine.togglePlayPause(),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.forward_10, size: 36),
                      onPressed: () => engine.seek(
                        engine.currentPosition + const Duration(seconds: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioWaveformPainter extends CustomPainter {
  final bool isPlaying;
  final math.Random _rand = math.Random(1);

  _AudioWaveformPainter({required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withOpacity(0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    int bars = (size.width / 8).floor();
    double spacing = size.width / bars;

    for (int i = 0; i < bars; i++) {
      double height = isPlaying
          ? (_rand.nextDouble() * size.height * 0.8 + size.height * 0.2)
          : size.height * 0.1;
      double topY = (size.height - height) / 2;
      canvas.drawLine(
        Offset(i * spacing, topY),
        Offset(i * spacing, topY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWaveformPainter old) =>
      old.isPlaying || isPlaying;
}

class _LotusBreathingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (over 19 seconds for 4-7-8)
  _LotusBreathingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Map linear progress to 4-7-8 breathing phases
    // 4s Inhale (0 -> 4/19), 7s Hold (4/19 -> 11/19), 8s Exhale (11/19 -> 19/19)
    double scale = 0.5;
    String instruction = "INHALE";

    if (progress < 4 / 19) {
      scale = 0.5 + 0.5 * Curves.easeInOutCubic.transform(progress / (4 / 19));
    } else if (progress < 11 / 19) {
      scale = 1.0;
      instruction = "HOLD";
    } else {
      scale =
          1.0 -
          0.5 *
              Curves.easeInOutCubic.transform((progress - 11 / 19) / (8 / 19));
      instruction = "EXHALE";
    }

    // Draw Expanding Lotus Petals
    final paint = Paint()
      ..color = AppColors.secondary.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    for (int i = 0; i < 8; i++) {
      final path = Path();
      path.moveTo(0, 0);
      path.quadraticBezierTo(50, -50, 0, -100);
      path.quadraticBezierTo(-50, -50, 0, 0);
      canvas.drawPath(path, paint);
      canvas.rotate((2 * math.pi) / 8);
    }

    canvas.drawCircle(Offset.zero, 30, Paint()..color = AppColors.primary);
    canvas.restore();

    // Center Text
    final tp = TextPainter(
      text: TextSpan(
        text: instruction,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LotusBreathingPainter old) => true;
}

// ============================================================================
// 10. OFFLINE PACKS SCREEN
// ============================================================================

class OfflinePacksScreen extends StatelessWidget {
  const OfflinePacksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final offlinePacks = state.packs
        .where((p) => p.downloadState == DownloadState.downloaded)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Vault')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceHighlight.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(
                  Icons.airplanemode_active,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Simulate Offline Mode', style: AppStyles.h3),
                ),
                Switch(
                  value: state.isOfflineMode,
                  activeColor: AppColors.accent,
                  onChanged: (v) => state.toggleOfflineMode(v),
                ),
              ],
            ),
          ),
          Expanded(
            child: offlinePacks.isEmpty
                ? const Center(
                    child: Text('No packs downloaded.', style: AppStyles.body),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: offlinePacks.length,
                    itemBuilder: (ctx, i) => _PackCard(pack: offlinePacks[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 11. PROFILE / ANALYTICS SCREEN & CUSTOM HEATMAP PAINTER
// ============================================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Journey')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBadge(
                label: 'Current Streak',
                value: '${state.currentStreak}',
                icon: Icons.local_fire_department,
                color: AppColors.warning,
              ),
              _StatBadge(
                label: 'Mindful Minutes',
                value: '${state.totalMindfulMinutes}',
                icon: Icons.spa,
                color: AppColors.accent,
              ),
              _StatBadge(
                label: 'Sessions',
                value: '${state.history.length}',
                icon: Icons.headphones,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 48),

          const Text('Consistency Matrix', style: AppStyles.h2),
          const SizedBox(height: 8),
          const Text('Last 90 days of practice', style: AppStyles.caption),
          const SizedBox(height: 24),

          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: CustomPaint(
              painter: _HeatmapPainter(data: state.heatmapData, days: 90),
            ),
          ),

          const SizedBox(height: 48),
          const Text('Recent Sessions', style: AppStyles.h2),
          const SizedBox(height: 16),
          if (state.history.isEmpty)
            const Text('No history yet.')
          else
            ...state.history
                .take(10)
                .map(
                  (l) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: AppColors.success),
                    ),
                    title: Text(
                      l.sessionTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${TimeUtils.formatShortDate(l.timestamp)} • ${l.durationSeconds ~/ 60} min',
                    ),
                    trailing: Text(
                      l.type.name,
                      style: AppStyles.caption.copyWith(
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

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: AppStyles.caption),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final Map<DateTime, int> data;
  final int days;
  _HeatmapPainter({required this.data, required this.days});

  @override
  void paint(Canvas canvas, Size size) {
    final now = TimeUtils.startOfDay(DateTime.now());
    int cols = (days / 7).ceil();
    double boxSize = (size.width - (cols - 1) * 4) / cols;
    if (boxSize > (size.height - 6 * 4) / 7)
      boxSize = (size.height - 6 * 4) / 7;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      int col = cols - 1 - (i ~/ 7);
      int row = date.weekday % 7;
      int count = data[date] ?? 0;

      if (count == 0)
        paint.color = AppColors.surfaceHighlight;
      else if (count == 1)
        paint.color = AppColors.primary.withOpacity(0.4);
      else
        paint.color = AppColors.primary;

      double x = col * (boxSize + 4);
      double y = row * (boxSize + 4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, boxSize, boxSize),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
