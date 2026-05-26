import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// ENTRY POINT
// ============================================================================

// Per-file Color compatibility shim (replaces deprecated `withOpacity` usage)
extension ColorWithValues on Color {
  Color withValues(double opacity) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int b = value & 0xFF;
    return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const GroceryWorkspaceApp());
}

// ============================================================================
// DATA MODELS & ARCHITECTURAL SCHEMAS
// ============================================================================

enum ItemCategory { produce, meatSeafood, dairy, bakery, pantry, household }

enum DeviceIdentity { deviceAlpha, deviceBeta }

class FamilyMember {
  final String id;
  final String name;
  final Color avatarColor;
  final String role;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.role,
  });
}

class GroceryItem {
  final String id;
  final String listId;
  final String name;
  final double quantity;
  final String unit;
  final ItemCategory category;
  final bool isPurchased;
  final DateTime lastModified;

  const GroceryItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isPurchased = false,
    required this.lastModified,
  });

  String get categoryString =>
      category.toString().split('.').last.toUpperCase();

  GroceryItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    ItemCategory? category,
    bool? isPurchased,
    DateTime? lastModified,
  }) {
    return GroceryItem(
      id: id,
      listId: listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}

class GroceryList {
  final String id;
  final String title;
  final String ownerId;
  final List<String> sharedMemberIds;
  final bool isDeleted;
  final DateTime lastModified;

  const GroceryList({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.sharedMemberIds,
    this.isDeleted = false,
    required this.lastModified,
  });

  GroceryList copyWith({
    String? title,
    List<String>? sharedMemberIds,
    bool? isDeleted,
    DateTime? lastModified,
  }) {
    return GroceryList(
      id: id,
      title: title ?? this.title,
      ownerId: ownerId,
      sharedMemberIds: sharedMemberIds ?? this.sharedMemberIds,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}

class SyncLogEntry {
  final DateTime timestamp;
  final String message;
  final String type; // "PUSH", "PULL", "MERGE", "CONFLICT"

  const SyncLogEntry({
    required this.timestamp,
    required this.message,
    required this.type,
  });
}

// ============================================================================
// STATE ENGINE (MANAGES MULTIPLE DEVICES & CLOUD STORAGE FOR SYNC INDUCTION)
// ============================================================================

class GroceryWorkspaceState extends ChangeNotifier {
  // Family configuration structure
  final List<FamilyMember> _familyMembers = [];

  // Simulated Distributed Topology
  // To show cross-device sync offline/online in one file, we maintain independent data stores.
  final Map<String, GroceryList> _cloudLists = {};
  final Map<String, GroceryItem> _cloudItems = {};

  final Map<String, GroceryList> _deviceAlphaLists = {};
  final Map<String, GroceryItem> _deviceAlphaItems = {};

  final Map<String, GroceryList> _deviceBetaLists = {};
  final Map<String, GroceryItem> _deviceBetaItems = {};

  // Device settings states
  DeviceIdentity _activeDevice = DeviceIdentity.deviceAlpha;
  bool _isDeviceAlphaOnline = true;
  bool _isDeviceBetaOnline = true;

  // Global telemetry logging
  final List<SyncLogEntry> _syncTelemetryLog = [];

  GroceryWorkspaceState() {
    _seedWorkspaceData();
  }

  // --- Getters ---
  DeviceIdentity get activeDevice => _activeDevice;
  bool get isAlphaOnline => _isDeviceAlphaOnline;
  bool get isBetaOnline => _isDeviceBetaOnline;
  bool get isCurrentDeviceOnline => _activeDevice == DeviceIdentity.deviceAlpha
      ? _isDeviceAlphaOnline
      : _isDeviceBetaOnline;
  List<FamilyMember> get familyMembers => List.unmodifiable(_familyMembers);
  List<SyncLogEntry> get syncTelemetryLog =>
      List.unmodifiable(_syncTelemetryLog.reversed);

  // Access structures based on runtime device alignment
  Map<String, GroceryList> get _activeListStorage =>
      _activeDevice == DeviceIdentity.deviceAlpha
      ? _deviceAlphaLists
      : _deviceBetaLists;
  Map<String, GroceryItem> get _activeItemStorage =>
      _activeDevice == DeviceIdentity.deviceAlpha
      ? _deviceAlphaItems
      : _deviceBetaItems;

  List<GroceryList> get activeLists =>
      _activeListStorage.values.where((l) => !l.isDeleted).toList();

  List<GroceryItem> getItemsForList(String listId) {
    return _activeItemStorage.values
        .where((item) => item.listId == listId)
        .toList();
  }

  // --- Device Switch Controls ---
  void switchActiveDevice(DeviceIdentity targets) {
    _activeDevice = targets;
    _logTelemetry(
      "Switched workspace viewport terminal focus to ${targets.toString().split('.').last.toUpperCase()}",
      "SYSTEM",
    );
    notifyListeners();
  }

  void toggleOnlineConnectivity(DeviceIdentity device) {
    if (device == DeviceIdentity.deviceAlpha) {
      _isDeviceAlphaOnline = !_isDeviceAlphaOnline;
      _logTelemetry(
        "Device Alpha network connectivity changed to: ${_isDeviceAlphaOnline ? 'ONLINE' : 'OFFLINE'}",
        "SYSTEM",
      );
      if (_isDeviceAlphaOnline)
        executeBackgroundSynchronization(DeviceIdentity.deviceAlpha);
    } else {
      _isDeviceBetaOnline = !_isDeviceBetaOnline;
      _logTelemetry(
        "Device Beta network connectivity changed to: ${_isDeviceBetaOnline ? 'ONLINE' : 'OFFLINE'}",
        "SYSTEM",
      );
      if (_isDeviceBetaOnline)
        executeBackgroundSynchronization(DeviceIdentity.deviceBeta);
    }
    notifyListeners();
  }

  // --- Core CRUD Workflows (Applied localized to focused device) ---
  void createGroceryList(String title) {
    final id =
        "list_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100)}";
    final newList = GroceryList(
      id: id,
      title: title,
      ownerId: "user_primary",
      sharedMemberIds: [],
      lastModified: DateTime.now(),
    );
    _activeListStorage[id] = newList;
    _logTelemetry(
      "Created list '$title' locally on active node device.",
      "LOCAL_WRITE",
    );

    _triggerAutoSyncCycle();
    notifyListeners();
  }

  void addGroceryItem(
    String listId,
    String name,
    double qty,
    String unit,
    ItemCategory category,
  ) {
    final id =
        "item_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100)}";
    final newItem = GroceryItem(
      id: id,
      listId: listId,
      name: name,
      quantity: qty,
      unit: unit,
      category: category,
      lastModified: DateTime.now(),
    );
    _activeItemStorage[id] = newItem;

    // Explicitly update parent container timestamp modification tracking attributes
    if (_activeListStorage.containsKey(listId)) {
      _activeListStorage[listId] = _activeListStorage[listId]!.copyWith(
        lastModified: DateTime.now(),
      );
    }

    _logTelemetry(
      "Added item '$name' ($qty $unit) to tracking context.",
      "LOCAL_WRITE",
    );
    _triggerAutoSyncCycle();
    notifyListeners();
  }

  void toggleItemPurchasedState(String itemId) {
    if (_activeItemStorage.containsKey(itemId)) {
      final target = _activeItemStorage[itemId]!;
      _activeItemStorage[itemId] = target.copyWith(
        isPurchased: !target.isPurchased,
        lastModified: DateTime.now(),
      );

      if (_activeListStorage.containsKey(target.listId)) {
        _activeListStorage[target.listId] = _activeListStorage[target.listId]!
            .copyWith(lastModified: DateTime.now());
      }

      _logTelemetry(
        "Toggled purchase execution mapping context for item index signature: ${target.name}",
        "LOCAL_WRITE",
      );
      _triggerAutoSyncCycle();
      notifyListeners();
    }
  }

  void shareListWithFamilyMember(String listId, String memberId) {
    if (_activeListStorage.containsKey(listId)) {
      final list = _activeListStorage[listId]!;
      if (!list.sharedMemberIds.contains(memberId)) {
        final updatedShares = List<String>.from(list.sharedMemberIds)
          ..add(memberId);
        _activeListStorage[listId] = list.copyWith(
          sharedMemberIds: updatedShares,
          lastModified: DateTime.now(),
        );
        final memberName = _familyMembers
            .firstWhere((m) => m.id == memberId)
            .name;
        _logTelemetry(
          "Shared list '${list.title}' with member node: $memberName",
          "SHARE",
        );
        _triggerAutoSyncCycle();
        notifyListeners();
      }
    }
  }

  // --- Relational List Merging Engine ---
  void mergeTwoGroceryLists(String sourceListId, String targetListId) {
    final sourceList = _activeListStorage[sourceListId];
    final targetList = _activeListStorage[targetListId];

    if (sourceList == null || targetList == null) return;

    _logTelemetry(
      "Initiating explicit compile transaction merge: '${sourceList.title}' into '${targetList.title}'",
      "MERGE",
    );

    // Gather and map elements matching targeting parameters
    final sourceItems = _activeItemStorage.values
        .where((item) => item.listId == sourceListId)
        .toList();
    final targetItems = _activeItemStorage.values
        .where((item) => item.listId == targetListId)
        .toList();

        for (var srcItem in sourceItems) {
      // Look for match based on matching character names (Case Insensitive)
      final matchedTargetIdx = targetItems.indexWhere(
        (t) => t.name.trim().toLowerCase() == srcItem.name.trim().toLowerCase(),
      );

      if (matchedTargetIdx != -1) {
        // Quantities aggregated together safely across intersecting targets
        final existingItem = targetItems[matchedTargetIdx];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + srcItem.quantity,
          isPurchased:
              existingItem.isPurchased &&
              srcItem.isPurchased, // Keep active if either is unpurchased
          lastModified: DateTime.now(),
        );
        _activeItemStorage[existingItem.id] = updatedItem;
      } else {
        // Move unmatched source items under new parent destination references context bindings
        // Create matching item referencing target container
        _activeItemStorage[srcItem.id] = GroceryItem(
          id: srcItem.id,
          listId: targetListId,
          name: srcItem.name,
          quantity: srcItem.quantity,
          unit: srcItem.unit,
          category: srcItem.category,
          isPurchased: srcItem.isPurchased,
          lastModified: DateTime.now(),
        );
      }

      // Clean up/remove old source item records
      _activeItemStorage.remove(srcItem.id);
    }

    // Flag source list as soft-deleted out of viewports matrices layout tracking bounds
    _activeListStorage[sourceListId] = sourceList.copyWith(
      isDeleted: true,
      lastModified: DateTime.now(),
    );

    _logTelemetry(
      "Merge pipeline complete. Source container components integrated and archived.",
      "MERGE",
    );
    _triggerAutoSyncCycle();
    notifyListeners();
  }

  // --- Distributed Synchronization Layer & Conflict Reconciliation ---
  void _triggerAutoSyncCycle() {
    if (isCurrentDeviceOnline) {
      executeBackgroundSynchronization(_activeDevice);
    } else {
      _logTelemetry(
        "Device Offline. Operations logged to localized partition cache for deferred processing queue.",
        "OFFLINE_HOLD",
      );
    }
  }

  void executeBackgroundSynchronization(DeviceIdentity device) {
    final bool onlineState = (device == DeviceIdentity.deviceAlpha)
        ? _isDeviceAlphaOnline
        : _isDeviceBetaOnline;
    if (!onlineState) return;

    final Map<String, GroceryList> deviceLists =
        (device == DeviceIdentity.deviceAlpha)
        ? _deviceAlphaLists
        : _deviceBetaLists;
    final Map<String, GroceryItem> deviceItems =
        (device == DeviceIdentity.deviceAlpha)
        ? _deviceAlphaItems
        : _deviceBetaItems;
    final String label = (device == DeviceIdentity.deviceAlpha)
        ? "DEVICE_ALPHA"
        : "DEVICE_BETA";

    _logTelemetry(
      "Establishing handshake telemetry linkage pipeline with Cloud server for $label...",
      "SYNC_START",
    );

    // 1. Sync Lists Engine: Process bidirectionally using Timestamp Conflict Resolution Architecture
    deviceLists.forEach((id, localList) {
      if (!_cloudLists.containsKey(id)) {
        // Cloud missing definition. Push local item to server
        _cloudLists[id] = localList;
        _logTelemetry(
          "Cloud Repository Sync: Propagated new upstream tracking list '${localList.title}'",
          "PUSH",
        );
      } else {
        final cloudList = _cloudLists[id]!;
        if (localList.lastModified.isAfter(cloudList.lastModified)) {
          _cloudLists[id] = localList;
          _logTelemetry(
            "Conflict Reconciled: Upstream Cloud partition updated via fresher localized dataset sequence context.",
            "PUSH",
          );
        } else if (cloudList.lastModified.isAfter(localList.lastModified)) {
          deviceLists[id] = cloudList;
          _logTelemetry(
            "Conflict Reconciled: Downstream client state corrected via prioritized upstream cloud sequence configuration.",
            "PULL",
          );
        }
      }
    });

    // Mirror any upstream list sets added via external nodes down to localized client arrays
    _cloudLists.forEach((id, cloudList) {
      if (!deviceLists.containsKey(id)) {
        deviceLists[id] = cloudList;
        _logTelemetry(
          "Downstream Replication Pipeline: Synced new tracking structure '${cloudList.title}' into client system cache.",
          "PULL",
        );
      }
    });

    // 2. Sync Grocery Items Engine Elements Boundary Layout Execution
    deviceItems.forEach((id, localItem) {
      if (!_cloudItems.containsKey(id)) {
        _cloudItems[id] = localItem;
      } else {
        final cloudItem = _cloudItems[id]!;
        if (localItem.lastModified.isAfter(cloudItem.lastModified)) {
          _cloudItems[id] = localItem;
        } else if (cloudItem.lastModified.isAfter(localItem.lastModified)) {
          deviceItems[id] = cloudItem;
        }
      }
    });

    _cloudItems.forEach((id, cloudItem) {
      if (!deviceItems.containsKey(id)) {
        deviceItems[id] = cloudItem;
      }
    });

    _logTelemetry(
      "Synchronization processing complete. Datastores normalized to consistent parity matching values.",
      "SYNC_END",
    );
  }

  void _logTelemetry(String message, String type) {
    _syncTelemetryLog.add(
      SyncLogEntry(timestamp: DateTime.now(), message: message, type: type),
    );
    if (_syncTelemetryLog.length > 100) _syncTelemetryLog.removeAt(0);
  }

  // --- Seed Initialization Configurations Data Structures mapping framework ---
  void _seedWorkspaceData() {
    _familyMembers.addAll([
      const FamilyMember(
        id: "mem_1",
        name: "Sarah (Co-owner)",
        avatarColor: Colors.deepPurple,
        role: "Spouse",
      ),
      const FamilyMember(
        id: "mem_2",
        name: "Alex",
        avatarColor: Colors.teal,
        role: "Teenager",
      ),
      const FamilyMember(
        id: "mem_3",
        name: "Dad",
        avatarColor: Colors.blueGrey,
        role: "Parent",
      ),
    ]);

    // Setup generic initial lists
    final list1 = GroceryList(
      id: "l_seed_1",
      title: "Weekly Grocery Run",
      ownerId: "user_primary",
      sharedMemberIds: ["mem_1"],
      lastModified: DateTime.now().subtract(const Duration(hours: 2)),
    );
    final list2 = GroceryList(
      id: "l_seed_2",
      title: "Friday Night BBQ Party",
      ownerId: "user_primary",
      sharedMemberIds: ["mem_1", "mem_2"],
      lastModified: DateTime.now().subtract(const Duration(minutes: 45)),
    );

    _cloudLists[list1.id] = list1;
    _cloudLists[list2.id] = list2;

    final item1 = GroceryItem(
      id: "i_1",
      listId: "l_seed_1",
      name: "Organic Whole Milk",
      quantity: 2,
      unit: "Gallons",
      category: ItemCategory.dairy,
      lastModified: DateTime.now().subtract(const Duration(hours: 2)),
    );
    final item2 = GroceryItem(
      id: "i_2",
      listId: "l_seed_1",
      name: "Avocados",
      quantity: 5,
      unit: "pcs",
      category: ItemCategory.produce,
      isPurchased: true,
      lastModified: DateTime.now().subtract(const Duration(hours: 1)),
    );
    final item3 = GroceryItem(
      id: "i_3",
      listId: "l_seed_2",
      name: "Ribeye Steaks",
      quantity: 4,
      unit: "packs",
      category: ItemCategory.meatSeafood,
      lastModified: DateTime.now().subtract(const Duration(minutes: 45)),
    );
    final item4 = GroceryItem(
      id: "i_4",
      listId: "l_seed_2",
      name: "Brioche Buns",
      quantity: 2,
      unit: "Bags",
      category: ItemCategory.bakery,
      lastModified: DateTime.now().subtract(const Duration(minutes: 30)),
    );

    _cloudItems[item1.id] = item1;
    _cloudItems[item2.id] = item2;
    _cloudItems[item3.id] = item3;
    _cloudItems[item4.id] = item4;

    // Clone baseline dataset uniformly to all nodes for matching structural defaults out-of-box operation
    _deviceAlphaLists[list1.id] = list1;
    _deviceAlphaLists[list2.id] = list2;
    _deviceAlphaItems[item1.id] = item1;
    _deviceAlphaItems[item2.id] = item2;
    _deviceAlphaItems[item3.id] = item3;
    _deviceAlphaItems[item4.id] = item4;

    _deviceBetaLists[list1.id] = list1;
    _deviceBetaLists[list2.id] = list2;
    _deviceBetaItems[item1.id] = item1;
    _deviceBetaItems[item2.id] = item2;
    _deviceBetaItems[item3.id] = item3;
    _deviceBetaItems[item4.id] = item4;

    _logTelemetry(
      "System Workspace initialization complete. Local distributed structures operational.",
      "SYSTEM",
    );
  }
}

final GroceryWorkspaceState globalGroceryWorkspaceState =
    GroceryWorkspaceState();

// ============================================================================
// SYSTEM CONTAINER MANAGEMENT FRAMEWORK
// ============================================================================

class GroceryWorkspaceApp extends StatelessWidget {
  const GroceryWorkspaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: globalGroceryWorkspaceState,
      builder: (context, child) {
        return MaterialApp(
          title: 'FamilyCart SyncEngine Workspace',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(
              0xFF0F766E,
            ), // Deep Emerald/Teal Culinary Accent
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              primary: const Color(0xFF0F766E),
              secondary: const Color(0xFF1E293B),
              surface: Colors.white,
              background: const Color(0xFFF8FAFC),
              error: const Color(0xFFE11D48),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              bodyLarge: TextStyle(
                fontSize: 15,
                color: Color(0xFF334155),
                height: 1.4,
              ),
              bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          home: const WorkspaceDashboardBridge(),
        );
      },
    );
  }
}

