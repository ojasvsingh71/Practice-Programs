import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

void main() {
  runApp(const SkyNetAviationApp());
}

class SkyNetAviationApp extends StatelessWidget {
  const SkyNetAviationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AviationStateProvider(
      child: MaterialApp(
        title: 'SkyNet Booking Terminal',
        debugShowCheckedModeBanner: false,
        home: MasterBookingTerminal(),
      ),
    );
  }
}

// ==========================================
// 1. GLOBAL ENUMS & CONSTANTS
// ==========================================

enum SeatClass { economy, business, first }

enum FlightStatus { scheduled, delayed, boarding, departed }

enum BookingStep { search, seatSelection, checkout, boardingPass }

const List<String> globalHubs = [
  'New York (JFK)',
  'London (LHR)',
  'Tokyo (HND)',
  'Dubai (DXB)',
  'Paris (CDG)',
  'Singapore (SIN)',
  'Los Angeles (LAX)',
  'Sydney (SYD)',
];

const List<String> airlines = [
  'Oceanic Airlines',
  'Global Airways',
  'Starlight Aviation',
];

// ==========================================
// 2. CORE DATA MODELS
// ==========================================

class AircraftSeat {
  final String id; // e.g., 1A, 12C
  final int row;
  final String letter;
  final SeatClass seatClass;
  bool isBooked;

  AircraftSeat({
    required this.id,
    required this.row,
    required this.letter,
    required this.seatClass,
    this.isBooked = false,
  });

  double get priceMultiplier {
    switch (seatClass) {
      case SeatClass.first:
        return 3.5;
      case SeatClass.business:
        return 2.0;
      case SeatClass.economy:
        return 1.0;
    }
  }
}

class FlightRoute {
  final String flightNumber;
  final String airline;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double baseFare;
  final FlightStatus status;
  final Map<String, AircraftSeat> seatMap;

  FlightRoute({
    required this.flightNumber,
    required this.airline,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.baseFare,
    this.status = FlightStatus.scheduled,
    required this.seatMap,
  });

  Duration get duration => arrivalTime.difference(departureTime);
}

class DiscountCoupon {
  final String code;
  final double discountMultiplier; // 0.20 for 20% off
  final bool isValid;

  const DiscountCoupon({
    required this.code,
    required this.discountMultiplier,
    this.isValid = true,
  });
}

class BoardingPass {
  final String pnr;
  final String passengerName;
  final FlightRoute flight;
  final AircraftSeat seat;
  final double baseFare;
  final double taxes;
  final double discount;
  final double totalPaid;
  final DateTime issuedAt;

  const BoardingPass({
    required this.pnr,
    required this.passengerName,
    required this.flight,
    required this.seat,
    required this.baseFare,
    required this.taxes,
    required this.discount,
    required this.totalPaid,
    required this.issuedAt,
  });
}

// ==========================================
// 3. ENTERPRISE STATE MANAGEMENT ENGINE
// ==========================================

class FlightEngineController extends ChangeNotifier {
  final List<FlightRoute> _masterFlightDatabase = [];
  final Map<String, DiscountCoupon> _couponDatabase = {
    'FLY20': const DiscountCoupon(code: 'FLY20', discountMultiplier: 0.20),
    'VIP50': const DiscountCoupon(code: 'VIP50', discountMultiplier: 0.50),
    'SUMMER10': const DiscountCoupon(
      code: 'SUMMER10',
      discountMultiplier: 0.10,
    ),
  };
  final List<BoardingPass> _issuedTickets = [];

  // Active Session State
  BookingStep currentStep = BookingStep.search;
  FlightRoute? selectedFlight;
  AircraftSeat? selectedSeat;
  DiscountCoupon? activeCoupon;
  String passengerName = '';

  // Search Filters
  String? searchOrigin;
  String? searchDestination;
  DateTime? searchDate;
  List<FlightRoute> searchResults = [];

  FlightEngineController() {
    _seedEnterpriseMockData();
  }

