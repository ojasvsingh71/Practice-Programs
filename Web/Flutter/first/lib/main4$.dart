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
// 1. CONSTANTS, ENUMS, & THEME
// ============================================================================

enum UserRole { passenger, driver }

enum RideStatus {
  idle,
  searching,
  requestTimeout,
  accepted,
  arriving,
  inProgress,
  completed,
  cancelled,
}

class AppColors {
  static const Color primary = Color(0xFF000000); // Uber-like Black
  static const Color accent = Color(0xFF276EF1); // Blue accent
  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);

  static const Color mapBackground = Color(0xFFE5E5E5);
  static const Color mapRoad = Color(0xFFFFFFFF);
  static const Color routeLine = accent;
}

// ============================================================================
// 2. DOMAIN MODELS & MATH (GEOMETRY)
// ============================================================================

/// Represents a 2D coordinate on our custom mock map (0.0 to 100.0)
class GeoCoord {
  final double x;
  final double y;
  const GeoCoord(this.x, this.y);

  /// Calculates Euclidean distance (mocking Haversine for 2D plane)
  double distanceTo(GeoCoord other) {
    return math.sqrt(math.pow(other.x - x, 2) + math.pow(other.y - y, 2));
  }

  /// Interpolates between this coordinate and another by a fraction t (0.0 to 1.0)
  GeoCoord lerp(GeoCoord other, double t) {
    return GeoCoord(x + (other.x - x) * t, y + (other.y - y) * t);
  }
}

class User {
  final String id;
  final String name;
  final UserRole role;
  final String avatar;
  final double rating;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
    this.rating = 4.9,
  });
}

class RideRequest {
  final String id;
  final User passenger;
  final GeoCoord origin;
  final GeoCoord destination;
  final String originName;
  final String destName;
  final double estimatedFare;
  final double estimatedDistance; // arbitrary units

  RideRequest({
    required this.id,
    required this.passenger,
    required this.origin,
    required this.destination,
    required this.originName,
    required this.destName,
    required this.estimatedFare,
    required this.estimatedDistance,
  });
}

class RideSession {
  final RideRequest request;
  final User driver;
  RideStatus status;
  GeoCoord driverLocation;

  RideSession({
    required this.request,
    required this.driver,
    required this.status,
    required this.driverLocation,
  });
}

// ============================================================================
// 3. MOCK BACKEND ENGINE & DISPATCHER
// ============================================================================

/// Simulates a WebSocket-based Dispatch Backend
class MockDispatchEngine {
  static final MockDispatchEngine _instance = MockDispatchEngine._internal();
  factory MockDispatchEngine() => _instance;
  MockDispatchEngine._internal();

  final math.Random _random = math.Random();

  // Base Fare Calculation Callback
  double calculateFare(GeoCoord origin, GeoCoord destination) {
    final distance = origin.distanceTo(destination);
    final baseFare = 5.00;
    final perUnit = 1.25;
    final surge = _random.nextDouble() > 0.7
        ? 1.5
        : 1.0; // 30% chance of 1.5x surge
    return double.parse(
      (baseFare + (distance * perUnit) * surge).toStringAsFixed(2),
    );
  }

  // --- PASSENGER SIMULATION API ---

