import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
// Per-file Color compatibility shim (replaces deprecated withOpacity usage)
extension ColorWithValues on Color {
  Color withValues(double opacity) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int b = value & 0xFF;
    return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
  }
}


void main() {
  runApp(const TableReservationPlatformApp());
}

class TableReservationPlatformApp extends StatelessWidget {
  const TableReservationPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReservationStateProvider(
      child: MaterialApp(
        title: 'MaitreD Enterprise Core',
        debugShowCheckedModeBanner: false,
        home: MasterReservationHub(),
      ),
    );
  }
}

// ==========================================
// 1. GLOBAL ENUMS & CONFIGURATIONS
// ==========================================

enum TableStatus { available, occupied, reserved, dirty, maintenance }

enum ReservationStatus { confirmed, seated, completed, cancelled, noShow }

enum WaitlistStatus { waiting, notified, seated, abandoned }

enum TableShape { rectangle, circle, booth }

// ==========================================
// 2. CORE DATA MODELS
// ==========================================

class DiningTable {
  final String id;
  final String label;
  final int capacity;
  final TableShape shape;
  final Offset coordinates;
  final Size dimensions;
  TableStatus currentStatus;

  DiningTable({
    required this.id,
    required this.label,
    required this.capacity,
    required this.shape,
    required this.coordinates,
    required this.dimensions,
    this.currentStatus = TableStatus.available,
  });
}

class GuestProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final bool isVIP;
  final int noShowCount;

  const GuestProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.isVIP = false,
    this.noShowCount = 0,
  });
}

class Reservation {
  final String id;
  final GuestProfile guest;
  final String tableId;
  final int partySize;
  final DateTime startTime;
  final DateTime endTime;
  ReservationStatus status;
  final String specialRequests;
  final DateTime bookedAt;

  Reservation({
    required this.id,
    required this.guest,
    required this.tableId,
    required this.partySize,
    required this.startTime,
    required this.endTime,
    this.status = ReservationStatus.confirmed,
    this.specialRequests = '',
    required this.bookedAt,
  });

  // Core Concurrency & Double Booking Logic Vector
  bool overlapsWith(DateTime checkStart, DateTime checkEnd) {
    if (status == ReservationStatus.cancelled ||
        status == ReservationStatus.noShow ||
        status == ReservationStatus.completed) {
      return false;
    }
    // Check for temporal intersection
    return checkStart.isBefore(endTime) && checkEnd.isAfter(startTime);
  }
}

class WaitlistParty {
  final String id;
  final GuestProfile guest;
  final int partySize;
  final DateTime joinedAt;
  DateTime? notifiedAt;
  WaitlistStatus status;

  WaitlistParty({
    required this.id,
    required this.guest,
    required this.partySize,
    required this.joinedAt,
    this.status = WaitlistStatus.waiting,
    this.notifiedAt,
  });

  Duration get currentWaitTime => DateTime.now().difference(joinedAt);
}

class CommunicationLog {
  final DateTime timestamp;
  final String recipient;
  final String type; // SMS, EMAIL
  final String payload;
  final bool delivered;

  const CommunicationLog({
    required this.timestamp,
    required this.recipient,
    required this.type,
    required this.payload,
    this.delivered = true,
  });
}

// ==========================================
// 3. ENTERPRISE STATE MANAGEMENT ENGINE
// ==========================================

class ReservationEngineController extends ChangeNotifier {
  final List<DiningTable> _floorPlanTables = [];
  final List<Reservation> _masterReservationLedger = [];
  final List<WaitlistParty> _activeWaitlist = [];
  final List<CommunicationLog> _communicationLogs = [];
  final List<GuestProfile> _guestDatabase = [];

  // Temporal Simulation State
  late DateTime _simulatedCurrentTime;
  Timer? _simulationClockTimer;
  bool _isSimulationRunning = true;
  // Simulation speed multiplier (unused currently)

  List<DiningTable> get tables => List.unmodifiable(_floorPlanTables);
  List<Reservation> get reservations =>
      List.unmodifiable(_masterReservationLedger);
  List<WaitlistParty> get waitlist => List.unmodifiable(_activeWaitlist);
  List<CommunicationLog> get commLogs => List.unmodifiable(_communicationLogs);
  DateTime get currentTime => _simulatedCurrentTime;
  bool get isSimulationRunning => _isSimulationRunning;

  ReservationEngineController() {
    // Start simulation at 17:00 (5:00 PM) for dinner service
    final now = DateTime.now();
    _simulatedCurrentTime = DateTime(now.year, now.month, now.day, 17, 0);

    _initializeFloorPlanTopology();
    _seedEnterpriseMockData();
    _startTemporalSimulation();
  }

