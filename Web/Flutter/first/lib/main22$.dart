import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const TransitLinkApp());
}

class TransitLinkApp extends StatelessWidget {
  const TransitLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransitStateProvider(
      child: MaterialApp(
        title: 'TransitLink Bus Reservations',
        debugShowCheckedModeBanner: false,
        home: MasterTransitTerminal(),
      ),
    );
  }
}

// ==========================================
// 1. GLOBAL ENUMS & CONSTANTS
// ==========================================

enum SeatStatus { available, locked, booked }

enum AppStep { search, results, seatSelection, checkout, ticket }

const List<String> transitHubs = [
  'New York',
  'Boston',
  'Washington DC',
  'Philadelphia',
  'Chicago',
  'Detroit',
  'Columbus',
  'Indianapolis',
];

const List<String> operators = [
  'ExpressLine',
  'InterCity Transit',
  'NightRider Coach',
  'PrimeBus',
];

// ==========================================
// 2. CORE DATA MODELS
// ==========================================

class BusSeat {
  final String id; // e.g., 1A, 10D
  final int row;
  final String letter;
  SeatStatus status;
  DateTime? lockedUntil;

  BusSeat({
    required this.id,
    required this.row,
    required this.letter,
    this.status = SeatStatus.available,
    this.lockedUntil,
  });

  bool get isLocked =>
      status == SeatStatus.locked &&
      lockedUntil != null &&
      lockedUntil!.isAfter(DateTime.now());

  void unlockIfExpired() {
    if (status == SeatStatus.locked &&
        lockedUntil != null &&
        DateTime.now().isAfter(lockedUntil!)) {
      status = SeatStatus.available;
      lockedUntil = null;
    }
  }
}

class BusTrip {
  final String tripId;
  final String operatorName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final Map<String, BusSeat> seatMap;

  BusTrip({
    required this.tripId,
    required this.operatorName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.seatMap,
  });

  Duration get duration => arrivalTime.difference(departureTime);
}

class BusTicket {
  final String ticketId;
  final String passengerName;
  final BusTrip trip;
  final BusSeat seat;
  final double amountPaid;
  final DateTime issuedAt;

  const BusTicket({
    required this.ticketId,
    required this.passengerName,
    required this.trip,
    required this.seat,
    required this.amountPaid,
    required this.issuedAt,
  });
}

// ==========================================
// 3. ENTERPRISE STATE MANAGEMENT & LOCKING ENGINE
// ==========================================

class TransitEngineController extends ChangeNotifier {
  final List<BusTrip> _masterSchedule = [];
  final List<BusTicket> _issuedTickets = [];

  // Active Session State
  AppStep currentStep = AppStep.search;
  BusTrip? selectedTrip;
  BusSeat? selectedSeat;
  String passengerName = '';

  // Search Filters
  String? searchOrigin;
  String? searchDestination;
  DateTime? searchDate;
  List<BusTrip> searchResults = [];

  // Locking Timer
  Timer? _lockTimer;
  int remainingLockSeconds = 0;

  TransitEngineController() {
    _seedEnterpriseMockData();
    // Background worker to periodically clear expired locks system-wide
    Timer.periodic(const Duration(seconds: 5), (_) => _purgeExpiredLocks());
  }

  void _seedEnterpriseMockData() {
    final rand = math.Random();
    final now = DateTime.now();

    for (int i = 0; i < 200; i++) {
      String origin = transitHubs[rand.nextInt(transitHubs.length)];
      String dest;
      do {
        dest = transitHubs[rand.nextInt(transitHubs.length)];
      } while (dest == origin);

      DateTime dep = now.add(
        Duration(days: rand.nextInt(14), hours: rand.nextInt(24)),
      );
      DateTime arr = dep.add(
        Duration(hours: rand.nextInt(5) + 2, minutes: rand.nextInt(60)),
      );

      _masterSchedule.add(
        BusTrip(
          tripId: 'TRP-${rand.nextInt(9000) + 1000}',
          operatorName: operators[rand.nextInt(operators.length)],
          origin: origin,
          destination: dest,
          departureTime: dep,
          arrivalTime: arr,
          price: 25.0 + rand.nextInt(80),
          seatMap: _generateBusTopology(),
        ),
      );
    }
  }