  /// Requests a ride and returns a stream of session updates
  Stream<RideSession> requestRideAsPassenger(RideRequest request) async* {
    // 1. Searching phase
    yield RideSession(
      request: request,
      driver: _createMockDriver(),
      status: RideStatus.searching,
      driverLocation: const GeoCoord(0, 0), // placeholder
    );

    await Future.delayed(const Duration(seconds: 3));

    // Simulate 20% chance of no drivers available (Timeout)
    if (_random.nextDouble() < 0.2) {
      yield RideSession(
        request: request,
        driver: _createMockDriver(),
        status: RideStatus.requestTimeout,
        driverLocation: const GeoCoord(0, 0),
      );
      return;
    }

    // 2. Driver Accepted
    final mockDriver = _createMockDriver();
    // Spawn driver somewhere nearby
    GeoCoord driverLoc = GeoCoord(
      request.origin.x + (_random.nextDouble() * 20 - 10),
      request.origin.y + (_random.nextDouble() * 20 - 10),
    );

    yield RideSession(
      request: request,
      driver: mockDriver,
      status: RideStatus.accepted,
      driverLocation: driverLoc,
    );
    await Future.delayed(const Duration(seconds: 1));

    // 3. Arriving Phase (interpolate location)
    yield* _simulateMovement(
      request: request,
      driver: mockDriver,
      start: driverLoc,
      end: request.origin,
      status: RideStatus.arriving,
      durationSecs: 5,
    );

    // Wait for passenger to board
    yield RideSession(
      request: request,
      driver: mockDriver,
      status: RideStatus.inProgress,
      driverLocation: request.origin,
    );
    await Future.delayed(const Duration(seconds: 2));

    // 4. In Progress Phase (interpolate to destination)
    yield* _simulateMovement(
      request: request,
      driver: mockDriver,
      start: request.origin,
      end: request.destination,
      status: RideStatus.inProgress,
      durationSecs: 8,
    );

    // 5. Completed
    yield RideSession(
      request: request,
      driver: mockDriver,
      status: RideStatus.completed,
      driverLocation: request.destination,
    );
  }

  // --- DRIVER SIMULATION API ---

