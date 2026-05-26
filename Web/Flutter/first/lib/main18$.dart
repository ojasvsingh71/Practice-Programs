import 'package:flutter/material.dart';
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
  runApp(const DeliveryFleetTrackerApp());
}

class DeliveryFleetTrackerApp extends StatelessWidget {
  const DeliveryFleetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const FleetStateProvider(
      child: MaterialApp(
        title: 'ApexFleet Logistics Engine',
        debugShowCheckedModeBanner: false,
        home: MainLogisticsHubScreen(),
      ),
    );
  }
}

// ==========================================
// 1. GLOBAL SYSTEM ENUMS & CONFIGURATIONS
// ==========================================

enum VehicleType { heavyTruck, localVan, electricRunner, droneQuad }

enum VehicleStatus { idle, loading, inTransit, gpsOutage, maintenance }

enum RouteStatus { unassigned, optimized, active, complete, disrupted }

enum GpsSignalStrength { excellent, degraded, critical, offline }

// Vector 2D representation for geographical simulated positions
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  double distanceTo(GeoPoint other) {
    return math.sqrt(
      math.pow(latitude - other.latitude, 2) +
          math.pow(longitude - other.longitude, 2),
    );
  }

  static GeoPoint lerp(GeoPoint a, GeoPoint b, double t) {
    return GeoPoint(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }
}

// ==========================================
// 2. ADVANCED DATA CORE MODELS
// ==========================================

class TelemetryPacket {
  final DateTime timestamp;
  final GeoPoint position;
  final double speedKmh;
  final double batteryOrFuelLevel;
  final GpsSignalStrength signal;
  final bool isDeadReckoned;

  const TelemetryPacket({
    required this.timestamp,
    required this.position,
    required this.speedKmh,
    required this.batteryOrFuelLevel,
    required this.signal,
    this.isDeadReckoned = false,
  });
}

class RouteStop {
  final String id;
  final String address;
  final GeoPoint location;
  final String manifestPackageId;
  bool isCompleted;

  RouteStop({
    required this.id,
    required this.address,
    required this.location,
    required this.manifestPackageId,
    this.isCompleted = false,
  });
}

class DeliveryRoute {
  final String id;
  final String labelIdentifier;
  final List<RouteStop> stops;
  final double totalEstimatedDistance;
  RouteStatus trackingStatus;
  int currentStopIndex;

  DeliveryRoute({
    required this.id,
    required this.labelIdentifier,
    required this.stops,
    required this.totalEstimatedDistance,
    this.trackingStatus = RouteStatus.unassigned,
    this.currentStopIndex = 0,
  });
}

class FleetVehicle {
  final String id;
  final String chassisVin;
  final String driverName;
  final VehicleType classType;
  VehicleStatus currentStatus;

  // Telemetry properties
  GeoPoint currentCoordinates;
  double headingHeadingDegrees;
  double operationalVelocity;
  double reserveEnergyPercentage;
  GpsSignalStrength gpsSignal;

  // Bound active configurations
  String? activeAssignedRouteId;
  double currentRouteProgressPct; // 0.0 to 1.0

  // GPS Outage Buffering State
  final List<TelemetryPacket> offlineLocalBufferCache = [];
  int simulatedOutageDurationSeconds = 0;

  FleetVehicle({
    required this.id,
    required this.chassisVin,
    required this.driverName,
    required this.classType,
    required this.currentCoordinates,
    this.currentStatus = VehicleStatus.idle,
    this.headingHeadingDegrees = 0.0,
    this.operationalVelocity = 0.0,
    this.reserveEnergyPercentage = 100.0,
    this.gpsSignal = GpsSignalStrength.excellent,
    this.activeAssignedRouteId,
    this.currentRouteProgressPct = 0.0,
  });
}

// ==========================================
// 3. ENTERPRISE FLEET CONTROLLER STATE MANAGEMENT
// ==========================================

class FleetTrackingController extends ChangeNotifier {
  final List<FleetVehicle> _registeredFleet = [];
  final List<DeliveryRoute> _logisticsRoutes = [];
  final List<String> _systemConsoleTelemetryLogs = [];

  Timer? _globalSimulationHeartbeatTimer;
  bool _isSimulationActive = true;

  List<FleetVehicle> get fleet => List.unmodifiable(_registeredFleet);
  List<DeliveryRoute> get routes => List.unmodifiable(_logisticsRoutes);
  List<String> get centralLogs =>
      List.unmodifiable(_systemConsoleTelemetryLogs);
  bool get isSimulationActive => _isSimulationActive;

  FleetTrackingController() {
    _seedEnterpriseMockData();
    _startTelemetryHeartbeatSimulation();
  }

