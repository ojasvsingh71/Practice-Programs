import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum SeatType { standard, premium, accessible }

enum SeatStatus { available, booked, selected }

enum BookingStatus { confirmed, cancelled, failed }

enum PaymentMethod { wallet, creditCard }

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700

  static const Color primary = Color(0xFFEAB308); // Yellow 500 (Cinematic Gold)
  static const Color primaryDark = Color(0xFFCA8A04); // Yellow 600
  static const Color accent = Color(0xFF3B82F6); // Blue 500

  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color seatAvailable = Color(0xFF334155); // Slate 700
  static const Color seatBooked = Color(0xFFEF4444); // Red 500
  static const Color seatSelected = Color(0xFF10B981); // Emerald 500
  static const Color seatPremium = Color(0xFF8B5CF6); // Violet 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
}

class AppStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textMain,
    letterSpacing: -0.5,
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
    fontSize: 15,
    color: AppColors.textMain,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );
  static const TextStyle goldText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}

// ============================================================================
// 2. UTILS & EXCEPTIONS
// ============================================================================

class CinemaException implements Exception {
  final String message;
  CinemaException(this.message);
  @override
  String toString() => message;
}

class SeatConflictException extends CinemaException {
  SeatConflictException([
    String m =
        "One or more selected seats have just been booked by someone else.",
  ]) : super(m);
}

class InsufficientFundsException extends CinemaException {
  InsufficientFundsException([String m = "Insufficient wallet balance."])
    : super(m);
}

class NetworkException extends CinemaException {
  NetworkException([String m = "Network timeout. Try again."]) : super(m);
}

class Formatters {
  static String currency(double amount) => '\$${amount.toStringAsFixed(2)}';
  static String duration(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';
  static String dateShort(DateTime d) => '${_month(d.month)} ${d.day}';
  static String time(DateTime d) {
    int h = d.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h == 0)
      h = 12;
    else if (h > 12)
      h -= 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} $p';
  }

  static String _month(int m) => const [
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
  ][m - 1];
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;
  double walletBalance;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.walletBalance = 150.0,
  });
}

class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final String backdropUrl;
  final String genre;
  final int durationMins;
  final String rating;
  final String synopsis;
  final double imdbScore;

  Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.backdropUrl,
    required this.genre,
    required this.durationMins,
    required this.rating,
    required this.synopsis,
    required this.imdbScore,
  });
}

class Showtime {
  final String id;
  final String movieId;
  final String theaterName;
  final String screenName;
  final DateTime startTime;
  final Map<String, Seat>
  seatMap; // Simulated DB of seats for this specific show

  Showtime({
    required this.id,
    required this.movieId,
    required this.theaterName,
    required this.screenName,
    required this.startTime,
    required this.seatMap,
  });
}

class Seat {
  final String id; // e.g. "A1"
  final int rowIndex;
  final int colIndex;
  final SeatType type;
  final double price;
  SeatStatus status;

  Seat({
    required this.id,
    required this.rowIndex,
    required this.colIndex,
    required this.type,
    required this.price,
    this.status = SeatStatus.available,
  });
  Seat copyWith({SeatStatus? status}) => Seat(
    id: id,
    rowIndex: rowIndex,
    colIndex: colIndex,
    type: type,
    price: price,
    status: status ?? this.status,
  );
}

class Booking {
  final String id;
  final String userId;
  final String showtimeId;
  final Movie movie;
  final Showtime showtime;
  final List<Seat> seats;
  final double subtotal;
  final double convenienceFee;
  final double totalAmount;
  BookingStatus status;
  final DateTime timestamp;

  Booking({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.movie,
    required this.showtime,
    required this.seats,
    required this.subtotal,
    required this.convenienceFee,
    required this.totalAmount,
    this.status = BookingStatus.confirmed,
    required this.timestamp,
  });
}

// ============================================================================
// 4. MOCK BACKEND ENGINE
// ============================================================================

class MockCinemaBackend {
  static final MockCinemaBackend _instance = MockCinemaBackend._internal();
  factory MockCinemaBackend() => _instance;
  MockCinemaBackend._internal() {
    _seedData();
  }

