import 'dart:async';
import 'dart:math';
import 'dart:ui';
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


/// ============================================================================
/// 1. MAIN ENTRY POINT & APP SETUP
/// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MusicLibraryApp());
}

class MusicLibraryApp extends StatelessWidget {
  const MusicLibraryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      child: MaterialApp(
        title: 'Aura Music',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}

/// ============================================================================
/// 2. THEME & STYLING CONFIGURATION
/// ============================================================================
class AppTheme {
  static const Color primaryColor = Color(0xFF1DB954);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF282828);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: textPrimary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: textPrimary,
        inactiveTrackColor: surfaceColor,
        thumbColor: textPrimary,
        overlayColor: textPrimary.withOpacity(0.2),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
    );
  }
}

/// ============================================================================
/// 3. DATA MODELS
/// ============================================================================
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final Duration duration;
  final String lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.duration,
    this.lyrics = "Instrumental or lyrics not available.",
  });
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.songs,
  });
}

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final int monthlyListeners;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.monthlyListeners,
  });
}

/// ============================================================================
/// 4. MOCK DATABASE (Massive Data Generation)
/// ============================================================================
class MockDatabase {
  static final Random _random = Random();

  static String _generateRandomColorUrl() {
    final colors = ['123456', 'ff5733', '33ff57', '3357ff', 'ff33f6', 'f6ff33'];
    return 'https://via.placeholder.com/400/${colors[_random.nextInt(colors.length)]}/ffffff?text=Cover';
  }

  // Generates exactly 100 songs to populate the app
  static List<Song> generateSongs() {
    List<Song> songs = [];
    List<String> artists = [
      'The Midnight',
      'FM-84',
      'Timecop1983',
      'Gunship',
      'Kavinsky',
      'Daft Punk',
      'Justice',
    ];
    List<String> adjectives = [
      'Neon',
      'Dark',
      'Silent',
      'Electric',
      'Crystal',
      'Midnight',
      'Summer',
      'Digital',
    ];
    List<String> nouns = [
      'City',
      'Dreams',
      'Nights',
      'Love',
      'Echo',
      'Horizon',
      'Driver',
      'Wave',
    ];

    for (int i = 1; i <= 100; i++) {
      String artist = artists[_random.nextInt(artists.length)];
      String title =
          '${adjectives[_random.nextInt(adjectives.length)]} ${nouns[_random.nextInt(nouns.length)]}';

      songs.add(
        Song(
          id: 'song_$i',
          title: title,
          artist: artist,
          album: '$artist - The Anthology',
          coverUrl: _generateRandomColorUrl(),
          duration: Duration(seconds: 150 + _random.nextInt(180)),
          lyrics:
              "Verse 1\nWalking down the $title\nFeeling the rhythm of the $artist\n\nChorus\nOh yeah, this is the sound of the night!\n" *
              3,
        ),
      );
    }
    return songs;
  }

  static final List<Song> allSongs = generateSongs();

  static final List<Playlist> playlists = [
    Playlist(
      id: 'pl_1',
      name: 'Synthwave Essentials',
      description: 'The best retro-futuristic tracks.',
      coverUrl: _generateRandomColorUrl(),
      songs: allSongs.sublist(0, 20),
    ),
    Playlist(
      id: 'pl_2',
      name: 'Late Night Drive',
      description: 'Perfect for empty highways.',
      coverUrl: _generateRandomColorUrl(),
      songs: allSongs.sublist(20, 40),
    ),
    Playlist(
      id: 'pl_3',
      name: 'Workout Mix',
      description: 'High energy beats to keep you moving.',
      coverUrl: _generateRandomColorUrl(),
      songs: allSongs.sublist(40, 60),
    ),
  ];