  /// Simulates going online and receiving requests
  Stream<RideRequest?> listenForRequests() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 3 + _random.nextInt(5)));

      final origin = GeoCoord(
        _random.nextDouble() * 100,
        _random.nextDouble() * 100,
      );
      final dest = GeoCoord(
        _random.nextDouble() * 100,
        _random.nextDouble() * 100,
      );

      yield RideRequest(
        id: 'REQ_${_random.nextInt(99999)}',
        passenger: User(
          id: 'P1',
          name: 'Sarah Connor',
          role: UserRole.passenger,
          rating: 4.8,
          avatar: 'S',
        ),
        origin: origin,
        destination: dest,
        originName: 'Central Park',
        destName: 'JFK Airport',
        estimatedFare: calculateFare(origin, dest),
        estimatedDistance: origin.distanceTo(dest),
      );

      // Wait for a bit, then nullify request if driver didn't accept (Timeout logic handled in State)
      await Future.delayed(const Duration(seconds: 15));
      yield null;
    }
  }

  Stream<RideSession> startRideAsDriver(
    RideRequest request,
    GeoCoord initialDriverLoc,
  ) async* {
    final driver = User(
      id: 'Me',
      name: 'Me',
      role: UserRole.driver,
      avatar: 'M',
    );

    // 1. Arriving
    yield* _simulateMovement(
      request: request,
      driver: driver,
      start: initialDriverLoc,
      end: request.origin,
      status: RideStatus.arriving,
      durationSecs: 5,
    );

    // 2. In Progress
    yield* _simulateMovement(
      request: request,
      driver: driver,
      start: request.origin,
      end: request.destination,
      status: RideStatus.inProgress,
      durationSecs: 8,
    );

    // 3. Complete
    yield RideSession(
      request: request,
      driver: driver,
      status: RideStatus.completed,
      driverLocation: request.destination,
    );
  }

  Stream<RideSession> _simulateMovement({
    required RideRequest request,
    required User driver,
    required GeoCoord start,
    required GeoCoord end,
    required RideStatus status,
    required int durationSecs,
  }) async* {
    int frames = durationSecs * 10; // 10 updates per second
    for (int i = 0; i <= frames; i++) {
      double t = i / frames;
      // Add a slight ease-in-out to movement
      double smoothT = t * t * (3 - 2 * t);
      GeoCoord current = start.lerp(end, smoothT);

      yield RideSession(
        request: request,
        driver: driver,
        status: status,
        driverLocation: current,
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  User _createMockDriver() {
    final names = ['Alex', 'David', 'Maria', 'James'];
    final name = names[_random.nextInt(names.length)];
    return User(
      id: 'D_${_random.nextInt(100)}',
      name: name,
      role: UserRole.driver,
      rating: 4.6 + (_random.nextDouble() * 0.4),
      avatar: name[0],
    );
  }
}

// ============================================================================
// 4. STATE MANAGEMENT (Custom AppStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockDispatchEngine _engine = MockDispatchEngine();

  User? currentUser;

  // Passenger State
  GeoCoord passengerLocation = const GeoCoord(50.0, 50.0);
  GeoCoord? selectedDestination;
  RideSession? currentPassengerSession;
  StreamSubscription? _passengerSub;

  // Driver State
  GeoCoord driverLocation = const GeoCoord(45.0, 55.0);
  bool isDriverOnline = false;
  RideRequest? incomingRequest;
  RideSession? currentDriverSession;
  StreamSubscription? _driverRequestSub;
  StreamSubscription? _driverRideSub;
  Timer? _incomingRequestTimer;
  int incomingRequestTimeout = 0;

  // --- Auth ---
  void login(String name, UserRole role) {
    currentUser = User(id: 'U_1', name: name, role: role, avatar: name[0]);
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    currentPassengerSession = null;
    isDriverOnline = false;
    _passengerSub?.cancel();
    _driverRequestSub?.cancel();
    _driverRideSub?.cancel();
    notifyListeners();
  }

  // --- Passenger Methods ---
  void setDestination(GeoCoord dest) {
    selectedDestination = dest;
    notifyListeners();
  }

  void requestRide() {
    if (selectedDestination == null) return;

    final req = RideRequest(
      id: 'REQ_${DateTime.now().millisecondsSinceEpoch}',
      passenger: currentUser!,
      origin: passengerLocation,
      destination: selectedDestination!,
      originName: 'Current Location',
      destName: 'Destination',
      estimatedFare: _engine.calculateFare(
        passengerLocation,
        selectedDestination!,
      ),
      estimatedDistance: passengerLocation.distanceTo(selectedDestination!),
    );

    currentPassengerSession = RideSession(
      request: req,
      driver: User(id: '', name: '', role: UserRole.driver, avatar: ''),
      status: RideStatus.searching,
      driverLocation: passengerLocation,
    );
    notifyListeners();

    _passengerSub?.cancel();
    _passengerSub = _engine.requestRideAsPassenger(req).listen((session) {
      currentPassengerSession = session;
      notifyListeners();
    });
  }

  void resetPassengerState() {
    _passengerSub?.cancel();
    currentPassengerSession = null;
    selectedDestination = null;
    notifyListeners();
  }

  // --- Driver Methods ---
  void toggleOnline() {
    isDriverOnline = !isDriverOnline;
    if (isDriverOnline) {
      _driverRequestSub = _engine.listenForRequests().listen((req) {
        if (currentDriverSession != null) return; // Busy

        if (req != null && incomingRequest == null) {
          incomingRequest = req;
          incomingRequestTimeout = 15;
          _incomingRequestTimer?.cancel();
          _incomingRequestTimer = Timer.periodic(const Duration(seconds: 1), (
            timer,
          ) {
            if (incomingRequestTimeout > 0) {
              incomingRequestTimeout--;
              notifyListeners();
            } else {
              _ignoreRequest();
            }
          });
        } else if (req == null) {
          _ignoreRequest();
        }
        notifyListeners();
      });
    } else {
      _driverRequestSub?.cancel();
      _ignoreRequest();
    }
    notifyListeners();
  }

  void _ignoreRequest() {
    _incomingRequestTimer?.cancel();
    incomingRequest = null;
    notifyListeners();
  }

  void acceptRequest() {
    if (incomingRequest == null) return;
    final req = incomingRequest!;
    _ignoreRequest();

    currentDriverSession = RideSession(
      request: req,
      driver: currentUser!,
      status: RideStatus.accepted,
      driverLocation: driverLocation,
    );
    notifyListeners();

    _driverRideSub?.cancel();
    _driverRideSub = _engine.startRideAsDriver(req, driverLocation).listen((
      session,
    ) {
      currentDriverSession = session;
      driverLocation = session.driverLocation; // update local driver GPS
      notifyListeners();
    });
  }

  void completeDriverRide() {
    _driverRideSub?.cancel();
    currentDriverSession = null;
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
// 5. MAIN APP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const RideApp());
}

class RideApp extends StatelessWidget {
  const RideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Ride',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Helvetica Neue',
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const RootRouter(),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.currentUser == null) return const AuthScreen();
    if (state.currentUser!.role == UserRole.passenger)
      return const PassengerHomeScreen();
    return const DriverHomeScreen();
  }
}

