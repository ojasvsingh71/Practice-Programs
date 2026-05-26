import 'dart:async';
import 'dart:math' as math;
// removed unused import 'dart:ui'
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

enum PlaybackState { idle, buffering, playing, paused, completed, error }

enum DownloadStatus { none, downloading, downloaded, failed }

enum PlaybackSpeed { x0_5, x1_0, x1_2, x1_5, x2_0 }

class AppColors {
  static const Color background = Color(
    0xFF09090B,
  ); // Slate 950 (Deep Pitch Black)
  static const Color surface = Color(0xFF18181B); // Zinc 900
  static const Color surfaceHighlight = Color(0xFF27272A); // Zinc 800

  static const Color primary = Color(0xFF8B5CF6); // Violet 500
  static const Color primaryDark = Color(0xFF6D28D9); // Violet 700
  static const Color accent = Color(0xFF10B981); // Emerald 500

  static const Color textMain = Color(0xFFFAFAFA); // Zinc 50
  static const Color textMuted = Color(0xFFA1A1AA); // Zinc 400

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const List<Color> gradients = [Color(0xFF8B5CF6), Color(0xFF3B82F6)];
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
    fontWeight: FontWeight.w700,
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
    fontWeight: FontWeight.w500,
  );
}

// ============================================================================
// 2. EXCEPTIONS & UTILITIES
// ============================================================================

