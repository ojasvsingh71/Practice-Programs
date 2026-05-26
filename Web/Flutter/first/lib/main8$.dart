import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;
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
// 1. CONSTANTS, ENUMS & THEMES
// ============================================================================

enum DeviceType { thermostat, light, camera, lock, motionSensor }

enum ConnectionState { online, offline, error, updating }

enum AlertSeverity { info, warning, critical }

enum Room { livingRoom, bedroom, kitchen, garage, exterior }

class AppColors {
  static const Color primary = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDark = Color(0xFF1E3A8A); // Blue 900
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700
  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color accent = Color(0xFF8B5CF6); // Violet 500
}

class AppStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
    letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textMain,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );
}

// ============================================================================
// 2. EXCEPTIONS & UTILS
// ============================================================================

abstract class IoTException implements Exception {
  final String message;
  final String deviceId;
  IoTException(this.deviceId, this.message);
  @override
  String toString() => '[$deviceId] $message';
}

class DeviceOfflineException extends IoTException {
  DeviceOfflineException(
    String deviceId, [
    String msg = "Device is unreachable.",
  ]) : super(deviceId, msg);
}

class SensorTimeoutException extends IoTException {
  SensorTimeoutException(
    String deviceId, [
    String msg = "Sensor failed to respond in time.",
  ]) : super(deviceId, msg);
}

class UnauthorizedHardwareException extends IoTException {
  UnauthorizedHardwareException(
    String deviceId, [
    String msg = "Invalid device signature.",
  ]) : super(deviceId, msg);
}

class FormatUtils {
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static String date(DateTime d) => '${d.month}/${d.day}/${d.year}';
}

// ============================================================================
// 3. MIXINS (Logger & Alert Triggers)
// ============================================================================

class LogEntry {
  final DateTime timestamp;
  final String message;
  LogEntry(this.message) : timestamp = DateTime.now();
}

/// Provides standardized logging capabilities for any SmartDevice
mixin DeviceLoggerMixin {
  final Queue<LogEntry> _logs = Queue<LogEntry>();
  final int _maxLogs = 50;

  void logDeviceEvent(String message) {
    if (_logs.length >= _maxLogs) _logs.removeFirst();
    _logs.addLast(LogEntry(message));
    // Print to standard output for debug simulation
    debugPrint('[HW_LOG] $message');
  }

  List<LogEntry> get recentLogs => _logs.toList().reversed.toList();
}

class Alert {
  final String id;
  final String deviceId;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  bool isRead;

  Alert({
    required this.id,
    required this.deviceId,
    required this.message,
    required this.severity,
    this.isRead = false,
  }) : timestamp = DateTime.now();
}

/// Enables devices to evaluate telemetric data against thresholds and emit alerts
mixin AlertTriggerMixin {
  final List<Alert> _activeAlerts = [];

  void evaluateThreshold(
    String deviceId,
    String metricName,
    double value,
    double min,
    double max,
  ) {
    if (value > max) {
      _triggerAlert(
        deviceId,
        '$metricName exceeded maximum threshold: ${value.toStringAsFixed(1)} (Max: $max)',
        AlertSeverity.critical,
      );
    } else if (value < min) {
      _triggerAlert(
        deviceId,
        '$metricName dropped below minimum threshold: ${value.toStringAsFixed(1)} (Min: $min)',
        AlertSeverity.warning,
      );
    }
  }

  void _triggerAlert(String deviceId, String message, AlertSeverity severity) {
    final alert = Alert(
      id: 'ALT_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      deviceId: deviceId,
      message: message,
      severity: severity,
    );
    _activeAlerts.add(alert);
    // Notify central hub (Simulated via global stream in the Engine)
    MockIoTHub().dispatchAlert(alert);
  }
}

// ============================================================================
// 4. DOMAIN MODELS (POLYMORPHIC IoT DEVICES)
// ============================================================================

abstract class SmartDevice with DeviceLoggerMixin, AlertTriggerMixin {
  final String id;
  final String name;
  final DeviceType type;
  final Room room;