  void _seedEnterpriseMockData() {
    // Generate Logistics Routes across a mock sector plane coordinates (0.0 -> 100.0 scale)
    _logisticsRoutes.addAll([
      DeliveryRoute(
        id: 'RTE-Alpha',
        labelIdentifier: 'Metro Core Express Express #104',
        totalEstimatedDistance: 42.8,
        stops: [
          RouteStop(
            id: 'STP-101',
            address: 'Downtown Distribution Hub A',
            location: const GeoPoint(20.0, 20.0),
            manifestPackageId: 'PKG-009A',
          ),
          RouteStop(
            id: 'STP-102',
            address: 'High-Rise Commerce Zone Terminal',
            location: const GeoPoint(45.0, 30.0),
            manifestPackageId: 'PKG-012B',
          ),
          RouteStop(
            id: 'STP-103',
            address: 'North-Side Waterfront Cargo Deck',
            location: const GeoPoint(70.0, 15.0),
            manifestPackageId: 'PKG-119X',
          ),
        ],
      ),
      DeliveryRoute(
        id: 'RTE-Beta',
        labelIdentifier: 'Suburban Loop Supply Chain Network',
        totalEstimatedDistance: 89.5,
        stops: [
          RouteStop(
            id: 'STP-201',
            address: 'Industrial Depot Quad 4',
            location: const GeoPoint(10.0, 80.0),
            manifestPackageId: 'PKG-441',
          ),
          RouteStop(
            id: 'STP-202',
            address: 'Valley Residential Locker Complex',
            location: const GeoPoint(50.0, 75.0),
            manifestPackageId: 'PKG-772',
          ),
          RouteStop(
            id: 'STP-203',
            address: 'Peripheral Transit Port Yard',
            location: const GeoPoint(90.0, 90.0),
            manifestPackageId: 'PKG-301',
          ),
        ],
      ),
      DeliveryRoute(
        id: 'RTE-Gamma',
        labelIdentifier: 'Cross-County Freight Pipeline Route',
        totalEstimatedDistance: 154.2,
        stops: [
          RouteStop(
            id: 'STP-301',
            address: 'Central Runway Logistics Bay 2',
            location: const GeoPoint(5.0, 45.0),
            manifestPackageId: 'PKG-902',
          ),
          RouteStop(
            id: 'STP-302',
            address: 'Tech Park Research Fulfillment Gate',
            location: const GeoPoint(50.0, 50.0),
            manifestPackageId: 'PKG-551',
          ),
          RouteStop(
            id: 'STP-303',
            address: 'East-Gate Freight Sorting Depot',
            location: const GeoPoint(95.0, 55.0),
            manifestPackageId: 'PKG-618',
          ),
        ],
      ),
    ]);

    // Populate Fleet Roster
    _registeredFleet.addAll([
      FleetVehicle(
        id: 'TRK-701',
        chassisVin: '1AFV7801X9021',
        driverName: 'Marcus Vance',
        classType: VehicleType.heavyTruck,
        currentCoordinates: const GeoPoint(20.0, 20.0),
      ),
      FleetVehicle(
        id: 'VAN-402',
        chassisVin: '4GHSV331A4482',
        driverName: 'Sarah Jenkins',
        classType: VehicleType.localVan,
        currentCoordinates: const GeoPoint(10.0, 80.0),
      ),
      FleetVehicle(
        id: 'EV-109',
        chassisVin: '5ELX9211K7731',
        driverName: 'Alex Mercer',
        classType: VehicleType.electricRunner,
        currentCoordinates: const GeoPoint(5.0, 45.0),
      ),
      FleetVehicle(
        id: 'DRN-05',
        chassisVin: 'QUAD-DRONE-88',
        driverName: 'Autonomous SkyNet Core',
        classType: VehicleType.droneQuad,
        currentCoordinates: const GeoPoint(50.0, 50.0),
      ),
    ]);

    // Assign Initial Routes
    _assignRouteToVehicle('RTE-Alpha', 'TRK-701');
    _assignRouteToVehicle('RTE-Beta', 'VAN-402');

    _logEvent(
      "System Initialization Complete. 4 asset transponders loaded cleanly into logistics matrix.",
    );
  }

  void _startTelemetryHeartbeatSimulation() {
    _globalSimulationHeartbeatTimer = Timer.periodic(
      const Duration(milliseconds: 1000),
      (timer) {
        if (!_isSimulationActive) return;
        _executeSimulationTick();
      },
    );
  }