  final math.Random _random = math.Random();
  final List<Movie> _movies = [];
  final List<Showtime> _showtimes = [];
  final List<Booking> _bookings = [];
  late User _mockUser;

  // Default constructor removed — singleton pattern used via factory

  void _seedData() {
    _mockUser = User(
      id: 'USR_1',
      name: 'Alex Cinephile',
      email: 'alex@cinema.net',
      walletBalance: 200.0,
    );

    final m1 = Movie(
      id: 'M1',
      title: 'Dune: Part Two',
      genre: 'Sci-Fi • Adventure',
      durationMins: 166,
      rating: 'PG-13',
      imdbScore: 8.8,
      posterUrl:
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=400&q=80',
      backdropUrl:
          'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?auto=format&fit=crop&w=1000&q=80',
      synopsis:
          'Paul Atreides unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.',
    );
    final m2 = Movie(
      id: 'M2',
      title: 'Interstellar',
      genre: 'Sci-Fi • Drama',
      durationMins: 169,
      rating: 'PG-13',
      imdbScore: 8.6,
      posterUrl:
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?auto=format&fit=crop&w=400&q=80',
      backdropUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1000&q=80',
      synopsis:
          'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
    );
    final m3 = Movie(
      id: 'M3',
      title: 'The Dark Knight',
      genre: 'Action • Crime',
      durationMins: 152,
      rating: 'PG-13',
      imdbScore: 9.0,
      posterUrl:
          'https://images.unsplash.com/photo-1509347528160-9a9e33742cdb?auto=format&fit=crop&w=400&q=80',
      backdropUrl:
          'https://images.unsplash.com/photo-1497124401559-3e75ec2ed794?auto=format&fit=crop&w=1000&q=80',
      synopsis:
          'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.',
    );

    _movies.addAll([m1, m2, m3]);

    // Generate Showtimes for the next 3 days
    final now = DateTime.now();
    for (int i = 0; i < 3; i++) {
      for (var movie in _movies) {
        _showtimes.add(
          Showtime(
            id: 'ST_${movie.id}_D${i}_1',
            movieId: movie.id,
            theaterName: 'Cinemark IMAX',
            screenName: 'Screen 1',
            startTime: DateTime(now.year, now.month, now.day + i, 14, 30),
            seatMap: _generateSeatMap(),
          ),
        );
        _showtimes.add(
          Showtime(
            id: 'ST_${movie.id}_D${i}_2',
            movieId: movie.id,
            theaterName: 'Cinemark IMAX',
            screenName: 'Screen 2',
            startTime: DateTime(now.year, now.month, now.day + i, 19, 00),
            seatMap: _generateSeatMap(),
          ),
        );
      }
    }
  }

  /// Generates a complex seating arrangement
  /// 10 Rows (A-J), 12 Columns. Premium seats in the back.
  Map<String, Seat> _generateSeatMap() {
    final map = <String, Seat>{};
    const rowLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];