// ============================================================================
// MAIN INTERACTIVE PANEL MANAGEMENT ROUTER VIEWBRIDGE BRIDGE
// ============================================================================

class WorkspaceDashboardBridge extends StatefulWidget {
  const WorkspaceDashboardBridge({Key? key}) : super(key: key);

  @override
  State<WorkspaceDashboardBridge> createState() =>
      _WorkspaceDashboardBridgeState();
}

class _WorkspaceDashboardBridgeState extends State<WorkspaceDashboardBridge> {
  int _currentNavigationIndex = 0;

  final List<Widget> _workspaceViewports = [
    const ListShelfViewport(),
    const FamilyHubViewport(),
    const SyncSimulatorViewport(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = globalGroceryWorkspaceState;
    final activeDeviceLabel = state.activeDevice == DeviceIdentity.deviceAlpha
        ? "Alpha Device Mode"
        : "Beta Device Mode";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "FamilyCart Workspace",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              "$activeDeviceLabel (${state.isCurrentDeviceOnline ? 'Connected/Online' : 'Offline Mode'})",
              style: TextStyle(
                fontSize: 11,
                color: Colors.teal.shade100,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        elevation: 4,
        actions: [
          // Device Emulator fast selector control ribbon interface
          PopupMenuButton<DeviceIdentity>(
            initialValue: state.activeDevice,
            onSelected: (device) => state.switchActiveDevice(device),
            icon: const Icon(
              Icons.phonelink_setup_rounded,
              color: Colors.white,
            ),
            tooltip: "Switch Emulated Node Terminal",
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DeviceIdentity.deviceAlpha,
                child: Text("Terminal Node: Device Alpha"),
              ),
              const PopupMenuItem(
                value: DeviceIdentity.deviceBeta,
                child: Text("Terminal Node: Device Beta"),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              state.isCurrentDeviceOnline
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color: Colors.white,
            ),
            tooltip: "Toggle Network Status Connection Block",
            onPressed: () => state.toggleOnlineConnectivity(state.activeDevice),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentNavigationIndex,
        children: _workspaceViewports,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentNavigationIndex,
          onDestinationSelected: (idx) =>
              setState(() => _currentNavigationIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0F766E).withOpacity(0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_rounded),
              label: 'My Lists',
            ),
            NavigationDestination(
              icon: Icon(Icons.family_restroom_rounded),
              label: 'Family Share',
            ),
            NavigationDestination(
              icon: Icon(Icons.sync_alt_rounded),
              label: 'Sync Console',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VIEWPORT 1: GROCERY LISTS CORE CONTROL SHELF PANEL
// ============================================================================

class ListShelfViewport extends StatelessWidget {
  const ListShelfViewport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lists = globalGroceryWorkspaceState.activeLists;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Quick Utility Header Segment Row Action Panels
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Procurement Registers (${lists.length})",
                    style: theme.textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF0F766E,
                          ).withOpacity(0.08),
                        ),
                        icon: const Icon(
                          Icons.merge_type_rounded,
                          color: Color(0xFF0F766E),
                        ),
                        tooltip: "Execute List Compiling Merge Sequence",
                        onPressed: () => _displayMergeWizardModal(context),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: "Create New Container Register",
                        onPressed: () => _displayListCreationPrompt(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Dynamic Stream Builders Rendering Local File Cache Matrices Layouts
            Expanded(
              child: lists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_clear_rounded,
                            size: 54,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No active list entities localized inside database.",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final list = lists[index];
                        final itemsCount = globalGroceryWorkspaceState
                            .getItemsForList(list.id)
                            .length;
                        final purchasedCount = globalGroceryWorkspaceState
                            .getItemsForList(list.id)
                            .where((i) => i.isPurchased)
                            .length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade100),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF0F766E,
                              ).withOpacity(0.1),
                              child: const Icon(
                                Icons.format_list_bulleted_rounded,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                            title: Text(
                              list.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              "$purchasedCount / $itemsCount elements procured • Shared with (${list.sharedMemberIds.length}) members",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ListItemsDetailViewport(targetList: list),
                                ),
                              );
                            },
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

  // --- Utility Actions Dialogues Creators ---
  void _displayListCreationPrompt(BuildContext context) {
    final TextEditingController fieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Initialize Registry Element"),
        content: TextField(
          controller: fieldController,
          decoration: const InputDecoration(
            hintText: "Registry name (e.g., Target Run, Staples)",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abort"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (fieldController.text.trim().isNotEmpty) {
                globalGroceryWorkspaceState.createGroceryList(
                  fieldController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Commit Entry"),
          ),
        ],
      ),
    );
  }

  void _displayMergeWizardModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ListMergeProcessingSheetForm(),
    );
  }
}