  Map<String, BusSeat> _generateBusTopology() {
    Map<String, BusSeat> seats = {};
    final rand = math.Random();

    // Standard Coach: 14 rows, 4 seats per row (A, B) Aisle (C, D)
    for (int r = 1; r <= 14; r++) {
      for (String l in ['A', 'B', 'C', 'D']) {
        // Randomly pre-book some seats, rarely lock some
        double chance = rand.nextDouble();
        SeatStatus initialStatus = SeatStatus.available;
        DateTime? lockTime;

        if (chance > 0.85) {
          initialStatus = SeatStatus.booked;
        } else if (chance > 0.80) {
          initialStatus = SeatStatus.locked;
          lockTime = DateTime.now().add(Duration(seconds: rand.nextInt(120)));
        }

        seats['$r$l'] = BusSeat(
          id: '$r$l',
          row: r,
          letter: l,
          status: initialStatus,
          lockedUntil: lockTime,
        );
      }
    }
    return seats;
  }

  void _purgeExpiredLocks() {
    bool changesMade = false;
    for (var trip in _masterSchedule) {
      for (var seat in trip.seatMap.values) {
        if (seat.status == SeatStatus.locked &&
            seat.lockedUntil != null &&
            DateTime.now().isAfter(seat.lockedUntil!)) {
          seat.status = SeatStatus.available;
          seat.lockedUntil = null;
          changesMade = true;
        }
      }
    }
    if (changesMade) notifyListeners();
  }

  // --- ACTIONS ---

  void executeSearch(String origin, String dest, DateTime date) {
    searchOrigin = origin;
    searchDestination = dest;
    searchDate = date;

    searchResults = _masterSchedule.where((t) {
      return t.origin == origin &&
          t.destination == dest &&
          t.departureTime.year == date.year &&
          t.departureTime.month == date.month &&
          t.departureTime.day == date.day;
    }).toList();

    searchResults.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    currentStep = AppStep.results;
    notifyListeners();
  }

  void selectTrip(BusTrip trip) {
    selectedTrip = trip;
    selectedSeat = null;
    currentStep = AppStep.seatSelection;
    notifyListeners();
  }

  bool initiateSeatLock(BusSeat seat) {
    // Refresh lock state first
    seat.unlockIfExpired();

    if (seat.status != SeatStatus.available) return false;

    // Release any previously held seat by this user
    if (selectedSeat != null) {
      selectedTrip!.seatMap[selectedSeat!.id]!.status = SeatStatus.available;
      selectedTrip!.seatMap[selectedSeat!.id]!.lockedUntil = null;
    }

    // Lock new seat for 60 seconds
    seat.status = SeatStatus.locked;
    seat.lockedUntil = DateTime.now().add(const Duration(seconds: 60));
    selectedSeat = seat;

    _startLockCountdown(60);
    currentStep = AppStep.checkout;
    notifyListeners();
    return true;
  }