  void _executeSimulationTick() {
    for (var vehicle in _registeredFleet) {
      if (vehicle.activeAssignedRouteId == null) continue;

      final route = _getRouteById(vehicle.activeAssignedRouteId!);
      if (route == null || route.trackingStatus == RouteStatus.complete)
        continue;

      // Advance progress track variable metrics
      vehicle.currentRouteProgressPct += 0.0125;
      if (vehicle.currentRouteProgressPct >= 1.0) {
        vehicle.currentRouteProgressPct = 1.0;
        vehicle.currentStatus = VehicleStatus.idle;
        route.trackingStatus = RouteStatus.complete;
        vehicle.operationalVelocity = 0.0;
        _logEvent(
          "Asset ${vehicle.id} successfully finalized Route ${route.id}. Manifest package sequence cleared.",
        );
        notifyListeners();
        continue;
      }

      // Calculate path segments interpolations
      final totalStops = route.stops.length;
      final currentSegmentProgress =
          vehicle.currentRouteProgressPct * (totalStops - 1);
      final currentStopSegmentIndex = currentSegmentProgress.floor();
      final segmentInterpolationFactor =
          currentSegmentProgress - currentStopSegmentIndex;

      final startStop = route.stops[currentStopSegmentIndex];
      final targetStop =
          route.stops[math.min(currentStopSegmentIndex + 1, totalStops - 1)];

      if (route.currentStopIndex != currentStopSegmentIndex) {
        route.stops[route.currentStopIndex].isCompleted = true;
        route.currentStopIndex = currentStopSegmentIndex;
        _logEvent(
          "Asset ${vehicle.id} crossed Waypoint checkpoint Checkpoint ${startStop.id}.",
        );
      }

      // Live Position Computing
      final computedNextPosition = GeoPoint.lerp(
        startStop.location,
        targetStop.location,
        segmentInterpolationFactor,
      );

      // Calculate directional vector angle headings
      final deltaLong =
          targetStop.location.longitude - startStop.location.longitude;
      final deltaLat =
          targetStop.location.latitude - startStop.location.latitude;
      vehicle.headingHeadingDegrees =
          (math.atan2(deltaLong, deltaLat) * 180 / math.pi) % 360;

      // Deplete energy reserves adaptively
      vehicle.reserveEnergyPercentage = math.max(
        0.0,
        vehicle.reserveEnergyPercentage -
            (0.05 * (vehicle.classType == VehicleType.heavyTruck ? 1.5 : 1.0)),
      );

      // Handle GPS Signal State Pipeline Architecture Matrix
      if (vehicle.currentStatus == VehicleStatus.gpsOutage) {
        vehicle.simulatedOutageDurationSeconds++;
        vehicle.gpsSignal = GpsSignalStrength.offline;
        vehicle.operationalVelocity =
            45.0; // Simulated flat dead reckoning constraint variable

        // ** Dead Reckoning Implementation Process **
        // Compute position vector shifts purely off speed vectors and heading metrics without coordinate feedback systems
        double angleRad = vehicle.headingHeadingDegrees * math.pi / 180;
        double speedFactorOffset =
            0.08; // Arbitrary coordinate scale delta map tracking factor
        vehicle.currentCoordinates = GeoPoint(
          vehicle.currentCoordinates.latitude +
              (math.cos(angleRad) * speedFactorOffset),
          vehicle.currentCoordinates.longitude +
              (math.sin(angleRad) * speedFactorOffset),
        );

        // Cache parameters locally to vehicle internal memory cache structures
        vehicle.offlineLocalBufferCache.add(
          TelemetryPacket(
            timestamp: DateTime.now(),
            position: vehicle.currentCoordinates,
            speedKmh: vehicle.operationalVelocity,
            batteryOrFuelLevel: vehicle.reserveEnergyPercentage,
            signal: GpsSignalStrength.offline,
            isDeadReckoned: true,
          ),
        );

        if (vehicle.simulatedOutageDurationSeconds >= 12) {
          _recoverGpsConnectivity(vehicle);
        }
      } else {
        // Safe operational state
        vehicle.currentCoordinates = computedNextPosition;
        vehicle.operationalVelocity = 65.0 + math.Random().nextInt(15);
        vehicle.gpsSignal = GpsSignalStrength.excellent;
        vehicle.currentStatus = VehicleStatus.inTransit;
      }
    }
    notifyListeners();
  }

  void _assignRouteToVehicle(String routeId, String vehicleId) {
    final route = _getRouteById(routeId);
    final vehicle = _getVehicleById(vehicleId);

    if (route != null && vehicle != null) {
      route.trackingStatus = RouteStatus.active;
      vehicle.activeAssignedRouteId = routeId;
      vehicle.currentStatus = VehicleStatus.inTransit;
      vehicle.currentRouteProgressPct = 0.0;
      route.currentStopIndex = 0;
      for (var s in route.stops) {
        s.isCompleted = false;
      }
      _logEvent(
        "Dispatched driver ${vehicle.driverName} on route ${route.labelIdentifier}.",
      );
      notifyListeners();
    }
  }

