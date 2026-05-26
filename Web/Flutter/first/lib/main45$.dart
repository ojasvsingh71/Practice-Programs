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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LexiApp());
}

// ============================================================================
// DATA MODELS
// ============================================================================

enum PartOfSpeech {
  noun,
  verb,
  adjective,
  adverb,
  pronoun,
  conjunction,
  interjection,
}

class DefinitionItem {
  final PartOfSpeech partOfSpeech;
  final String definition;
  final String example;
  final List<String> synonyms;
  final List<String> antonyms;

  const DefinitionItem({
    required this.partOfSpeech,
    required this.definition,
    required this.example,
    this.synonyms = const [],
    this.antonyms = const [],
  });

  String get partOfSpeechString =>
      partOfSpeech.toString().split('.').last.toUpperCase();
}

class DictionaryResult {
  final String word;
  final String phonetic;
  final List<DefinitionItem> meanings;
  final bool isFromCacheFallback;

  const DictionaryResult({
    required this.word,
    required this.phonetic,
    required this.meanings,
    this.isFromCacheFallback = false,
  });
}

class TranslationPair {
  final String sourceText;
  final String translatedText;
  final String sourceLangCode;
  final String targetLangCode;
  final DateTime timestamp;

  const TranslationPair({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLangCode,
    required this.targetLangCode,
    required this.timestamp,
  });
}

class Language {
  final String name;
  final String code;
  final String flag;

  const Language({required this.name, required this.code, required this.flag});
}

// ============================================================================
// NETWORK & FALLBACK STORAGE LOGIC (MOCK CENTRAL ENGINE)
// ============================================================================

class LexiEngine {
  // Simulates cloud dictionary service database
  static const Map<String, DictionaryResult> _cloudDictionaryDatabase = {
    "serendipity": DictionaryResult(
      word: "Serendipity",
      phonetic: "/ˌserənˈdipədē/",
      meanings: [
        DefinitionItem(
          partOfSpeech: PartOfSpeech.noun,
          definition:
              "The occurrence and development of events by chance in a happy or beneficial way.",
          example:
              "We found the charming little restaurant by pure serendipity.",
          synonyms: ["chance", "fluke", "luck", "coincidence"],
          antonyms: ["misfortune", "design", "calculation"],
        ),
      ],
    ),
    "ephemeral": DictionaryResult(
      word: "Ephemeral",
      phonetic: "/əˈfemərəl/",
      meanings: [
        DefinitionItem(
          partOfSpeech: PartOfSpeech.adjective,
          definition: "Lasting for a very short time.",
          example: "Fashions are ephemeral, but true style is timeless.",
          synonyms: ["transitory", "transient", "fleeting", "short-lived"],
          antonyms: ["permanent", "eternal", "enduring"],
        ),
      ],
    ),
    "eloquent": DictionaryResult(
      word: "Eloquent",
      phonetic: "/ˈeləkwənt/",
      meanings: [
        DefinitionItem(
          partOfSpeech: PartOfSpeech.adjective,
          definition: "Fluent or persuasive in speaking or writing.",
          example: "The president made an eloquent appeal for peace.",
          synonyms: ["articulate", "persuasive", "expressive"],
          antonyms: ["inarticulate", "weak", "unpersuasive"],
        ),
      ],
    ),
  };

  // Simulates on-device embedded SQLite/Room cache backup for API Failures
  static const Map<String, DictionaryResult> _localOfflineCacheDatabase = {
    "serendipity": DictionaryResult(
      word: "Serendipity (Offline Cache)",
      phonetic: "/ˌserənˈdipədē/",
      isFromCacheFallback: true,
      meanings: [
        DefinitionItem(
          partOfSpeech: PartOfSpeech.noun,
          definition:
              "[LOCAL CACHE] Finding valuable or agreeable things not sought for.",
          example: "A fortunate stroke of serendipity brought them together.",
        ),
      ],
    ),
    "ephemeral": DictionaryResult(
      word: "Ephemeral (Offline Cache)",
      phonetic: "/əˈfemərəl/",
      isFromCacheFallback: true,
      meanings: [
        DefinitionItem(
          partOfSpeech: PartOfSpeech.adjective,
          definition: "[LOCAL CACHE] Fleeting or short-lived baseline record.",
          example: "The ephemeral joys of childhood summer days.",
        ),
      ],
    ),
  };