  void _startLockCountdown(int seconds) {
    _lockTimer?.cancel();
    remainingLockSeconds = seconds;
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingLockSeconds > 0) {
        remainingLockSeconds--;
        notifyListeners();
      } else {
        _handleLockExpiration();
      }
    });
  }

  void _handleLockExpiration() {
    _lockTimer?.cancel();
    if (selectedSeat != null && currentStep == AppStep.checkout) {
      // Revert seat
      selectedTrip!.seatMap[selectedSeat!.id]!.status = SeatStatus.available;
      selectedTrip!.seatMap[selectedSeat!.id]!.lockedUntil = null;
      selectedSeat = null;

      // Kick user back to seat selection
      currentStep = AppStep.seatSelection;
      notifyListeners();
    }
  }

  Future<bool> processPaymentAndTicket(String name) async {
    if (selectedSeat == null || remainingLockSeconds <= 0) return false;

    passengerName = name;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Final security check: Has the lock expired during processing?
    if (DateTime.now().isAfter(selectedSeat!.lockedUntil!)) {
      _handleLockExpiration();
      return false;
    }

    // Success! Finalize Booking.
    _lockTimer?.cancel();
    selectedTrip!.seatMap[selectedSeat!.id]!.status = SeatStatus.booked;
    selectedTrip!.seatMap[selectedSeat!.id]!.lockedUntil = null;

    final ticket = BusTicket(
      ticketId: 'TKT-${math.Random().nextInt(900000) + 100000}',
      passengerName: passengerName,
      trip: selectedTrip!,
      seat: selectedSeat!,
      amountPaid: selectedTrip!.price,
      issuedAt: DateTime.now(),
    );

    _issuedTickets.add(ticket);
    currentStep = AppStep.ticket;
    notifyListeners();
    return true;
  }

  void resetSession() {
    _lockTimer?.cancel();
    if (selectedSeat != null && selectedSeat!.status == SeatStatus.locked) {
      selectedTrip!.seatMap[selectedSeat!.id]!.status = SeatStatus.available;
      selectedTrip!.seatMap[selectedSeat!.id]!.lockedUntil = null;
    }
    selectedTrip = null;
    selectedSeat = null;
    passengerName = '';
    currentStep = AppStep.search;
    notifyListeners();
  }

  void goBack() {
    if (currentStep == AppStep.ticket) {
      resetSession();
    } else if (currentStep == AppStep.checkout) {
      // Cancel lock
      _lockTimer?.cancel();
      selectedTrip!.seatMap[selectedSeat!.id]!.status = SeatStatus.available;
      selectedTrip!.seatMap[selectedSeat!.id]!.lockedUntil = null;
      selectedSeat = null;
      currentStep = AppStep.seatSelection;
    } else if (currentStep == AppStep.seatSelection) {
      currentStep = AppStep.results;
    } else if (currentStep == AppStep.results) {
      currentStep = AppStep.search;
    }
    notifyListeners();
  }

  List<BusTicket> get issuedTickets => List.unmodifiable(_issuedTickets);

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}

// State Injector
class TransitStateProvider extends StatefulWidget {
  final Widget child;
  const TransitStateProvider({super.key, required this.child});

  static TransitEngineController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedTransitProvider>();
    assert(result != null, 'TransitStateProvider not found in context tree');
    return result!.controller;
  }

  @override
  State<TransitStateProvider> createState() => _TransitStateProviderState();
}

class _TransitStateProviderState extends State<TransitStateProvider> {
  late TransitEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = TransitEngineController();
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
    return _InheritedTransitProvider(
      controller: controller,
      child: widget.child,
    );
  }
}

class _InheritedTransitProvider extends InheritedWidget {
  final TransitEngineController controller;
  const _InheritedTransitProvider({
    required this.controller,
    required super.child,
  });
  @override
  bool updateShouldNotify(covariant _InheritedTransitProvider oldWidget) =>
      true;
}

// ==========================================
// 4. MAIN LAYOUT HUB (SHELL)
// ==========================================

class MasterTransitTerminal extends StatelessWidget {
  const MasterTransitTerminal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TransitStateProvider.of(context);

    Widget activeView;
    switch (controller.currentStep) {
      case AppStep.search:
        activeView = const RouteSearchView();
        break;
      case AppStep.results:
        activeView = const TripResultsView();
        break;
      case AppStep.seatSelection:
        activeView = const SeatSelectionView();
        break;
      case AppStep.checkout:
        activeView = const CheckoutAndLockView();
        break;
      case AppStep.ticket:
        activeView = const TicketView();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e293b),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.directions_bus, color: Color(0xfffbbf24)),
            SizedBox(width: 12),
            Text(
              "TransitLink",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading: controller.currentStep != AppStep.search
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => controller.goBack(),
              )
            : null,
        actions: [
          if (controller.currentStep == AppStep.checkout)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffef4444),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Lock Expires in 00:${controller.remainingLockSeconds.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: activeView,
      ),
    );
  }
}

// ==========================================
// 5. VIEW 1: ROUTE SEARCH ENGINE
// ==========================================

class RouteSearchView extends StatefulWidget {
  const RouteSearchView({super.key});

  @override
  State<RouteSearchView> createState() => _RouteSearchViewState();
}