  void _seedEnterpriseMockData() {
    final rand = math.Random();
    final now = DateTime.now();

    for (int i = 0; i < 150; i++) {
      String origin = globalHubs[rand.nextInt(globalHubs.length)];
      String dest;
      do {
        dest = globalHubs[rand.nextInt(globalHubs.length)];
      } while (dest == origin);

      DateTime dep = now.add(
        Duration(days: rand.nextInt(30), hours: rand.nextInt(24)),
      );
      DateTime arr = dep.add(
        Duration(hours: rand.nextInt(12) + 2, minutes: rand.nextInt(60)),
      );

      _masterFlightDatabase.add(
        FlightRoute(
          flightNumber:
              '${airlines[rand.nextInt(airlines.length)].substring(0, 2).toUpperCase()}${rand.nextInt(900) + 100}',
          airline: airlines[rand.nextInt(airlines.length)],
          origin: origin,
          destination: dest,
          departureTime: dep,
          arrivalTime: arr,
          baseFare: 150.0 + rand.nextInt(600),
          seatMap: _generateAircraftTopology(),
        ),
      );
    }
  }

  Map<String, AircraftSeat> _generateAircraftTopology() {
    Map<String, AircraftSeat> seats = {};
    final rand = math.Random();

    // First Class (Rows 1-2, 4 seats: A, B, E, F)
    for (int r = 1; r <= 2; r++) {
      for (String l in ['A', 'B', 'E', 'F']) {
        seats['$r$l'] = AircraftSeat(
          id: '$r$l',
          row: r,
          letter: l,
          seatClass: SeatClass.first,
          isBooked: rand.nextDouble() > 0.7,
        );
      }
    }
    // Business Class (Rows 3-6, 6 seats: A, B, C, D, E, F)
    for (int r = 3; r <= 6; r++) {
      for (String l in ['A', 'B', 'C', 'D', 'E', 'F']) {
        seats['$r$l'] = AircraftSeat(
          id: '$r$l',
          row: r,
          letter: l,
          seatClass: SeatClass.business,
          isBooked: rand.nextDouble() > 0.6,
        );
      }
    }
    // Economy Class (Rows 7-25, 6 seats: A, B, C, D, E, F)
    for (int r = 7; r <= 25; r++) {
      for (String l in ['A', 'B', 'C', 'D', 'E', 'F']) {
        seats['$r$l'] = AircraftSeat(
          id: '$r$l',
          row: r,
          letter: l,
          seatClass: SeatClass.economy,
          isBooked: rand.nextDouble() > 0.4,
        );
      }
    }
    return seats;
  }

  // --- ACTIONS ---

  void executeSearch(String origin, String dest, DateTime date) {
    searchOrigin = origin;
    searchDestination = dest;
    searchDate = date;

    searchResults = _masterFlightDatabase.where((f) {
      return f.origin == origin &&
          f.destination == dest &&
          f.departureTime.year == date.year &&
          f.departureTime.month == date.month &&
          f.departureTime.day == date.day;
    }).toList();

    searchResults.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    notifyListeners();
  }

  void selectFlightForBooking(FlightRoute flight) {
    selectedFlight = flight;
    selectedSeat = null;
    activeCoupon = null;
    currentStep = BookingStep.seatSelection;
    notifyListeners();
  }

  void selectSeat(AircraftSeat seat) {
    if (seat.isBooked) return;
    selectedSeat = seat;
    notifyListeners();
  }

  void proceedToCheckout() {
    if (selectedSeat != null) {
      currentStep = BookingStep.checkout;
      notifyListeners();
    }
  }