  void _initializeFloorPlanTopology() {
    // Left Wing (Window Seats)
    _floorPlanTables.add(
      DiningTable(
        id: 'T-11',
        label: '11',
        capacity: 2,
        shape: TableShape.rectangle,
        coordinates: const Offset(50, 50),
        dimensions: const Size(60, 60),
      ),
    );
    _floorPlanTables.add(
      DiningTable(
        id: 'T-12',
        label: '12',
        capacity: 2,
        shape: TableShape.rectangle,
        coordinates: const Offset(50, 150),
        dimensions: const Size(60, 60),
      ),
    );
    _floorPlanTables.add(
      DiningTable(
        id: 'T-13',
        label: '13',
        capacity: 4,
        shape: TableShape.rectangle,
        coordinates: const Offset(50, 250),
        dimensions: const Size(60, 100),
      ),
    );

    // Center Floor (Large Rounds)
    _floorPlanTables.add(
      DiningTable(
        id: 'T-21',
        label: '21',
        capacity: 6,
        shape: TableShape.circle,
        coordinates: const Offset(250, 100),
        dimensions: const Size(90, 90),
      ),
    );
    _floorPlanTables.add(
      DiningTable(
        id: 'T-22',
        label: '22',
        capacity: 6,
        shape: TableShape.circle,
        coordinates: const Offset(250, 250),
        dimensions: const Size(90, 90),
      ),
    );

    // Right Wing (Booths)
    _floorPlanTables.add(
      DiningTable(
        id: 'B-31',
        label: '31',
        capacity: 4,
        shape: TableShape.booth,
        coordinates: const Offset(450, 50),
        dimensions: const Size(100, 70),
      ),
    );
    _floorPlanTables.add(
      DiningTable(
        id: 'B-32',
        label: '32',
        capacity: 4,
        shape: TableShape.booth,
        coordinates: const Offset(450, 150),
        dimensions: const Size(100, 70),
      ),
    );
    _floorPlanTables.add(
      DiningTable(
        id: 'B-33',
        label: '33',
        capacity: 4,
        shape: TableShape.booth,
        coordinates: const Offset(450, 250),
        dimensions: const Size(100, 70),
      ),
    );

    // VIP Room
    _floorPlanTables.add(
      DiningTable(
        id: 'V-99',
        label: 'VIP',
        capacity: 10,
        shape: TableShape.rectangle,
        coordinates: const Offset(650, 150),
        dimensions: const Size(140, 80),
      ),
    );
  }

  void _seedEnterpriseMockData() {
    final guest1 = GuestProfile(
      id: 'G-001',
      fullName: 'Arthur Pendragon',
      phoneNumber: '555-0101',
      email: 'arthur@camelot.co',
      isVIP: true,
    );
    final guest2 = GuestProfile(
      id: 'G-002',
      fullName: 'Lara Croft',
      phoneNumber: '555-0102',
      email: 'lara@raider.net',
    );
    final guest3 = GuestProfile(
      id: 'G-003',
      fullName: 'Bruce Wayne',
      phoneNumber: '555-0999',
      email: 'bwayne@wayneenterprises.com',
      isVIP: true,
    );
    _guestDatabase.addAll([guest1, guest2, guest3]);

    // Pre-seed some reservations
    _makeInternalReservation(
      guest1,
      'V-99',
      8,
      _simulatedCurrentTime.add(const Duration(minutes: 30)),
      const Duration(hours: 2),
      'Anniversary. Prepare Champagne.',
    );
    _makeInternalReservation(
      guest2,
      'T-11',
      2,
      _simulatedCurrentTime,
      const Duration(minutes: 90),
      '',
    );

    // Seed waitlist
    _activeWaitlist.add(
      WaitlistParty(
        id: 'WL-101',
        guest: guest3,
        partySize: 3,
        joinedAt: _simulatedCurrentTime.subtract(const Duration(minutes: 15)),
      ),
    );
  }

  // --- CORE BOOKING LOGIC & COLLISION AVOIDANCE ---

  bool checkTableAvailability(String tableId, DateTime start, DateTime end) {
    // Prevention of Double Booking Vector
    for (var res in _masterReservationLedger) {
      if (res.tableId == tableId && res.overlapsWith(start, end)) {
        return false; // Collision detected
      }
    }
    return true; // Clear for booking
  }

  List<DiningTable> findAvailableTables(
    DateTime start,
    DateTime end,
    int partySize,
  ) {
    return _floorPlanTables.where((table) {
      if (table.capacity < partySize) return false;
      return checkTableAvailability(table.id, start, end);
    }).toList();
  }