abstract class PodcastException implements Exception {
  final String message;
  PodcastException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends PodcastException {
  NetworkException([String m = "Network timeout."]) : super(m);
}

class AudioDecodeException extends PodcastException {
  AudioDecodeException([String m = "Failed to decode audio stream."])
    : super(m);
}

class Formatters {
  static String duration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0)
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  static String date(DateTime d) {
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

class Podcast {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final List<String> categories;
  final double rating;

  Podcast({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.categories,
    this.rating = 5.0,
  });
}

class Episode {
  final String id;
  final String podcastId;
  final String title;
  final String description;
  final Duration duration;
  final DateTime publishDate;

  // Dynamic State
  DownloadStatus downloadStatus;
  double downloadProgress;
  Duration resumePosition;

  Episode({
    required this.id,
    required this.podcastId,
    required this.title,
    required this.description,
    required this.duration,
    required this.publishDate,
    this.downloadStatus = DownloadStatus.none,
    this.downloadProgress = 0.0,
    this.resumePosition = Duration.zero,
  });

  Episode copyWith({
    DownloadStatus? downloadStatus,
    double? downloadProgress,
    Duration? resumePosition,
  }) {
    return Episode(
      id: id,
      podcastId: podcastId,
      title: title,
      description: description,
      duration: duration,
      publishDate: publishDate,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      resumePosition: resumePosition ?? this.resumePosition,
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final List<String> episodeIds;
  final String coverUrl;

  Playlist({
    required this.id,
    required this.name,
    required this.episodeIds,
    required this.coverUrl,
  });
}

// ============================================================================
// 4. MOCK AUDIO ENGINE (Simulates Streaming, Buffering, Playback)
// ============================================================================

class MockAudioPlayer {
  final StreamController<PlaybackState> _stateCtrl =
      StreamController<PlaybackState>.broadcast();
  final StreamController<Duration> _positionCtrl =
      StreamController<Duration>.broadcast();
  final StreamController<Episode> _episodeCtrl =
      StreamController<Episode>.broadcast();

  Stream<PlaybackState> get stateStream => _stateCtrl.stream;
  Stream<Duration> get positionStream => _positionCtrl.stream;
  Stream<Episode> get episodeStream => _episodeCtrl.stream;

  PlaybackState state = PlaybackState.idle;
  Episode? currentEpisode;
  Duration currentPosition = Duration.zero;
  PlaybackSpeed speed = PlaybackSpeed.x1_0;

  Timer? _playbackTimer;

  void play(Episode episode) async {
    if (currentEpisode?.id != episode.id) {
      currentEpisode = episode;
      currentPosition = episode.resumePosition;
      _episodeCtrl.sink.add(episode);
      _positionCtrl.sink.add(currentPosition);

      // Simulate Buffering on new episode
      _updateState(PlaybackState.buffering);
      await Future.delayed(const Duration(milliseconds: 1500));
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
    else if (currentEpisode != null)
      play(currentEpisode!);
  }

  void seek(Duration position) {
    if (currentEpisode == null) return;
    currentPosition = Duration(
      milliseconds: position.inMilliseconds.clamp(
        0,
        currentEpisode!.duration.inMilliseconds,
      ),
    );
    _positionCtrl.sink.add(currentPosition);
  }

  void skipForward() => seek(currentPosition + const Duration(seconds: 15));
  void skipBackward() => seek(currentPosition - const Duration(seconds: 15));

  void setSpeed(PlaybackSpeed newSpeed) {
    speed = newSpeed;
    if (state == PlaybackState.playing) {
      _playbackTimer?.cancel();
      _startTimer(); // Restart timer with new tick rate
    }
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    // High-frequency tick for smooth UI updates
    const tickMs = 50;
    _playbackTimer = Timer.periodic(const Duration(milliseconds: tickMs), (
      timer,
    ) {
      if (currentEpisode == null) return;

      double multiplier = _getSpeedMultiplier();
      int increment = (tickMs * multiplier).toInt();

      currentPosition += Duration(milliseconds: increment);

      if (currentPosition >= currentEpisode!.duration) {
        currentPosition = currentEpisode!.duration;
        _updateState(PlaybackState.completed);
        timer.cancel();
      }

      _positionCtrl.sink.add(currentPosition);
    });
  }

  double _getSpeedMultiplier() {
    switch (speed) {
      case PlaybackSpeed.x0_5:
        return 0.5;
      case PlaybackSpeed.x1_0:
        return 1.0;
      case PlaybackSpeed.x1_2:
        return 1.25;
      case PlaybackSpeed.x1_5:
        return 1.5;
      case PlaybackSpeed.x2_0:
        return 2.0;
    }
  }

  void _updateState(PlaybackState newState) {
    state = newState;
    _stateCtrl.sink.add(state);
  }

  void dispose() {
    _playbackTimer?.cancel();
    _stateCtrl.close();
    _positionCtrl.close();
    _episodeCtrl.close();
  }
}

// ============================================================================
// 5. MOCK BACKEND ENGINE & DOWNLOAD QUEUE
// ============================================================================

class MockPodcastDatabase {
  static final MockPodcastDatabase _instance = MockPodcastDatabase._internal();
  factory MockPodcastDatabase() => _instance;
  MockPodcastDatabase._internal() {
    _seedData();
  }

  final math.Random _rand = math.Random();
  final Map<String, Podcast> _podcasts = {};
  final Map<String, Episode> _episodes = {};
  final Map<String, Playlist> _playlists = {};

  // Public unnamed constructor removed; seeding occurs in `_internal()`.

  void _seedData() {
    final now = DateTime.now();
    const lorem =
        "In this highly anticipated episode, we dive deep into the mechanics of modern software architecture, exploring the tradeoffs between microservices and monoliths. Join our guest experts as they share battle-tested strategies for scaling enterprise systems.";

    // Seed Podcasts
    final p1 = Podcast(
      id: 'P1',
      title: 'The Flutter Way',
      author: 'Nexus Media',
      description:
          'Weekly discussions on declarative UI, state management, and mobile engineering.',
      coverUrl:
          'https://images.unsplash.com/photo-1617042375876-a13e36732a04?auto=format&fit=crop&w=400&q=80',
      categories: ['Technology', 'Programming'],
    );
    final p2 = Podcast(
      id: 'P2',
      title: 'Startup Diaries',
      author: 'Silicon Valley Network',
      description:
          'Candid interviews with founders about the grueling journey of building a company from scratch.',
      coverUrl:
          'https://images.unsplash.com/photo-1556761175-5973dc0f32d7?auto=format&fit=crop&w=400&q=80',
      categories: ['Business', 'Entrepreneurship'],
    );
    final p3 = Podcast(
      id: 'P3',
      title: 'Deep Space Mysteries',
      author: 'AstroCast',
      description:
          'Exploring the cosmos, black holes, and the future of interstellar travel.',
      coverUrl:
          'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=400&q=80',
      categories: ['Science', 'Astronomy'],
    );

    _podcasts.addAll({p1.id: p1, p2.id: p2, p3.id: p3});

    // Seed Episodes
    for (int i = 0; i < 15; i++) {
      String pId = [p1.id, p2.id, p3.id][_rand.nextInt(3)];
      String epId = 'EP_$i';
      _episodes[epId] = Episode(
        id: epId,
        podcastId: pId,
        title: 'Episode ${i + 1}: ${_generateTitle()}',
        description: lorem,
        duration: Duration(
          minutes: 30 + _rand.nextInt(60),
          seconds: _rand.nextInt(60),
        ),
        publishDate: now.subtract(Duration(days: i * 3)),
      );
    }

    // Seed Playlists
    _playlists['PL1'] = Playlist(
      id: 'PL1',
      name: 'Coding Commute',
      episodeIds: _episodes.values
          .where((e) => e.podcastId == 'P1')
          .take(3)
          .map((e) => e.id)
          .toList(),
      coverUrl: p1.coverUrl,
    );
    _playlists['PL2'] = Playlist(
      id: 'PL2',
      name: 'Science Weekend',
      episodeIds: _episodes.values
          .where((e) => e.podcastId == 'P3')
          .take(4)
          .map((e) => e.id)
          .toList(),
      coverUrl: p3.coverUrl,
    );
  }

  String _generateTitle() {
    const words = [
      "Architecture",
      "Scaling",
      "Failures",
      "Success",
      "Funding",
      "The Core",
      "Mysteries",
      "Quantum",
      "Widgets",
      "Deployment",
    ];
    return "${words[_rand.nextInt(words.length)]} and ${words[_rand.nextInt(words.length)]}";
  }

  Future<void> _latency([int ms = 600]) async =>
      await Future.delayed(Duration(milliseconds: ms + _rand.nextInt(400)));

  Future<List<Podcast>> getPodcasts() async {
    await _latency();
    return _podcasts.values.toList();
  }

  Future<List<Episode>> getEpisodes(String podcastId) async {
    await _latency();
    return _episodes.values.where((e) => e.podcastId == podcastId).toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }

  Future<List<Playlist>> getPlaylists() async {
    await _latency();
    return _playlists.values.toList();
  }

  Podcast getPodcastInfo(String id) => _podcasts[id]!;
  Episode getEpisodeInfo(String id) => _episodes[id]!;

  /// Simulates a byte-stream download for offline listening
  Stream<double> downloadEpisode(String episodeId) async* {
    int chunks = 20;
    for (int i = 1; i <= chunks; i++) {
      await Future.delayed(Duration(milliseconds: 100 + _rand.nextInt(200)));
      yield i / chunks;
    }
  }
}

// ============================================================================
// 6. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockPodcastDatabase _db = MockPodcastDatabase();
  final MockAudioPlayer audioEngine = MockAudioPlayer();

  bool isGlobalLoading = true;
  String? globalError;

  List<Podcast> featuredPodcasts = [];
  List<Episode> recentEpisodes = [];
  List<Playlist> myPlaylists = [];

  // Active View State
  Podcast? activePodcast;
  List<Episode> activePodcastEpisodes = [];

  // Download Manager
  final Map<String, StreamSubscription> _activeDownloads = {};

  AppState() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      featuredPodcasts = await _db.getPodcasts();
      myPlaylists = await _db.getPlaylists();

      // Load recent from all
      final allEps = _db._episodes.values.toList()
        ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
      recentEpisodes = allEps.take(10).toList();

      // Hook up audio engine listener to force UI rebuilds on play/pause
      audioEngine.stateStream.listen((_) => notifyListeners());
      audioEngine.episodeStream.listen((_) => notifyListeners());
    } catch (e) {
      globalError = "Failed to load podcasts.";
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<void> openPodcast(Podcast p) async {
    isGlobalLoading = true;
    notifyListeners();
    try {
      activePodcast = p;
      activePodcastEpisodes = await _db.getEpisodes(p.id);
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  // --- Playback Controls Proxy ---
  void playEpisode(Episode e) {
    audioEngine.play(e);
  }

  // --- Download Engine ---
  void toggleDownload(Episode e) {
    if (e.downloadStatus == DownloadStatus.downloaded) {
      _removeDownload(e.id);
    } else if (e.downloadStatus == DownloadStatus.none ||
        e.downloadStatus == DownloadStatus.failed) {
      _startDownload(e.id);
    }
  }

  void _startDownload(String epId) {
    if (_activeDownloads.containsKey(epId)) return;
    _updateEpState(
      epId,
      (e) => e.copyWith(
        downloadStatus: DownloadStatus.downloading,
        downloadProgress: 0.0,
      ),
    );

    _activeDownloads[epId] = _db
        .downloadEpisode(epId)
        .listen(
          (progress) => _updateEpState(
            epId,
            (e) => e.copyWith(downloadProgress: progress),
          ),
          onDone: () {
            _activeDownloads.remove(epId);
            _updateEpState(
              epId,
              (e) => e.copyWith(
                downloadStatus: DownloadStatus.downloaded,
                downloadProgress: 1.0,
              ),
            );
          },
          onError: (_) {
            _activeDownloads.remove(epId);
            _updateEpState(
              epId,
              (e) => e.copyWith(downloadStatus: DownloadStatus.failed),
            );
          },
        );
  }

  void _removeDownload(String epId) {
    _updateEpState(
      epId,
      (e) => e.copyWith(
        downloadStatus: DownloadStatus.none,
        downloadProgress: 0.0,
      ),
    );
  }

  void _updateEpState(String epId, Episode Function(Episode) updater) {
    int idx1 = recentEpisodes.indexWhere((e) => e.id == epId);
    if (idx1 != -1) recentEpisodes[idx1] = updater(recentEpisodes[idx1]);

    int idx2 = activePodcastEpisodes.indexWhere((e) => e.id == epId);
    if (idx2 != -1)
      activePodcastEpisodes[idx2] = updater(activePodcastEpisodes[idx2]);

    notifyListeners();
  }

  Podcast getPodcast(String id) => _db.getPodcastInfo(id);
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
// 7. MAIN APP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PodcastApp());
}

class PodcastApp extends StatelessWidget {
  const PodcastApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Podcasts',
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
    if (state.isGlobalLoading && state.featuredPodcasts.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return const MainScaffold();
  }
}

// ============================================================================
// 8. MAIN SCAFFOLD & GLOBAL MINI-PLAYER
// ============================================================================

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final _screens = [
    const DiscoverScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final hasActiveAudio = state.audioEngine.currentEpisode != null;

    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            bottom: hasActiveAudio
                ? 140
                : 80, // Padding for MiniPlayer + NavBar
            child: _screens[_currentIndex],
          ),

          // Global Mini Player Overlay
          if (hasActiveAudio)
            Positioned(
              left: 8,
              right: 8,
              bottom: 90, // Above NavBar
              child: const MiniPlayer(),
            ),

          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.surfaceHighlight, width: 1),
                ),
                color: AppColors.background,
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                backgroundColor: AppColors.background,
                indicatorColor: AppColors.primary.withOpacity(0.2),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore, color: AppColors.primary),
                    label: 'Discover',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(
                      Icons.library_music,
                      color: AppColors.primary,
                    ),
                    label: 'Library',
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
// 9. DISCOVER / HOME SCREEN
// ============================================================================

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: const Text('Good Morning', style: AppStyles.h2),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Text('Featured Shows', style: AppStyles.h3),
                ),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.featuredPodcasts.length,
                    itemBuilder: (ctx, i) => _FeaturedPodcastCard(
                      podcast: state.featuredPodcasts[i],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text('New Episodes', style: AppStyles.h3),
                ),
              ],
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _EpisodeTile(
                episode: state.recentEpisodes[index],
                showPodcastName: true,
              ),
              childCount: state.recentEpisodes.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedPodcastCard extends StatelessWidget {
  final Podcast podcast;
  const _FeaturedPodcastCard({required this.podcast});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context, listen: false);
    return GestureDetector(
      onTap: () async {
        await state.openPodcast(podcast);
        if (context.mounted)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PodcastDetailScreen()),
          );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'cover_${podcast.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  podcast.coverUrl,
                  height: 160,
                  width: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              podcast.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              podcast.author,
              style: AppStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool showPodcastName;
  const _EpisodeTile({required this.episode, this.showPodcastName = false});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final podcast = state.getPodcast(episode.podcastId);
    final isPlaying =
        state.audioEngine.currentEpisode?.id == episode.id &&
        state.audioEngine.state == PlaybackState.playing;