  static final List<Artist> topArtists = [
    Artist(
      id: 'a_1',
      name: 'The Midnight',
      imageUrl: _generateRandomColorUrl(),
      monthlyListeners: 1500000,
    ),
    Artist(
      id: 'a_2',
      name: 'Kavinsky',
      imageUrl: _generateRandomColorUrl(),
      monthlyListeners: 2000000,
    ),
    Artist(
      id: 'a_3',
      name: 'Daft Punk',
      imageUrl: _generateRandomColorUrl(),
      monthlyListeners: 15000000,
    ),
    Artist(
      id: 'a_4',
      name: 'Justice',
      imageUrl: _generateRandomColorUrl(),
      monthlyListeners: 4000000,
    ),
  ];
}

/// ============================================================================
/// 5. STATE MANAGEMENT & AUDIO CONTROLLER (Core Logic)
/// ============================================================================
enum RepeatMode { none, all, one }

class MusicController extends ChangeNotifier {
  // Playback State
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Song? _currentSong;
  List<Song> _queue = [];
  List<Song> _originalQueue = [];
  int _currentIndex = -1;

  // Settings State
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;
  Set<String> _favoriteSongIds = {};

  // Engine Simulation
  Timer? _playbackTimer;

  // Getters
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  Set<String> get favoriteSongIds => _favoriteSongIds;

  double get progress {
    if (_currentSong == null || _currentSong!.duration.inSeconds == 0)
      return 0.0;
    return _currentPosition.inSeconds / _currentSong!.duration.inSeconds;
  }

  // Initialization
  MusicController() {
    _initFavorites();
  }

  void _initFavorites() {
    // Simulating loading favorites from local storage
    _favoriteSongIds = {'song_1', 'song_5', 'song_12'};
    notifyListeners();
  }

  // Playback Controls
  void play(List<Song> songs, {int initialIndex = 0}) {
    _originalQueue = List.from(songs);
    _queue = List.from(songs);

    if (_isShuffle) {
      _applyShuffle();
      // Ensure the selected song remains the first in shuffled queue
      Song selected = _originalQueue[initialIndex];
      _queue.remove(selected);
      _queue.insert(0, selected);
      _currentIndex = 0;
    } else {
      _currentIndex = initialIndex;
    }

    _currentSong = _queue[_currentIndex];
    _currentPosition = Duration.zero;
    _startPlayback();
    notifyListeners();
  }

  void resume() {
    if (_currentSong != null && !_isPlaying) {
      _startPlayback();
      notifyListeners();
    }
  }

  void pause() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else if (_currentSong != null) {
      resume();
    } else if (MockDatabase.allSongs.isNotEmpty) {
      play(MockDatabase.allSongs);
    }
  }

  void next() {
    if (_queue.isEmpty) return;

    if (_repeatMode == RepeatMode.one) {
      _currentPosition = Duration.zero;
      _startPlayback();
      return;
    }

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      _currentSong = _queue[_currentIndex];
      _currentPosition = Duration.zero;
      _startPlayback();
    } else {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
        _currentSong = _queue[_currentIndex];
        _currentPosition = Duration.zero;
        _startPlayback();
      } else {
        pause();
        _currentPosition = Duration.zero;
      }
    }
    notifyListeners();
  }

  void previous() {
    if (_queue.isEmpty) return;

    if (_currentPosition.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      _currentSong = _queue[_currentIndex];
      _currentPosition = Duration.zero;
      _startPlayback();
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _queue.length - 1;
      _currentSong = _queue[_currentIndex];
      _currentPosition = Duration.zero;
      _startPlayback();
    }
    notifyListeners();
  }

  void seek(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  // Modes
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      _applyShuffle();
      // Keep current song at index 0
      if (_currentSong != null) {
        _queue.remove(_currentSong);
        _queue.insert(0, _currentSong!);
        _currentIndex = 0;
      }
    } else {
      _queue = List.from(_originalQueue);
      if (_currentSong != null) {
        _currentIndex = _queue.indexOf(_currentSong!);
      }
    }
    notifyListeners();
  }

  void _applyShuffle() {
    _queue.shuffle(Random());
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
    notifyListeners();
  }

  // Favorites
  void toggleFavorite(String songId) {
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    notifyListeners();
  }

  bool isFavorite(String songId) => _favoriteSongIds.contains(songId);

  // Engine Simulation
  void _startPlayback() {
    _isPlaying = true;
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSong != null) {
        if (_currentPosition.inSeconds < _currentSong!.duration.inSeconds) {
          _currentPosition = Duration(seconds: _currentPosition.inSeconds + 1);
          notifyListeners();
        } else {
          next();
        }
      }
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