  // --- Outage Protocol Interface Vectors ---
  void forceSimulateGpsOutage(String vehicleId) {
    final vehicle = _getVehicleById(vehicleId);
    if (vehicle != null && vehicle.currentStatus == VehicleStatus.inTransit) {
      vehicle.currentStatus = VehicleStatus.gpsOutage;
      vehicle.gpsSignal = GpsSignalStrength.offline;
      vehicle.simulatedOutageDurationSeconds = 0;
      vehicle.offlineLocalBufferCache.clear();
      _logEvent(
        "CRITICAL CRITICAL WARNING: Asset Transponder $vehicleId lost satellite handshake lock. Entering Dead Reckoning local telemetry mode.",
      );
      notifyListeners();
    }
  }

  void _recoverGpsConnectivity(FleetVehicle vehicle) {
    vehicle.currentStatus = VehicleStatus.inTransit;
    vehicle.gpsSignal = GpsSignalStrength.excellent;
    int flushedCount = vehicle.offlineLocalBufferCache.length;

    _logEvent(
      "SIGNAL RESTORED: Handshake lock verified on asset ${vehicle.id}. Re-syncing structural telemetry stream data pipeline...",
    );
    _logEvent(
      "SUCCESS: Flushed $flushedCount buffered log packets securely from local cache system matrices back into central fleet database logs.",
    );

    vehicle.offlineLocalBufferCache.clear();
    vehicle.simulatedOutageDurationSeconds = 0;
  }

  void toggleSimulationState() {
    _isSimulationActive = !_isSimulationActive;
    _logEvent(
      "Master telemetry engine tracking states switched: Active Flag = $_isSimulationActive",
    );
    notifyListeners();
  }

  void createNewRouteConfiguration(DeliveryRoute route) {
    _logisticsRoutes.add(route);
    _logEvent(
      "Created raw custom delivery profile: ${route.labelIdentifier}. Path optimized.",
    );
    notifyListeners();
  }

  void _logEvent(String message) {
    _systemConsoleTelemetryLogs.insert(
      0,
      "[${DateTime.now().toIso8601String().substring(11, 19)}] $message",
    );
    if (_systemConsoleTelemetryLogs.length > 100)
      _systemConsoleTelemetryLogs.removeLast();
  }

  DeliveryRoute? _getRouteById(String id) =>
      _logisticsRoutes.firstWhere((r) => r.id == id);
  FleetVehicle? _getVehicleById(String id) =>
      _registeredFleet.firstWhere((v) => v.id == id);

  @override
  void dispose() {
    _globalSimulationHeartbeatTimer?.cancel();
    super.dispose();
  }
}

// Global scope inherited context model provider
class FleetStateProvider extends StatefulWidget {
  final Widget child;
  const FleetStateProvider({super.key, required this.child});

  static FleetTrackingController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedFleetProvider>();
    assert(
      result != null,
      'Operational FleetStateProvider context bound fault.',
    );
    return result!.controller;
  }

  @override
  State<FleetStateProvider> createState() => _FleetStateProviderState();
}

class _FleetStateProviderState extends State<FleetStateProvider> {
  late FleetTrackingController controller;

  @override
  void initState() {
    super.initState();
    controller = FleetTrackingController();
    controller.addListener(_onStateMutationChange);
  }

  void _onStateMutationChange() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_onStateMutationChange);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedFleetProvider(controller: controller, child: widget.child);
  }
}

class _InheritedFleetProvider extends InheritedWidget {
  final FleetTrackingController controller;
  const _InheritedFleetProvider({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedFleetProvider oldWidget) => true;
}

// ==========================================
// 4. MAIN CENTRAL INTERFACE LAYOUT HUB
// ==========================================

class MainLogisticsHubScreen extends StatefulWidget {
  const MainLogisticsHubScreen({super.key});

  @override
  State<MainLogisticsHubScreen> createState() => _MainLogisticsHubScreenState();
}

class _MainLogisticsHubScreenState extends State<MainLogisticsHubScreen> {
  int _activeScreenViewRailIndex = 0;

