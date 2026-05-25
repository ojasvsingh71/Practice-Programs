import 'dart:async';
import 'dart:math' as math;
// removed unused import 'dart:ui'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum TrackType { mobile, web, cloud, ai, design, leadership }

enum SessionType { keynote, workshop, panel, networking }

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700

  static const Color primary = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700
  static const Color accent = Color(0xFFF59E0B); // Amber 500

  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF10B981); // Emerald 500

  static Color getTrackColor(TrackType type) {
    switch (type) {
      case TrackType.mobile:
        return const Color(0xFF3B82F6);
      case TrackType.web:
        return const Color(0xFFF59E0B);
      case TrackType.cloud:
        return const Color(0xFF10B981);
      case TrackType.ai:
        return const Color(0xFF8B5CF6);
      case TrackType.design:
        return const Color(0xFFEC4899);
      case TrackType.leadership:
        return const Color(0xFF64748B);
    }
  }
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
// 2. EXCEPTIONS & UTILITIES
// ============================================================================

abstract class ConferenceException implements Exception {
  final String message;
  ConferenceException(this.message);
  @override
  String toString() => message;
}

class ScheduleConflictException extends ConferenceException {
  ScheduleConflictException([
    String m = "This session overlaps with another event in your agenda.",
  ]) : super(m);
}

class CapacityException extends ConferenceException {
  CapacityException([String m = "This session is currently full."]) : super(m);
}

class NetworkException extends ConferenceException {
  NetworkException([String m = "Network timeout."]) : super(m);
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
  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String formatDate(DateTime d) =>
      '${_weekDays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  static String formatShortDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';
  static String formatTime(DateTime d) {
    int h = d.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h == 0)
      h = 12;
    else if (h > 12)
      h -= 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} $p';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// Local shim for compatibility with other mains (kept local to this file)
class Formatters {
  static String formatTime(DateTime d) => DateUtilsFormatter.formatTime(d);
  static String formatDate(DateTime d) => DateUtilsFormatter.formatDate(d);
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
}

class Speaker {
  final String id;
  final String name;
  final String title;
  final String company;
  final String bio;
  final String avatarUrl;

  Speaker({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.bio,
    required this.avatarUrl,
  });
}

class Venue {
  final String id;
  final String name;
  final int capacity;

  Venue({required this.id, required this.name, required this.capacity});
}

class Session {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final TrackType track;
  final SessionType type;
  final String venueId;
  final List<String> speakerIds;
  int currentAttendees;

  Session({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.track,
    required this.type,
    required this.venueId,
    required this.speakerIds,
    this.currentAttendees = 0,
  });

  Duration get duration => endTime.difference(startTime);
}

class UserAgenda {
  final String userId;
  final List<String> bookmarkedSessionIds;

  UserAgenda({required this.userId, required this.bookmarkedSessionIds});
}

// ============================================================================
// 4. MOCK BACKEND ENGINE & CONFLICT RESOLUTION
// ============================================================================

class MockConferenceEngine {
  static final MockConferenceEngine _instance =
      MockConferenceEngine._internal();
  factory MockConferenceEngine() => _instance;
  MockConferenceEngine._internal() {
    _seedData();
  }

  final math.Random _random = math.Random();

  final Map<String, Speaker> _speakers = {};
  final Map<String, Venue> _venues = {};
  final Map<String, Session> _sessions = {};
  final Map<String, UserAgenda> _agendas = {};