  bool _makeInternalReservation(
    GuestProfile guest,
    String tableId,
    int partySize,
    DateTime start,
    Duration duration,
    String notes,
  ) {
    final end = start.add(duration);

    // Final concurrency validation block lock
    if (!checkTableAvailability(tableId, start, end)) {
      _dispatchSystemLog(
        "CRITICAL COLLISION AVOIDED",
        "System blocked double booking attempt on Table $tableId at ${start.hour}:${start.minute.toString().padLeft(2, '0')}.",
      );
      return false;
    }

    final newRes = Reservation(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      guest: guest,
      tableId: tableId,
      partySize: partySize,
      startTime: start,
      endTime: end,
      specialRequests: notes,
      bookedAt: _simulatedCurrentTime,
    );

    _masterReservationLedger.add(newRes);
    _dispatchCommunication(
      guest,
      'SMS',
      "MaitreD: Your reservation for $partySize is confirmed for ${_formatTime(start)}.",
    );
    notifyListeners();
    return true;
  }

  bool requestClientReservation(
    String name,
    String phone,
    int partySize,
    DateTime start,
    String tableId,
    String notes,
  ) {
    // Lookup or create guest
    GuestProfile guest = _guestDatabase.firstWhere(
      (g) => g.phoneNumber == phone,
      orElse: () {
        final newG = GuestProfile(
          id: 'G-${math.Random().nextInt(90000)}',
          fullName: name,
          phoneNumber: phone,
          email: 'unknown@client.net',
        );
        _guestDatabase.add(newG);
        return newG;
      },
    );
    return _makeInternalReservation(
      guest,
      tableId,
      partySize,
      start,
      const Duration(minutes: 90),
      notes,
    );
  }

  // --- WAITLIST & YIELD MANAGEMENT ---

  void addToWaitlist(String name, String phone, int partySize) {
    GuestProfile guest = GuestProfile(
      id: 'G-${math.Random().nextInt(90000)}',
      fullName: name,
      phoneNumber: phone,
      email: '',
    );
    final party = WaitlistParty(
      id: 'WL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      guest: guest,
      partySize: partySize,
      joinedAt: _simulatedCurrentTime,
    );
    _activeWaitlist.add(party);

    int etaMinutes = calculateWaitlistETA(partySize);
    _dispatchCommunication(
      guest,
      'SMS',
      "MaitreD: You are on the list! Estimated wait time is $etaMinutes minutes. We will text you when your table is ready.",
    );
    notifyListeners();
  }

  void notifyWaitlistPartyReady(String waitlistId) {
    final party = _activeWaitlist.firstWhere((w) => w.id == waitlistId);
    party.status = WaitlistStatus.notified;
    party.notifiedAt = _simulatedCurrentTime;
    _dispatchCommunication(
      party.guest,
      'SMS',
      "MaitreD: GREAT NEWS! Your table is ready. Please proceed to the host stand within 5 minutes.",
    );
    notifyListeners();
  }

  void seatWaitlistParty(String waitlistId, String tableId) {
    final party = _activeWaitlist.firstWhere((w) => w.id == waitlistId);
    party.status = WaitlistStatus.seated;
    _makeInternalReservation(
      party.guest,
      tableId,
      party.partySize,
      _simulatedCurrentTime,
      const Duration(minutes: 90),
      'Seated from waitlist',
    );
    updateTableStatus(tableId, TableStatus.occupied);
    notifyListeners();
  }

  int calculateWaitlistETA(int partySize) {
    // Advanced heuristic: based on queue position and active dining duration
    int partiesAhead = _activeWaitlist
        .where((w) => w.status == WaitlistStatus.waiting)
        .length;
    int baseWait = 15; // Base 15 mins
    return baseWait + (partiesAhead * 10);
  }

  // --- FLOOR & SEATING OPERATIONS ---

  void updateTableStatus(String tableId, TableStatus status) {
    final table = _floorPlanTables.firstWhere((t) => t.id == tableId);
    table.currentStatus = status;
    notifyListeners();
  }

  void seatReservation(String resId) {
    final res = _masterReservationLedger.firstWhere((r) => r.id == resId);
    res.status = ReservationStatus.seated;
    updateTableStatus(res.tableId, TableStatus.occupied);
  }

  void clearTable(String tableId) {
    updateTableStatus(tableId, TableStatus.dirty);
    // Find active seated reservation and mark complete
    try {
      final res = _masterReservationLedger.firstWhere(
        (r) => r.tableId == tableId && r.status == ReservationStatus.seated,
      );
      res.status = ReservationStatus.completed;
    } catch (e) {
      // Ignored if manually seated
    }
    notifyListeners();
  }

  // --- TELEMETRY & SIMULATION ENGINE ---

  void _startTemporalSimulation() {
    _simulationClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSimulationRunning) return;