  ConnectionState connectionState = ConnectionState.offline;
  int batteryLevel; // 0-100
  DateTime lastUpdate = DateTime.now();

  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.room,
    this.batteryLevel = 100,
  }) {
    logDeviceEvent('Device initialized and registered.');
  }

  /// Abstract method called by the IoT Engine polling loop
  void processTelemetry();

  /// Abstract method for sending commands to the device
  Future<void> sendCommand(Map<String, dynamic> payload);

  void setOffline() {
    connectionState = ConnectionState.offline;
    logDeviceEvent('Device connection lost.');
  }

  void setOnline() {
    connectionState = ConnectionState.online;
    logDeviceEvent('Device reconnected.');
  }
}

class TelemetryPoint {
  final DateTime time;
  final double value;
  TelemetryPoint(this.time, this.value);
}

class Thermostat extends SmartDevice {
  double currentTemperature = 72.0;
  double targetTemperature = 72.0;
  double currentHumidity = 45.0;
  bool isHeating = false;
  bool isCooling = false;

  final Queue<TelemetryPoint> temperatureHistory = Queue<TelemetryPoint>();

  Thermostat({required String id, required String name, required Room room})
    : super(id: id, name: name, type: DeviceType.thermostat, room: room);

  @override
  void processTelemetry() {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(id);

    // Simulate environment drift
    double drift = (math.Random().nextDouble() - 0.5) * 0.5;

    // Actuate HVAC
    if (currentTemperature < targetTemperature - 1.0) {
      isHeating = true;
      isCooling = false;
      currentTemperature += 0.5 + drift; // Heating up
    } else if (currentTemperature > targetTemperature + 1.0) {
      isHeating = false;
      isCooling = true;
      currentTemperature -= 0.5 - drift; // Cooling down
    } else {
      isHeating = false;
      isCooling = false;
      currentTemperature += drift * 0.5; // Natural drift
    }

    currentHumidity += (math.Random().nextDouble() - 0.5) * 2;
    currentHumidity = currentHumidity.clamp(30.0, 70.0);

    // Update history for chart
    if (temperatureHistory.length > 30) temperatureHistory.removeFirst();
    temperatureHistory.addLast(
      TelemetryPoint(DateTime.now(), currentTemperature),
    );

    lastUpdate = DateTime.now();
    logDeviceEvent(
      'Telemetry synced: Temp ${currentTemperature.toStringAsFixed(1)}F',
    );

    // Use AlertTriggerMixin
    evaluateThreshold(id, 'Temperature', currentTemperature, 60.0, 85.0);
  }

  @override
  Future<void> sendCommand(Map<String, dynamic> payload) async {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(
        id,
        "Cannot send command to offline device.",
      );

    if (payload.containsKey('targetTemperature')) {
      targetTemperature = payload['targetTemperature'];
      logDeviceEvent('Target temperature set to $targetTemperature');
    }
  }
}

class SmartLight extends SmartDevice {
  bool isOn = false;
  double brightness = 100.0; // 0-100
  Color color = Colors.white;

  SmartLight({required String id, required String name, required Room room})
    : super(id: id, name: name, type: DeviceType.light, room: room);

  @override
  void processTelemetry() {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(id);
    lastUpdate = DateTime.now();
    // Simulate rare bulb burnout (Timeout exception)
    if (math.Random().nextDouble() < 0.005) {
      throw SensorTimeoutException(id, "Light bulb filament unresponsive.");
    }
  }

  @override
  Future<void> sendCommand(Map<String, dynamic> payload) async {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(id);
    if (payload.containsKey('isOn')) isOn = payload['isOn'];
    if (payload.containsKey('brightness')) brightness = payload['brightness'];
    if (payload.containsKey('color')) color = payload['color'];
    logDeviceEvent('State updated: Power=$isOn, Brightness=$brightness');
  }
}

class SecurityCamera extends SmartDevice {
  bool isRecording = false;
  bool motionDetected = false;

  SecurityCamera({required String id, required String name, required Room room})
    : super(id: id, name: name, type: DeviceType.camera, room: room);

  @override
  void processTelemetry() {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(id);
    lastUpdate = DateTime.now();

    // Simulate motion detection algorithm
    bool previousMotion = motionDetected;
    motionDetected = math.Random().nextDouble() < 0.1; // 10% chance of motion

    if (motionDetected && !previousMotion) {
      logDeviceEvent('Motion detected in sector A.');
      isRecording = true;
      _triggerAlert(
        id,
        'Motion detected on $name camera!',
        AlertSeverity.warning,
      );
    } else if (!motionDetected && previousMotion) {
      isRecording = false;
      logDeviceEvent('Motion cleared. Recording stopped.');
    }
  }