  bool applyCoupon(String code) {
    final coupon = _couponDatabase[code.toUpperCase()];
    if (coupon != null && coupon.isValid) {
      activeCoupon = coupon;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> processPaymentAndTicket(String name) async {
    passengerName = name;
    notifyListeners();

    // Simulate network/payment delay
    await Future.delayed(const Duration(seconds: 2));

    // Double-booking check
    if (selectedFlight!.seatMap[selectedSeat!.id]!.isBooked) {
      return false; // Collision occurred
    }

    // Lock seat
    selectedFlight!.seatMap[selectedSeat!.id]!.isBooked = true;

    // Financials
    double fare = selectedFlight!.baseFare * selectedSeat!.priceMultiplier;
    double taxes = fare * 0.15;
    double discount = activeCoupon != null
        ? (fare + taxes) * activeCoupon!.discountMultiplier
        : 0.0;
    double total = (fare + taxes) - discount;

    final pass = BoardingPass(
      pnr: 'SKY${math.Random().nextInt(90000) + 10000}',
      passengerName: passengerName,
      flight: selectedFlight!,
      seat: selectedSeat!,
      baseFare: fare,
      taxes: taxes,
      discount: discount,
      totalPaid: total,
      issuedAt: DateTime.now(),
    );

    _issuedTickets.add(pass);
    currentStep = BookingStep.boardingPass;
    notifyListeners();
    return true;
  }

  void resetSession() {
    selectedFlight = null;
    selectedSeat = null;
    activeCoupon = null;
    passengerName = '';
    currentStep = BookingStep.search;
    notifyListeners();
  }

  List<BoardingPass> get issuedTickets => List.unmodifiable(_issuedTickets);
}

// State Injector
class AviationStateProvider extends StatefulWidget {
  final Widget child;
  const AviationStateProvider({super.key, required this.child});

  static FlightEngineController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedAviationProvider>();
    assert(result != null, 'AviationStateProvider not found in context tree');
    return result!.controller;
  }

  @override
  State<AviationStateProvider> createState() => _AviationStateProviderState();
}

class _AviationStateProviderState extends State<AviationStateProvider> {
  late FlightEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = FlightEngineController();
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
    return _InheritedAviationProvider(
      controller: controller,
      child: widget.child,
    );
  }
}

class _InheritedAviationProvider extends InheritedWidget {
  final FlightEngineController controller;
  const _InheritedAviationProvider({
    required this.controller,
    required super.child,
  });
  @override
  bool updateShouldNotify(covariant _InheritedAviationProvider oldWidget) =>
      true;
}

// ==========================================
// 4. MAIN LAYOUT HUB (SHELL)
// ==========================================

class MasterBookingTerminal extends StatelessWidget {
  const MasterBookingTerminal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AviationStateProvider.of(context);