  final List<Widget> _subScreenViewportMatrix = [
    const RealtimeFleetDashboardView(),
    const FleetRosterControlView(),
    const RoutePipelinePlannerView(),
    const SystemTelemetryLogTerminalView(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = FleetStateProvider.of(context);
    final activeOutages = controller.fleet
        .where((v) => v.currentStatus == VehicleStatus.gpsOutage)
        .length;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _activeScreenViewRailIndex,
            onDestinationSelected: (idx) =>
                setState(() => _activeScreenViewRailIndex = idx),
            backgroundColor: const Color(0xff0f172a),
            labelType: NavigationRailLabelType.all,
            unselectedIconTheme: const IconThemeData(color: Color(0xff64748b)),
            unselectedLabelTextStyle: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 11,
            ),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            indicatorColor: const Color(0xff3b82f6),
            leading: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.router_rounded,
                  color: Color(0xff38bdf8),
                  size: 32,
                ),
                const SizedBox(height: 6),
                const Text(
                  "APEX",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  "FLEET",
                  style: TextStyle(
                    color: Color(0xff38bdf8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text("Monitor"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: Text("Vehicles"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: Text("Routes"),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text('$activeOutages'),
                  isLabelVisible: activeOutages > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.terminal_outlined),
                ),
                selectedIcon: const Icon(Icons.terminal),
                label: const Text("Telemetry"),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: Icon(
                      controller.isSimulationActive
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: controller.isSimulationActive
                          ? Colors.green
                          : Colors.orange,
                      size: 36,
                    ),
                    onPressed: () => controller.toggleSimulationState(),
                    tooltip: "Toggle Live Simulation Clock",
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xffcbd5e1),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _subScreenViewportMatrix[_activeScreenViewRailIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. VIEWPORT 1: REALTIME FLEET DASHBOARD MONITOR
// ==========================================

class RealtimeFleetDashboardView extends StatelessWidget {
  const RealtimeFleetDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FleetStateProvider.of(context);

    int transitCount = controller.fleet
        .where((v) => v.currentStatus == VehicleStatus.inTransit)
        .length;
    int outageCount = controller.fleet
        .where((v) => v.currentStatus == VehicleStatus.gpsOutage)
        .length;
    int idleCount = controller.fleet
        .where((v) => v.currentStatus == VehicleStatus.idle)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          "Logistics Network Topology Stream",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Structural Analytics Columns Panels
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _DashboardMetricCard(
                        title: "Active Asset Deployment",
                        value: "$transitCount / ${controller.fleet.length}",
                        icon: Icons.navigation,
                        tintColor: const Color(0xff2563eb),
                      ),
                      _DashboardMetricCard(
                        title: "GPS Outage Failures",
                        value: "$outageCount",
                        icon: Icons.gps_off,
                        tintColor: const Color(0xffdc2626),
                        statusWarn: outageCount > 0,
                      ),
                      _DashboardMetricCard(
                        title: "Staging Terminals (Idle)",
                        value: "$idleCount",
                        icon: Icons.gite,
                        tintColor: const Color(0xff475569),
                      ),
                      _DashboardMetricCard(
                        title: "Active Pipeline Routes",
                        value:
                            "${controller.routes.where((r) => r.trackingStatus == RouteStatus.active).length}",
                        icon: Icons.alt_route,
                        tintColor: const Color(0xff0d9488),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Visual Telemetry Grid Mapping",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xff1e293b),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff0f172a),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: FleetVectorMapPainter(
                                  vehicles: controller.fleet,
                                  routes: controller.routes,
                                ),
                              ),
                            ),
                            // Map Legends Overlay Block elements
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xdd1e293b),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMapLegendItem(
                                      Colors.green,
                                      "Signal Nominal (Active Path)",
                                    ),
                                    _buildMapLegendItem(
                                      Colors.red,
                                      "GPS Outage - Inertial Reckoning Mode",
                                    ),
                                    _buildMapLegendItem(
                                      Colors.orange,
                                      "Assigned Route Vector Paths",
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
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Live Status Side Feed Ticker stream
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Real-time Tactical Event Log",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xff1e293b),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: controller.centralLogs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 12, color: Color(0xfff1f5f9)),
                        itemBuilder: (context, idx) {
                          final logLine = controller.centralLogs[idx];
                          final isCritical =
                              logLine.contains("CRITICAL") ||
                              logLine.contains("WARNING");
                          return Text(
                            logLine,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: isCritical
                                  ? Colors.red.shade800
                                  : Colors.grey.shade700,
                              fontWeight: isCritical
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        },
                      ),
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

  Widget _buildMapLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color tintColor;
  final bool statusWarn;

  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tintColor,
    this.statusWarn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusWarn ? const Color(0xfffef2f2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusWarn ? Colors.red.shade300 : const Color(0xffe2e8f0),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff64748b),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: statusWarn
                      ? Colors.red.shade900
                      : const Color(0xff0f172a),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Icon(icon, color: statusWarn ? Colors.red : tintColor, size: 28),
        ],
      ),
    );
  }
}