  @override
  Future<void> sendCommand(Map<String, dynamic> payload) async {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(id);
    if (payload.containsKey('record')) {
      isRecording = payload['record'];
      logDeviceEvent('Manual recording override: $isRecording');
    }
  }
}

class SmartLock extends SmartDevice {
  bool isLocked = true;
  bool doorOpen = false;

  SmartLock({required String id, required String name, required Room room})
    : super(
        id: id,
        name: name,
        type: DeviceType.lock,
        room: room,
        batteryLevel: 85,
      );

  @override
  void processTelemetry() {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(id);
    lastUpdate = DateTime.now();

    // Battery degradation simulation
    if (math.Random().nextDouble() < 0.05) batteryLevel -= 1;
    evaluateThreshold(id, 'Battery', batteryLevel.toDouble(), 15.0, 100.0);

    // Security risk simulation
    if (!isLocked && doorOpen && math.Random().nextDouble() < 0.1) {
      _triggerAlert(
        id,
        '$name has been left open and unlocked!',
        AlertSeverity.critical,
      );
    }
  }

  @override
  Future<void> sendCommand(Map<String, dynamic> payload) async {
    if (connectionState == ConnectionState.offline)
      throw DeviceOfflineException(id);
    if (payload.containsKey('isLocked')) {
      isLocked = payload['isLocked'];
      logDeviceEvent(
        'Lock state changed to: ${isLocked ? "LOCKED" : "UNLOCKED"}',
      );
    }
  }
}

// ============================================================================
// 5. MOCK IOT HUB ENGINE (Polling & Network Simulation)
// ============================================================================

class MockIoTHub {
  static final MockIoTHub _instance = MockIoTHub._internal();
  factory MockIoTHub() => _instance;
  MockIoTHub._internal();

  final List<SmartDevice> _registeredDevices = [];
  final StreamController<Alert> _alertController =
      StreamController<Alert>.broadcast();
  final StreamController<void> _tickController =
      StreamController<void>.broadcast();

  Timer? _pollingTimer;
  final math.Random _random = math.Random();

  Stream<Alert> get alertStream => _alertController.stream;
  Stream<void> get tickStream => _tickController.stream;
  List<SmartDevice> get devices => List.unmodifiable(_registeredDevices);

  void initializeHub() {
    // Register Mock Hardware
    _registeredDevices.addAll([
      Thermostat(id: 'TH_01', name: 'Main Thermostat', room: Room.livingRoom)
        ..setOnline(),
      Thermostat(id: 'TH_02', name: 'Upstairs HVAC', room: Room.bedroom)
        ..setOnline(),
      SmartLight(id: 'LT_01', name: 'Sofa Lamp', room: Room.livingRoom)
        ..setOnline()
        ..isOn = true,
      SmartLight(id: 'LT_02', name: 'Kitchen Overhead', room: Room.kitchen)
        ..setOnline(),
      SmartLight(id: 'LT_03', name: 'Nightstand Light', room: Room.bedroom)
        ..setOnline(),
      SecurityCamera(id: 'CAM_01', name: 'Porch Camera', room: Room.exterior)
        ..setOnline(),
      SecurityCamera(id: 'CAM_02', name: 'Garage Cam', room: Room.garage)
        ..setOnline(),
      SmartLock(id: 'LCK_01', name: 'Front Door', room: Room.exterior)
        ..setOnline(),
    ]);

    _startPollingLoop();
  }

  void _startPollingLoop() {
    // Simulates an MQTT/WebSocket polling heartbeat every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      for (var device in _registeredDevices) {
        // 1. Simulate Network Instability
        if (_random.nextDouble() < 0.02) {
          // 2% chance to drop offline
          device.setOffline();
        } else if (device.connectionState == ConnectionState.offline &&
            _random.nextDouble() < 0.3) {
          device.setOnline(); // 30% chance to reconnect if offline
        }

        // 2. Poll Telemetry and catch Hardware Exceptions
        try {
          device.processTelemetry();
        } on DeviceOfflineException {
          // Expected, silently ignore until reconnected
        } on SensorTimeoutException catch (e) {
          device.connectionState = ConnectionState.error;
          device.logDeviceEvent('ERROR: ${e.message}');
          dispatchAlert(
            Alert(
              id: 'ERR_${e.deviceId}',
              deviceId: e.deviceId,
              message: e.message,
              severity: AlertSeverity.warning,
            ),
          );
        } on IoTException catch (e) {
          debugPrint('Critical IoT Failure: $e');
        } catch (e) {
          // Catch unhandled
          device.connectionState = ConnectionState.error;
        }
      }
      // Notify UI to rebuild
      _tickController.sink.add(null);
    });
  }

  void dispatchAlert(Alert alert) {
    _alertController.sink.add(alert);
  }

  void dispose() {
    _pollingTimer?.cancel();
    _alertController.close();
    _tickController.close();
  }
}