/// Provider Wrapper to inject state without external packages
class AppStateProvider extends StatefulWidget {
  final Widget child;
  const AppStateProvider({Key? key, required this.child}) : super(key: key);

  static MusicController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedAppState>()!
        .controller;
  }

  @override
  _AppStateProviderState createState() => _AppStateProviderState();
}

class _AppStateProviderState extends State<AppStateProvider> {
  final MusicController _controller = MusicController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _InheritedAppState(controller: _controller, child: widget.child);
      },
    );
  }
}

class _InheritedAppState extends InheritedWidget {
  final MusicController controller;

  const _InheritedAppState({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedAppState oldWidget) => true;
}

/// ============================================================================
/// 6. MAIN NAVIGATION (Bottom Tabs)
/// ============================================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppStateProvider.of(context);
    final hasActiveAudio = controller.currentSong != null;

    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          IndexedStack(index: _currentIndex, children: _screens),

          // Persistent Mini Player above Nav Bar
          if (hasActiveAudio)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const FullPlayerScreen(),
                  );
                },
                child: const MiniPlayer(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasActiveAudio)
            const SizedBox(height: 65), // Offset for mini player
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 7. HOME SCREEN
/// ============================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Good Evening'),
              titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.5),
                      AppTheme.backgroundColor,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              IconButton(icon: const Icon(Icons.history), onPressed: () {}),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickPicks(context),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Made For You'),
                  const SizedBox(height: 16),
                  _buildHorizontalList(context, MockDatabase.playlists),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Recently Played'),
                  const SizedBox(height: 16),
                  _buildRecentList(context),
                  const SizedBox(height: 100), // padding for mini player
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPicks(BuildContext context) {
    final songs = MockDatabase.allSongs.sublist(0, 6);
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return InkWell(
          onTap: () {
            AppStateProvider.of(
              context,
            ).play(MockDatabase.allSongs, initialIndex: index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                  child: Image.network(
                    song.coverUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    song.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<Playlist> playlists) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlist: playlist),
                ),
              );
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      playlist.coverUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    playlist.description,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentList(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: MockDatabase.topArtists.length,
        itemBuilder: (context, index) {
          final artist = MockDatabase.topArtists[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(artist.imageUrl),
                ),
                const SizedBox(height: 8),
                Text(
                  artist.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================================
/// 8. PLAYLIST DETAIL SCREEN
/// ============================================================================
class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({Key? key, required this.playlist})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = AppStateProvider.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: Image.network(playlist.coverUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.description,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, color: Colors.grey),
                      const SizedBox(width: 16),
                      const Icon(Icons.more_vert, color: Colors.grey),
                      const Spacer(),
                      FloatingActionButton(
                        backgroundColor: AppTheme.primaryColor,
                        onPressed: () {
                          controller.play(playlist.songs);
                        },
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = playlist.songs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    song.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.more_vert, color: Colors.grey),
                onTap: () {
                  controller.play(playlist.songs, initialIndex: index);
                },
              );
            }, childCount: playlist.songs.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 9. SEARCH SCREEN
/// ============================================================================
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    List<Song> results = _query.isEmpty
        ? []
        : MockDatabase.allSongs
              .where(
                (s) =>
                    s.title.toLowerCase().contains(_query.toLowerCase()) ||
                    s.artist.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Artists, songs, or podcasts',
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: Colors.black),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? const Center(child: Text('Search for your favorite tracks.'))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final song = results[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      song.coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  onTap: () {
                    AppStateProvider.of(context).play([song]);
                  },
                );
              },
            ),
    );
  }
}