  // Asynchronous query engine simulating API lookup with built-in fallback triggers
  static Future<DictionaryResult> lookupWord({
    required String word,
    required bool forceCloudFailure,
  }) async {
    final cleanWord = word.trim().toLowerCase();

    // Simulate API Network Request Latency
    await Future.delayed(const Duration(milliseconds: 1200));

    if (forceCloudFailure) {
      // Simulate API Crash, Gateway Outages, or DNS Resolution failure -> Trigger Failover
      if (_localOfflineCacheDatabase.containsKey(cleanWord)) {
        return _localOfflineCacheDatabase[cleanWord]!;
      } else {
        throw Exception(
          "Cloud API is down and word does not exist in local SQLite fallback cache.",
        );
      }
    }

    // Cloud Success Route
    if (_cloudDictionaryDatabase.containsKey(cleanWord)) {
      return _cloudDictionaryDatabase[cleanWord]!;
    } else {
      // Generic mock fallback return if text entry wasn't predefined
      return DictionaryResult(
        word: word,
        phonetic: "/ʊnˈnoʊn/",
        meanings: [
          DefinitionItem(
            partOfSpeech: PartOfSpeech.noun,
            definition:
                "Dynamic definition processed successfully via fallback algorithmic parsing engine.",
            example: "The user searched for '$word' successfully.",
          ),
        ],
      );
    }
  }

  // Asynchronous cloud machine translation system engine mock
  static Future<String> cloudTranslate({
    required String text,
    required String fromCode,
    required String toCode,
    required bool forceCloudFailure,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (forceCloudFailure) {
      // Return local algorithmic offline fallback translator matrix string
      return "[Offline Engine Fallback Output]: Local matrices translated direct string input tokens: '$text' to destination language '$toCode'.";
    }

    if (text.isEmpty) return "";
    return "$text (Translated accurately from $fromCode into $toCode via Neural API Cloud Engine)";
  }
}

// ============================================================================
// CENTRAL APPLICATION ARCHITECTURE STATE (CHANGENOTIFIER)
// ============================================================================

class AppState extends ChangeNotifier {
  // Engine Control Switches
  bool _forceCloudFailures = false;
  bool get forceCloudFailures => _forceCloudFailures;

  set forceCloudFailures(bool value) {
    _forceCloudFailures = value;
    notifyListeners();
  }

  // Application Data Stores
  final List<String> _searchHistory = ["serendipity", "ephemeral"];
  final Set<String> _favorites = {"serendipity"};
  final List<TranslationPair> _translationHistory = [];

  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  Set<String> get favorites => _favorites;
  List<TranslationPair> get translationHistory =>
      List.unmodifiable(_translationHistory);

  // Active Context States
  DictionaryResult? _activeQueryResult;
  bool _isDictionaryLoading = false;
  String _dictionaryErrorMessage = "";

  DictionaryResult? get activeQueryResult => _activeQueryResult;
  bool get isDictionaryLoading => _isDictionaryLoading;
  String get dictionaryErrorMessage => _dictionaryErrorMessage;

  // Active Translation State Variables
  bool _isTranslationLoading = false;
  String _lastTranslationResult = "";

  bool get isTranslationLoading => _isTranslationLoading;
  String get lastTranslationResult => _lastTranslationResult;

  // Configuration Constants
  final List<Language> languages = const [
    Language(name: "English", code: "EN", flag: "🇺🇸"),
    Language(name: "Spanish", code: "ES", flag: "🇪🇸"),
    Language(name: "French", code: "FR", flag: "🇫🇷"),
    Language(name: "German", code: "DE", flag: "🇩🇪"),
    Language(name: "Japanese", code: "JA", flag: "🇯🇵"),
  ];

  late Language sourceLanguage;
  late Language targetLanguage;

  AppState() {
    sourceLanguage = languages[0]; // EN
    targetLanguage = languages[1]; // ES
  }

  // --- Operational Methods ---

  void toggleFavorite(String word) {
    final clean = word.trim().toLowerCase();
    if (_favorites.contains(clean)) {
      _favorites.remove(clean);
    } else {
      _favorites.add(clean);
    }
    notifyListeners();
  }

  void clearHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  void swapLanguages() {
    final temp = sourceLanguage;
    sourceLanguage = targetLanguage;
    targetLanguage = temp;
    notifyListeners();
  }

  void setSourceLanguage(Language lang) {
    sourceLanguage = lang;
    notifyListeners();
  }

  void setTargetLanguage(Language lang) {
    targetLanguage = lang;
    notifyListeners();
  }