// ==========================================
// 6. CUSTOM VECTOR GRAPHICS MAP ENGINE PAINTER
// ==========================================

class FleetVectorMapPainter extends CustomPainter {
  final List<FleetVehicle> vehicles;
  final List<DeliveryRoute> routes;

  FleetVectorMapPainter({required this.vehicles, required this.routes});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xff0f172a);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw coordinate reference grid structures lines lines
    final gridPaint = Paint()
      ..color = const Color(0xff1e293b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double horizontalSpacing = size.width / 10;
    double verticalSpacing = size.height / 10;

    for (int i = 1; i < 10; i++) {
      canvas.drawLine(
        Offset(horizontalSpacing * i, 0),
        Offset(horizontalSpacing * i, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, verticalSpacing * i),
        Offset(size.width, verticalSpacing * i),
        gridPaint,
      );
    }

    // Draw active optimized trajectory path channels
    for (var route in routes) {
      if (route.trackingStatus == RouteStatus.unassigned) continue;

      final pathPaint = Paint()
        ..color = const Color(0xfff97316).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < route.stops.length - 1; i++) {
        Offset start = _translateGeoToCanvas(route.stops[i].location, size);
        Offset end = _translateGeoToCanvas(route.stops[i + 1].location, size);
        canvas.drawLine(start, end, pathPaint);
      }

      // Draw node sequence waypoint shapes points
      for (var stop in route.stops) {
        final stopPaint = Paint()
          ..color = stop.isCompleted
              ? const Color(0xff64748b)
              : const Color(0xfff97316)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          _translateGeoToCanvas(stop.location, size),
          4.0,
          stopPaint,
        );
      }
    }

    // Draw physical vehicle tracking points with connection parameters
    for (var vehicle in vehicles) {
      Offset pos = _translateGeoToCanvas(vehicle.currentCoordinates, size);

      bool isOutage = vehicle.currentStatus == VehicleStatus.gpsOutage;
      final vehicleColor = isOutage
          ? const Color(0xffdc2626)
          : const Color(0xff10b981);

      if (isOutage) {
        // Draw uncertainty radius mapping indicator bounds for inertial dead reckoning tracking
        final uncertaintyPaint = Paint()
          ..color = Colors.red.withOpacity(0.15)
          ..style = PaintingStyle.fill;
        double calculatedRadius =
            12.0 + (vehicle.simulatedOutageDurationSeconds * 1.5);
        canvas.drawCircle(pos, calculatedRadius, uncertaintyPaint);

        final uncertaintyBorder = Paint()
          ..color = Colors.red.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(pos, calculatedRadius, uncertaintyBorder);
      }

      // Draw vector heading orientation arrow indicator pointers
      final vehiclePaint = Paint()
        ..color = vehicleColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 7.0, vehiclePaint);

      // Core text tag labeling identifier overlay matrix
      final textPainter = TextPainter(
        text: TextSpan(
          text: vehicle.id,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - (textPainter.width / 2), pos.dy - 18),
      );
    }
  }

  Offset _translateGeoToCanvas(GeoPoint geo, Size canvasSize) {
    // Maps internal tracking plane system coordinates (0-100) scale onto adaptive UI layouts safely
    double x = (geo.latitude / 100.0) * canvasSize.width;
    double y = (geo.longitude / 100.0) * canvasSize.height;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant FleetVectorMapPainter oldDelegate) => true;
}

// ==========================================
// 7. VIEWPORT 2: VEHICLE ROSTER CONTROL MATRIX
// ==========================================