// ============================================================================
// 6. STATE MANAGEMENT (Custom AppStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockIoTHub _hub = MockIoTHub();

  List<SmartDevice> get devices => _hub.devices;
  final List<Alert> activeAlerts = [];

  Room? selectedRoomFilter;
  bool isHubConnected = false;

  AppState() {
    _initSystem();
  }

  void _initSystem() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate bootup
    isHubConnected = true;
    _hub.initializeHub();

    // Listen to Polling Ticks to trigger UI rebuilds
    _hub.tickStream.listen((_) {
      notifyListeners();
    });

    // Listen to Alert Triggers
    _hub.alertStream.listen((alert) {
      activeAlerts.insert(0, alert);
      notifyListeners();
    });

    notifyListeners();
  }

  void setRoomFilter(Room? room) {
    selectedRoomFilter = room;
    notifyListeners();
  }

  void markAlertRead(String alertId) {
    final alert = activeAlerts.firstWhere((a) => a.id == alertId);
    alert.isRead = true;
    notifyListeners();
  }

  Future<void> sendDeviceCommand(
    String deviceId,
    Map<String, dynamic> payload,
  ) async {
    final device = devices.firstWhere((d) => d.id == deviceId);
    try {
      await device.sendCommand(payload);
      notifyListeners(); // Optimistic UI update
    } on IoTException catch (e) {
      // Re-throw to UI for Snackbar rendering
      throw e;
    }
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
// 7. APP ROOT & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Home',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: AppColors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const BootScreen(),
      ),
    );
  }
}