  // Action pipeline to search definitions with systemic handling of fallbacks
  Future<void> executeDictionaryLookup(
    String targetWord,
    BuildContext context,
  ) async {
    if (targetWord.trim().isEmpty) return;

    _isDictionaryLoading = true;
    _dictionaryErrorMessage = "";
    _activeQueryResult = null;
    notifyListeners();

    final cleanWord = targetWord.trim().toLowerCase();

    // Add to history list uniqueness check
    if (_searchHistory.contains(cleanWord)) {
      _searchHistory.remove(cleanWord);
    }
    _searchHistory.insert(0, cleanWord);

    try {
      _activeQueryResult = await LexiEngine.lookupWord(
        word: cleanWord,
        forceCloudFailure: _forceCloudFailures,
      );

      if (_activeQueryResult!.isFromCacheFallback && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  "API Timeout/Failure. Loaded local fallback dictionary cache data.",
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      _dictionaryErrorMessage = e.toString().replaceAll("Exception:", "");
    } finally {
      _isDictionaryLoading = false;
      notifyListeners();
    }
  }

  // Action pipeline to perform translations
  Future<void> executeTranslationPipeline(String input) async {
    if (input.trim().isEmpty) {
      _lastTranslationResult = "";
      notifyListeners();
      return;
    }

    _isTranslationLoading = true;
    notifyListeners();

    try {
      _lastTranslationResult = await LexiEngine.cloudTranslate(
        text: input,
        fromCode: sourceLanguage.code,
        toCode: targetLanguage.code,
        forceCloudFailure: _forceCloudFailures,
      );

      _translationHistory.insert(
        0,
        TranslationPair(
          sourceText: input,
          translatedText: _lastTranslationResult,
          sourceLangCode: sourceLanguage.code,
          targetLangCode: targetLanguage.code,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _lastTranslationResult =
          "System Error Processing Pipeline: ${e.toString()}";
    } finally {
      _isTranslationLoading = false;
      notifyListeners();
    }
  }
}

final AppState globalState = AppState();

// ============================================================================
// APP ENTRY VIEWPORT CONFIGURATOR
// ============================================================================

class LexiApp extends StatelessWidget {
  const LexiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: globalState,
      builder: (context, child) {
        return MaterialApp(
          title: 'LexiCloud Dictionary & Translator',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF2A66FF),
            scaffoldBackgroundColor: const Color(0xFFF7F9FC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2A66FF),
              primary: const Color(0xFF2A66FF),
              secondary: const Color(0xFF101828),
              surface: Colors.white,
              background: const Color(0xFFF7F9FC),
              error: const Color(0xFFD92D20),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF101828),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Color(0xFF475467),
                height: 1.5,
              ),
              bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF475467)),
            ),
          ),
          home: const SystemDashboardWrapper(),
        );
      },
    );
  }
}

// ============================================================================
// SYSTEM DASHBOARD WRAPPER (NAV BAR BRIDGE)
// ============================================================================

class SystemDashboardWrapper extends StatefulWidget {
  const SystemDashboardWrapper({Key? key}) : super(key: key);

  @override
  State<SystemDashboardWrapper> createState() => _SystemDashboardWrapperState();
}

class _SystemDashboardWrapperState extends State<SystemDashboardWrapper> {
  int _activeNavIndex = 0;