    for (int r = 0; r < rowLabels.length; r++) {
      for (int c = 1; c <= 12; c++) {
        // Create an aisle gap at col 3 and 10
        if (c == 3 || c == 10) continue;

        final id = '${rowLabels[r]}$c';
        final isPremium = r >= 7; // Rows H, I, J are premium
        final price = isPremium ? 22.50 : 14.00;

        // Randomly pre-book some seats to simulate real environment
        final isBooked = _random.nextDouble() < 0.3;

        map[id] = Seat(
          id: id,
          rowIndex: r,
          colIndex: c,
          type: isPremium ? SeatType.premium : SeatType.standard,
          price: price,
          status: isBooked ? SeatStatus.booked : SeatStatus.available,
        );
      }
    }
    return map;
  }

  Future<void> _latency([int ms = 800]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(500)));

  Future<User> getUser() async {
    await _latency(500);
    return _mockUser;
  }

  Future<List<Movie>> getMovies() async {
    await _latency();
    return List.from(_movies);
  }

  Future<List<Showtime>> getShowtimes(String movieId) async {
    await _latency(400);
    return _showtimes.where((s) => s.movieId == movieId).toList();
  }

  /// Atomic Booking Transaction Simulation
  Future<Booking> processBooking(
    String showtimeId,
    List<Seat> requestedSeats,
  ) async {
    await _latency(2000); // Simulate heavy payment & lock processing

    final showtime = _showtimes.firstWhere((s) => s.id == showtimeId);
    final movie = _movies.firstWhere((m) => m.id == showtime.movieId);

    // 1. Concurrency Check: Ensure seats aren't already booked
    for (var seat in requestedSeats) {
      if (showtime.seatMap[seat.id]?.status == SeatStatus.booked) {
        throw SeatConflictException(
          "Seat ${seat.id} was just booked by someone else.",
        );
      }
    }

    // 2. Calculate Totals
    final subtotal = requestedSeats.fold(0.0, (sum, s) => sum + s.price);
    final convenienceFee = requestedSeats.length * 1.50;
    final total = subtotal + convenienceFee;

    // 3. Payment Processing (Wallet)
    if (_mockUser.walletBalance < total) {
      throw InsufficientFundsException();
    }
    _mockUser.walletBalance -= total; // Deduct

    // 4. Finalize Seat State
    for (var seat in requestedSeats) {
      showtime.seatMap[seat.id]!.status = SeatStatus.booked;
    }

    // 5. Create Booking Record
    final booking = Booking(
      id: 'BKG_${DateTime.now().millisecondsSinceEpoch}',
      userId: _mockUser.id,
      showtimeId: showtimeId,
      movie: movie,
      showtime: showtime,
      seats: List.from(requestedSeats),
      subtotal: subtotal,
      convenienceFee: convenienceFee,
      totalAmount: total,
      timestamp: DateTime.now(),
    );

    _bookings.add(booking);
    return booking;
  }

  Future<List<Booking>> getMyBookings() async {
    await _latency(600);
    final sorted = List<Booking>.from(_bookings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  Future<void> cancelBooking(String bookingId) async {
    await _latency(1500);
    final booking = _bookings.firstWhere((b) => b.id == bookingId);
    if (booking.status == BookingStatus.cancelled)
      throw CinemaException("Already cancelled.");

    // Calculate Refund Policy (e.g., 80% refund)
    final refundAmount = booking.totalAmount * 0.8;

    // Process Refund
    _mockUser.walletBalance += refundAmount;
    booking.status = BookingStatus.cancelled;

    // Free up seats
    for (var seat in booking.seats) {
      booking.showtime.seatMap[seat.id]?.status = SeatStatus.available;
    }
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (Custom AppStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockCinemaBackend _api = MockCinemaBackend();

  User? currentUser;
  bool isGlobalLoading = true;
  String? globalError;

  List<Movie> movies = [];
  List<Booking> myBookings = [];

  // Booking Flow State
  Movie? selectedMovie;
  List<Showtime> availableShowtimes = [];
  Showtime? selectedShowtime;
  List<Seat> selectedSeats = [];

  AppState() {
    _init();
  }

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      currentUser = await _api.getUser();
      movies = await _api.getMovies();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshWalletAndBookings() async {
    myBookings = await _api.getMyBookings();
    notifyListeners();
  }

  // --- Booking Pipeline ---
  Future<void> selectMovie(Movie m) async {
    selectedMovie = m;
    selectedShowtime = null;
    selectedSeats.clear();
    availableShowtimes.clear();
    notifyListeners();

    availableShowtimes = await _api.getShowtimes(m.id);
    notifyListeners();
  }

  void selectShowtime(Showtime st) {
    selectedShowtime = st;
    selectedSeats.clear();
    notifyListeners();
  }

  void toggleSeatSelection(Seat seat) {
    if (seat.status == SeatStatus.booked) return;

    final existingIndex = selectedSeats.indexWhere((s) => s.id == seat.id);
    if (existingIndex >= 0) {
      selectedSeats.removeAt(existingIndex);
    } else {
      if (selectedSeats.length >= 8) {
        _setError("Maximum 8 seats allowed per booking.");
        Future.delayed(const Duration(seconds: 3), () => _setError(null));
        return;
      }
      selectedSeats.add(seat);
    }
    notifyListeners();
  }

  Future<bool> confirmBooking() async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.processBooking(selectedShowtime!.id, selectedSeats);
      await refreshWalletAndBookings();
      // Clear flow
      selectedMovie = null;
      selectedShowtime = null;
      selectedSeats.clear();
      return true;
    } on CinemaException catch (e) {
      _setError(e.message);
      // Auto-refresh seat map in case of conflict
      availableShowtimes = await _api.getShowtimes(selectedMovie!.id);
      final refreshedShowtime = availableShowtimes.firstWhere(
        (s) => s.id == selectedShowtime!.id,
      );
      selectShowtime(refreshedShowtime); // Rebind to get new seat statuses
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.cancelBooking(bookingId);
      await refreshWalletAndBookings();
      return true;
    } catch (e) {
      _setError("Failed to cancel booking.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void addFunds() {
    currentUser!.walletBalance += 50.0;
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
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CinemaxApp());
}

class CinemaxApp extends StatelessWidget {
  const CinemaxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Cinemax Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
    if (state.isGlobalLoading && state.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
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
    const MyTicketsScreen(),
    const WalletScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num),
            label: 'My Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. DISCOVER & MOVIE DETAILS
// ============================================================================

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text(
            'C I N E M A X',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: AppColors.primary,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text('Now Playing', style: AppStyles.h2),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 380,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.movies.length,
              itemBuilder: (context, index) {
                final movie = state.movies[index];
                return GestureDetector(
                  onTap: () {
                    state.selectMovie(movie);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MovieDetailScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'poster_${movie.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              movie.posterUrl,
                              height: 320,
                              width: 240,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          movie.title,
                          style: AppStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.imdbScore.toString(),
                              style: AppStyles.goldText,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              movie.genre,
                              style: AppStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final movie = state.selectedMovie;
    if (movie == null) return const Scaffold();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster_${movie.id}',
                    child: Image.network(movie.posterUrl, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: BoxDecoration(
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: AppStyles.h1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movie.rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.duration(movie.durationMins),
                        style: AppStyles.caption,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.imdbScore} IMDb',
                        style: AppStyles.goldText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Synopsis', style: AppStyles.h3),
                  const SizedBox(height: 8),
                  Text(movie.synopsis, style: AppStyles.body),
                  const SizedBox(height: 32),

                  const Text('Select Showtime', style: AppStyles.h3),
                  const SizedBox(height: 16),

                  if (state.availableShowtimes.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: state.availableShowtimes
                          .map(
                            (st) => ActionChip(
                              label: Text(Formatters.time(st.startTime)),
                              backgroundColor: AppColors.surface,
                              side: BorderSide(color: AppColors.surfaceLight),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                              onPressed: () {
                                state.selectShowtime(st);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SeatSelectionScreen(),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 100),
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
// 8. SEAT SELECTION ENGINE
// ============================================================================

class SeatSelectionScreen extends StatelessWidget {
  const SeatSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final showtime = state.selectedShowtime;
    if (showtime == null) return const Scaffold();

    final subtotal = state.selectedSeats.fold(0.0, (sum, s) => sum + s.price);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(showtime.theaterName, style: const TextStyle(fontSize: 16)),
            Text(
              '${Formatters.dateShort(showtime.startTime)} • ${Formatters.time(showtime.startTime)}',
              style: AppStyles.caption,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Screen Graphic CustomPainter
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 48.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: CustomPaint(painter: _CinemaScreenPainter()),
            ),
          ),

          // Seat Matrix (InteractiveViewer for Pinch-to-Zoom)
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 2.5,
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildSeatGrid(context, state, showtime),
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _LegendItem(color: AppColors.seatAvailable, label: 'Available'),
                _LegendItem(color: AppColors.seatSelected, label: 'Selected'),
                _LegendItem(color: AppColors.seatBooked, label: 'Booked'),
                _LegendItem(color: AppColors.seatPremium, label: 'Premium'),
              ],
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.selectedSeats.length} Seats',
                        style: AppStyles.caption,
                      ),
                      Text(Formatters.currency(subtotal), style: AppStyles.h2),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: state.selectedSeats.isEmpty
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          ),
                    child: const Text(
                      'PROCEED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
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

  Widget _buildSeatGrid(
    BuildContext context,
    AppState state,
    Showtime showtime,
  ) {
    const rowLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rowLabels.map((rLabel) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  rLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ...List.generate(12, (colIndex) {
                int c = colIndex + 1;
                // Aisle gaps
                if (c == 3 || c == 10) return const SizedBox(width: 32); // Gap

                final seatId = '$rLabel$c';
                final seat = showtime.seatMap[seatId];
                if (seat == null)
                  return const SizedBox(
                    width: 28,
                    height: 28,
                  ); // Should not happen, but safe fallback

                final isSelected = state.selectedSeats.any(
                  (s) => s.id == seatId,
                );

                return GestureDetector(
                  onTap: () => state.toggleSeatSelection(seat),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.seatSelected
                          : (seat.status == SeatStatus.booked
                                ? AppColors.seatBooked
                                : (seat.type == SeatType.premium
                                      ? AppColors.seatPremium
                                      : AppColors.seatAvailable)),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppStyles.caption),
      ],
    );
  }
}

class _CinemaScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height);

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5); // Glow effect

    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 9. CHECKOUT & PAYMENT ENGINE
// ============================================================================

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  void _handlePayment(BuildContext context, AppState state) async {
    final success = await state.confirmBooking();
    if (success && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TicketSuccessScreen()),
        (route) => route.isFirst,
      );
    } else if (context.mounted && state.globalError != null) {
      _showErrorDialog(context, state);
    }
  }

  void _showErrorDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: const [
            Icon(Icons.error, color: AppColors.error),
            SizedBox(width: 8),
            Text('Transaction Failed'),
          ],
        ),
        content: Text(state.globalError!),
        actions: [
          ElevatedButton(
            onPressed: () {
              state._setError(null);
              Navigator.pop(ctx);
              Navigator.pop(ctx); /* pop back to seat selection */
            },
            child: const Text('Back to Seats'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser!;
    final seats = state.selectedSeats;
    final subtotal = seats.fold(0.0, (sum, s) => sum + s.price);
    final convenienceFee = seats.length * 1.50;
    final total = subtotal + convenienceFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Order Summary
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.selectedMovie!.title, style: AppStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      '${state.selectedShowtime!.theaterName} • ${state.selectedShowtime!.screenName}',
                      style: AppStyles.caption,
                    ),
                    Text(
                      '${Formatters.dateShort(state.selectedShowtime!.startTime)} at ${Formatters.time(state.selectedShowtime!.startTime)}',
                      style: AppStyles.goldText,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    _BillRow(
                      label: 'Seats (${seats.map((s) => s.id).join(', ')})',
                      value: Formatters.currency(subtotal),
                    ),
                    _BillRow(
                      label: 'Convenience Fee',
                      value: Formatters.currency(convenienceFee),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(thickness: 2),
                    ),
                    _BillRow(
                      label: 'Total Amount',
                      value: Formatters.currency(total),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Method
              const Text('Payment Method', style: AppStyles.h3),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cinemax Wallet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Balance: ${Formatters.currency(user.walletBalance)}',
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (user.walletBalance < total)
                      const Text(
                        'Insufficient',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
              if (user.walletBalance < total) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => state.addFunds(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add \$50 to Wallet'),
                  ),
                ),
              ],
            ],
          ),

          if (state.isGlobalLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        color: AppColors.surface,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (state.isGlobalLoading || user.walletBalance < total)
                  ? null
                  : () => _handlePayment(context, state),
              child: Text(
                'PAY ${Formatters.currency(total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _BillRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class TicketSuccessScreen extends StatelessWidget {
  const TicketSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: AppColors.seatSelected,
            ),
            const SizedBox(height: 24),
            const Text('Booking Confirmed!', style: AppStyles.h1),
            const SizedBox(height: 16),
            const Text(
              'Your digital tickets are ready.',
              style: AppStyles.body,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('VIEW MY TICKETS'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 10. TICKETS & CANCELLATION ENGINE
// ============================================================================

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({Key? key}) : super(key: key);

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => AppStore.of(context, listen: false).refreshWalletAndBookings(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final bookings = state.myBookings;

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: bookings.isEmpty
          ? const Center(
              child: Text("No tickets booked yet.", style: AppStyles.body),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                final isCancelled = b.status == BookingStatus.cancelled;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketDetailScreen(booking: b),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCancelled
                            ? AppColors.seatBooked.withOpacity(0.5)
                            : AppColors.surfaceLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Image.network(
                            b.movie.posterUrl,
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isCancelled)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.seatBooked.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'CANCELLED',
                                      style: TextStyle(
                                        color: AppColors.seatBooked,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  b.movie.title,
                                  style: AppStyles.h3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${Formatters.dateShort(b.showtime.startTime)} • ${Formatters.time(b.showtime.startTime)}',
                                  style: AppStyles.goldText,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${b.seats.length} Seats: ${b.seats.map((s) => s.id).join(', ')}',
                                  style: AppStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TicketDetailScreen extends StatelessWidget {
  final Booking booking;
  const TicketDetailScreen({Key? key, required this.booking}) : super(key: key);

  void _handleCancel(BuildContext context, AppState state) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Booking?'),
        content: Text(
          'Are you sure? A cancellation fee of 20% applies. You will be refunded ${Formatters.currency(booking.totalAmount * 0.8)} to your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.seatBooked,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await state.cancelBooking(booking.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking Cancelled. Wallet refunded.'),
            backgroundColor: AppColors.seatSelected,
          ),
        );
        Navigator.pop(context);
      } else if (context.mounted && state.globalError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.globalError!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final isCancelled = booking.status == BookingStatus.cancelled;

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Custom Mock QR Code Graphic
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isCancelled
                  ? const Center(
                      child: Text(
                        'CANCELLED',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : CustomPaint(painter: _MockQRPainter(seed: booking.id)),
            ),
            const SizedBox(height: 32),

            Text(
              booking.movie.title,
              style: AppStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(booking.showtime.theaterName, style: AppStyles.h3),
            const SizedBox(height: 4),
            Text(
              'Screen: ${booking.showtime.screenName}',
              style: AppStyles.caption,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: AppColors.surfaceLight),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TicketMeta(
                  label: 'Date',
                  value: Formatters.dateShort(booking.showtime.startTime),
                ),
                _TicketMeta(
                  label: 'Time',
                  value: Formatters.time(booking.showtime.startTime),
                ),
                _TicketMeta(
                  label: 'Seats',
                  value: booking.seats.map((s) => s.id).join(', '),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: AppColors.surfaceLight),
            ),

            Text(
              'Booking ID: ${booking.id}',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 48),

            if (!isCancelled &&
                booking.showtime.startTime.isAfter(DateTime.now()))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.seatBooked,
                    side: const BorderSide(color: AppColors.seatBooked),
                  ),
                  onPressed: state.isGlobalLoading
                      ? null
                      : () => _handleCancel(context, state),
                  child: state.isGlobalLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.seatBooked,
                        )
                      : const Text('CANCEL BOOKING'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketMeta extends StatelessWidget {
  final String label;
  final String value;
  const _TicketMeta({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: AppStyles.goldText),
      ],
    );
  }
}

class _MockQRPainter extends CustomPainter {
  final String seed;
  _MockQRPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed.hashCode);
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    double step = size.width / 15;
    for (int r = 1; r < 14; r++) {
      for (int c = 1; c < 14; c++) {
        // Draw position anchors
        if ((r <= 3 && c <= 3) || (r <= 3 && c >= 11) || (r >= 11 && c <= 3)) {
          if (r == 2 && c == 2)
            canvas.drawRect(
              Rect.fromLTWH(c * step, r * step, step, step),
              paint,
            );
          if (r == 2 && c == 12)
            canvas.drawRect(
              Rect.fromLTWH(c * step, r * step, step, step),
              paint,
            );
          if (r == 12 && c == 2)
            canvas.drawRect(
              Rect.fromLTWH(c * step, r * step, step, step),
              paint,
            );
          continue;
        }
        if (rand.nextDouble() > 0.5) {
          canvas.drawRect(Rect.fromLTWH(c * step, r * step, step, step), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 11. WALLET SYSTEM
// ============================================================================

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(user.walletBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('ADD FUNDS (\$50)'),
                onPressed: () => state.addFunds(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