class FleetRosterControlView extends StatelessWidget {
  const FleetRosterControlView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FleetStateProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          "Fleet Transponder Ledger Manifest",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.fleet.length,
        itemBuilder: (context, idx) {
          final vehicle = controller.fleet[idx];
          final assignedRoute = vehicle.activeAssignedRouteId != null
              ? controller.routes.firstWhere(
                  (r) => r.id == vehicle.activeAssignedRouteId,
                )
              : null;

          bool isOutageActive =
              vehicle.currentStatus == VehicleStatus.gpsOutage;

          return Card(
            color: isOutageActive ? const Color(0xfffff5f5) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isOutageActive
                    ? Colors.red.shade300
                    : const Color(0xffe2e8f0),
                width: isOutageActive ? 1.5 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOutageActive
                          ? Colors.red.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getVehicleClassIcon(vehicle.classType),
                      color: isOutageActive
                          ? Colors.red.shade900
                          : const Color(0xff1e293b),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              vehicle.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStatusBadge(vehicle.currentStatus),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Active Personnel Driver: ${vehicle.driverName}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff475569),
                          ),
                        ),
                        Text(
                          "VIN Identification Sequence: ${vehicle.chassisVin}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Track Assignment: ${assignedRoute?.labelIdentifier ?? 'None (Unallocated Capacity)'}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: vehicle.currentRouteProgressPct,
                          backgroundColor: const Color(0xffe2e8f0),
                          color: isOutageActive
                              ? Colors.red
                              : const Color(0xff2563eb),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sector Real-Time Progress: ${(vehicle.currentRouteProgressPct * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.battery_charging_full,
                              size: 16,
                              color: Colors.grey,
                            ),
                            Text(
                              " ${vehicle.reserveEnergyPercentage.toStringAsFixed(0)}% Capacity",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Velocity Vector: ${vehicle.operationalVelocity.toStringAsFixed(1)} km/h",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Heading Angle: ${vehicle.headingHeadingDegrees.toStringAsFixed(0)}° Azimuth",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutageActive
                          ? Colors.grey
                          : const Color(0xffdc2626),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    onPressed: vehicle.currentStatus == VehicleStatus.inTransit
                        ? () => controller.forceSimulateGpsOutage(vehicle.id)
                        : null,
                    child: const Text("Trigger GPS Outage"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getVehicleClassIcon(VehicleType type) {
    switch (type) {
      case VehicleType.heavyTruck:
        return Icons.local_shipping;
      case VehicleType.localVan:
        return Icons.airport_shuttle;
      case VehicleType.electricRunner:
        return Icons.electric_car;
      case VehicleType.droneQuad:
        return Icons.grid_view;
    }
  }

  Widget _buildStatusBadge(VehicleStatus status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;
    String label = "Idle";

    if (status == VehicleStatus.inTransit) {
      bg = const Color(0xffdcfce7);
      fg = const Color(0xff15803d);
      label = "In Transit";
    } else if (status == VehicleStatus.gpsOutage) {
      bg = const Color(0xfffee2e2);
      fg = const Color(0xff991b1b);
      label = "GPS OUTAGE ACTIVE";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ==========================================
// 8. VIEWPORT 3: ROUTE PIPELINE PLANNER
// ==========================================

class RoutePipelinePlannerView extends StatefulWidget {
  const RoutePipelinePlannerView({super.key});

  @override
  State<RoutePipelinePlannerView> createState() =>
      _RoutePipelinePlannerViewState();
}

class _RoutePipelinePlannerViewState extends State<RoutePipelinePlannerView> {
  final _routeFormKey = GlobalKey<FormState>();

  String routeLabel = "";
  double estimatedDist = 0.0;

  // Dynamic working configuration sequence variables lists
  final List<RouteStop> temporaryCreatedStopsBuffer = [];

  @override
  Widget build(BuildContext context) {
    final controller = FleetStateProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          "Route Provisioning & Optimization Core",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Configured Path Framework Distribution Maps",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.routes.length,
                      itemBuilder: (context, index) {
                        final r = controller.routes[index];
                        return Card(
                          color: Colors.white,
                          child: ExpansionTile(
                            leading: const Icon(
                              Icons.alt_route,
                              color: Color(0xff0d9488),
                            ),
                            title: Text(
                              r.labelIdentifier,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Total Route Scope Distance: ${r.totalEstimatedDistance} km | Waypoints: ${r.stops.length}",
                            ),
                            trailing: _buildRouteStatusToken(r.trackingStatus),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: const Color(0xfff8fafc),
                                child: Column(
                                  children: r.stops.map((stop) {
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        stop.isCompleted
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: stop.isCompleted
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      title: Text(
                                        stop.address,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Latitude: ${stop.location.latitude.toStringAsFixed(2)} | Longitude: ${stop.location.longitude.toStringAsFixed(2)}",
                                      ),
                                      trailing: Text(
                                        "Pkg Tracking: ${stop.manifestPackageId}",
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _routeFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Construct Custom Delivery Path Segment",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Route Descriptor Unique Identity Label",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Unique nomenclature framework required"
                            : null,
                        onSaved: (v) => routeLabel = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Calculated Distance Matrix Metrics (km)",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => double.tryParse(v ?? '') == null
                            ? "Numerical validation check fault"
                            : null,
                        onSaved: (v) => estimatedDist = double.parse(v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Route Waypoint Nodes Sequence",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text("Append Stop Point"),
                            onPressed: () {
                              setState(() {
                                temporaryCreatedStopsBuffer.add(
                                  RouteStop(
                                    id: 'STP-${math.Random().nextInt(1000)}',
                                    address:
                                        'Simulated Drop Location Sector ${temporaryCreatedStopsBuffer.length + 1}',
                                    location: GeoPoint(
                                      math.Random().nextDouble() * 90,
                                      math.Random().nextDouble() * 90,
                                    ),
                                    manifestPackageId:
                                        'PKG-${math.Random().nextInt(900) + 100}',
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      ...temporaryCreatedStopsBuffer.map(
                        (stop) => Card(
                          color: const Color(0xfff1f5f9),
                          child: ListTile(
                            dense: true,
                            title: Text(stop.address),
                            subtitle: Text(
                              "Geographic Coordinates Map Vector: [${stop.location.latitude.toStringAsFixed(1)}, ${stop.location.longitude.toStringAsFixed(1)}]",
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => setState(
                                () => temporaryCreatedStopsBuffer.remove(stop),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0d9488),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (_routeFormKey.currentState!.validate() &&
                                temporaryCreatedStopsBuffer.isNotEmpty) {
                              _routeFormKey.currentState!.save();

                              final generatedRoute = DeliveryRoute(
                                id: 'RTE-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}',
                                labelIdentifier: routeLabel,
                                stops: List.from(temporaryCreatedStopsBuffer),
                                totalEstimatedDistance: estimatedDist,
                              );

                              controller.createNewRouteConfiguration(
                                generatedRoute,
                              );
                              _routeFormKey.currentState!.reset();
                              setState(() {
                                temporaryCreatedStopsBuffer.clear();
                              });
                            }
                          },
                          child: const Text(
                            "Compile and Optimize Path Blueprint Strategy",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStatusToken(RouteStatus status) {
    Color c = Colors.grey;
    if (status == RouteStatus.active) c = Colors.blue;
    if (status == RouteStatus.complete) c = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ==========================================
// 9. VIEWPORT 4: LIVE TELEMETRY SYSTEM LOGGER
// ==========================================

class SystemTelemetryLogTerminalView extends StatelessWidget {
  const SystemTelemetryLogTerminalView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FleetStateProvider.of(context);
    final vehiclesInCriticalState = controller.fleet
        .where((v) => v.currentStatus == VehicleStatus.gpsOutage)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text(
          "Localized Cache Storage & Outage Diagnostics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff1e293b),
        scrolledUnderElevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: vehiclesInCriticalState.isNotEmpty
                  ? const Color(0xff7f1d1d)
                  : const Color(0xff064e3b),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                vehiclesInCriticalState.isNotEmpty
                    ? "OUTAGE ALERT PROTOCOL ACTIVE: Dead Reckoning Engaged"
                    : "All Core Transponders Online & Synchronized",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Local Buffer Diagnostics Monitoring Framework",
              style: TextStyle(
                color: Color(0xff38bdf8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "When GPS communication grids go down, affected hardware nodes isolate data packages and cache positional matrix logs into persistent hardware sector arrays. Below are the records currently accumulating waiting for automatic validation sync steps.",
              style: TextStyle(color: Color(0xff94a3b8), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: vehiclesInCriticalState.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.gpp_good_outlined,
                            color: Colors.green,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No Local Buffers Blocked. System Communication Topology At Zero Leak Factor.",
                            style: TextStyle(
                              color: Color(0xff94a3b8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: vehiclesInCriticalState.length,
                      itemBuilder: (context, index) {
                        final v = vehiclesInCriticalState[index];
                        return Card(
                          color: const Color(0xff1e293b),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Hardware Node Asset Token: ${v.id}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      "Buffered Frame Accumulation Size: ${v.offlineLocalBufferCache.length} packets",
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Total Outage Duration Counter: ${v.simulatedOutageDurationSeconds} Continuous Telemetry Clock Cycles",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                const Divider(
                                  height: 20,
                                  color: Color(0xff334155),
                                ),
                                const Text(
                                  "Live Local Inertial Readouts Stream (In Memory Buffering Sequence):",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 120,
                                  color: const Color(0xff090d16),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: v.offlineLocalBufferCache.length,
                                    itemBuilder: (context, pIdx) {
                                      final packet =
                                          v.offlineLocalBufferCache[(v
                                                      .offlineLocalBufferCache
                                                      .length -
                                                  1) -
                                              pIdx];
                                      return Text(
                                        "[DR_REC_LOG] Timestamp: ${packet.timestamp.toIso8601String().substring(11, 23)} | Coord Vector: [${packet.position.latitude.toStringAsFixed(4)}, ${packet.position.longitude.toStringAsFixed(4)}] | Inertial Speed: ${packet.speedKmh.toStringAsFixed(1)} km/h | Sync Verification Token: FALSE_CACHED_LOCAL",
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