/// ============================================================================
/// 10. LIBRARY SCREEN
/// ============================================================================
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Library'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Artists'),
              Tab(text: 'Albums'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLibraryPlaylists(),
            _buildLibraryArtists(),
            const Center(child: Text('Albums Empty')),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryPlaylists() {
    return ListView.builder(
      itemCount: MockDatabase.playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.favorite, color: Colors.white),
            ),
            title: const Text('Liked Songs'),
            subtitle: const Text('Playlist • 3 songs'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          );
        }
        final playlist = MockDatabase.playlists[index - 1];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              playlist.coverUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(playlist.name),
          subtitle: Text('Playlist • ${playlist.songs.length} songs'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(playlist: playlist),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryArtists() {
    return ListView.builder(
      itemCount: MockDatabase.topArtists.length,
      itemBuilder: (context, index) {
        final artist = MockDatabase.topArtists[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(artist.imageUrl),
          ),
          title: Text(artist.name),
          subtitle: const Text('Artist'),
        );
      },
    );
  }
}

/// ============================================================================
/// 11. FAVORITES SCREEN
/// ============================================================================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = AppStateProvider.of(context);
    final favoriteSongs = MockDatabase.allSongs
        .where((s) => controller.isFavorite(s.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Liked Songs')),
      body: favoriteSongs.isEmpty
          ? const Center(child: Text('No favorite songs yet.'))
          : ListView.builder(
              itemCount: favoriteSongs.length,
              itemBuilder: (context, index) {
                final song = favoriteSongs[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      song.coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => controller.toggleFavorite(song.id),
                  ),
                  onTap: () =>
                      controller.play(favoriteSongs, initialIndex: index),
                );
              },
            ),
    );
  }
}

/// ============================================================================
/// 12. SETTINGS SCREEN
/// ============================================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const UserProfileHeader(),
          const Divider(color: Colors.grey),
          ListTile(
            title: const Text('Data Saver'),
            subtitle: const Text(
              'Sets your audio quality to low and disables canvases.',
            ),
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
          ListTile(
            title: const Text('Offline mode'),
            subtitle: const Text(
              'When you go offline, you\'ll only be able to play music you\'ve downloaded.',
            ),
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
          ListTile(
            title: const Text('Crossfade'),
            subtitle: const Text('Allows you to crossfade between songs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Equalizer'),
            subtitle: const Text('Adjust audio frequencies'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EqualizerScreen()),
              );
            },
          ),
          const SizedBox(height: 32),
          Center(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text(
                  'LOG OUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text('View Profile', style: TextStyle(color: Colors.grey)),
            ],
          ),
          Spacer(),
          Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 13. EQUALIZER SCREEN (Mock Visuals)