    return InkWell(
      onTap: () => state.playEpisode(episode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                podcast.coverUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPodcastName)
                    Text(
                      podcast.title,
                      style: AppStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  Text(
                    episode.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isPlaying ? AppColors.primary : AppColors.textMain,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.description,
                    style: AppStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        Formatters.date(episode.publishDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        Formatters.duration(episode.duration),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      _DownloadButton(episode: episode),
                      const SizedBox(width: 8),
                      Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 28,
                        color: isPlaying
                            ? AppColors.primary
                            : AppColors.textMain,
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

class _DownloadButton extends StatelessWidget {
  final Episode episode;
  const _DownloadButton({required this.episode});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    if (episode.downloadStatus == DownloadStatus.downloading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: episode.downloadProgress,
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    IconData ic = Icons.arrow_circle_down;
    Color c = AppColors.textMuted;
    if (episode.downloadStatus == DownloadStatus.downloaded) {
      ic = Icons.offline_pin;
      c = AppColors.accent;
    }
    if (episode.downloadStatus == DownloadStatus.failed) {
      ic = Icons.error;
      c = AppColors.error;
    }

    return GestureDetector(
      onTap: () => state.toggleDownload(episode),
      child: Icon(ic, size: 20, color: c),
    );
  }
}

// ============================================================================
// 10. PODCAST DETAILS SCREEN (Parallax & Episodes)
// ============================================================================

class PodcastDetailScreen extends StatelessWidget {
  const PodcastDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final podcast = state.activePodcast;
    if (podcast == null) return const Scaffold();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'cover_${podcast.id}',
                    child: Image.network(podcast.coverUrl, fit: BoxFit.cover),
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
                  Container(
                    color: AppColors.background.withOpacity(0.5),
                  ), // Darken for text readability
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(podcast.title, style: AppStyles.h1),
                  const SizedBox(height: 8),
                  Text(
                    podcast.author,
                    style: AppStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(podcast.description, style: AppStyles.body),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textMain,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'SUBSCRIBE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text('${podcast.rating}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(color: AppColors.surfaceHighlight),
                  ),
                  const Text('All Episodes', style: AppStyles.h2),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _EpisodeTile(episode: state.activePodcastEpisodes[index]),
              childCount: state.activePodcastEpisodes.length,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 11. MINI PLAYER & FULL SCREEN IMMERSIVE PLAYER
// ============================================================================

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FullScreenPlayer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final engine = state.audioEngine;
    final ep = engine.currentEpisode;
    if (ep == null) return const SizedBox.shrink();

    final isPlaying = engine.state == PlaybackState.playing;
    final podcast = state.getPodcast(ep.podcastId);

    return GestureDetector(
      onTap: () => _openFullPlayer(context),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        podcast.coverUrl,
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
                            ep.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            podcast.title,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay),
                      onPressed: () => engine.skipBackward(),
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 28,
                      ),
                      onPressed: () => engine.togglePlayPause(),
                    ),
                  ],
                ),
              ),
            ),
            // Progress Bar
            StreamBuilder<Duration>(
              stream: engine.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final prog = (pos.inMilliseconds / ep.duration.inMilliseconds)
                    .clamp(0.0, 1.0);
                return LinearProgressIndicator(
                  value: prog,
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

class FullScreenPlayer extends StatelessWidget {
  const FullScreenPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final engine = state.audioEngine;
    final ep = engine.currentEpisode!;
    final podcast = state.getPodcast(ep.podcastId);
    final isPlaying = engine.state == PlaybackState.playing;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            // Cover Art
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  podcast.coverUrl,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Meta
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ep.title,
                style: AppStyles.h2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                podcast.author,
                style: AppStyles.h3.copyWith(color: AppColors.textMuted),
              ),
            ),

            const SizedBox(height: 32),

            // Dynamic Custom Waveform Visualizer
            SizedBox(
              height: 60,
              width: double.infinity,
              child: CustomPaint(
                painter: _AudioWaveformPainter(isPlaying: isPlaying),
              ),
            ),

            // Scrubber
            StreamBuilder<Duration>(
              stream: engine.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceHighlight,
                        thumbColor: AppColors.textMain,
                      ),
                      child: Slider(
                        value: pos.inMilliseconds.toDouble(),
                        min: 0,
                        max: ep.duration.inMilliseconds.toDouble(),
                        onChanged: (val) =>
                            engine.seek(Duration(milliseconds: val.toInt())),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.duration(pos),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          Formatters.duration(ep.duration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const Spacer(),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    // Cycle speed
                    const speeds = [
                      PlaybackSpeed.x1_0,
                      PlaybackSpeed.x1_2,
                      PlaybackSpeed.x1_5,
                      PlaybackSpeed.x2_0,
                    ];
                    int i = speeds.indexOf(engine.speed);
                    engine.setSpeed(speeds[(i + 1) % speeds.length]);
                    // Force rebuild (hacky for this local scope, better handled via state)
                    (context as Element).markNeedsBuild();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      engine.speed.name
                              .replaceAll('x', '')
                              .replaceAll('_', '.') +
                          'x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.replay, size: 36),
                  onPressed: () => engine.skipBackward(),
                ),
                GestureDetector(
                  onTap: () => engine.togglePlayPause(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.textMain,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppColors.background,
                      size: 40,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.forward, size: 36),
                  onPressed: () => engine.skipForward(),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM AUDIO WAVEFORM PAINTER ---
class _AudioWaveformPainter extends CustomPainter {
  final bool isPlaying;
  final math.Random _rand = math.Random(
    42,
  ); // static seed for consistent bars, dynamic heights

  _AudioWaveformPainter({required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final int barCount = (size.width / 8).floor();
    final double spacing = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      // If playing, randomize height aggressively to simulate audio data. Else, flatline.
      double height = isPlaying
          ? (_rand.nextDouble() * size.height * 0.8 + size.height * 0.2)
          : size.height * 0.1;

      // Mirror vertically
      double topY = (size.height - height) / 2;
      double bottomY = topY + height;

      canvas.drawLine(
        Offset(i * spacing, topY),
        Offset(i * spacing, bottomY),
        paint,
      );
    }
  }

  // To make it animate constantly while playing, we rely on the state ticking the UI.
  @override
  bool shouldRepaint(covariant _AudioWaveformPainter old) =>
      old.isPlaying || isPlaying;
}

// ============================================================================
// 12. LIBRARY & PROFILE Placeholders
// ============================================================================

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Library')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: state.myPlaylists.length,
        itemBuilder: (ctx, i) {
          final pl = state.myPlaylists[i];
          return ListTile(
            contentPadding: const EdgeInsets.only(bottom: 16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                pl.coverUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              pl.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${pl.episodeIds.length} episodes',
              style: AppStyles.caption,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Profile & Settings', style: AppStyles.h2)),
  );
}