class _RouteSearchViewState extends State<RouteSearchView> {
  String? _origin;
  String? _dest;
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final controller = TransitStateProvider.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Where to next?",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Search hundreds of daily routes across the country.",
              style: TextStyle(fontSize: 18, color: Color(0xff64748b)),
            ),
            const SizedBox(height: 48),
            Card(
              elevation: 8,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Leaving From",
                        prefixIcon: const Icon(Icons.my_location),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: _origin,
                      items: transitHubs
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(h)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _origin = v),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Going To",
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: _dest,
                      items: transitHubs
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(h)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _dest = v),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (selected != null) setState(() => _date = selected);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Travel Date",
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xfffbbf24),
                          foregroundColor: const Color(0xff0f172a),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            _origin != null && _dest != null && _origin != _dest
                            ? () => controller.executeSearch(
                                _origin!,
                                _dest!,
                                _date,
                              )
                            : null,
                        child: const Text(
                          "FIND BUSES",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
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
}

// ==========================================
// 6. VIEW 2: SEARCH RESULTS
// ==========================================

class TripResultsView extends StatelessWidget {
  const TripResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TransitStateProvider.of(context);

    if (controller.searchResults.isEmpty) {
      return const Center(
        child: Text(
          "No trips available for this route on the selected date.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final trip = controller.searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.operatorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff3b82f6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _TimeBlock(
                            time: trip.departureTime,
                            location: trip.origin,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.grey,
                            ),
                          ),
                          _TimeBlock(
                            time: trip.arrivalTime,
                            location: trip.destination,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${trip.duration.inHours}h ${trip.duration.inMinutes % 60}m direct",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${trip.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff10b981),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0f172a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => controller.selectTrip(trip),
                        child: const Text(
                          "SELECT SEAT",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final DateTime time;
  final String location;
  const _TimeBlock({required this.time, required this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xff0f172a),
          ),
        ),
        Text(
          location,
          style: const TextStyle(
            color: Color(0xff64748b),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 7. VIEW 3: SEAT SELECTION
// ==========================================

class SeatSelectionView extends StatelessWidget {
  const SeatSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TransitStateProvider.of(context);
    final trip = controller.selectedTrip!;

    return Row(
      children: [
        // Bus Topography
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xfff1f5f9),
            child: Center(
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(48),
                  border: Border.all(color: const Color(0xffcbd5e1), width: 4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 20),
                  ],
                ),
                child: Column(
                  children: [
                    // Driver area
                    Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xffcbd5e1),
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.drive_eta,
                          size: 40,
                          color: Color(0xff94a3b8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 24,
                        ),
                        itemCount: 14, // 14 rows
                        itemBuilder: (context, index) {
                          int row = index + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _SeatWidget(seat: trip.seatMap['${row}A']!),
                                    const SizedBox(width: 8),
                                    _SeatWidget(seat: trip.seatMap['${row}B']!),
                                  ],
                                ),
                                // Aisle
                                SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Text(
                                      row.toString(),
                                      style: const TextStyle(
                                        color: Color(0xffcbd5e1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    _SeatWidget(seat: trip.seatMap['${row}C']!),
                                    const SizedBox(width: 8),
                                    _SeatWidget(seat: trip.seatMap['${row}D']!),
                                  ],
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
          ),
        ),
        // Legend & Selection info
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Your Seat",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 32),
                _LegendItem(
                  color: Colors.white,
                  borderColor: const Color(0xffcbd5e1),
                  text: "Available",
                ),
                const SizedBox(height: 12),
                _LegendItem(
                  color: const Color(0xfffbbf24),
                  borderColor: const Color(0xffd97706),
                  text: "Locked (In Checkout)",
                ),
                const SizedBox(height: 12),
                _LegendItem(
                  color: const Color(0xff94a3b8),
                  borderColor: const Color(0xff64748b),
                  text: "Booked",
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xff0f172a),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Information",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Selecting an available seat will securely lock it for 60 seconds while you complete checkout.",
                        style: TextStyle(color: Colors.white, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String text;

  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final BusSeat seat;

  const _SeatWidget({required this.seat});

  @override
  Widget build(BuildContext context) {
    final controller = TransitStateProvider.of(context);

    // Ensure accurate visual representation if lock naturally expired without system purge
    seat.unlockIfExpired();

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xffcbd5e1);
    Color textColor = const Color(0xff64748b);

    if (seat.status == SeatStatus.booked) {
      bgColor = const Color(0xfff1f5f9);
      borderColor = const Color(0xff94a3b8);
      textColor = const Color(0xff94a3b8);
    } else if (seat.status == SeatStatus.locked) {
      bgColor = const Color(0xfffef3c7);
      borderColor = const Color(0xfffbbf24);
      textColor = const Color(0xffd97706);
    }

    return GestureDetector(
      onTap: () {
        if (seat.status == SeatStatus.available) {
          bool locked = controller.initiateSeatLock(seat);
          if (!locked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Seat could not be locked. It may have just been taken.",
                ),
              ),
            );
          }
        } else if (seat.status == SeatStatus.locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "This seat is currently locked by another user in checkout.",
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: seat.status == SeatStatus.booked
              ? const Icon(Icons.close, color: Color(0xff94a3b8), size: 20)
              : seat.status == SeatStatus.locked
              ? const Icon(Icons.lock, color: Color(0xfffbbf24), size: 18)
              : Text(
                  seat.id,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
      ),
    );
  }
}

// ==========================================
// 8. VIEW 4: CHECKOUT AND LOCK
// ==========================================

class CheckoutAndLockView extends StatefulWidget {
  const CheckoutAndLockView({super.key});

  @override
  State<CheckoutAndLockView> createState() => _CheckoutAndLockViewState();
}

class _CheckoutAndLockViewState extends State<CheckoutAndLockView> {
  final _nameController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final controller = TransitStateProvider.of(context);
    final trip = controller.selectedTrip!;
    final seat = controller.selectedSeat!;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Secure Checkout",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Seat ${seat.id} is locked for you.",
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xff10b981),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        "\$${trip.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff0f172a),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 48),
                  const Text(
                    "Passenger Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Legal Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff10b981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.payment),
                        label: const Text(
                          "PAY & CONFIRM BOOKING",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        onPressed: () async {
                          if (_nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter passenger name."),
                              ),
                            );
                            return;
                          }
                          setState(() => _isProcessing = true);
                          bool success = await controller
                              .processPaymentAndTicket(_nameController.text);
                          if (!mounted) return;
                          setState(() => _isProcessing = false);
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "LOCK EXPIRED or error occurred. Returning to seat selection.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
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

// ==========================================
// 9. VIEW 5: DIGITAL TICKET
// ==========================================

class TicketView extends StatelessWidget {
  const TicketView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TransitStateProvider.of(context);
    final ticket = controller.issuedTickets.last;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Color(0xff10b981), size: 80),
          const SizedBox(height: 16),
          const Text(
            "Booking Confirmed!",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 48),

          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xff1e293b),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket.trip.operatorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ticket.ticketId,
                        style: const TextStyle(
                          color: Color(0xfffbbf24),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      _TicketRow(
                        label: "Passenger",
                        value: ticket.passengerName.toUpperCase(),
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _TicketRow(
                              label: "From",
                              value: ticket.trip.origin,
                              isLarge: true,
                            ),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.grey),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _TicketRow(
                                label: "To",
                                value: ticket.trip.destination,
                                isLarge: true,
                                alignRight: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _TicketRow(
                            label: "Date",
                            value:
                                "${ticket.trip.departureTime.month}/${ticket.trip.departureTime.day}/${ticket.trip.departureTime.year}",
                          ),
                          _TicketRow(
                            label: "Time",
                            value:
                                "${ticket.trip.departureTime.hour}:${ticket.trip.departureTime.minute.toString().padLeft(2, '0')}",
                          ),
                          _TicketRow(
                            label: "Seat",
                            value: ticket.seat.id,
                            color: const Color(0xff3b82f6),
                            isLarge: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xfff1f5f9),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://upload.wikimedia.org/wikipedia/commons/e/e9/UPC-A-036000291452.svg",
                      ),
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => controller.resetSession(),
            child: const Text("Book Another Trip"),
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLarge;
  final bool alignRight;
  final Color? color;

  const _TicketRow({
    required this.label,
    required this.value,
    this.isLarge = false,
    this.alignRight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 20 : 16,
            fontWeight: FontWeight.w900,
            color: color ?? const Color(0xff0f172a),
          ),
        ),
      ],
    );
  }
}