/// ============================================================================
class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({Key? key}) : super(key: key);

  @override
  _EqualizerScreenState createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  List<double> _frequencies = [0.5, 0.7, 0.4, 0.6, 0.5, 0.8];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_frequencies.length, (index) {
                  return Column(
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: _frequencies[index],
                            onChanged: (val) =>
                                setState(() => _frequencies[index] = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(index + 1) * 60}Hz',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() => _frequencies = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]);
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// 14. MINI PLAYER (Persistent Bottom Bar)
/// ============================================================================
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = AppStateProvider.of(context);
    final song = controller.currentSong;

    if (song == null) return const SizedBox.shrink();

    return Container(
      height: 65,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    song.coverUrl,
                    width: 45,
                    height: 45,
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
                        song.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    controller.isFavorite(song.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: controller.isFavorite(song.id)
                        ? AppTheme.primaryColor
                        : Colors.white,
                  ),
                  onPressed: () => controller.toggleFavorite(song.id),
                ),
                IconButton(
                  icon: Icon(
                    controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: controller.togglePlayPause,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Progress Bar at bottom of mini player
          LinearProgressIndicator(
            value: controller.progress,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 2,
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 15. FULL PLAYER SCREEN (The Main Playing Interface)
/// ============================================================================
class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({Key? key}) : super(key: key);

  @override
  _FullPlayerScreenState createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppStateProvider.of(context);
    final song = controller.currentSong;

    if (song == null)
      return const Scaffold(body: Center(child: Text('No song playing')));

    if (controller.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background blurred image
          Positioned.fill(
            child: Image.network(song.coverUrl, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Column(
                        children: [
                          Text(
                            'PLAYING FROM PLAYLIST',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                          ),
                          Text(
                            'Synthwave Essentials',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showLyrics = !_showLyrics),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _showLyrics
                          ? _buildLyricsView(song.lyrics)
                          : _buildAlbumArt(song.coverUrl),
                    ),
                  ),
                ),

                // Controls & Progress
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      // Title & Favorite
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarqueeText(
                                  text: song.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  song.artist,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              controller.isFavorite(song.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: controller.isFavorite(song.id)
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              size: 32,
                            ),
                            onPressed: () => controller.toggleFavorite(song.id),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Seek Bar
                      _buildProgressBar(controller, song),

                      const SizedBox(height: 16),

                      // Main Transport Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: controller.isShuffle
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                            ),
                            onPressed: controller.toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 40),
                            onPressed: controller.previous,
                          ),
                          GestureDetector(
                            onTap: controller.togglePlayPause,
                            child: Container(
                              height: 72,
                              width: 72,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.black,
                                size: 40,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 40),
                            onPressed: controller.next,
                          ),
                          IconButton(
                            icon: Icon(
                              controller.repeatMode == RepeatMode.none
                                  ? Icons.repeat
                                  : controller.repeatMode == RepeatMode.all
                                  ? Icons.repeat
                                  : Icons.repeat_one,
                              color: controller.repeatMode != RepeatMode.none
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                            ),
                            onPressed: controller.toggleRepeat,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Bottom Icons (Devices, Queue)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.devices),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.queue_music),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) =>
                                    QueueScreen(controller: controller),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(String url) {
    return Center(
      key: const ValueKey('art'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2.0 * pi,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        url,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLyricsView(String lyrics) {
    return Container(
      key: const ValueKey('lyrics'),
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Text(
          lyrics,
          style: const TextStyle(
            fontSize: 24,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProgressBar(MusicController controller, Song song) {
    return Column(
      children: [
        Slider(
          value: controller.progress.clamp(0.0, 1.0),
          onChanged: (val) {
            final newSeconds = (val * song.duration.inSeconds).round();
            controller.seek(Duration(seconds: newSeconds));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(controller.currentPosition),
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                _formatDuration(song.duration),
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

/// ============================================================================
/// 16. QUEUE SCREEN
/// ============================================================================
class QueueScreen extends StatelessWidget {
  final MusicController controller;
  const QueueScreen({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Playing Queue'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        itemCount: controller.queue.length,
        itemBuilder: (context, index) {
          final song = controller.queue[index];
          final isCurrent = song.id == controller.currentSong?.id;
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                song.coverUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: isCurrent ? AppTheme.primaryColor : Colors.white,
              ),
            ),
            subtitle: Text(song.artist),
            trailing: isCurrent
                ? const Icon(Icons.volume_up, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              // Play selected track from queue
              int idx = controller.queue.indexOf(song);
              if (idx != -1) {
                controller.play(controller.queue, initialIndex: idx);
                Navigator.pop(context);
              }
            },
          );
        },
      ),
    );
  }
}

/// ============================================================================
/// 17. UTILITY WIDGETS (Marquee, Section Header, etc)
/// ============================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const MarqueeText({Key? key, required this.text, required this.style})
    : super(key: key);

  @override
  _MarqueeTextState createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _startScrolling();
      }
    });
  }

  void _startScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) break;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 4),
        curve: Curves.linear,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) break;
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Text(widget.text, style: widget.style),
    );
  }
}