  final List<Widget> _navigationViewports = [
    const DictionaryDashboardViewport(),
    const MachineTranslatorViewport(),
    const LibraryFavoritesViewport(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _activeNavIndex,
        children: _navigationViewports,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _activeNavIndex,
          onTap: (targetIndex) {
            setState(() {
              _activeNavIndex = targetIndex;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          iconSize: 24,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.import_contacts_rounded),
              activeIcon: Icon(Icons.import_contacts_rounded),
              label: "Dictionary",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.g_translate_rounded),
              activeIcon: Icon(Icons.g_translate_rounded),
              label: "Translator",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmarks_rounded),
              activeIcon: Icon(Icons.bookmarks_rounded),
              label: "Saved Words",
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VIEWPORT 1: DICTIONARY DASHBOARD
// ============================================================================

class DictionaryDashboardViewport extends StatefulWidget {
  const DictionaryDashboardViewport({Key? key}) : super(key: key);

  @override
  State<DictionaryDashboardViewport> createState() =>
      _DictionaryDashboardViewportState();
}

class _DictionaryDashboardViewportState
    extends State<DictionaryDashboardViewport> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch(String word) {
    if (word.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    globalState.executeDictionaryLookup(word, context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "LexiCloud Dictionary",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Row(
            children: [
              const Text(
                "Simulate Offline Mode",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: globalState.forceCloudFailures,
                activeColor: Colors.orange,
                onChanged: (val) {
                  globalState.forceCloudFailures = val;
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Search Input Platform
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _triggerSearch,
                  decoration: InputDecoration(
                    hintText: "Enter an English word (e.g., Serendipity)...",
                    prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF2F4F7),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (t) => setState(() {}),
                ),
              ),

              // Results Content or Dynamic History/Trends Canvas
              Expanded(
                child: AnimatedBuilder(
                  animation: globalState,
                  builder: (context, child) {
                    if (globalState.isDictionaryLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              "Quering cloud dictionary framework layers...",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    if (globalState.dictionaryErrorMessage.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                globalState.dictionaryErrorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (globalState.activeQueryResult != null) {
                      return _buildDefinitionContentLayout(
                        globalState.activeQueryResult!,
                        theme,
                      );
                    }

                    // Default Dashboard Layer: Search History and Analytics Trends
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (globalState.searchHistory.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Recent Search Queries",
                                  style: theme.textTheme.titleMedium,
                                ),
                                TextButton(
                                  onPressed: () => globalState.clearHistory(),
                                  child: const Text(
                                    "Clear All",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: globalState.searchHistory.map((word) {
                                return ActionChip(
                                  label: Text(word),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade200),
                                  onPressed: () {
                                    _searchController.text = word;
                                    _triggerSearch(word);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),
                          ],

                          Text(
                            "App Analytics Metrics: Search Frequency Trends",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 180,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: LexiTrendChartPainter(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefinitionContentLayout(DictionaryResult data, ThemeData theme) {
    final cleanWord = data.word.trim().toLowerCase();
    final isFav = globalState.favorites.contains(cleanWord);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Word Identification Block
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.word, style: theme.textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        data.phonetic,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          // Play simulated text-to-speech audio loop
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              ),
              color: isFav ? Colors.amber : Colors.grey,
              iconSize: 32,
              onPressed: () {
                setState(() {
                  globalState.toggleFavorite(data.word);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 16),

        // Meanings Mapping Engine Loop
        ...data.meanings.map((meaning) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Part of Speech Identifier Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    meaning.partOfSpeechString,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Semantics Context Core Text
                Text(meaning.definition, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),

                // Example String Contextual Representation
                if (meaning.example.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey.shade300,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        "\"${meaning.example}\"",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                // Synonyms Token Mappers
                if (meaning.synonyms.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Synonyms",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: meaning.synonyms
                        .map((syn) => _buildLexicalTokenChip(syn, Colors.teal))
                        .toList(),
                  ),
                ],

                // Antonyms Token Mappers
                if (meaning.antonyms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Antonyms",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: meaning.antonyms
                        .map(
                          (ant) =>
                              _buildLexicalTokenChip(ant, Colors.redAccent),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLexicalTokenChip(String term, Color colorAccent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorAccent.withOpacity(0.2)),
      ),
      child: Text(
        term,
        style: TextStyle(
          color: colorAccent,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Custom Graphing Tool to display search frequency parameters natively
class LexiTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    final linePaint = Paint()
      ..color = const Color(0xFF2A66FF)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // Draw coordinate grids background
    double horizontalStep = size.height / 4;
    for (int i = 0; i <= 4; i++) {
      double y = i * horizontalStep;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Data points configuration matrix mapping logic representation
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.65),
      Offset(size.width * 0.6, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.45),
      Offset(size.width, size.height * 0.1),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var point in points) {
      path.lineTo(point.dx, point.dy);
    }

    // Create complex vertical translucent drop shadow bounds gradient
    final gradientPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fillPaint.shader = LinearGradient(
      colors: [const Color(0xFF2A66FF).withOpacity(0.2), Colors.transparent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(gradientPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw interactive node circles endpoints
    final jointPaint = Paint()
      ..color = const Color(0xFF101828)
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 4.0, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// VIEWPORT 2: MACHINE TRANSLATOR VIEWPORT
// ============================================================================

class MachineTranslatorViewport extends StatefulWidget {
  const MachineTranslatorViewport({Key? key}) : super(key: key);

  @override
  State<MachineTranslatorViewport> createState() =>
      _MachineTranslatorViewportState();
}

class _MachineTranslatorViewportState extends State<MachineTranslatorViewport>
    with SingleTickerProviderStateMixin {
  final TextEditingController _translationInputController =
      TextEditingController();
  late AnimationController _swapAnimationController;

  @override
  void initState() {
    super.initState();
    _swapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _translationInputController.dispose();
    _swapAnimationController.dispose();
    super.dispose();
  }

  void _triggerTranslationFlow() {
    FocusScope.of(context).unfocus();
    globalState.executeTranslationPipeline(_translationInputController.text);
  }

  void _executeLanguageSwapSequence() {
    globalState.swapLanguages();
    if (_swapAnimationController.isCompleted) {
      _swapAnimationController.reverse();
    } else {
      _swapAnimationController.forward();
    }
    if (_translationInputController.text.isNotEmpty) {
      globalState.executeTranslationPipeline(_translationInputController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Neural Translator Engine",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Selector Matrix Controls Bridge Block View representation
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildLanguageDropdownSelector(isSource: true),
                    ),
                    RotationTransition(
                      turns: Tween<double>(
                        begin: 0.0,
                        end: 0.5,
                      ).animate(_swapAnimationController),
                      child: IconButton(
                        icon: Icon(
                          Icons.swap_horizontal_circle_rounded,
                          color: theme.primaryColor,
                          size: 28,
                        ),
                        onPressed: _executeLanguageSwapSequence,
                      ),
                    ),
                    Expanded(
                      child: _buildLanguageDropdownSelector(isSource: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Raw Input String Block Area Panel View representation
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _translationInputController,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          hintText: "Enter text content to translate here...",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                        onChanged: (text) {
                          if (text.isEmpty) setState(() {});
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              _translationInputController.clear();
                              globalState.executeTranslationPipeline("");
                              setState(() {});
                            },
                          ),
                          ElevatedButton(
                            onPressed:
                                _translationInputController.text.isNotEmpty
                                ? _triggerTranslationFlow
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text("Translate"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Translation Output Target Process Monitor View representation Frame
              AnimatedBuilder(
                animation: globalState,
                builder: (context, child) {
                  if (globalState.isTranslationLoading) {
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (globalState.lastTranslationResult.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101828),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TRANSLATION (${globalState.targetLanguage.code})",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: globalState.lastTranslationResult,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Translation copied to clipboards buffer.",
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            globalState.lastTranslationResult,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 32),
              Text(
                "Translation Log History",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Translation History Mapping Layout Node representation
              AnimatedBuilder(
                animation: globalState,
                builder: (context, child) {
                  if (globalState.translationHistory.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          "No translations in execution logs registry records.",
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: globalState.translationHistory.length,
                    itemBuilder: (context, idx) {
                      final log = globalState.translationHistory[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  log.sourceLangCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_right_alt_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                Text(
                                  log.targetLangCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.sourceText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              log.translatedText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdownSelector({required bool isSource}) {
    final currentSelected = isSource
        ? globalState.sourceLanguage
        : globalState.targetLanguage;

    return DropdownButtonHideUnderline(
      child: DropdownButton<Language>(
        value: currentSelected,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        onChanged: (Language? selected) {
          if (selected != null) {
            if (isSource) {
              globalState.setSourceLanguage(selected);
            } else {
              globalState.setTargetLanguage(selected);
            }
          }
        },
        items: globalState.languages.map((Language targetLang) {
          return DropdownMenuItem<Language>(
            value: targetLang,
            child: Row(
              children: [
                Text(targetLang.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  targetLang.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// VIEWPORT 3: LIBRARY FAVORITES VIEWPORT
// ============================================================================

class LibraryFavoritesViewport extends StatelessWidget {
  const LibraryFavoritesViewport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Saved Bookmarks Library",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: globalState,
          builder: (context, child) {
            if (globalState.favorites.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_outline_rounded,
                        size: 72,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No Saved Bookmarks Detected",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF344054),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Words bookmarked during dictionary queries populate this tracking directory module.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final favList = globalState.favorites.toList();

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: favList.length,
              itemBuilder: (context, index) {
                final wordToken = favList[index];

                // Capitalize first character token gracefully
                final stylizedWord = wordToken.isNotEmpty
                    ? '${wordToken[0].toUpperCase()}${wordToken.substring(1)}'
                    : wordToken;

                return Dismissible(
                  key: Key(wordToken),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    globalState.toggleFavorite(wordToken);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Purged '$stylizedWord' from bookmarks buffer storage library.",
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      title: Text(
                        stylizedWord,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        // Redirect systemic query targeting back into processing view thread
                        globalState.executeDictionaryLookup(wordToken, context);

                        // Access fallback controller navigator wrapper tree logic safely
                        final dashboardState = context
                            .findAncestorStateOfType<
                              _SystemDashboardWrapperState
                            >();
                        if (dashboardState != null) {
                          dashboardState.setState(() {
                            dashboardState._activeNavIndex =
                                0; // Flash index back safely
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
