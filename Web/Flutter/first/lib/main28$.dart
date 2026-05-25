import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME CONFIGURATION
// ============================================================================

enum NewsCategory {
  all,
  world,
  technology,
  business,
  science,
  sports,
  entertainment,
}

enum SyncStatus { none, downloading, downloaded, failed }

enum ReadingTheme { light, dark, sepia }

class AppColors {
  // Main Theme
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceHighlight = Color(0xFFF1F5F9); // Slate 100
  static const Color primary = Color(0xFFE11D48); // Rose 600 (Journalistic Red)
  static const Color primaryDark = Color(0xFFBE123C); // Rose 700
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // States
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Reader Themes
  static const Color sepiaBg = Color(0xFFFBF0D9);
  static const Color sepiaText = Color(0xFF5F4B32);
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkText = Color(0xFFE2E8F0);
}

class AppStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textMain,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const TextStyle subhead = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
    letterSpacing: -0.3,
  );
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textMain,
    height: 1.6,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle h2 = subhead;
  static const TextStyle h3 = title;
}

// ============================================================================
// 2. EXCEPTIONS & UTILS
// ============================================================================

abstract class NewsException implements Exception {
  final String message;
  NewsException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends NewsException {
  NetworkException([String m = "Network unavailable. Showing offline data."])
    : super(m);
}

class CacheMissException extends NewsException {
  CacheMissException([String m = "Article not available offline."]) : super(m);
}

class TimeFormatter {
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  static String readTime(String content) {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil(); // Avg 200 wpm
    return '$minutes min read';
  }
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class Source {
  final String id;
  final String name;
  final String logoUrl;
  Source({required this.id, required this.name, required this.logoUrl});
}

class Article {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final Source source;
  final NewsCategory category;
  final String author;
  final DateTime publishedAt;

  // Local State Metadata
  bool isBookmarked;
  SyncStatus syncStatus;
  double downloadProgress; // 0.0 to 1.0

  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.source,
    required this.category,
    required this.author,
    required this.publishedAt,
    this.isBookmarked = false,
    this.syncStatus = SyncStatus.none,
    this.downloadProgress = 0.0,
  });

  Article copyWith({
    bool? isBookmarked,
    SyncStatus? syncStatus,
    double? downloadProgress,
  }) {
    return Article(
      id: id,
      title: title,
      summary: summary,
      content: content,
      imageUrl: imageUrl,
      source: source,
      category: category,
      author: author,
      publishedAt: publishedAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      syncStatus: syncStatus ?? this.syncStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

class ReaderSettings {
  final double fontSize;
  final double lineHeight;
  final bool isSerif;
  final ReadingTheme theme;

  ReaderSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.6,
    this.isSerif = true,
    this.theme = ReadingTheme.light,
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    bool? isSerif,
    ReadingTheme? theme,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      isSerif: isSerif ?? this.isSerif,
      theme: theme ?? this.theme,
    );
  }
}

// ============================================================================
// 4. MOCK CLOUD API & LOCAL STORAGE ENGINE
// ============================================================================

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal() {
    _seedData();
  }

  final math.Random _rand = math.Random();
  final List<Article> _cloudDatabase = [];

  // Simulated Local Storage
  final Map<String, Article> _localCache = {};
  final Set<String> _bookmarkedIds = {};
  final Set<String> _offlineIds = {};

  bool isSimulatingOffline = false;

  // Public constructor removed; seeding moved to `_internal()`.