      _simulatedCurrentTime = _simulatedCurrentTime.add(
        Duration(minutes: 1),
      ); // 1 sec real = 1 min sim
      _executeSimulationMatrixTick();
      notifyListeners();
    });
  }

  void _executeSimulationMatrixTick() {
    // 1. Auto-expire notified waitlist parties after 10 mins
    for (var w in _activeWaitlist) {
      if (w.status == WaitlistStatus.notified && w.notifiedAt != null) {
        if (_simulatedCurrentTime.difference(w.notifiedAt!).inMinutes > 10) {
          w.status = WaitlistStatus.abandoned;
          _dispatchCommunication(
            w.guest,
            'SMS',
            "MaitreD: You didn't arrive in time. We have released your spot to the next party.",
          );
        }
      }
    }

    // 2. Evaluate Table Status based on schedule
    for (var table in _floorPlanTables) {
      if (table.currentStatus == TableStatus.dirty ||
          table.currentStatus == TableStatus.maintenance)
        continue;

      bool isCurrentlyOccupied = _masterReservationLedger.any(
        (r) => r.tableId == table.id && r.status == ReservationStatus.seated,
      );
      bool isReservedSoon = _masterReservationLedger.any(
        (r) =>
            r.tableId == table.id &&
            r.status == ReservationStatus.confirmed &&
            r.startTime.difference(_simulatedCurrentTime).inMinutes > 0 &&
            r.startTime.difference(_simulatedCurrentTime).inMinutes <= 30,
      );

      if (isCurrentlyOccupied) {
        table.currentStatus = TableStatus.occupied;
      } else if (isReservedSoon) {
        table.currentStatus = TableStatus.reserved;
      } else {
        table.currentStatus = TableStatus.available;
      }
    }
  }

  void toggleSimulation() {
    _isSimulationRunning = !_isSimulationRunning;
    notifyListeners();
  }

  void _dispatchCommunication(GuestProfile guest, String type, String message) {
    _communicationLogs.insert(
      0,
      CommunicationLog(
        timestamp: _simulatedCurrentTime,
        recipient: guest.phoneNumber,
        type: type,
        payload: message,
      ),
    );
    if (_communicationLogs.length > 50)
      _communicationLogs.removeLast(); // Keep memory clean
  }

  void _dispatchSystemLog(String type, String message) {
    _communicationLogs.insert(
      0,
      CommunicationLog(
        timestamp: _simulatedCurrentTime,
        recipient: 'SYSTEM_ADMIN',
        type: type,
        payload: message,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _simulationClockTimer?.cancel();
    super.dispose();
  }
}

// State Provider Injector
class ReservationStateProvider extends StatefulWidget {
  final Widget child;
  const ReservationStateProvider({super.key, required this.child});

  static ReservationEngineController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedReservationProvider>();
    assert(
      result != null,
      'ReservationStateProvider not found in context tree',
    );
    return result!.controller;
  }

  @override
  State<ReservationStateProvider> createState() =>
      _ReservationStateProviderState();
}

class _ReservationStateProviderState extends State<ReservationStateProvider> {
  late ReservationEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = ReservationEngineController();
    controller.addListener(_onStateChange);
  }

  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_onStateChange);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedReservationProvider(
      controller: controller,
      child: widget.child,
    );
  }
}

class _InheritedReservationProvider extends InheritedWidget {
  final ReservationEngineController controller;
  const _InheritedReservationProvider({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _InheritedReservationProvider oldWidget) =>
      true;
}

// ==========================================
// 4. MAIN LAYOUT HUB (SHELL)
// ==========================================

class MasterReservationHub extends StatefulWidget {
  const MasterReservationHub({super.key});

  @override
  State<MasterReservationHub> createState() => _MasterReservationHubState();
}

class _MasterReservationHubState extends State<MasterReservationHub> {
  int _activeMenuIndex = 0;