  final DateTime conferenceStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 10,
    9,
    0,
  );

  // Public unnamed constructor removed; seeding occurs in `_internal()`.

  void _seedData() {
    // Seed Venues
    final v1 = Venue(id: 'V1', name: 'Main Hall', capacity: 1000);
    final v2 = Venue(id: 'V2', name: 'Room Alpha', capacity: 200);
    final v3 = Venue(id: 'V3', name: 'Room Beta', capacity: 150);
    _venues.addAll({v1.id: v1, v2.id: v2, v3.id: v3});

    // Seed Speakers
    final s1 = Speaker(
      id: 'S1',
      name: 'Dr. Evelyn Carter',
      title: 'VP of Engineering',
      company: 'NexusTech',
      bio: 'Evelyn leads cloud infrastructure at NexusTech.',
      avatarUrl: 'https://i.pravatar.cc/150?u=s1',
    );
    final s2 = Speaker(
      id: 'S2',
      name: 'Marcus Chen',
      title: 'Senior Mobile Dev',
      company: 'AppWorks',
      bio: 'Marcus is an expert in declarative UI frameworks.',
      avatarUrl: 'https://i.pravatar.cc/150?u=s2',
    );
    final s3 = Speaker(
      id: 'S3',
      name: 'Sarah OConnor',
      title: 'Lead Designer',
      company: 'CreativeCo',
      bio: 'Sarah focuses on accessibility in modern web apps.',
      avatarUrl: 'https://i.pravatar.cc/150?u=s3',
    );
    _speakers.addAll({s1.id: s1, s2.id: s2, s3.id: s3});

    // Seed Sessions - Day 1
    final d1 = conferenceStartDate;
    _addSession(
      'K1',
      'The Future of Declarative UIs',
      'Opening Keynote discussing the evolution of mobile development.',
      d1,
      d1.add(const Duration(hours: 1)),
      TrackType.mobile,
      SessionType.keynote,
      'V1',
      ['S2'],
    );
    _addSession(
      'W1',
      'Mastering Cloud Deployments',
      'Deep dive into Kubernetes and Docker.',
      d1.add(const Duration(hours: 1, minutes: 15)),
      d1.add(const Duration(hours: 3)),
      TrackType.cloud,
      SessionType.workshop,
      'V2',
      ['S1'],
    );
    _addSession(
      'P1',
      'Design Systems at Scale',
      'Panel discussion on building cohesive components.',
      d1.add(const Duration(hours: 1, minutes: 30)),
      d1.add(const Duration(hours: 2, minutes: 30)),
      TrackType.design,
      SessionType.panel,
      'V3',
      ['S3'],
    );

    // Seed Sessions - Day 2
    final d2 = d1.add(const Duration(days: 1));
    _addSession(
      'K2',
      'AI in Production',
      'How to safely deploy LLMs.',
      d2,
      d2.add(const Duration(hours: 1)),
      TrackType.ai,
      SessionType.keynote,
      'V1',
      ['S1'],
    );
    _addSession(
      'W2',
      'Advanced State Management',
      'Managing complex app states efficiently.',
      d2.add(const Duration(hours: 1, minutes: 30)),
      d2.add(const Duration(hours: 3)),
      TrackType.mobile,
      SessionType.workshop,
      'V2',
      ['S2'],
    );
  }

  void _addSession(
    String id,
    String title,
    String desc,
    DateTime start,
    DateTime end,
    TrackType track,
    SessionType type,
    String vId,
    List<String> sIds,
  ) {
    _sessions[id] = Session(
      id: id,
      title: title,
      description: desc,
      startTime: start,
      endTime: end,
      track: track,
      type: type,
      venueId: vId,
      speakerIds: sIds,
    );
  }

  Future<void> _latency([int ms = 400]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(300)));

  // --- API Methods ---
  Future<User> login() async {
    await _latency(600);
    final u = User(
      id: 'U1',
      name: 'Alex Attendee',
      email: 'alex@dev.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=u1',
    );
    _agendas[u.id] = UserAgenda(
      userId: u.id,
      bookmarkedSessionIds: ['K1'],
    ); // Pre-seed an agenda item
    return u;
  }

  Future<List<Session>> getSessions() async {
    await _latency();
    return _sessions.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<List<Speaker>> getSpeakers() async {
    await _latency();
    return _speakers.values.toList();
  }

  Future<List<Venue>> getVenues() async {
    await _latency();
    return _venues.values.toList();
  }

  Future<UserAgenda> getAgenda(String userId) async {
    await _latency(200);
    return _agendas[userId]!;
  }

  /// Complex conflict resolution algorithm
  Future<void> toggleBookmark(String userId, String sessionId) async {
    await _latency(400);
    final agenda = _agendas[userId];
    if (agenda == null) throw Exception("User agenda not found.");

    if (agenda.bookmarkedSessionIds.contains(sessionId)) {
      agenda.bookmarkedSessionIds.remove(sessionId);
      _sessions[sessionId]!.currentAttendees--;
      return;
    }

    final targetSession = _sessions[sessionId];
    if (targetSession == null) throw Exception("Session not found.");

    // 1. Capacity Check
    final venue = _venues[targetSession.venueId]!;
    if (targetSession.currentAttendees >= venue.capacity) {
      throw CapacityException();
    }

    // 2. Overlap Check
    for (String existingId in agenda.bookmarkedSessionIds) {
      final existing = _sessions[existingId]!;
      // Overlap condition: StartA < EndB AND EndA > StartB
      if (targetSession.startTime.isBefore(existing.endTime) &&
          targetSession.endTime.isAfter(existing.startTime)) {
        throw ScheduleConflictException("Overlaps with '${existing.title}'.");
      }
    }

    // Success
    agenda.bookmarkedSessionIds.add(sessionId);
    targetSession.currentAttendees++;
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (Custom AppStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockConferenceEngine _api = MockConferenceEngine();

  bool isLoading = true;
  String? globalError;

  User? currentUser;
  List<Session> allSessions = [];
  List<Speaker> speakers = [];
  List<Venue> venues = [];
  List<String> myAgendaIds = [];

  // Filter State
  TrackType? selectedTrackFilter;
  DateTime? selectedDate;
  List<DateTime> conferenceDates = [];

  AppState() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      currentUser = await _api.login();
      final futures = await Future.wait([
        _api.getSessions(),
        _api.getSpeakers(),
        _api.getVenues(),
        _api.getAgenda(currentUser!.id),
      ]);

      allSessions = futures[0] as List<Session>;
      speakers = futures[1] as List<Speaker>;
      venues = futures[2] as List<Venue>;
      myAgendaIds = (futures[3] as UserAgenda).bookmarkedSessionIds;

      // Extract unique dates
      final dates = allSessions
          .map(
            (s) =>
                DateTime(s.startTime.year, s.startTime.month, s.startTime.day),
          )
          .toSet()
          .toList();
      dates.sort((a, b) => a.compareTo(b));
      conferenceDates = dates;
      if (dates.isNotEmpty) selectedDate = dates.first;
    } catch (e) {
      globalError = "Failed to load conference data.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  void setDateFilter(DateTime d) {
    selectedDate = d;
    notifyListeners();
  }

  void setTrackFilter(TrackType? t) {
    selectedTrackFilter = t;
    notifyListeners();
  }

  Future<bool> toggleAgendaBookmark(String sessionId) async {
    _setError(null);
    try {
      await _api.toggleBookmark(currentUser!.id, sessionId);
      final agenda = await _api.getAgenda(currentUser!.id);
      myAgendaIds = agenda.bookmarkedSessionIds;
      notifyListeners();
      return true;
    } on ConferenceException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // --- Relational Getters ---
  List<Session> get filteredSessions {
    if (selectedDate == null) return [];
    return allSessions.where((s) {
      final matchesDate = DateUtilsFormatter.isSameDay(
        s.startTime,
        selectedDate!,
      );
      final matchesTrack =
          selectedTrackFilter == null || s.track == selectedTrackFilter;
      return matchesDate && matchesTrack;
    }).toList();
  }

  List<Session> get myAgendaSessions {
    return allSessions.where((s) => myAgendaIds.contains(s.id)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Venue getVenue(String id) => venues.firstWhere((v) => v.id == id);
  Speaker getSpeaker(String id) => speakers.firstWhere((s) => s.id == id);
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
  runApp(const DevConApp());
}

class DevConApp extends StatelessWidget {
  const DevConApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus DevCon',
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
    if (state.isLoading)
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
    const ScheduleScreen(),
    const SpeakersScreen(),
    const AgendaScreen(),
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
            icon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Speakers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'My Agenda',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. SCHEDULE SCREEN (Custom Timeline & Filters)
// ============================================================================

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final sessions = state.filteredSessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DevCon 2026',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(state.currentUser!.avatarUrl),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.conferenceDates.length,
              itemBuilder: (ctx, i) {
                final d = state.conferenceDates[i];
                final isSelected = state.selectedDate == d;
                return GestureDetector(
                  onTap: () => state.setDateFilter(d),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceHighlight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Day ${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${d.month}/${d.day}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Track Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TrackChip(
                  label: 'All Tracks',
                  isSelected: state.selectedTrackFilter == null,
                  onTap: () => state.setTrackFilter(null),
                ),
                ...TrackType.values.map(
                  (t) => _TrackChip(
                    label: t.name.toUpperCase(),
                    isSelected: state.selectedTrackFilter == t,
                    color: AppColors.getTrackColor(t),
                    onTap: () => state.setTrackFilter(t),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Timeline View
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Text(
                      'No sessions match your filters.',
                      style: AppStyles.body,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessions.length,
                    itemBuilder: (ctx, i) => _SessionCard(session: sessions[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrackChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;
  const _TrackChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.surfaceHighlight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color ?? AppColors.surfaceHighlight),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  const _SessionCard({required this.session});

  void _handleBookmark(BuildContext context, AppState state) async {
    final success = await state.toggleAgendaBookmark(session.id);
    if (!success && context.mounted && state.globalError != null) {
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
    final trackColor = AppColors.getTrackColor(session.track);
    final isBookmarked = state.myAgendaIds.contains(session.id);
    final venue = state.getVenue(session.venueId);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: trackColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${Formatters.formatTime(session.startTime)} - ${Formatters.formatTime(session.endTime)}',
                    style: TextStyle(
                      color: trackColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                    onPressed: () => _handleBookmark(context, state),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(session.title, style: AppStyles.h3),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(venue.name, style: AppStyles.caption),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.type.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Speaker Avatars
              Row(
                children: session.speakerIds.map((id) {
                  final speaker = state.getSpeaker(id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(speaker.avatarUrl),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 8. SESSION DETAIL SCREEN (Parallax & Speaker Info)
// ============================================================================

class SessionDetailScreen extends StatelessWidget {
  final Session session;
  const SessionDetailScreen({Key? key, required this.session})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final trackColor = AppColors.getTrackColor(session.track);
    final isBookmarked = state.myAgendaIds.contains(session.id);
    final venue = state.getVenue(session.venueId);
    final isFull = session.currentAttendees >= venue.capacity;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: trackColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [trackColor.withOpacity(0.8), AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: () async {
                  final success = await state.toggleAgendaBookmark(session.id);
                  if (!success && context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.globalError!),
                        backgroundColor: AppColors.error,
                      ),
                    );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: trackColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      session.track.name.toUpperCase(),
                      style: TextStyle(
                        color: trackColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(session.title, style: AppStyles.h1),
                  const SizedBox(height: 24),

                  // Meta Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _MetaRow(
                          icon: Icons.calendar_today,
                          label: DateUtilsFormatter.formatDate(
                            session.startTime,
                          ),
                        ),
                        const Divider(
                          height: 24,
                          color: AppColors.surfaceHighlight,
                        ),
                        _MetaRow(
                          icon: Icons.schedule,
                          label:
                              '${Formatters.formatTime(session.startTime)} - ${Formatters.formatTime(session.endTime)} (${session.duration.inMinutes} mins)',
                        ),
                        const Divider(
                          height: 24,
                          color: AppColors.surfaceHighlight,
                        ),
                        _MetaRow(
                          icon: Icons.location_on,
                          label: '${venue.name} (Capacity: ${venue.capacity})',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Overview', style: AppStyles.h2),
                  const SizedBox(height: 8),
                  Text(session.description, style: AppStyles.body),
                  const SizedBox(height: 32),

                  const Text('Speakers', style: AppStyles.h2),
                  const SizedBox(height: 16),
                  ...session.speakerIds.map((id) {
                    final s = state.getSpeaker(id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(s.avatarUrl),
                      ),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${s.title} @ ${s.company}'),
                      onTap: () => _showSpeakerProfile(context, s),
                    );
                  }).toList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isBookmarked
            ? AppColors.surfaceHighlight
            : (isFull ? AppColors.surfaceHighlight : AppColors.primary),
        onPressed: isFull && !isBookmarked
            ? null
            : () async {
                final success = await state.toggleAgendaBookmark(session.id);
                if (!success && context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.globalError!),
                      backgroundColor: AppColors.error,
                    ),
                  );
              },
        icon: Icon(
          isBookmarked
              ? Icons.check
              : (isFull ? Icons.block : Icons.bookmark_add),
          color: Colors.white,
        ),
        label: Text(
          isBookmarked
              ? 'SAVED TO AGENDA'
              : (isFull ? 'SESSION FULL' : 'ADD TO AGENDA'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showSpeakerProfile(BuildContext context, Speaker s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(32),
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
            CircleAvatar(
              radius: 64,
              backgroundImage: NetworkImage(s.avatarUrl),
            ),
            const SizedBox(height: 16),
            Text(s.name, style: AppStyles.h1),
            Text(
              '${s.title} at ${s.company}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Biography', style: AppStyles.h2),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(s.bio, style: AppStyles.body),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 9. MY AGENDA SCREEN & CUSTOM PAINTER (Timeline visualizer)
// ============================================================================

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final agenda = state.myAgendaSessions;

    // Group agenda by Day
    final Map<DateTime, List<Session>> grouped = {};
    for (var s in agenda) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      grouped.putIfAbsent(d, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Agenda')),
      body: agenda.isEmpty
          ? const Center(
              child: Text(
                'Your agenda is empty. Bookmark sessions to add them here.',
                textAlign: TextAlign.center,
                style: AppStyles.body,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: grouped.keys.length,
              itemBuilder: (ctx, i) {
                final date = grouped.keys.elementAt(i);
                final daySessions = grouped[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateUtilsFormatter.formatDate(date),
                      style: AppStyles.h2,
                    ),
                    const SizedBox(height: 16),
                    // Custom Visual Timeline for the day
                    Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: daySessions.length,
                        itemBuilder: (c, idx) {
                          final s = daySessions[idx];
                          return _TimelineNode(
                            session: s,
                            isLast: idx == daySessions.length - 1,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final Session session;
  final bool isLast;
  const _TimelineNode({required this.session, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getTrackColor(session.track);
    return IntrinsicHeight(
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 8.0,
              ),
              child: Column(
                children: [
                  Text(
                    Formatters.formatTime(session.startTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    Formatters.formatTime(session.endTime),
                    style: AppStyles.caption,
                  ),
                ],
              ),
            ),
          ),

          // Node Line Column
          SizedBox(
            width: 30,
            child: CustomPaint(
              painter: _TimelineLinePainter(color: color, isLast: isLast),
            ),
          ),

          // Content Column
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionDetailScreen(session: session),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: AppStyles.h3),
                    const SizedBox(height: 4),
                    Text(
                      AppStore.of(
                        context,
                        listen: false,
                      ).getVenue(session.venueId).name,
                      style: AppStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLinePainter extends CustomPainter {
  final Color color;
  final bool isLast;
  _TimelineLinePainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.surfaceHighlight
      ..strokeWidth = 2;
    final paintCircle = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw Line
    if (!isLast) {
      canvas.drawLine(
        Offset(size.width / 2, 30),
        Offset(size.width / 2, size.height),
        paintLine,
      );
    }

    // Draw Node
    canvas.drawCircle(Offset(size.width / 2, 30), 8, paintCircle);
    canvas.drawCircle(Offset(size.width / 2, 30), 8, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ============================================================================
// 10. SPEAKERS DIRECTORY (Placeholder to complete routing)
// ============================================================================

class SpeakersScreen extends StatelessWidget {
  const SpeakersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Speakers')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: state.speakers.length,
        itemBuilder: (ctx, i) {
          final s = state.speakers[i];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(s.avatarUrl),
              ),
              title: Text(
                s.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${s.title} @ ${s.company}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap:
                  () {}, // Re-use _showSpeakerProfile from SessionDetail if modularized
            ),
          );
        },
      ),
    );
  }
}