    Widget activeView;
    switch (controller.currentStep) {
      case BookingStep.search:
        activeView = const FlightSearchView();
        break;
      case BookingStep.seatSelection:
        activeView = const SeatSelectionView();
        break;
      case BookingStep.checkout:
        activeView = const CheckoutView();
        break;
      case BookingStep.boardingPass:
        activeView = const BoardingPassView();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff1f5f9),
      body: Row(
        children: [
          // Sidebar Navigation / Status
          Container(
            width: 260,
            color: const Color(0xff0f172a),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const Icon(
                  Icons.flight_takeoff,
                  color: Color(0xff38bdf8),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "SKYNET",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Text(
                  "AVIATION PLATFORM",
                  style: TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                _buildStepIndicator(
                  context,
                  "1. Route Search",
                  controller.currentStep == BookingStep.search,
                  controller.currentStep.index > 0,
                ),
                _buildStepIndicator(
                  context,
                  "2. Seat Allocation",
                  controller.currentStep == BookingStep.seatSelection,
                  controller.currentStep.index > 1,
                ),
                _buildStepIndicator(
                  context,
                  "3. Checkout & Issue",
                  controller.currentStep == BookingStep.checkout,
                  controller.currentStep.index > 2,
                ),
                _buildStepIndicator(
                  context,
                  "4. Boarding Pass",
                  controller.currentStep == BookingStep.boardingPass,
                  controller.currentStep.index > 3,
                ),
                const Spacer(),
                if (controller.currentStep != BookingStep.search)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Session"),
                      onPressed: () => controller.resetSession(),
                    ),
                  ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: activeView,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    String label,
    bool isActive,
    bool isPast,
  ) {
    Color color = isActive
        ? const Color(0xff38bdf8)
        : (isPast ? const Color(0xff10b981) : const Color(0xff475569));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.check_circle : Icons.circle,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. VIEW 1: FLIGHT SEARCH ENGINE
// ==========================================

class FlightSearchView extends StatefulWidget {
  const FlightSearchView({super.key});

  @override
  State<FlightSearchView> createState() => _FlightSearchViewState();
}

class _FlightSearchViewState extends State<FlightSearchView> {
  String? _origin;
  String? _dest;
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final controller = AviationStateProvider.of(context);

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Search Global Routes",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 32),
          // Search Parameters
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Origin Hub",
                      border: OutlineInputBorder(),
                    ),
                    value: _origin,
                    items: globalHubs
                        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                        .toList(),
                    onChanged: (v) => setState(() => _origin = v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.swap_horiz, color: Colors.grey, size: 32),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Destination Hub",
                      border: OutlineInputBorder(),
                    ),
                    value: _dest,
                    items: globalHubs
                        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                        .toList(),
                    onChanged: (v) => setState(() => _dest = v),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selected != null) setState(() => _date = selected);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Departure Date",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        "${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff38bdf8),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text(
                      "SEARCH",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed:
                        _origin != null && _dest != null && _origin != _dest
                        ? () =>
                              controller.executeSearch(_origin!, _dest!, _date)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Search Results Vector
          if (controller.searchResults.isNotEmpty) ...[
            Text(
              "Available Flights (${controller.searchResults.length})",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: controller.searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final f = controller.searchResults[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xffcbd5e1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.flight,
                              color: Color(0xff0f172a),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${f.airline} • ${f.flightNumber}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff64748b),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      "${f.departureTime.hour}:${f.departureTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xff0f172a),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Icon(
                                        Icons.arrow_right_alt,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "${f.arrivalTime.hour}:${f.arrivalTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xff0f172a),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${f.duration.inHours}h ${f.duration.inMinutes % 60}m duration",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "From",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "\$${f.baseFare.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xff10b981),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff0f172a),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    controller.selectFlightForBooking(f),
                                child: const Text("Select Seats"),
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
          ] else if (controller.searchOrigin != null) ...[
            const Expanded(
              child: Center(
                child: Text(
                  "No routes available matching your criteria.",
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 6. VIEW 2: INTERACTIVE AIRCRAFT SEAT MAP
// ==========================================

class SeatSelectionView extends StatelessWidget {
  const SeatSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AviationStateProvider.of(context);
    final flight = controller.selectedFlight!;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Seat Allocation - ${flight.flightNumber}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select a seat to proceed to checkout.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aircraft Fuselage rendering
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(200),
                      border: Border.all(
                        color: const Color(0xffe2e8f0),
                        width: 4,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(200),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 48.0,
                          horizontal: 24.0,
                        ),
                        children: [
                          _buildClassSection(
                            context,
                            flight,
                            SeatClass.first,
                            1,
                            2,
                          ),
                          const Divider(
                            height: 48,
                            thickness: 2,
                            color: Color(0xffe2e8f0),
                          ),
                          _buildClassSection(
                            context,
                            flight,
                            SeatClass.business,
                            3,
                            6,
                          ),
                          const Divider(
                            height: 48,
                            thickness: 2,
                            color: Color(0xffe2e8f0),
                          ),
                          _buildClassSection(
                            context,
                            flight,
                            SeatClass.economy,
                            7,
                            25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
                // Dynamic Ledger Sidebar
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selection Ledger",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 32),
                        if (controller.selectedSeat == null)
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Awaiting seat selection...",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else ...[
                          _LedgerRow(
                            label: "Seat Assignment",
                            value: controller.selectedSeat!.id,
                          ),
                          _LedgerRow(
                            label: "Class",
                            value: controller.selectedSeat!.seatClass.name
                                .toUpperCase(),
                          ),
                          const SizedBox(height: 16),
                          _LedgerRow(
                            label: "Base Flight Fare",
                            value: "\$${flight.baseFare.toStringAsFixed(2)}",
                          ),
                          _LedgerRow(
                            label: "Class Multiplier",
                            value:
                                "x${controller.selectedSeat!.priceMultiplier}",
                          ),
                          const Divider(height: 32),
                          _LedgerRow(
                            label: "Estimated Total (Pre-tax)",
                            value:
                                "\$${(flight.baseFare * controller.selectedSeat!.priceMultiplier).toStringAsFixed(2)}",
                            isBold: true,
                            color: const Color(0xff10b981),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff38bdf8),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => controller.proceedToCheckout(),
                              child: const Text(
                                "PROCEED TO CHECKOUT",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSection(
    BuildContext context,
    FlightRoute flight,
    SeatClass sClass,
    int startRow,
    int endRow,
  ) {
    String title = sClass == SeatClass.first
        ? "FIRST CLASS"
        : (sClass == SeatClass.business ? "BUSINESS CLASS" : "ECONOMY");
    Color color = sClass == SeatClass.first
        ? const Color(0xffd4af37)
        : (sClass == SeatClass.business
              ? const Color(0xff8b5cf6)
              : const Color(0xff3b82f6));

    List<Widget> rows = [];
    rows.add(
      Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );

    for (int r = startRow; r <= endRow; r++) {
      List<Widget> seats = [];
      List<String> layout = sClass == SeatClass.first
          ? ['A', 'B', 'E', 'F']
          : ['A', 'B', 'C', 'D', 'E', 'F'];

      for (int i = 0; i < layout.length; i++) {
        String seatId = '$r${layout[i]}';
        AircraftSeat seat = flight.seatMap[seatId]!;
        seats.add(_SeatWidget(seat: seat, color: color));

        // Add Aisle Gap
        if (sClass == SeatClass.first && i == 1)
          seats.add(const SizedBox(width: 48)); // Wide aisle
        if (sClass != SeatClass.first && i == 2)
          seats.add(const SizedBox(width: 40)); // Standard aisle
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: seats,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _SeatWidget extends StatelessWidget {
  final AircraftSeat seat;
  final Color color;

  const _SeatWidget({required this.seat, required this.color});

  @override
  Widget build(BuildContext context) {
    final controller = AviationStateProvider.of(context);
    bool isSelected = controller.selectedSeat?.id == seat.id;

    return GestureDetector(
      onTap: () => controller.selectSeat(seat),
      child: Container(
        width: 40,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: seat.isBooked
              ? const Color(0xffe2e8f0)
              : (isSelected ? color : Colors.white),
          border: Border.all(
            color: seat.isBooked ? const Color(0xffcbd5e1) : color,
            width: 2,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(8),
            bottom: Radius.circular(4),
          ),
        ),
        child: Center(
          child: seat.isBooked
              ? const Icon(Icons.close, color: Color(0xff94a3b8), size: 20)
              : Text(
                  seat.id,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
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
// 7. VIEW 3: CHECKOUT & TICKETING ENGINE
// ==========================================

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _couponController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final controller = AviationStateProvider.of(context);
    final flight = controller.selectedFlight!;
    final seat = controller.selectedSeat!;

    double baseFare = flight.baseFare * seat.priceMultiplier;
    double taxes = baseFare * 0.15;
    double discount = controller.activeCoupon != null
        ? (baseFare + taxes) * controller.activeCoupon!.discountMultiplier
        : 0.0;
    double total = (baseFare + taxes) - discount;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Forms
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Passenger & Payment Details",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Passenger Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Legal Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const Divider(height: 48),
                      const Text(
                        "Promotions & Discounts",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: const InputDecoration(
                                labelText: "Promo Code",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0f172a),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                            ),
                            onPressed: () {
                              bool success = controller.applyCoupon(
                                _couponController.text,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "Coupon Applied!"
                                        : "Invalid or Expired Code",
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            },
                            child: const Text("Apply"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          // Financial Summary
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xff0f172a),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Summary",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _LedgerRow(
                    label: "Flight ${flight.flightNumber}",
                    value: "",
                    color: Colors.white70,
                  ),
                  _LedgerRow(
                    label: "Route",
                    value:
                        "${flight.origin.substring(0, 3).toUpperCase()} ➔ ${flight.destination.substring(0, 3).toUpperCase()}",
                    color: Colors.white,
                  ),
                  _LedgerRow(
                    label: "Seat",
                    value: "${seat.id} (${seat.seatClass.name})",
                    color: Colors.white,
                  ),
                  const Divider(height: 32, color: Colors.white24),
                  _LedgerRow(
                    label: "Base Fare",
                    value: "\$${baseFare.toStringAsFixed(2)}",
                    color: Colors.white70,
                  ),
                  _LedgerRow(
                    label: "Taxes & Fees (15%)",
                    value: "\$${taxes.toStringAsFixed(2)}",
                    color: Colors.white70,
                  ),
                  if (discount > 0)
                    _LedgerRow(
                      label: "Discount (${controller.activeCoupon!.code})",
                      value: "-\$${discount.toStringAsFixed(2)}",
                      color: const Color(0xff10b981),
                    ),
                  const Divider(height: 32, color: Colors.white24),
                  _LedgerRow(
                    label: "TOTAL TO PAY",
                    value: "\$${total.toStringAsFixed(2)}",
                    isBold: true,
                    color: const Color(0xff38bdf8),
                    size: 24,
                  ),
                  const Spacer(),
                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff38bdf8),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff10b981),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.lock),
                        label: const Text(
                          "SECURE CHECKOUT & TICKET",
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
                                  "SEAT COLLISION DETECTED. Seat no longer available.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            controller.resetSession();
                          }
                        },
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
}

// ==========================================
// 8. VIEW 4: BOARDING PASS RENDERER
// ==========================================

class BoardingPassView extends StatelessWidget {
  const BoardingPassView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AviationStateProvider.of(context);
    final ticket = controller.issuedTickets.last;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Color(0xff10b981), size: 64),
          const SizedBox(height: 16),
          const Text(
            "Ticket Issued Successfully",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 48),

          // Boarding Pass Graphic
          Container(
            width: 800,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Main Pass Body
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ticket.flight.airline.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff0f172a),
                                letterSpacing: 2,
                              ),
                            ),
                            const Icon(
                              Icons.flight_takeoff,
                              color: Color(0xffcbd5e1),
                              size: 32,
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _TicketDataBlock(
                                label: "PASSENGER",
                                value: ticket.passengerName.toUpperCase(),
                              ),
                            ),
                            Expanded(
                              child: _TicketDataBlock(
                                label: "FLIGHT",
                                value: ticket.flight.flightNumber,
                              ),
                            ),
                            Expanded(
                              child: _TicketDataBlock(
                                label: "DATE",
                                value:
                                    "${ticket.flight.departureTime.day} ${_month(ticket.flight.departureTime.month)}",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _TicketDataBlock(
                                label: "FROM",
                                value: ticket.flight.origin,
                                isLarge: true,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                            Expanded(
                              child: _TicketDataBlock(
                                label: "TO",
                                value: ticket.flight.destination,
                                isLarge: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Perforated Separator
                Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Color(0xffcbd5e1),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ), // Flutter lacks dashed borders natively without CustomPaint, solid is fine for mockup
                  ),
                ),
                // Stub Section
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: const BoxDecoration(
                      color: Color(0xfff8fafc),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TicketDataBlock(
                          label: "SEAT",
                          value: ticket.seat.id,
                          isLarge: true,
                          color: const Color(0xff38bdf8),
                        ),
                        const SizedBox(height: 16),
                        _TicketDataBlock(
                          label: "CLASS",
                          value: ticket.seat.seatClass.name.toUpperCase(),
                        ),
                        const SizedBox(height: 16),
                        _TicketDataBlock(
                          label: "DEPARTURE",
                          value:
                              "${ticket.flight.departureTime.hour}:${ticket.flight.departureTime.minute.toString().padLeft(2, '0')}",
                        ),
                        const Spacer(),
                        // Mock Barcode
                        Container(
                          height: 40,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                "https://upload.wikimedia.org/wikipedia/commons/e/e9/UPC-A-036000291452.svg",
                              ),
                              fit: BoxFit.fill,
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
        ],
      ),
    );
  }

  String _month(int m) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[m - 1];
  }
}

class _TicketDataBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool isLarge;
  final Color? color;

  const _TicketDataBlock({
    required this.label,
    required this.value,
    this.isLarge = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
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

// Utility Row Builder
class _LedgerRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  final double? size;

  const _LedgerRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
    this.size,
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
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
              fontSize: size ?? 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: color ?? Colors.black87,
              fontSize: size ?? 14,
            ),
          ),
        ],
      ),
    );
  }
}