  final List<Widget> _viewports = [
    const FloorPlanTelemetryView(),
    const MasterBookingDeskView(),
    const WaitlistManagementView(),
    const SystemCommunicationsLogView(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = ReservationStateProvider.of(context);
    final String formattedClock =
        "${controller.currentTime.hour.toString().padLeft(2, '0')}:${controller.currentTime.minute.toString().padLeft(2, '0')}";
    final activeWaitlistCount = controller.waitlist
        .where((w) => w.status == WaitlistStatus.waiting)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xff1e1e2c),
            selectedIndex: _activeMenuIndex,
            onDestinationSelected: (idx) =>
                setState(() => _activeMenuIndex = idx),
            extended: true,
            minExtendedWidth: 260,
            unselectedIconTheme: const IconThemeData(color: Color(0xff8b8b9e)),
            unselectedLabelTextStyle: const TextStyle(color: Color(0xff8b8b9e)),
            selectedIconTheme: const IconThemeData(
              color: Color(0xffd4af37),
            ), // Gold theme for high-end dining
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xffd4af37),
              fontWeight: FontWeight.bold,
            ),
            leading: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.restaurant,
                  color: Color(0xffd4af37),
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  "MaitreD",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  "ENTERPRISE CORE",
                  style: TextStyle(
                    color: Color(0xff8b8b9e),
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff2a2a3d),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xffd4af37).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedClock,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.grid_view),
                label: Text("Floor Plan & Seating"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.book_online),
                label: Text("Booking Desk"),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text('$activeWaitlistCount'),
                  isLabelVisible: activeWaitlistCount > 0,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.people_alt_outlined),
                ),
                selectedIcon: const Icon(Icons.people_alt),
                label: const Text("Waitlist & Yield"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.terminal),
                label: Text("Comms Dispatch Log"),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: InkWell(
                    onTap: () => controller.toggleSimulation(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: controller.isSimulationRunning
                            ? const Color(0xffdcfce7).withOpacity(0.1)
                            : const Color(0xfffee2e2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: controller.isSimulationRunning
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.isSimulationRunning
                                ? Icons.speed
                                : Icons.pause,
                            color: controller.isSimulationRunning
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.isSimulationRunning
                                ? "CLOCK RUNNING"
                                : "CLOCK PAUSED",
                            style: TextStyle(
                              color: controller.isSimulationRunning
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _viewports[_activeMenuIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. VIEW 1: INTERACTIVE FLOOR PLAN TELEMETRY
// ==========================================

class FloorPlanTelemetryView extends StatelessWidget {
  const FloorPlanTelemetryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ReservationStateProvider.of(context);

    // Calculate telemetry stats
    int totalCapacity = controller.tables.fold(0, (sum, t) => sum + t.capacity);
    int seatedGuests = controller.reservations
        .where((r) => r.status == ReservationStatus.seated)
        .fold(0, (sum, r) => sum + r.partySize);
    double occupancyRate = totalCapacity > 0
        ? (seatedGuests / totalCapacity) * 100
        : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Restaurant Topology & Seat Vector Control",
          style: TextStyle(
            color: Color(0xff1e1e2c),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Floor Plan Canvas
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffe2e8f0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: const Color(0xffcbd5e1), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Floor grid background texture
                      Positioned.fill(
                        child: CustomPaint(painter: GridBackgroundPainter()),
                      ),
                      // Dynamic interactive tables
                      ...controller.tables.map(
                        (table) => Positioned(
                          left: table.coordinates.dx,
                          top: table.coordinates.dy,
                          child: GestureDetector(
                            onTap: () => _showTableControlDialogue(
                              context,
                              table,
                              controller,
                            ),
                            child: CustomPaint(
                              size: table.dimensions,
                              painter: TableRenderer(table: table),
                            ),
                          ),
                        ),
                      ),
                      // Legend Box
                      Positioned(
                        bottom: 24,
                        right: 24,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _legendRow(
                                Colors.white,
                                "Available (Green Border)",
                              ),
                              _legendRow(const Color(0xffef4444), "Occupied"),
                              _legendRow(
                                const Color(0xfff59e0b),
                                "Reserved (< 30m)",
                              ),
                              _legendRow(
                                const Color(0xff94a3b8),
                                "Dirty / Bussing",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Sidebar Telemetry & Actions
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Yield Metrics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1e1e2c),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TelemetryCard(
                    title: "Current Floor Occupancy",
                    value: "${occupancyRate.toStringAsFixed(1)}%",
                    icon: Icons.pie_chart,
                    color: const Color(0xff3b82f6),
                  ),
                  const SizedBox(height: 12),
                  _TelemetryCard(
                    title: "Active Seated Guests",
                    value: "$seatedGuests",
                    icon: Icons.airline_seat_recline_normal,
                    color: const Color(0xff8b5cf6),
                  ),
                  const SizedBox(height: 12),
                  _TelemetryCard(
                    title: "Upcoming Covers (2H)",
                    value:
                        "${controller.reservations.where((r) => r.status == ReservationStatus.confirmed && r.startTime.difference(controller.currentTime).inHours < 2).length}",
                    icon: Icons.upcoming,
                    color: const Color(0xfff59e0b),
                  ),
                  const Divider(height: 48),
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1e1e2c),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff10b981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Seat Walk-In Party"),
                    onPressed: () {
                      // Stub for generic walk-in
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Select an available table on the floor plan to seat a walk-in.",
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showTableControlDialogue(
    BuildContext context,
    DiningTable table,
    ReservationEngineController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        // Find if occupied
        final currentRes = controller.reservations
            .cast<Reservation?>()
            .firstWhere(
              (r) =>
                  r?.tableId == table.id &&
                  r?.status == ReservationStatus.seated,
              orElse: () => null,
            );

        return AlertDialog(
          title: Text("Table ${table.label} Command Matrix"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hardware Capacity: ${table.capacity} Tops"),
              Text(
                "Current Status Matrix: ${table.currentStatus.name.toUpperCase()}",
              ),
              const SizedBox(height: 16),
              if (currentRes != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Active Cover Details",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Guest: ${currentRes.guest.fullName}"),
                      Text("Party Size: ${currentRes.partySize}"),
                      Text(
                        "Seated At: ${currentRes.startTime.hour}:${currentRes.startTime.minute.toString().padLeft(2, '0')}",
                      ),
                      if (currentRes.specialRequests.isNotEmpty)
                        Text(
                          "Notes: ${currentRes.specialRequests}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (table.currentStatus == TableStatus.available)
              TextButton(
                onPressed: () {
                  controller.updateTableStatus(
                    table.id,
                    TableStatus.occupied,
                  ); // Walk-in dummy trigger
                  Navigator.pop(context);
                },
                child: const Text("Seat Generic Walk-In"),
              ),
            if (table.currentStatus == TableStatus.occupied)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  controller.clearTable(table.id);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Bus Table (Mark Dirty)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            if (table.currentStatus == TableStatus.dirty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  controller.updateTableStatus(table.id, TableStatus.available);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Table Cleaned & Reset",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _TelemetryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff64748b),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xff1e1e2c),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter to render Grid Background
class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double step = 40.0;
    for (double i = 0; i < size.width; i += step)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += step)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter to render highly stylized tables and procedural chairs
class TableRenderer extends CustomPainter {
  final DiningTable table;

  TableRenderer({required this.table});

  @override
  void paint(Canvas canvas, Size size) {
    // Determine Color based on state matrix
    Color fill;
    Color stroke = Colors.black87;
    double strokeWidth = 2.0;

    switch (table.currentStatus) {
      case TableStatus.available:
        fill = Colors.white;
        stroke = const Color(0xff10b981); // Green available glow
        strokeWidth = 3.0;
        break;
      case TableStatus.occupied:
        fill = const Color(0xffef4444); // Red occupied
        break;
      case TableStatus.reserved:
        fill = const Color(0xfff59e0b); // Orange reserved warning
        break;
      case TableStatus.dirty:
        fill = const Color(0xff94a3b8); // Grey dirty
        stroke = Colors.black45;
        break;
      case TableStatus.maintenance:
        fill = Colors.black87;
        break;
    }

    final tablePaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final chairPaint = Paint()
      ..color = const Color(0xff64748b)
      ..style = PaintingStyle.fill;

    // Draw Shape Geometry
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (table.shape == TableShape.rectangle) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        tablePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );
      _drawRectangularChairs(canvas, size, chairPaint, table.capacity);
    } else if (table.shape == TableShape.circle) {
      canvas.drawCircle(rect.center, size.width / 2, tablePaint);
      canvas.drawCircle(rect.center, size.width / 2, borderPaint);
      _drawCircularChairs(canvas, size, chairPaint, table.capacity);
    } else if (table.shape == TableShape.booth) {
      canvas.drawRect(rect, tablePaint);
      canvas.drawRect(rect, borderPaint);
      // Draw Booth Cushions
      final cushionPaint = Paint()..color = const Color(0xff475569);
      canvas.drawRRect(
        RRect.fromLTRBR(0, -10, size.width, 10, const Radius.circular(4)),
        cushionPaint,
      ); // Top cushion
      canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          size.height - 10,
          size.width,
          size.height + 10,
          const Radius.circular(4),
        ),
        cushionPaint,
      ); // Bottom cushion
    }

    // Label Rendering
    final textPainter = TextPainter(
      text: TextSpan(
        text: table.label,
        style: TextStyle(
          color: fill == Colors.white ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawRectangularChairs(
    Canvas canvas,
    Size size,
    Paint paint,
    int capacity,
  ) {
    double chairSize = 14.0;
    int chairsPerSide = capacity ~/ 2;
    double spacing = size.width / (chairsPerSide + 1);

    for (int i = 1; i <= chairsPerSide; i++) {
      // Top Chairs
      canvas.drawCircle(Offset(spacing * i, -10), chairSize / 2, paint);
      // Bottom Chairs
      canvas.drawCircle(
        Offset(spacing * i, size.height + 10),
        chairSize / 2,
        paint,
      );
    }
  }

  void _drawCircularChairs(
    Canvas canvas,
    Size size,
    Paint paint,
    int capacity,
  ) {
    double chairSize = 14.0;
    double radius = (size.width / 2) + 12.0; // Distance from center

    for (int i = 0; i < capacity; i++) {
      double angle = (2 * math.pi / capacity) * i;
      double cx = size.width / 2 + radius * math.cos(angle);
      double cy = size.height / 2 + radius * math.sin(angle);
      canvas.drawCircle(Offset(cx, cy), chairSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TableRenderer oldDelegate) => true; // Dynamic state changes require constant repaints
}

// ==========================================
// 6. VIEW 2: MASTER BOOKING DESK FORM
// ==========================================

class MasterBookingDeskView extends StatefulWidget {
  const MasterBookingDeskView({super.key});

  @override
  State<MasterBookingDeskView> createState() => _MasterBookingDeskViewState();
}

class _MasterBookingDeskViewState extends State<MasterBookingDeskView> {
  final _formKey = GlobalKey<FormState>();

  String _clientName = "";
  String _clientPhone = "";
  int _partySize = 2;
  String _specialNotes = "";

  DateTime? _selectedTime;
  String? _selectedTableId;

  List<DiningTable> _availableTablesCaches = [];

  void _executeAvailabilityQuery(ReservationEngineController controller) {
    if (_selectedTime != null) {
      final endDuration = _selectedTime!.add(const Duration(minutes: 90));
      setState(() {
        _availableTablesCaches = controller.findAvailableTables(
          _selectedTime!,
          endDuration,
          _partySize,
        );
        _selectedTableId = null; // reset selection
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ReservationStateProvider.of(context);

    // Generate logical time slots ahead of simulation current time
    List<DateTime> timeSlots = [];
    DateTime slotCursor = controller.currentTime;
    // Round up to nearest 15 mins for UI cleanliness
    int remain = slotCursor.minute % 15;
    slotCursor = slotCursor.add(Duration(minutes: 15 - remain));

    for (int i = 0; i < 12; i++) {
      // Next 3 hours of slots
      timeSlots.add(slotCursor);
      slotCursor = slotCursor.add(const Duration(minutes: 15));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Digital Reservation Terminal",
          style: TextStyle(
            color: Color(0xff1e1e2c),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xffe2e8f0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Guest Demographics",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Full Guest Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Required validation fault" : null,
                            onSaved: (v) => _clientName = v!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Contact Phone (SMS Routing)",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Required validation fault" : null,
                            onSaved: (v) => _clientPhone = v!,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Temporal Parameters",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                "Party Size Vector: ",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Slider(
                                value: _partySize.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                label: _partySize.toString(),
                                activeColor: const Color(0xffd4af37),
                                onChanged: (v) {
                                  setState(() => _partySize = v.toInt());
                                  _executeAvailabilityQuery(controller);
                                },
                              ),
                              Text(
                                "$_partySize Tops",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<DateTime>(
                            decoration: const InputDecoration(
                              labelText: "Target Reservation Epoch",
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedTime,
                            items: timeSlots.map((time) {
                              return DropdownMenuItem(
                                value: time,
                                child: Text(
                                  "${time.hour}:${time.minute.toString().padLeft(2, '0')} (Expected Finish: ${time.add(const Duration(minutes: 90)).hour}:${time.add(const Duration(minutes: 90)).minute.toString().padLeft(2, '0')})",
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedTime = val);
                              _executeAvailabilityQuery(controller);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Dietary / VIP Notes",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            onSaved: (v) => _specialNotes = v ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Temporal Collision Matrix (Available Hardware)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xff1e1e2c),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedTime == null)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Define temporal parameters to execute geometric availability queries.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else if (_availableTablesCaches.isEmpty)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xfffee2e2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "YIELD CAPACITY EXCEEDED",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              "No tables support this party size within the requested epoch without double-booking.",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.queue_play_next),
                              label: const Text("Divert to Waitlist Queue"),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  controller.addToWaitlist(
                                    _clientName,
                                    _clientPhone,
                                    _partySize,
                                  );
                                  _formKey.currentState!.reset();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Party diverted to dynamic waitlist.",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: _availableTablesCaches.length,
                        itemBuilder: (context, index) {
                          final table = _availableTablesCaches[index];
                          bool isSelected = _selectedTableId == table.id;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedTableId = table.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xffd4af37).withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xffd4af37)
                                      : const Color(0xffe2e8f0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    table.shape == TableShape.booth
                                        ? Icons.chair_alt
                                        : Icons.table_restaurant,
                                    color: isSelected
                                        ? const Color(0xffd4af37)
                                        : Colors.grey,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Table ${table.label}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xffd4af37)
                                          : const Color(0xff1e1e2c),
                                    ),
                                  ),
                                  Text(
                                    "Max Tops: ${table.capacity}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Action Block
                  if (_availableTablesCaches.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1e1e2c),
                          foregroundColor: const Color(0xffd4af37),
                        ),
                        onPressed: _selectedTableId == null
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  bool success = controller
                                      .requestClientReservation(
                                        _clientName,
                                        _clientPhone,
                                        _partySize,
                                        _selectedTime!,
                                        _selectedTableId!,
                                        _specialNotes,
                                      );
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Reservation committed and confirmed securely.",
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                        backgroundColor: Color(0xff1e1e2c),
                                      ),
                                    );
                                    _formKey.currentState!.reset();
                                    setState(() {
                                      _selectedTime = null;
                                      _selectedTableId = null;
                                      _availableTablesCaches.clear();
                                    });
                                  }
                                }
                              },
                        child: const Text(
                          "COMMIT RESERVATION ALLOCATION",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. VIEW 3: DYNAMIC WAITLIST MANAGEMENT
// ==========================================

class WaitlistManagementView extends StatelessWidget {
  const WaitlistManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ReservationStateProvider.of(context);
    final activeList = controller.waitlist
        .where(
          (w) =>
              w.status == WaitlistStatus.waiting ||
              w.status == WaitlistStatus.notified,
        )
        .toList();

    // Sort logic: Waiting first, then notified
    activeList.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Yield & Queue Synchronization",
          style: TextStyle(
            color: Color(0xff1e1e2c),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricBadge(
                    "Parties In Queue",
                    "${activeList.length}",
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricBadge(
                    "Average Queue Depth Time",
                    "24m",
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricBadge(
                    "Abandonment Rate (Today)",
                    "4.2%",
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xffe2e8f0)),
                ),
                child: activeList.isEmpty
                    ? const Center(
                        child: Text(
                          "Queue structure is empty. Zero bottlenecks detected.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: activeList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final party = activeList[index];
                          final waitMins = controller.currentTime
                              .difference(party.joinedAt)
                              .inMinutes;
                          final isNotified =
                              party.status == WaitlistStatus.notified;

                          return ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: isNotified
                                  ? const Color(0xffdcfce7)
                                  : const Color(0xfff1f5f9),
                              radius: 24,
                              child: Icon(
                                isNotified
                                    ? Icons.notifications_active
                                    : Icons.hourglass_empty,
                                color: isNotified ? Colors.green : Colors.grey,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  party.guest.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (party.guest.isVIP) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffd4af37),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "VIP",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  "Party of ${party.partySize} | Wait Duration: $waitMins mins",
                                ),
                                if (isNotified)
                                  Text(
                                    "Dispatch Webhook Sent: ${party.notifiedAt!.hour}:${party.notifiedAt!.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isNotified
                                ? ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff1e1e2c),
                                      foregroundColor: const Color(0xffd4af37),
                                    ),
                                    icon: const Icon(Icons.event_seat),
                                    label: const Text("Assign Hardware (Seat)"),
                                    onPressed: () =>
                                        _showSeatAssignmentDialogue(
                                          context,
                                          controller,
                                          party,
                                        ),
                                  )
                                : OutlinedButton.icon(
                                    icon: const Icon(Icons.sms),
                                    label: const Text(
                                      "Ping Webhook (Notify Ready)",
                                    ),
                                    onPressed: () => controller
                                        .notifyWaitlistPartyReady(party.id),
                                  ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge(String label, String val, Color c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _showSeatAssignmentDialogue(
    BuildContext context,
    ReservationEngineController controller,
    WaitlistParty party,
  ) {
    // Find free tables that fit the party
    final freeTables = controller.tables
        .where(
          (t) =>
              t.currentStatus == TableStatus.available &&
              t.capacity >= party.partySize,
        )
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Seat Vector Assignment: ${party.guest.fullName}"),
          content: SizedBox(
            width: double.maxFinite,
            child: freeTables.isEmpty
                ? const Text(
                    "Warning: No clean hardware available with required topological capacity.",
                    style: TextStyle(color: Colors.red),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: freeTables.length,
                    itemBuilder: (context, i) {
                      final t = freeTables[i];
                      return ListTile(
                        leading: const Icon(Icons.table_restaurant),
                        title: Text(
                          "Table ${t.label} (Capacity: ${t.capacity})",
                        ),
                        trailing: ElevatedButton(
                          child: const Text("Commit Seat"),
                          onPressed: () {
                            controller.seatWaitlistParty(party.id, t.id);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel Allocation"),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// 8. VIEW 4: COMMUNICATIONS DISPATCH LOG
// ==========================================

class SystemCommunicationsLogView extends StatelessWidget {
  const SystemCommunicationsLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ReservationStateProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xff0f172a), // Terminal theme
      appBar: AppBar(
        title: const Text(
          "Twilio/SendGrid Payload Webhook Inspector",
          style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
        ),
        backgroundColor: const Color(0xff1e293b),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.commLogs.length,
        itemBuilder: (context, index) {
          final log = controller.commLogs[index];
          final timeStr =
              "[${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}]";

          Color typeColor = Colors.blueAccent;
          if (log.type == 'CRITICAL COLLISION AVOIDED')
            typeColor = Colors.redAccent;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.white70,
                ),
                children: [
                  TextSpan(
                    text: "$timeStr ",
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                  TextSpan(
                    text: "<${log.type}> ",
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: "TO:${log.recipient} ",
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                  TextSpan(text: "=> ${log.payload}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