// ============================================================================
// 6. AUTH SCREEN
// ============================================================================

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_taxi, size: 100, color: Colors.white),
              const SizedBox(height: 32),
              const Text(
                'NEXUS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const Text(
                'Move the way you want',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => state.login('Alice', UserRole.passenger),
                child: const Text(
                  'LOG IN AS RIDER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => state.login('Bob', UserRole.driver),
                child: const Text(
                  'DRIVE & EARN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. PASSENGER FLOW
// ============================================================================

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({Key? key}) : super(key: key);

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showDestinationPicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Where to?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter destination',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _DestTile(
                    title: 'JFK Airport',
                    subtitle: 'Queens, NY',
                    coord: const GeoCoord(80, 20),
                    onTap: (c) {
                      state.setDestination(c);
                      Navigator.pop(ctx);
                    },
                  ),
                  _DestTile(
                    title: 'Central Park',
                    subtitle: 'Manhattan, NY',
                    coord: const GeoCoord(30, 80),
                    onTap: (c) {
                      state.setDestination(c);
                      Navigator.pop(ctx);
                    },
                  ),
                  _DestTile(
                    title: 'Empire State Building',
                    subtitle: 'Manhattan, NY',
                    coord: const GeoCoord(70, 70),
                    onTap: (c) {
                      state.setDestination(c);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final session = state.currentPassengerSession;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Interactive Map Layer
          Positioned.fill(
            child: MockMapWidget(
              userLocation: state.passengerLocation,
              destination: state.selectedDestination,
              driverLocation: session?.driverLocation,
              routeStart: session?.status == RideStatus.arriving
                  ? session?.driverLocation
                  : state.passengerLocation,
              routeEnd: session?.status == RideStatus.arriving
                  ? state.passengerLocation
                  : state.selectedDestination,
              showRoute: session != null || state.selectedDestination != null,
            ),
          ),

          // 2. Top Controls
          Positioned(
            top: 50,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              onPressed: () => state.logout(),
              child: const Icon(Icons.menu),
            ),
          ),

          // 3. Bottom UI Layer based on State
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildBottomUI(context, state, session),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomUI(
    BuildContext context,
    AppState state,
    RideSession? session,
  ) {
    if (session == null) {
      if (state.selectedDestination == null) {
        // Idle
        return _buildIdleSheet(context, state);
      } else {
        // Estimate
        return _buildEstimateSheet(state);
      }
    }

    switch (session.status) {
      case RideStatus.searching:
        return _buildSearchingSheet();
      case RideStatus.requestTimeout:
        return _buildTimeoutSheet(state);
      case RideStatus.accepted:
      case RideStatus.arriving:
        return _buildTrackingSheet(session, 'Driver is arriving');
      case RideStatus.inProgress:
        return _buildTrackingSheet(session, 'Heading to destination');
      case RideStatus.completed:
        return _buildReceiptSheet(state, session);
      default:
        return const SizedBox();
    }
  }

  Widget _buildIdleSheet(BuildContext context, AppState state) {
    return Container(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showDestinationPicker(context, state),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.black54),
                    SizedBox(width: 16),
                    Text(
                      'Where to?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateSheet(AppState state) {
    final fare = MockDispatchEngine().calculateFare(
      state.passengerLocation,
      state.selectedDestination!,
    );
    return Container(
      key: const ValueKey('estimate'),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NexusX',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$$fare',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Affordable, everyday rides',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        state.setDestination(null as dynamic), // Reset
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => state.requestRide(),
                    child: const Text('CONFIRM NEXUSX'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingSheet() {
    return Container(
      key: const ValueKey('searching'),
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (ctx, child) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(1 - _pulseCtrl.value),
                      width: 4 * _pulseCtrl.value,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.search, color: AppColors.accent),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Finding you a driver...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a few moments',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutSheet(AppState state) {
    return Container(
      key: const ValueKey('timeout'),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No drivers available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'All our drivers are currently busy. Please try again in a few minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => state.resetPassengerState(),
                child: const Text('OKAY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingSheet(RideSession session, String statusText) {
    return Container(
      key: ValueKey('tracking_${session.status}'),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.accent,
                child: Text(
                  session.driver.avatar,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                session.driver.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${session.driver.rating}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'Toyota Prius',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ABC-1234',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSheet(AppState state, RideSession session) {
    return Container(
      key: const ValueKey('receipt'),
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'You have arrived',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${session.request.estimatedFare}',
              style: const TextStyle(fontSize: 20, color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => state.resetPassengerState(),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final GeoCoord coord;
  final Function(GeoCoord) onTap;

  const _DestTile({
    required this.title,
    required this.subtitle,
    required this.coord,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.mapBackground,
        child: Icon(Icons.location_on, color: Colors.black),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: () => onTap(coord),
    );
  }
}

// ============================================================================
// 8. DRIVER FLOW
// ============================================================================

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final session = state.currentDriverSession;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          Positioned.fill(
            child: MockMapWidget(
              userLocation: state.driverLocation, // Center map on driver
              destination: session?.request.destination,
              driverLocation: state.driverLocation,
              routeStart: session?.status == RideStatus.arriving
                  ? state.driverLocation
                  : (session?.status == RideStatus.inProgress
                        ? state.driverLocation
                        : null),
              routeEnd: session?.status == RideStatus.arriving
                  ? session?.request.origin
                  : (session?.status == RideStatus.inProgress
                        ? session?.request.destination
                        : null),
              showRoute: session != null,
            ),
          ),

          // 2. Top Bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: 'menu',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onPressed: () => state.logout(),
                  child: const Icon(Icons.menu),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isDriverOnline
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isDriverOnline ? 'ONLINE' : 'OFFLINE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Incoming Request Overlay
          if (state.incomingRequest != null && session == null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'NEW REQUEST',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '\$${state.incomingRequest!.estimatedFare}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.my_location, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(state.incomingRequest!.originName),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(state.incomingRequest!.destName),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: state.incomingRequestTimeout / 15.0,
                                backgroundColor: AppColors.background,
                                color: AppColors.accent,
                                strokeWidth: 6,
                              ),
                            ),
                            Text(
                              '${state.incomingRequestTimeout}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                            ),
                            onPressed: () => state.acceptRequest(),
                            child: const Text(
                              'TAP TO ACCEPT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 4. Bottom Controls
          if (session == null && state.incomingRequest == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isDriverOnline
                          ? AppColors.error
                          : AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () => state.toggleOnline(),
                    child: Text(
                      state.isDriverOnline ? 'GO OFFLINE' : 'GO ONLINE',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. Active Ride UI
          if (session != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.status == RideStatus.arriving
                            ? 'PICK UP PASSENGER'
                            : (session.status == RideStatus.inProgress
                                  ? 'DROP OFF PASSENGER'
                                  : 'RIDE COMPLETE'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            session.request.passenger.avatar,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          session.request.passenger.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(
                          Icons.phone,
                          color: AppColors.accent,
                        ),
                      ),
                      if (session.status == RideStatus.completed) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => state.completeDriverRide(),
                            child: const Text('COMPLETE RIDE'),
                          ),
                        ),
                      ],
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

// ============================================================================
// 9. CUSTOM MOCK MAP ENGINE
// ============================================================================

class MockMapWidget extends StatelessWidget {
  final GeoCoord userLocation;
  final GeoCoord? destination;
  final GeoCoord? driverLocation;
  final GeoCoord? routeStart;
  final GeoCoord? routeEnd;
  final bool showRoute;

  const MockMapWidget({
    Key? key,
    required this.userLocation,
    this.destination,
    this.driverLocation,
    this.routeStart,
    this.routeEnd,
    this.showRoute = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mapBackground,
      child: CustomPaint(
        painter: _MapPainter(
          center: userLocation,
          destination: destination,
          driver: driverLocation,
          routeStart: routeStart,
          routeEnd: routeEnd,
          showRoute: showRoute,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final GeoCoord center;
  final GeoCoord? destination;
  final GeoCoord? driver;
  final GeoCoord? routeStart;
  final GeoCoord? routeEnd;
  final bool showRoute;

  _MapPainter({
    required this.center,
    this.destination,
    this.driver,
    this.routeStart,
    this.routeEnd,
    required this.showRoute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate Viewport Transform
    // We want to scale our 0-100 coordinate system to fit the screen.
    // If routing, bounding box includes start and end. Otherwise, center around user.
    double minX = center.x - 30;
    double maxX = center.x + 30;
    double minY = center.y - 30;
    double maxY = center.y + 30;

    if (showRoute && routeStart != null && routeEnd != null) {
      minX = math.min(routeStart!.x, routeEnd!.x) - 10;
      maxX = math.max(routeStart!.x, routeEnd!.x) + 10;
      minY = math.min(routeStart!.y, routeEnd!.y) - 10;
      maxY = math.max(routeStart!.y, routeEnd!.y) + 10;
    }

    final scaleX = size.width / (maxX - minX);
    final scaleY = size.height / (maxY - minY);
    final scale = math.min(scaleX, scaleY);

    // Offset to center the bounding box
    final offsetX = (size.width - (maxX - minX) * scale) / 2;
    final offsetY = (size.height - (maxY - minY) * scale) / 2;

    Offset toCanvas(GeoCoord coord) {
      return Offset(
        (coord.x - minX) * scale + offsetX,
        // Invert Y so 0 is bottom
        size.height - ((coord.y - minY) * scale + offsetY),
      );
    }

    // 2. Draw Decorative Map Grid / Roads
    final roadPaint = Paint()
      ..color = AppColors.mapRoad
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i <= 100; i += 10) {
      // Verticals
      canvas.drawLine(
        toCanvas(GeoCoord(i.toDouble(), 0)),
        toCanvas(GeoCoord(i.toDouble(), 100)),
        roadPaint,
      );
      // Horizontals
      canvas.drawLine(
        toCanvas(GeoCoord(0, i.toDouble())),
        toCanvas(GeoCoord(100, i.toDouble())),
        roadPaint,
      );
    }

    // 3. Draw Route Line
    if (showRoute && routeStart != null && routeEnd != null) {
      final routePaint = Paint()
        ..color = AppColors.routeLine
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(toCanvas(routeStart!), toCanvas(routeEnd!), routePaint);
    }

    // 4. Draw Destination Marker
    if (destination != null) {
      final destPos = toCanvas(destination!);
      final destPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: destPos, width: 16, height: 16),
        destPaint,
      );
    }

    // 5. Draw Passenger Marker
    final passPos = toCanvas(
      center,
    ); // In this mock, center is usually passenger or driver
    final passPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(passPos, 8, passPaint);
    canvas.drawCircle(
      passPos,
      16,
      Paint()
        ..color = AppColors.primary.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // 6. Draw Driver Marker (Car)
    if (driver != null) {
      final drvPos = toCanvas(driver!);

      // Draw car body
      final carPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      // rect intentionally unused (kept for potential future hit testing)

      // Calculate rotation based on movement direction (simplified mock: pointing right default)
      // For a real app, track previous coordinate to calculate atan2 angle
      canvas.save();
      canvas.translate(drvPos.dx, drvPos.dy);
      // If moving, we would rotate here.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 24, height: 12),
          const Radius.circular(4),
        ),
        carPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => true; // Repaint constantly for animation
}