// ============================================================================
// STATEFUL DIALOG MODULE Component: TRANS-COMPILING MERGING MATRIX MANAGER
// ============================================================================

class ListMergeProcessingSheetForm extends StatefulWidget {
  const ListMergeProcessingSheetForm({Key? key}) : super(key: key);

  @override
  State<ListMergeProcessingSheetForm> createState() =>
      _ListMergeProcessingSheetFormState();
}

class _ListMergeProcessingSheetFormState
    extends State<ListMergeProcessingSheetForm> {
  String? _sourceListId;
  String? _targetListId;

  @override
  Widget build(BuildContext context) {
    final availableLists = globalGroceryWorkspaceState.activeLists;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Relational Compiler Merge Wizard",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Select source registry block to drain and blend elements into baseline target registry context completely.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _sourceListId,
            decoration: const InputDecoration(
              labelText: "Source Registry (Drains out entirely)",
              border: OutlineInputBorder(),
            ),
            items: availableLists
                .map((l) => DropdownMenuItem(value: l.id, child: Text(l.title)))
                .toList(),
            onChanged: (v) => setState(() => _sourceListId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _targetListId,
            decoration: const InputDecoration(
              labelText:
                  "Target Destination Registry (Aggregates & Accumulates)",
              border: OutlineInputBorder(),
            ),
            items: availableLists
                .map((l) => DropdownMenuItem(value: l.id, child: Text(l.title)))
                .toList(),
            onChanged: (v) => setState(() => _targetListId = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed:
                (_sourceListId != null &&
                    _targetListId != null &&
                    _sourceListId != _targetListId)
                ? () {
                    globalGroceryWorkspaceState.mergeTwoGroceryLists(
                      _sourceListId!,
                      _targetListId!,
                    );
                    Navigator.pop(context);
                  }
                : null,
            child: const Text(
              "Execute Trans-Compile Aggregation",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NESTED MASTER-DETAIL VIEWPORT PAGE: REGISTRY INTERACTIVE ENTRY MATRIX
// ============================================================================

class ListItemsDetailViewport extends StatefulWidget {
  final GroceryList targetList;
  const ListItemsDetailViewport({Key? key, required this.targetList})
    : super(key: key);

  @override
  State<ListItemsDetailViewport> createState() =>
      _ListItemsDetailViewportState();
}

class _ListItemsDetailViewportState extends State<ListItemsDetailViewport> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  ItemCategory _selectedCategory = ItemCategory.produce;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _dispatchItemAddition() {
    if (_nameController.text.trim().isEmpty) return;
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final unit = _unitController.text.trim().isEmpty
        ? "units"
        : _unitController.text.trim();

    globalGroceryWorkspaceState.addGroceryItem(
      widget.targetList.id,
      _nameController.text.trim(),
      qty,
      unit,
      _selectedCategory,
    );

    _nameController.clear();
    _qtyController.clear();
    _unitController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = globalGroceryWorkspaceState.getItemsForList(
      widget.targetList.id,
    );

    // Group items: Active at top, purchased pushed to base bottom layer arrays automatically
    final activeItems = items.where((i) => !i.isPurchased).toList();
    final purchasedItems = items.where((i) => i.isPurchased).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.targetList.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F766E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: "Modify Share Access Tokens",
            onPressed: () => _displaySharingAssignmentOverlay(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Inline Interactive quick-add drawer container assembly block layout rows
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _nameController,
                            decoration: const InputDecoration(
                            hintText: "Item name...",
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                            hintText: "Qty",
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _unitController,
                            decoration: const InputDecoration(
                            hintText: "Unit",
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<ItemCategory>(
                        value: _selectedCategory,
                        isDense: true,
                        items: ItemCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.toString().split('.').last.toUpperCase(),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCategory = v);
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _dispatchItemAddition,
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text("Add Token"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Render structured checklist interface split layout matrices arrays
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        "Registry manifests are currently completely clear.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (activeItems.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "Needed Elements (${activeItems.length})",
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ...activeItems.map(
                            (item) => _buildChecklistRowNode(item, theme),
                          ),
                        ],
                        if (purchasedItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "Procured Log (${purchasedItems.length})",
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...purchasedItems.map(
                            (item) => _buildChecklistRowNode(item, theme),
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

  Widget _buildChecklistRowNode(GroceryItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: item.isPurchased ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: CheckboxListTile(
        value: item.isPurchased,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF0F766E),
        onChanged: (val) =>
            globalGroceryWorkspaceState.toggleItemPurchasedState(item.id),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
        subtitle: Text(
          "${item.categoryString} • ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}",
          style: TextStyle(
            fontSize: 11,
            color: item.isPurchased
                ? Colors.grey.shade300
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  void _displaySharingAssignmentOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Authorize Distributed Access Control Share",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...globalGroceryWorkspaceState.familyMembers.map((member) {
                  final isShared = widget.targetList.sharedMemberIds.contains(
                    member.id,
                  );
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: member.avatarColor,
                      child: Text(
                        member.name[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: Text("Role Designation: ${member.role}"),
                    trailing: isShared
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0F766E),
                          )
                        : const Icon(
                            Icons.add_circle_outline,
                            color: Colors.grey,
                          ),
                    onTap: isShared
                        ? null
                        : () {
                            globalGroceryWorkspaceState
                                .shareListWithFamilyMember(
                                  widget.targetList.id,
                                  member.id,
                                );
                            Navigator.pop(context);
                          },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// VIEWPORT 2: FAMILY HUB DECENTRALIZED MANAGEMENT DASHBOARD
// ============================================================================

class FamilyHubViewport extends StatelessWidget {
  const FamilyHubViewport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = globalGroceryWorkspaceState.familyMembers;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Family Cluster Namespace Nodes",
                style: theme.textTheme.displayLarge!.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                "Managing connected peer validation accounts linked to unified cross-device databases streams.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Matrix list of interactive profiles mapping signatures
              ...members.map((m) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: m.avatarColor,
                      radius: 20,
                      child: Text(
                        m.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      m.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      "Access Group Identity Profile: ${m.role}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "SYNCED",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                "Active Group Rules Policy Framework",
                style: theme.textTheme.titleMedium!.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildPolicyDisclaimerRow(
                Icons.security,
                "All actions utilize atomic clock timestamp validation mechanisms for automatic transaction reconciliation handling.",
              ),
              _buildPolicyDisclaimerRow(
                Icons.sync_lock_rounded,
                "Localized client nodes fall back to internal cache maps instantly during disconnect exceptions safely.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyDisclaimerRow(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// VIEWPORT 3: TELEMETRY DISTRIBUTED REPLICATION MONITOR SYNC VIEWPORT
// ============================================================================

class SyncSimulatorViewport extends StatelessWidget {
  const SyncSimulatorViewport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logEntries = globalGroceryWorkspaceState.syncTelemetryLog;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Structural Live Topology custom canvas painter display array layout panel context bounds
            Container(
              height: 140,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF0F172A,
                ), // Matrix Dark Telemetry Background
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: DataNetworkTopologyPainter(
                  isAlphaOnline: globalGroceryWorkspaceState.isAlphaOnline,
                  isBetaOnline: globalGroceryWorkspaceState.isBetaOnline,
                  activeNode: globalGroceryWorkspaceState.activeDevice,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Live Telemetry Synchronization Log Stream",
                    style: theme.textTheme.titleMedium!.copyWith(fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "REAL-TIME ENGINE",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Logging terminal readouts outputs array matrices rows implementation elements
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black),
                ),
                child: logEntries.isEmpty
                    ? const Center(
                        child: Text(
                          "Terminal pipelines clear. Awaiting logs stream data...",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: logEntries.length,
                        itemBuilder: (context, idx) {
                          final entry = logEntries[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "[${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}]",
                                  style: const TextStyle(
                                    fontFamily: "monospace",
                                    fontSize: 11,
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _fetchTelemetryTagColor(entry.type),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    entry.type,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: "monospace",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.message,
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 12,
                                      fontFamily: "monospace",
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
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

  Color _fetchTelemetryTagColor(String type) {
    switch (type) {
      case "SYSTEM":
        return Colors.blue.shade600;
      case "LOCAL_WRITE":
        return Colors.purple.shade500;
      case "PUSH":
        return Colors.green.shade600;
      case "PULL":
        return Colors.orange.shade600;
      case "MERGE":
        return Colors.deepOrange;
      case "CONFLICT":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ============================================================================
// CUSTOM CANVAS VISUALIZATION PAINTER: TELEMETRY TOPOLOGY VECTOR CHART GRAPH
// ============================================================================

class DataNetworkTopologyPainter extends CustomPainter {
  final bool isAlphaOnline;
  final bool isBetaOnline;
  final DeviceIdentity activeNode;

  const DataNetworkTopologyPainter({
    required this.isAlphaOnline,
    required this.isBetaOnline,
    required this.activeNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint nodePaint = Paint()..style = PaintingStyle.fill;

    // Define fixed positional coordinate reference parameters inside matrix canvas card layout area
    final Offset cloudCenterNode = Offset(size.width / 2, 35);
    final Offset deviceAlphaNode = Offset(size.width * 0.25, 100);
    final Offset deviceBetaNode = Offset(size.width * 0.75, 100);

    // 1. Draw connecting pipelines networks layers routes setup
    // Line Cloud <-> Alpha
    linePaint.color = isAlphaOnline
        ? const Color(0xFF14B8A6)
        : const Color(0xFF64748B);
    if (!isAlphaOnline) {
      _drawDashedVectorLine(
        canvas,
        cloudCenterNode,
        deviceAlphaNode,
        linePaint,
      );
    } else {
      canvas.drawLine(cloudCenterNode, deviceAlphaNode, linePaint);
    }

    // Line Cloud <-> Beta
    linePaint.color = isBetaOnline
        ? const Color(0xFF14B8A6)
        : const Color(0xFF64748B);
    if (!isBetaOnline) {
      _drawDashedVectorLine(canvas, cloudCenterNode, deviceBetaNode, linePaint);
    } else {
      canvas.drawLine(cloudCenterNode, deviceBetaNode, linePaint);
    }

    // 2. Draw Object Nodes Layers Vectors
    // Cloud Central Mainframe Node Configuration
    nodePaint.color = const Color(0xFF0EA5E9);
    canvas.drawCircle(cloudCenterNode, 14, nodePaint);
    _drawLabelCaptionText(
      canvas,
      "CLOUD SERVER",
      cloudCenterNode.translate(-34, -28),
      Colors.white,
      true,
    );

    // Client Terminal Node: Alpha
    nodePaint.color = isAlphaOnline
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    canvas.drawCircle(deviceAlphaNode, 10, nodePaint);
    _drawLabelCaptionText(
      canvas,
      "NODE_ALPHA",
      deviceAlphaNode.translate(-30, 14),
      Colors.white,
      false,
    );
    if (activeNode == DeviceIdentity.deviceAlpha) {
      _drawActiveNodeHalo(canvas, deviceAlphaNode);
    }

    // Client Terminal Node: Beta
    nodePaint.color = isBetaOnline
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    canvas.drawCircle(deviceBetaNode, 10, nodePaint);
    _drawLabelCaptionText(
      canvas,
      "NODE_BETA",
      deviceBetaNode.translate(-26, 14),
      Colors.white,
      false,
    );
    if (activeNode == DeviceIdentity.deviceBeta) {
      _drawActiveNodeHalo(canvas, deviceBetaNode);
    }
  }

  void _drawActiveNodeHalo(Canvas canvas, Offset coreCenter) {
    final Paint halo = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(coreCenter, 15, halo);
  }

  void _drawDashedVectorLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    final double totalDistance = (p2 - p1).distance;
    final Offset normalizedDirection = (p2 - p1) / totalDistance;
    double currentDistance = 0.0;

    while (currentDistance < totalDistance) {
      canvas.drawLine(
        p1 + normalizedDirection * currentDistance,
        p1 +
            normalizedDirection *
                min(currentDistance + dashWidth, totalDistance),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  void _drawLabelCaptionText(
    Canvas canvas,
    String text,
    Offset position,
    Color col,
    bool isHeading,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: isHeading ? 9 : 8,
          fontWeight: FontWeight.bold,
          fontFamily: "monospace",
          color: col,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant DataNetworkTopologyPainter oldDelegate) => true;
}