class BootScreen extends StatelessWidget {
  const BootScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    if (state.isHubConnected) {
      return const MainDashboardScaffold();
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hub, size: 80, color: AppColors.primary),
            const SizedBox(height: 32),
            const Text(
              'NEXUS IOT',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connecting to local bridge...',
              style: AppStyles.caption,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. MAIN DASHBOARD SHELL
// ============================================================================

class MainDashboardScaffold extends StatefulWidget {
  const MainDashboardScaffold({Key? key}) : super(key: key);

  @override
  State<MainDashboardScaffold> createState() => _MainDashboardScaffoldState();
}

class _MainDashboardScaffoldState extends State<MainDashboardScaffold> {
  int _currentIndex = 0;
  final _screens = [const HomeTab(), const AlertsTab(), const RoutinesTab()];

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final unreadAlerts = state.activeAlerts.where((a) => !a.isRead).length;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceHighlight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          showUnselectedLabels: false,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (unreadAlerts > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadAlerts',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'Routines',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 9. HOME TAB (Room Filter & Device Grid)
// ============================================================================

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  String _formatRoomName(Room room) {
    switch (room) {
      case Room.livingRoom:
        return "Living Room";
      case Room.bedroom:
        return "Bedroom";
      case Room.kitchen:
        return "Kitchen";
      case Room.garage:
        return "Garage";
      case Room.exterior:
        return "Exterior";
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final filteredDevices = state.selectedRoomFilter == null
        ? state.devices
        : state.devices
              .where((d) => d.room == state.selectedRoomFilter)
              .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Evening,',
                        style: AppStyles.h3.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Text('My Smart Home', style: AppStyles.h1),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=admin',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Room Filters
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _RoomFilterChip(
                    label: 'All Rooms',
                    isSelected: state.selectedRoomFilter == null,
                    onTap: () => state.setRoomFilter(null),
                  ),
                  ...Room.values.map(
                    (r) => _RoomFilterChip(
                      label: _formatRoomName(r),
                      isSelected: state.selectedRoomFilter == r,
                      onTap: () => state.setRoomFilter(r),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Device Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final device = filteredDevices[index];
                return _DeviceCard(device: device);
              }, childCount: filteredDevices.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _RoomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoomFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceHighlight,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final SmartDevice device;
  const _DeviceCard({required this.device});

  IconData _getIcon() {
    switch (device.type) {
      case DeviceType.thermostat:
        return Icons.thermostat;
      case DeviceType.light:
        return Icons.lightbulb;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.lock:
        return Icons.lock;
      case DeviceType.motionSensor:
        return Icons.sensors;
    }
  }

  Color _getStatusColor() {
    if (device.connectionState == ConnectionState.offline)
      return AppColors.textMuted;
    if (device.connectionState == ConnectionState.error) return AppColors.error;
    if (device is SmartLight && (device as SmartLight).isOn)
      return AppColors.accent;
    if (device is SmartLock && !(device as SmartLock).isLocked)
      return AppColors.warning;
    return AppColors.success;
  }

  String _getSubtitle() {
    if (device.connectionState == ConnectionState.offline) return 'Offline';
    if (device.connectionState == ConnectionState.error) return 'Error';

    if (device is Thermostat)
      return '${(device as Thermostat).currentTemperature.toStringAsFixed(1)}°F';
    if (device is SmartLight)
      return (device as SmartLight).isOn
          ? '${(device as SmartLight).brightness.toInt()}%'
          : 'Off';
    if (device is SecurityCamera)
      return (device as SecurityCamera).isRecording ? 'Recording' : 'Idle';
    if (device is SmartLock)
      return (device as SmartLock).isLocked ? 'Locked' : 'Unlocked';
    return 'Online';
  }

  @override
  Widget build(BuildContext context) {
    final bool isOffline = device.connectionState == ConnectionState.offline;

    return GestureDetector(
      onTap: () {
        if (!isOffline) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(device: device),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceHighlight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: isOffline ? 0.5 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIcon(), color: _getStatusColor(), size: 24),
                  ),
                  if (device.batteryLevel < 20)
                    const Icon(
                      Icons.battery_alert,
                      color: AppColors.error,
                      size: 16,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      color: isOffline ? AppColors.error : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 10. DEVICE DETAIL SCREEN & POLYMORPHIC CONTROLS
// ============================================================================

class DeviceDetailScreen extends StatelessWidget {
  final SmartDevice device;
  const DeviceDetailScreen({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    // Find live reference to guarantee re-renders during polling
    final liveDevice = state.devices.firstWhere((d) => d.id == device.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(liveDevice.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDeviceLogs(context, liveDevice),
          ),
        ],
      ),
      body: liveDevice.connectionState == ConnectionState.offline
          ? const Center(
              child: Text(
                'Device has gone offline.',
                style: TextStyle(color: AppColors.error, fontSize: 18),
              ),
            )
          : _buildDeviceControls(context, state, liveDevice),
    );
  }

  Widget _buildDeviceControls(
    BuildContext context,
    AppState state,
    SmartDevice device,
  ) {
    if (device is Thermostat)
      return _ThermostatUI(device: device, state: state);
    if (device is SmartLight)
      return _SmartLightUI(device: device, state: state);
    if (device is SecurityCamera) return _CameraUI(device: device);
    if (device is SmartLock) return _LockUI(device: device, state: state);
    return const Center(child: Text('Unknown device type.'));
  }

  void _showDeviceLogs(BuildContext context, SmartDevice device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hardware Audit Logs', style: AppStyles.h2),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: device.recentLogs.length,
                separatorBuilder: (c, i) =>
                    const Divider(color: AppColors.surfaceHighlight),
                itemBuilder: (ctx, idx) {
                  final log = device.recentLogs[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FormatUtils.time(log.timestamp),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            log.message,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
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
    );
  }
}

// --- THERMOSTAT CUSTOM UI ---

class _ThermostatUI extends StatelessWidget {
  final Thermostat device;
  final AppState state;
  const _ThermostatUI({required this.device, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        // Custom Radial Painter
        Center(
          child: GestureDetector(
            onPanUpdate: (details) {
              // Extremely simplified gesture handling for the dial
              // In production, use complex atan2 math to map drag to arc angles
              double delta = details.delta.dx > 0 ? 0.5 : -0.5;
              state.sendDeviceCommand(device.id, {
                'targetTemperature': (device.targetTemperature + delta).clamp(
                  60.0,
                  90.0,
                ),
              });
            },
            child: CustomPaint(
              size: const Size(300, 300),
              painter: ThermostatDialPainter(
                currentTemp: device.currentTemperature,
                targetTemp: device.targetTemperature,
                isHeating: device.isHeating,
                isCooling: device.isCooling,
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _InfoWidget(
              label: 'Humidity',
              value: '${device.currentHumidity.toStringAsFixed(0)}%',
            ),
            _InfoWidget(
              label: 'Mode',
              value: device.isHeating
                  ? 'Heating'
                  : (device.isCooling ? 'Cooling' : 'Eco'),
            ),
            _InfoWidget(label: 'Battery', value: '${device.batteryLevel}%'),
          ],
        ),
        const SizedBox(height: 48),
        // Telemetry Chart
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Temperature History', style: AppStyles.h3),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: TelemetryChartPainter(
                data: device.temperatureHistory.toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _InfoWidget extends StatelessWidget {
  final String label;
  final String value;
  const _InfoWidget({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// --- THERMOSTAT DIAL CUSTOM PAINTER ---

class ThermostatDialPainter extends CustomPainter {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final bool isCooling;

  ThermostatDialPainter({
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.isCooling,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Background Track
    final bgPaint = Paint()
      ..color = AppColors.surfaceHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      0.8 * math.pi,
      1.4 * math.pi,
      false,
      bgPaint,
    );

    // 2. Draw Ticks
    final tickPaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.3)
      ..strokeWidth = 2;
    for (int i = 0; i <= 40; i++) {
      double angle = 0.8 * math.pi + (i / 40) * 1.4 * math.pi;
      double innerR = radius - 45;
      double outerR = radius - 35;
      if (i % 5 == 0) outerR = radius - 30; // major ticks

      canvas.drawLine(
        Offset(
          center.dx + innerR * math.cos(angle),
          center.dy + innerR * math.sin(angle),
        ),
        Offset(
          center.dx + outerR * math.cos(angle),
          center.dy + outerR * math.sin(angle),
        ),
        tickPaint,
      );
    }

    // 3. Draw Target Arc
    double minTemp = 60.0;
    double maxTemp = 90.0;
    double normalizedTarget = (targetTemp - minTemp) / (maxTemp - minTemp);
    double targetAngle = 0.8 * math.pi + normalizedTarget * 1.4 * math.pi;

    Color activeColor = AppColors.textMuted;
    if (isHeating) activeColor = AppColors.error;
    if (isCooling) activeColor = AppColors.primary;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Draw sweep from start to target
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      0.8 * math.pi,
      normalizedTarget * 1.4 * math.pi,
      false,
      activePaint,
    );

    // 4. Draw Indicator Thumb
    final thumbPos = Offset(
      center.dx + (radius - 20) * math.cos(targetAngle),
      center.dy + (radius - 20) * math.sin(targetAngle),
    );
    canvas.drawCircle(
      thumbPos,
      16,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      thumbPos,
      6,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill,
    );

    // 5. Draw Text (Current Temp)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: currentTemp.toStringAsFixed(1),
      style: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 10,
      ),
    );

    // Target Subtext
    textPainter.text = TextSpan(
      text: 'Target: ${targetTemp.toStringAsFixed(1)}°',
      style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Always repaint for live polling
}

// --- TELEMETRY CHART PAINTER ---

class TelemetryChartPainter extends CustomPainter {
  final List<TelemetryPoint> data;
  TelemetryChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double minVal = data.map((e) => e.value).reduce(math.min) - 2;
    double maxVal = data.map((e) => e.value).reduce(math.max) + 2;
    double range = maxVal - minVal;
    if (range == 0) range = 1;

    final stepX = size.width / (data.length <= 1 ? 1 : data.length - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double normalizedY = (data[i].value - minVal) / range;
      double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Curve smoothing using cubic bezier
        double prevX = (i - 1) * stepX;
        double prevY =
            size.height -
            (((data[i - 1].value - minVal) / range) * size.height);

        double controlX1 = prevX + (x - prevX) / 2;
        double controlY1 = prevY;
        double controlX2 = prevX + (x - prevX) / 2;
        double controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill Gradient
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, size.height),
      [
        AppColors.primary.withOpacity(0.5),
        AppColors.background.withOpacity(0.0),
      ],
    );
    canvas.drawPath(fillPath, Paint()..shader = gradient);

    // Line Stroke
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- LIGHT CONTROLS UI ---

class _SmartLightUI extends StatelessWidget {
  final SmartLight device;
  final AppState state;
  const _SmartLightUI({required this.device, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb,
            size: 120,
            color: device.isOn ? AppColors.accent : AppColors.surfaceHighlight,
          ),
          const SizedBox(height: 48),
          SwitchListTile(
            title: const Text('Power', style: AppStyles.h2),
            value: device.isOn,
            activeColor: AppColors.accent,
            onChanged: (val) {
              try {
                state.sendDeviceCommand(device.id, {'isOn': val});
              } catch (e) {
                _showError(context, e.toString());
              }
            },
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Brightness', style: AppStyles.h3),
          ),
          Slider(
            value: device.brightness,
            min: 0,
            max: 100,
            activeColor: AppColors.accent,
            onChanged: device.isOn
                ? (val) {
                    try {
                      state.sendDeviceCommand(device.id, {'brightness': val});
                    } catch (e) {}
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// --- SECURITY CAMERA UI ---

class _CameraUI extends StatelessWidget {
  final SecurityCamera device;
  const _CameraUI({required this.device});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.videocam,
                  size: 64,
                  color: AppColors.surfaceHighlight,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    children: [
                      if (device.isRecording) ...[
                        const Icon(
                          Icons.circle,
                          color: AppColors.error,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'REC',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    FormatUtils.time(DateTime.now()),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: Icon(
              device.motionDetected
                  ? Icons.directions_run
                  : Icons.accessibility,
              color: device.motionDetected
                  ? AppColors.warning
                  : AppColors.success,
            ),
            title: const Text('Motion Sensor'),
            subtitle: Text(
              device.motionDetected ? 'Motion Detected!' : 'Clear',
            ),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SMART LOCK UI ---

class _LockUI extends StatelessWidget {
  final SmartLock device;
  final AppState state;
  const _LockUI({required this.device, required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              try {
                state.sendDeviceCommand(device.id, {
                  'isLocked': !device.isLocked,
                });
              } catch (e) {
                _showError(context, e.toString());
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: device.isLocked
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: device.isLocked
                      ? AppColors.success
                      : AppColors.warning,
                  width: 4,
                ),
              ),
              child: Icon(
                device.isLocked ? Icons.lock : Icons.lock_open,
                size: 80,
                color: device.isLocked ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            device.isLocked ? 'DOOR SECURED' : 'DOOR UNLOCKED',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: device.isLocked ? AppColors.success : AppColors.warning,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap the icon to ${device.isLocked ? "unlock" : "lock"}',
            style: AppStyles.caption,
          ),
        ],
      ),
    );
  }
}

void _showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error),
  );
}

// ============================================================================
// 11. ALERTS TAB
// ============================================================================

class AlertsTab extends StatelessWidget {
  const AlertsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final alerts = state.activeAlerts;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('System Alerts', style: AppStyles.h1),
          ),
          Expanded(
            child: alerts.isEmpty
                ? const Center(
                    child: Text(
                      'All clear. No active alerts.',
                      style: AppStyles.body,
                    ),
                  )
                : ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      Color severityColor =
                          alert.severity == AlertSeverity.critical
                          ? AppColors.error
                          : AppColors.warning;

                      return Dismissible(
                        key: Key(alert.id),
                        onDismissed: (direction) =>
                            state.markAlertRead(alert.id),
                        background: Container(
                          color: AppColors.success,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        child: Container(
                            color: alert.isRead
                              ? Colors.transparent
                              : severityColor.withOpacity(0.05),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: severityColor.withOpacity(0.2),
                              child: Icon(
                                Icons.warning,
                                color: severityColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              alert.message,
                              style: TextStyle(
                                fontWeight: alert.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                            subtitle: Text(
                              '${FormatUtils.date(alert.timestamp)} at ${FormatUtils.time(alert.timestamp)}',
                              style: AppStyles.caption,
                            ),
                          ),
                        ),
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
// 12. ROUTINES TAB (Placeholder for completeness)
// ============================================================================

class RoutinesTab extends StatelessWidget {
  const RoutinesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Automations & Routines Module', style: AppStyles.h2),
    );
  }
}