  void _seedData() {
    final s1 = Source(
      id: 'S1',
      name: 'Global Times',
      logoUrl: 'https://i.pravatar.cc/150?u=s1',
    );
    final s2 = Source(
      id: 'S2',
      name: 'Tech Insider',
      logoUrl: 'https://i.pravatar.cc/150?u=s2',
    );
    final s3 = Source(
      id: 'S3',
      name: 'Market Watch',
      logoUrl: 'https://i.pravatar.cc/150?u=s3',
    );
    final s4 = Source(
      id: 'S4',
      name: 'Science Daily',
      logoUrl: 'https://i.pravatar.cc/150?u=s4',
    );

    const lorem =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.\n\nNeque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.";
    final longLorem = List.generate(5, (_) => lorem).join('\n\n');

    final titles = [
      "Breakthrough in Quantum Computing Achieved",
      "Global Markets Rally Amid Tech Surge",
      "New AI Model Solves Complex Protein Folding",
      "Electric Vehicle Adoption Hits Record High",
      "Mars Rover Discovers Evidence of Ancient Water",
      "Central Bank Announces Surprise Rate Cut",
      "Major Cybersecurity Flaw Patched in Popular OS",
      "Climate Summit Concludes with Historic Agreement",
      "Next-Gen Smartphones to Feature Holographic Displays",
      "Startup Unveils Revolutionary Solid-State Battery",
      "Sports: Underdog Team Wins Championship",
      "Entertainment: Highly Anticipated Sequel Breaks Box Office Records",
    ];

    for (int i = 0; i < 40; i++) {
      final category =
          NewsCategory.values[_rand.nextInt(NewsCategory.values.length - 1) +
              1]; // Skip 'all'
      final source = [s1, s2, s3, s4][_rand.nextInt(4)];
      final date = DateTime.now().subtract(
        Duration(hours: _rand.nextInt(72), minutes: _rand.nextInt(60)),
      );

      _cloudDatabase.add(
        Article(
          id: 'ART_$i',
          title:
              titles[i % titles.length] +
              (i > titles.length ? ' (Update $i)' : ''),
          summary:
              'A brief summary of the breaking news regarding recent developments in the sector. Read more to find out how this impacts the global landscape.',
          content: 'INTRODUCTION\n\n$longLorem',
          imageUrl: 'https://picsum.photos/seed/$i/800/500',
          source: source,
          category: category,
          author: [
            'Jane Doe',
            'John Smith',
            'Alice Johnson',
            'Robert Lee',
          ][_rand.nextInt(4)],
          publishedAt: date,
        ),
      );
    }
    _cloudDatabase.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  Future<void> _latency([int ms = 600]) async =>
      await Future.delayed(Duration(milliseconds: ms + _rand.nextInt(400)));

  // --- API Methods ---

  /// Fetches articles from Cloud. Falls back to Local Cache if offline.
  Future<List<Article>> fetchFeed(NewsCategory category) async {
    await _latency(1000);

    if (isSimulatingOffline) {
      // Return cached feed
      final cached = _localCache.values.toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      if (category != NewsCategory.all)
        return cached.where((a) => a.category == category).toList();
      return cached;
    }

    // Cloud Fetch
    List<Article> result = List.from(_cloudDatabase);
    if (category != NewsCategory.all) {
      result = result.where((a) => a.category == category).toList();
    }

    // Apply local state overlays (bookmarks, sync status)
    result = result.map((a) {
      final isOffline = _offlineIds.contains(a.id);
      return a.copyWith(
        isBookmarked: _bookmarkedIds.contains(a.id),
        syncStatus: isOffline ? SyncStatus.downloaded : SyncStatus.none,
        downloadProgress: isOffline ? 1.0 : 0.0,
      );
    }).toList();

    // Cache the first page implicitly
    for (var a in result.take(15)) {
      _localCache[a.id] = a;
    }

    return result;
  }

  Future<void> toggleBookmark(String articleId) async {
    await _latency(200); // fast local op
    if (_bookmarkedIds.contains(articleId))
      _bookmarkedIds.remove(articleId);
    else
      _bookmarkedIds.add(articleId);
  }

  /// Simulates a byte-stream download queue for offline reading
  Stream<double> downloadArticle(String articleId) async* {
    if (isSimulatingOffline) throw NetworkException();

    final article = _cloudDatabase.firstWhere((a) => a.id == articleId);

    // Simulate chunked download
    int chunks = 10;
    for (int i = 1; i <= chunks; i++) {
      await Future.delayed(Duration(milliseconds: 200 + _rand.nextInt(100)));
      yield i / chunks;
    }

    // Save to deep local storage
    _offlineIds.add(article.id);
    _localCache[article.id] = article.copyWith(
      syncStatus: SyncStatus.downloaded,
      downloadProgress: 1.0,
    );
  }

  Future<List<Article>> getBookmarks() async {
    await _latency(300);
    return _cloudDatabase
        .where((a) => _bookmarkedIds.contains(a.id))
        .map(
          (a) => a.copyWith(
            isBookmarked: true,
            syncStatus: _offlineIds.contains(a.id)
                ? SyncStatus.downloaded
                : SyncStatus.none,
          ),
        )
        .toList();
  }

  Future<List<Article>> getDownloads() async {
    await _latency(300);
    return _localCache.values.where((a) => _offlineIds.contains(a.id)).toList();
  }

  Future<void> deleteDownload(String articleId) async {
    await _latency(200);
    _offlineIds.remove(articleId);
    if (!_bookmarkedIds.contains(articleId))
      _localCache.remove(articleId); // clean up if not bookmarked
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (InheritedNotifier)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockDatabase _api = MockDatabase();

  bool isGlobalLoading = true;
  bool isOfflineMode = false;
  String? globalError;

  NewsCategory currentCategory = NewsCategory.all;
  List<Article> feed = [];
  List<Article> bookmarks = [];
  List<Article> downloads = [];

  ReaderSettings readerSettings = ReaderSettings();

  // Manage active downloads to update UI progress
  final Map<String, StreamSubscription> _activeDownloads = {};

  AppState() {
    _boot();
  }

  Future<void> _boot() async {
    await refreshFeed();
    await _loadSecondaryData();
  }

  void _setError(String? e) {
    globalError = e;
    notifyListeners();
  }

  void toggleNetworkSimulation(bool isOffline) {
    isOfflineMode = isOffline;
    _api.isSimulatingOffline = isOffline;
    refreshFeed();
  }

  Future<void> refreshFeed() async {
    isGlobalLoading = true;
    _setError(null);
    notifyListeners();
    try {
      feed = await _api.fetchFeed(currentCategory);
      if (isOfflineMode) _setError("You are offline. Showing cached feed.");
    } on NetworkException catch (e) {
      _setError(e.message);
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSecondaryData() async {
    bookmarks = await _api.getBookmarks();
    downloads = await _api.getDownloads();
    notifyListeners();
  }

  void setCategory(NewsCategory cat) {
    currentCategory = cat;
    refreshFeed();
  }

  void toggleBookmark(String articleId) async {
    await _api.toggleBookmark(articleId);

    // Optimistic UI updates across all lists
    _updateArticleInLists(
      articleId,
      (a) => a.copyWith(isBookmarked: !a.isBookmarked),
    );
    await _loadSecondaryData();
  }

  void startDownload(String articleId) {
    if (isOfflineMode || _activeDownloads.containsKey(articleId)) return;

    _updateArticleInLists(
      articleId,
      (a) =>
          a.copyWith(syncStatus: SyncStatus.downloading, downloadProgress: 0.0),
    );

    _activeDownloads[articleId] = _api
        .downloadArticle(articleId)
        .listen(
          (progress) {
            _updateArticleInLists(
              articleId,
              (a) => a.copyWith(downloadProgress: progress),
            );
          },
          onDone: () {
            _activeDownloads.remove(articleId);
            _updateArticleInLists(
              articleId,
              (a) => a.copyWith(
                syncStatus: SyncStatus.downloaded,
                downloadProgress: 1.0,
              ),
            );
            _loadSecondaryData();
          },
          onError: (e) {
            _activeDownloads.remove(articleId);
            _updateArticleInLists(
              articleId,
              (a) => a.copyWith(syncStatus: SyncStatus.failed),
            );
          },
        );
  }

  void deleteDownload(String articleId) async {
    await _api.deleteDownload(articleId);
    _updateArticleInLists(
      articleId,
      (a) => a.copyWith(syncStatus: SyncStatus.none, downloadProgress: 0.0),
    );
    await _loadSecondaryData();
  }

  void _updateArticleInLists(String id, Article Function(Article) updater) {
    int fIdx = feed.indexWhere((a) => a.id == id);
    if (fIdx != -1) feed[fIdx] = updater(feed[fIdx]);

    int bIdx = bookmarks.indexWhere((a) => a.id == id);
    if (bIdx != -1) bookmarks[bIdx] = updater(bookmarks[bIdx]);

    notifyListeners();
  }

  // --- Reader Settings ---
  void updateReaderSettings(ReaderSettings newSettings) {
    readerSettings = newSettings;
    notifyListeners();
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
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NewsAggregatorApp());
}

class NewsAggregatorApp extends StatelessWidget {
  const NewsAggregatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus News',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textMain,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const MainScaffold(),
      ),
    );
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
    const BookmarksScreen(),
    const OfflineDownloadsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (state.globalError != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.textMain,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.globalError!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => state._setError(null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public, color: AppColors.primary),
            label: 'For You',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark, color: AppColors.primary),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_for_offline_outlined),
            selectedIcon: Icon(
              Icons.download_for_offline,
              color: AppColors.primary,
            ),
            label: 'Offline',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. FEED SCREEN & SHIMMER EFFECT
// ============================================================================

class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return RefreshIndicator(
      onRefresh: state.refreshFeed,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Parallax Header
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: const Text(
                'NexusBrief',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                  letterSpacing: -1,
                ),
              ),
              background: Container(
                color: AppColors.surfaceHighlight.withOpacity(0.3),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // Sticky Topic Filter
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTopicDelegate(
              child: Container(
                color: AppColors.surface.withOpacity(0.95),
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: NewsCategory.values.length,
                  itemBuilder: (ctx, i) {
                    final cat = NewsCategory.values[i];
                    final isSelected = state.currentCategory == cat;
                    return GestureDetector(
                      onTap: () => state.setCategory(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.textMain
                              : AppColors.surfaceHighlight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Feed Content
          if (state.isGlobalLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) => const _SkeletonArticleCard(),
                childCount: 5,
              ),
            )
          else if (state.feed.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No articles found.', style: AppStyles.caption),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final article = state.feed[index];
                // Make the first article a prominent "Hero" card
                return index == 0
                    ? _HeroArticleCard(article: article)
                    : _StandardArticleCard(article: article);
              }, childCount: state.feed.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StickyTopicDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTopicDelegate({required this.child});
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// --- ARTICLE CARDS ---

class _HeroArticleCard extends StatelessWidget {
  final Article article;
  const _HeroArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleReaderScreen(article: article),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'img_${article.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  article.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 250,
                    color: AppColors.surfaceHighlight,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        article.category.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      _SyncIndicator(article: article),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(article.title, style: AppStyles.headline),
                  const SizedBox(height: 12),
                  Text(
                    article.summary,
                    style: AppStyles.body.copyWith(color: AppColors.textMuted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(article.source.logoUrl),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${article.source.name} • ${TimeFormatter.timeAgo(article.publishedAt)}',
                          style: AppStyles.caption,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          article.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: article.isBookmarked
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        onPressed: () => state.toggleBookmark(article.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
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

class _StandardArticleCard extends StatelessWidget {
  final Article article;
  const _StandardArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleReaderScreen(article: article),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        article.source.name,
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SyncIndicator(article: article),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: AppStyles.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        TimeFormatter.timeAgo(article.publishedAt),
                        style: AppStyles.caption,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          article.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 20,
                          color: article.isBookmarked
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        onPressed: () => state.toggleBookmark(article.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Hero(
              tag: 'img_${article.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 100,
                    height: 100,
                    color: AppColors.surfaceHighlight,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textMuted,
                    ),
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

class _SyncIndicator extends StatelessWidget {
  final Article article;
  const _SyncIndicator({required this.article});
  @override
  Widget build(BuildContext context) {
    if (article.syncStatus == SyncStatus.none) return const SizedBox.shrink();
    if (article.syncStatus == SyncStatus.downloading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          value: article.downloadProgress,
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }
    if (article.syncStatus == SyncStatus.failed)
      return const Icon(Icons.error, size: 14, color: AppColors.error);
    return const Icon(
      Icons.offline_pin,
      size: 14,
      color: AppColors.success,
    ); // Downloaded
  }
}

// --- SHIMMER LOADER ---
class _SkeletonArticleCard extends StatefulWidget {
  const _SkeletonArticleCard();
  @override
  State<_SkeletonArticleCard> createState() => _SkeletonArticleCardState();
}

class _SkeletonArticleCardState extends State<_SkeletonArticleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _ShimmerPainter(progress: _ctrl.value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 12, color: Colors.white),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(width: 200, height: 16, color: Colors.white),
                    const SizedBox(height: 16),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * (progress - 0.5), 0),
        Offset(size.width * (progress + 0.5), 0),
        [
          AppColors.surfaceHighlight.withOpacity(0.3),
          AppColors.surfaceHighlight.withOpacity(0.7),
          AppColors.surfaceHighlight.withOpacity(0.3),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

// ============================================================================
// 8. ARTICLE READER (Immersive & Typography Engine)
// ============================================================================

class ArticleReaderScreen extends StatefulWidget {
  final Article article;
  const ArticleReaderScreen({Key? key, required this.article})
    : super(key: key);
  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.hasClients) {
        final maxScroll = _scrollCtrl.position.maxScrollExtent;
        final current = _scrollCtrl.offset;
        setState(() => _readProgress = (current / maxScroll).clamp(0.0, 1.0));
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showAppearanceSettings(AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          final s = state.readerSettings;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appearance', style: AppStyles.h2),
                const SizedBox(height: 24),
                const Text('Text Size', style: AppStyles.h3),
                Slider(
                  value: s.fontSize,
                  min: 14,
                  max: 28,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    state.updateReaderSettings(s.copyWith(fontSize: v));
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 16),
                const Text('Theme', style: AppStyles.h3),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ThemeBtn(
                      name: 'Light',
                      theme: ReadingTheme.light,
                      current: s.theme,
                      bg: Colors.white,
                      fg: Colors.black,
                      onTap: () {
                        state.updateReaderSettings(
                          s.copyWith(theme: ReadingTheme.light),
                        );
                        setModalState(() {});
                      },
                    ),
                    _ThemeBtn(
                      name: 'Sepia',
                      theme: ReadingTheme.sepia,
                      current: s.theme,
                      bg: AppColors.sepiaBg,
                      fg: AppColors.sepiaText,
                      onTap: () {
                        state.updateReaderSettings(
                          s.copyWith(theme: ReadingTheme.sepia),
                        );
                        setModalState(() {});
                      },
                    ),
                    _ThemeBtn(
                      name: 'Dark',
                      theme: ReadingTheme.dark,
                      current: s.theme,
                      bg: AppColors.darkBg,
                      fg: AppColors.darkText,
                      onTap: () {
                        state.updateReaderSettings(
                          s.copyWith(theme: ReadingTheme.dark),
                        );
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Serif Font', style: AppStyles.h3),
                  value: s.isSerif,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    state.updateReaderSettings(s.copyWith(isSerif: v));
                    setModalState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final liveArticle = state.feed.firstWhere(
      (a) => a.id == widget.article.id,
      orElse: () => state.bookmarks.firstWhere(
        (a) => a.id == widget.article.id,
        orElse: () => widget.article,
      ),
    );
    final rs = state.readerSettings;

    Color bgColor, textColor, mutedColor;
    if (rs.theme == ReadingTheme.dark) {
      bgColor = AppColors.darkBg;
      textColor = AppColors.darkText;
      mutedColor = Colors.white54;
    } else if (rs.theme == ReadingTheme.sepia) {
      bgColor = AppColors.sepiaBg;
      textColor = AppColors.sepiaText;
      mutedColor = AppColors.sepiaText.withOpacity(0.6);
    } else {
      bgColor = Colors.white;
      textColor = Colors.black87;
      mutedColor = Colors.black54;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: bgColor,
                iconTheme: IconThemeData(color: textColor),
                actions: [
                  IconButton(
                    icon: Icon(Icons.text_format, color: textColor),
                    onPressed: () => _showAppearanceSettings(state),
                  ),
                  IconButton(
                    icon: Icon(
                      liveArticle.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: liveArticle.isBookmarked
                          ? AppColors.primary
                          : textColor,
                    ),
                    onPressed: () => state.toggleBookmark(liveArticle.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'img_${liveArticle.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          liveArticle.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              Container(color: AppColors.surfaceHighlight),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [bgColor, Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveArticle.category.name.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        liveArticle.title,
                        style: TextStyle(
                          fontSize: rs.fontSize * 1.5,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          height: 1.2,
                          fontFamily: rs.isSerif ? 'Times New Roman' : 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              liveArticle.source.logoUrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                liveArticle.author,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${TimeFormatter.timeAgo(liveArticle.publishedAt)} • ${TimeFormatter.readTime(liveArticle.content)}',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Divider(),
                      ),

                      // Article Content
                      Text(
                        liveArticle.content,
                        style: TextStyle(
                          fontSize: rs.fontSize,
                          height: rs.lineHeight,
                          color: textColor,
                          fontFamily: rs.isSerif ? 'Times New Roman' : 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Custom Reading Progress Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height:
                  MediaQuery.of(context).padding.top +
                  AppBar().preferredSize.height,
              child: CustomPaint(
                painter: _ReadingProgressPainter(progress: _readProgress),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: liveArticle.syncStatus == SyncStatus.none
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.textMain,
              foregroundColor: AppColors.surface,
              icon: const Icon(Icons.download),
              label: const Text(
                'SAVE OFFLINE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                state.startDownload(liveArticle.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading for offline reading...'),
                  ),
                );
              },
            )
          : null,
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final String name;
  final ReadingTheme theme;
  final ReadingTheme current;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _ThemeBtn({
    required this.name,
    required this.theme,
    required this.current,
    required this.bg,
    required this.fg,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    bool isSel = theme == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(color: fg, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ReadingProgressPainter extends CustomPainter {
  final double progress;
  _ReadingProgressPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width * progress, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReadingProgressPainter old) =>
      old.progress != progress;
}

// ============================================================================
// 9. BOOKMARKS SCREEN
// ============================================================================

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Articles')),
      body: state.bookmarks.isEmpty
          ? const Center(
              child: Text('No bookmarked articles.', style: AppStyles.body),
            )
          : ListView.builder(
              itemCount: state.bookmarks.length,
              itemBuilder: (ctx, i) =>
                  _StandardArticleCard(article: state.bookmarks[i]),
            ),
    );
  }
}

// ============================================================================
// 10. OFFLINE DOWNLOADS SCREEN & QUEUE
// ============================================================================

class OfflineDownloadsScreen extends StatelessWidget {
  const OfflineDownloadsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Reading')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceHighlight.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: AppColors.textMuted),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Simulate Offline Mode', style: AppStyles.h3),
                ),
                Switch(
                  value: state.isOfflineMode,
                  activeColor: AppColors.primary,
                  onChanged: (v) => state.toggleNetworkSimulation(v),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.downloads.isEmpty
                ? const Center(
                    child: Text(
                      'No articles saved for offline reading.',
                      style: AppStyles.body,
                    ),
                  )
                : ListView.builder(
                    itemCount: state.downloads.length,
                    itemBuilder: (ctx, i) {
                      final article = state.downloads[i];
                      return Dismissible(
                        key: Key(article.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => state.deleteDownload(article.id),
                        child: _StandardArticleCard(article: article),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 11. SETTINGS PLACEHOLDER
// ============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Account & Preferences', style: AppStyles.h2),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Push Notifications'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          ListTile(
            leading: Icon(Icons.data_usage),
            title: Text('Data & Storage'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
