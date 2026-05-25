import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

void main() {
  runApp(const FoodAdminPlatformApp());
}

class FoodAdminPlatformApp extends StatelessWidget {
  const FoodAdminPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminStateProvider(
      child: MaterialApp(
        title: 'CraveCore Enterprise Admin',
        debugShowCheckedModeBanner: false,
        home: MasterAdminHub(),
      ),
    );
  }
}

// ==========================================
// 1. GLOBAL SYSTEM ENUMS & CONFIGURATIONS
// ==========================================

enum RestaurantStatus { pending, approved, suspended, rejected }

enum OrderStatus { placed, preparing, outForDelivery, delivered, cancelled }

enum DiscountType { percentage, flatAmount }

enum MenuCategory { appetizers, mains, desserts, beverages, specials }

// ==========================================
// 2. CORE DATA MODELS
// ==========================================

class Restaurant {
  final String id;
  final String name;
  final String ownerName;
  final String complianceTaxId;
  RestaurantStatus status;
  double platformRating;
  double totalRevenue;
  final DateTime appliedAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.complianceTaxId,
    this.status = RestaurantStatus.pending,
    this.platformRating = 0.0,
    this.totalRevenue = 0.0,
    required this.appliedAt,
  });
}

class MenuItem {
  final String id;
  final String restaurantId;
  String name;
  String description;
  double price;
  MenuCategory category;
  bool isAvailable;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
  });
}

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

class PlatformOrder {
  final String id;
  final String restaurantId;
  final String customerName;
  final List<OrderItem> items;
  final double subtotal;
  final double discountApplied;
  final double finalTotal;
  OrderStatus currentStatus;
  final DateTime timestamp;

  PlatformOrder({
    required this.id,
    required this.restaurantId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.discountApplied,
    required this.finalTotal,
    this.currentStatus = OrderStatus.placed,
    required this.timestamp,
  });
}

class DiscountRule {
  final String id;
  String code;
  DiscountType type;
  double value; // e.g., 15 for 15% or 10.0 for $10 flat
  double minimumOrderValue;
  bool isActive;
  int usageCount;
  DateTime expirationDate;

  DiscountRule({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minimumOrderValue,
    this.isActive = true,
    this.usageCount = 0,
    required this.expirationDate,
  });
}

// ==========================================
// 3. ENTERPRISE STATE MANAGEMENT CONTROLLER
// ==========================================

class FoodAdminController extends ChangeNotifier {
  final List<Restaurant> _restaurants = [];
  final List<MenuItem> _menuCatalog = [];
  final List<PlatformOrder> _liveOrders = [];
  final List<DiscountRule> _discountRules = [];
  final List<double> _hourlyRevenueGraphData = List.filled(24, 0.0);

  Timer? _liveTrafficSimulationTimer;
  bool _simulationActive = true;

  List<Restaurant> get restaurants => List.unmodifiable(_restaurants);
  List<MenuItem> get menuCatalog => List.unmodifiable(_menuCatalog);
  List<PlatformOrder> get liveOrders => List.unmodifiable(_liveOrders);
  List<DiscountRule> get discountRules => List.unmodifiable(_discountRules);
  List<double> get hourlyRevenueGraphData =>
      List.unmodifiable(_hourlyRevenueGraphData);

  FoodAdminController() {
    _seedEnterpriseDatabase();
    _startLiveTrafficSimulation();
  }

  void _seedEnterpriseDatabase() {
    // 1. Seed Restaurants
    _restaurants.addAll([
      Restaurant(
        id: 'RST-101',
        name: 'Bistro Cordon Bleu',
        ownerName: 'Chef Antoine',
        complianceTaxId: 'TAX-881-A',
        status: RestaurantStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 120)),
        platformRating: 4.8,
        totalRevenue: 145000.0,
      ),
      Restaurant(
        id: 'RST-102',
        name: 'Neon Noodle Bar',
        ownerName: 'Akira Fudo',
        complianceTaxId: 'TAX-902-B',
        status: RestaurantStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 45)),
        platformRating: 4.6,
        totalRevenue: 82000.0,
      ),
      Restaurant(
        id: 'RST-103',
        name: 'Rustic Hearth Pizza',
        ownerName: 'Maria Rossi',
        complianceTaxId: 'TAX-331-C',
        status: RestaurantStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Restaurant(
        id: 'RST-104',
        name: 'Vegan Void',
        ownerName: 'Chloe Zenith',
        complianceTaxId: 'TAX-114-V',
        status: RestaurantStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      Restaurant(
        id: 'RST-105',
        name: 'Greasy Spoon Diner',
        ownerName: 'Bob Vance',
        complianceTaxId: 'TAX-661-D',
        status: RestaurantStatus.suspended,
        appliedAt: DateTime.now().subtract(const Duration(days: 300)),
        platformRating: 2.1,
        totalRevenue: 12000.0,
      ),
    ]);

    // 2. Seed Menu Items
    _menuCatalog.addAll([
      MenuItem(
        id: 'MNU-01',
        restaurantId: 'RST-101',
        name: 'Truffle Risotto',
        description: 'Arborio rice with black truffle shavings.',
        price: 28.50,
        category: MenuCategory.mains,
      ),
      MenuItem(
        id: 'MNU-02',
        restaurantId: 'RST-101',
        name: 'Escargot Bites',
        description: 'Garlic butter and parsley.',
        price: 14.00,
        category: MenuCategory.appetizers,
      ),
      MenuItem(
        id: 'MNU-03',
        restaurantId: 'RST-102',
        name: 'Spicy Miso Ramen',
        description: 'Rich pork broth with chili oil.',
        price: 16.99,
        category: MenuCategory.mains,
      ),
      MenuItem(
        id: 'MNU-04',
        restaurantId: 'RST-102',
        name: 'Matcha Mochi',
        description: 'Green tea ice cream wrapped in rice dough.',
        price: 6.50,
        category: MenuCategory.desserts,
      ),
    ]);

    // 3. Seed Discount Rules
    _discountRules.addAll([
      DiscountRule(
        id: 'DSC-001',
        code: 'WELCOME20',
        type: DiscountType.percentage,
        value: 20.0,
        minimumOrderValue: 25.0,
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        usageCount: 412,
      ),
      DiscountRule(
        id: 'DSC-002',
        code: 'FLATTEN10',
        type: DiscountType.flatAmount,
        value: 10.0,
        minimumOrderValue: 50.0,
        expirationDate: DateTime.now().add(const Duration(days: 7)),
        usageCount: 89,
      ),
    ]);

    // 4. Seed Live Orders
    _liveOrders.addAll([
      _generateMockOrder('RST-101', OrderStatus.preparing),
      _generateMockOrder('RST-102', OrderStatus.placed),
      _generateMockOrder('RST-101', OrderStatus.outForDelivery),
      _generateMockOrder('RST-102', OrderStatus.delivered),
    ]);

    // 5. Seed Historical Graph Metrics
    final random = math.Random();
    for (int i = 0; i < 24; i++) {
      _hourlyRevenueGraphData[i] = 1000 + random.nextDouble() * 4000;
    }
  }

  PlatformOrder _generateMockOrder(String restaurantId, OrderStatus status) {
    final random = math.Random();
    final items = [
      OrderItem(
        menuItemId: 'MNU-XX',
        name: 'Random Item A',
        quantity: random.nextInt(3) + 1,
        unitPrice: 12.0 + random.nextDouble() * 10,
      ),
      if (random.nextBool())
        OrderItem(
          menuItemId: 'MNU-YY',
          name: 'Random Item B',
          quantity: 1,
          unitPrice: 5.0 + random.nextDouble() * 8,
        ),
    ];
    double subtotal = items.fold(0, (sum, item) => sum + item.totalPrice);

    return PlatformOrder(
      id: 'ORD-${math.Random().nextInt(900000) + 100000}',
      restaurantId: restaurantId,
      customerName: 'Customer_${math.Random().nextInt(9999)}',
      items: items,
      subtotal: subtotal,
      discountApplied: 0.0,
      finalTotal: subtotal,
      currentStatus: status,
      timestamp: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
    );
  }

  void _startLiveTrafficSimulation() {
    _liveTrafficSimulationTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) {
      if (!_simulationActive) return;

      final random = math.Random();

      // Randomly update an existing order's status to simulate progression
      if (_liveOrders.isNotEmpty && random.nextDouble() > 0.4) {
        final pendingOrders = _liveOrders
            .where(
              (o) =>
                  o.currentStatus != OrderStatus.delivered &&
                  o.currentStatus != OrderStatus.cancelled,
            )
            .toList();
        if (pendingOrders.isNotEmpty) {
          final targetOrder =
              pendingOrders[random.nextInt(pendingOrders.length)];
          if (targetOrder.currentStatus == OrderStatus.placed) {
            targetOrder.currentStatus = OrderStatus.preparing;
          } else if (targetOrder.currentStatus == OrderStatus.preparing) {
            targetOrder.currentStatus = OrderStatus.outForDelivery;
          } else if (targetOrder.currentStatus == OrderStatus.outForDelivery) {
            targetOrder.currentStatus = OrderStatus.delivered;
            // Update revenue upon delivery
            _hourlyRevenueGraphData[23] += targetOrder.finalTotal;
          }
          notifyListeners();
        }
      }

      // Randomly inject a new order
      if (random.nextDouble() > 0.7) {
        final approvedRestaurants = _restaurants
            .where((r) => r.status == RestaurantStatus.approved)
            .toList();
        if (approvedRestaurants.isNotEmpty) {
          final targetRestaurant =
              approvedRestaurants[random.nextInt(approvedRestaurants.length)];
          _liveOrders.insert(
            0,
            _generateMockOrder(targetRestaurant.id, OrderStatus.placed),
          );
          if (_liveOrders.length > 50)
            _liveOrders.removeLast(); // Maintain buffer limit
          notifyListeners();
        }
      }
    });
  }

  // --- API MUTATION METHODS ---

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final order = _liveOrders.firstWhere((o) => o.id == orderId);
    order.currentStatus = newStatus;
    if (newStatus == OrderStatus.delivered) {
      _hourlyRevenueGraphData[23] += order.finalTotal;
    }
    notifyListeners();
  }

  void reviewRestaurantApplication(String id, RestaurantStatus decision) {
    final restaurant = _restaurants.firstWhere((r) => r.id == id);
    restaurant.status = decision;
    notifyListeners();
  }

  void toggleDiscountRule(String id) {
    final rule = _discountRules.firstWhere((r) => r.id == id);
    rule.isActive = !rule.isActive;
    notifyListeners();
  }

  void saveDiscountRule(DiscountRule rule) {
    final index = _discountRules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      _discountRules[index] = rule;
    } else {
      _discountRules.add(rule);
    }
    notifyListeners();
  }

  void saveMenuItem(MenuItem item) {
    final index = _menuCatalog.indexWhere((m) => m.id == item.id);
    if (index >= 0) {
      _menuCatalog[index] = item;
    } else {
      _menuCatalog.add(item);
    }
    notifyListeners();
  }

  void toggleSimulation() {
    _simulationActive = !_simulationActive;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveTrafficSimulationTimer?.cancel();
    super.dispose();
  }
}

// Inherited Provider
class AdminStateProvider extends StatefulWidget {
  final Widget child;
  const AdminStateProvider({super.key, required this.child});

  static FoodAdminController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedAdminProvider>();
    assert(result != null, 'No AdminStateProvider found in context');
    return result!.controller;
  }

  @override
  State<AdminStateProvider> createState() => _AdminStateProviderState();
}

class _AdminStateProviderState extends State<AdminStateProvider> {
  late FoodAdminController controller;

  @override
  void initState() {
    super.initState();
    controller = FoodAdminController();
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
    return _InheritedAdminProvider(controller: controller, child: widget.child);
  }
}

class _InheritedAdminProvider extends InheritedWidget {
  final FoodAdminController controller;
  const _InheritedAdminProvider({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedAdminProvider old) => true;
}

// ==========================================
// 4. MAIN LAYOUT SHELL (NAVIGATION & ROUTING)
// ==========================================

class MasterAdminHub extends StatefulWidget {
  const MasterAdminHub({super.key});

  @override
  State<MasterAdminHub> createState() => _MasterAdminHubState();
}

class _MasterAdminHubState extends State<MasterAdminHub> {
  int _currentRailIndex = 0;

  final List<Widget> _viewportRegistry = [
    const TelemetryDashboardView(),
    const LiveKanbanOrderTracker(),
    const ComplianceApprovalMatrix(),
    const MenuEngineeringPanel(),
    const PromotionRulesEngine(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AdminStateProvider.of(context);
    final pendingCount = controller.restaurants
        .where((r) => r.status == RestaurantStatus.pending)
        .length;
    final activeOrdersCount = controller.liveOrders
        .where(
          (o) =>
              o.currentStatus != OrderStatus.delivered &&
              o.currentStatus != OrderStatus.cancelled,
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xfff1f5f9),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xff0f172a),
            selectedIndex: _currentRailIndex,
            onDestinationSelected: (idx) =>
                setState(() => _currentRailIndex = idx),
            extended: MediaQuery.of(context).size.width > 1200,
            minExtendedWidth: 260,
            unselectedIconTheme: const IconThemeData(color: Color(0xff64748b)),
            unselectedLabelTextStyle: const TextStyle(color: Color(0xff64748b)),
            selectedIconTheme: const IconThemeData(color: Color(0xff38bdf8)),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xff38bdf8),
              fontWeight: FontWeight.bold,
            ),
            indicatorColor: const Color(0xff1e293b),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xfff59e0b),
                    size: 32,
                  ),
                  if (MediaQuery.of(context).size.width > 1200) ...[
                    const SizedBox(width: 12),
                    const Text(
                      "CraveCore",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: Text("Command Center"),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text('$activeOrdersCount'),
                  isLabelVisible: activeOrdersCount > 0,
                  child: const Icon(Icons.view_kanban_outlined),
                ),
                selectedIcon: const Icon(Icons.view_kanban),
                label: const Text("Live Order Tracker"),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text('$pendingCount'),
                  isLabelVisible: pendingCount > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.verified_user_outlined),
                ),
                selectedIcon: const Icon(Icons.verified_user),
                label: const Text("Vendor Approvals"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.fastfood_outlined),
                selectedIcon: Icon(Icons.fastfood),
                label: Text("Menu Engineering"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.local_offer_outlined),
                selectedIcon: Icon(Icons.local_offer),
                label: Text("Promotions Engine"),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: Icon(
                      controller._simulationActive
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: controller._simulationActive
                          ? Colors.green
                          : Colors.orange,
                      size: 40,
                    ),
                    onPressed: () => controller.toggleSimulation(),
                    tooltip: "Toggle Live Environment Simulation",
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _viewportRegistry[_currentRailIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. VIEW 1: TELEMETRY DASHBOARD
// ==========================================

class TelemetryDashboardView extends StatelessWidget {
  const TelemetryDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdminStateProvider.of(context);
    final activeOrders = controller.liveOrders
        .where(
          (o) =>
              o.currentStatus != OrderStatus.delivered &&
              o.currentStatus != OrderStatus.cancelled,
        )
        .toList();
    final todayRevenue = controller.hourlyRevenueGraphData.fold(
      0.0,
      (a, b) => a + b,
    );
    final approvedVendors = controller.restaurants
        .where((r) => r.status == RestaurantStatus.approved)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Platform Global Overview",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xff1e293b),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    "Gross Merchandise Value (Today)",
                    "\$${todayRevenue.toStringAsFixed(2)}",
                    Icons.account_balance_wallet,
                    const Color(0xff10b981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    "Active Fulfilling Orders",
                    "${activeOrders.length}",
                    Icons.motorcycle,
                    const Color(0xff3b82f6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    "Approved Vendor Partners",
                    "$approvedVendors",
                    Icons.storefront,
                    const Color(0xff8b5cf6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    "System Gateway Health",
                    "99.98%",
                    Icons.health_and_safety,
                    const Color(0xfff59e0b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Advanced Custom Painted Graph Module
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffe2e8f0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hourly Transaction Volatility Matrix",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Real-time rendering of capital inflows across all integrated vendor systems.",
                      style: TextStyle(color: Color(0xff64748b), fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: PlatformRevenueGraphPainter(
                          dataPoints: controller.hourlyRevenueGraphData,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Bottom Matrix
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xffe2e8f0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recent System Exceptions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                            ),
                            title: const Text(
                              "Payment Gateway Latency Spike detected",
                            ),
                            subtitle: const Text(
                              "Region: US-East | Resolved automatically",
                            ),
                            trailing: Text(
                              "2m ago",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            title: const Text(
                              "Failed Webhook delivery to RST-105",
                            ),
                            subtitle: const Text(
                              "Endpoint returned 502 Bad Gateway",
                            ),
                            trailing: Text(
                              "14m ago",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Card(
                    color: const Color(0xff1e293b),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Platform Version Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatusRow(
                            "Core Services Router",
                            "v4.1.9",
                            true,
                          ),
                          const SizedBox(height: 12),
                          _buildStatusRow("Dispatch Engine", "v2.8.0", true),
                          const SizedBox(height: 12),
                          _buildStatusRow("Payment Clearing", "v1.0.4", true),
                          const SizedBox(height: 12),
                          _buildStatusRow(
                            "Machine Learning Fraud",
                            "v3.1.2",
                            false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String version, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xff94a3b8), fontSize: 13),
            ),
          ],
        ),
        Text(
          version,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xffe2e8f0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color.withOpacity(0.8), size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xff0f172a),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlatformRevenueGraphPainter extends CustomPainter {
  final List<double> dataPoints;

  PlatformRevenueGraphPainter({required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final double maxVal = dataPoints.reduce(math.max) * 1.2; // Add 20% headroom
    if (maxVal == 0) return;

    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xfff1f5f9)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 5; i++) {
      double y = size.height - (i * (size.height / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Line Chart Spline
    final chartPaint = Paint()
      ..color = const Color(0xff3b82f6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double stepX = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      double x = i * stepX;
      double y = size.height - ((dataPoints[i] / maxVal) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Curve approximation (cubic bezier for smoothness)
        double prevX = (i - 1) * stepX;
        double prevY =
            size.height - ((dataPoints[i - 1] / maxVal) * size.height);
        double controlPointX = prevX + (x - prevX) / 2;
        path.cubicTo(controlPointX, prevY, controlPointX, y, x, y);
      }
    }

    canvas.drawPath(path, chartPaint);

    // Draw Gradient Fill beneath the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff3b82f6).withOpacity(0.3),
          const Color(0xff3b82f6).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant PlatformRevenueGraphPainter old) => true;
}

// ==========================================
// 6. VIEW 2: LIVE KANBAN ORDER TRACKER (DRAG & DROP)
// ==========================================

class LiveKanbanOrderTracker extends StatelessWidget {
  const LiveKanbanOrderTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Real-Time Fulfillment Routing",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xff1e293b),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKanbanColumn(
              context,
              "New Orders Placed",
              OrderStatus.placed,
              const Color(0xfff43f5e),
            ),
            const SizedBox(width: 16),
            _buildKanbanColumn(
              context,
              "Kitchen Preparing",
              OrderStatus.preparing,
              const Color(0xfff59e0b),
            ),
            const SizedBox(width: 16),
            _buildKanbanColumn(
              context,
              "Out For Delivery",
              OrderStatus.outForDelivery,
              const Color(0xff3b82f6),
            ),
            const SizedBox(width: 16),
            _buildKanbanColumn(
              context,
              "Delivered / Closed",
              OrderStatus.delivered,
              const Color(0xff10b981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    String title,
    OrderStatus statusCategory,
    Color headerColor,
  ) {
    final controller = AdminStateProvider.of(context);
    final columnOrders = controller.liveOrders
        .where((o) => o.currentStatus == statusCategory)
        .toList();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffe2e8f0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: headerColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: headerColor.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${columnOrders.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Drag Target Body
            Expanded(
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  controller.updateOrderStatus(details.data, statusCategory);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: candidateData.isNotEmpty
                        ? headerColor.withOpacity(0.05)
                        : Colors.transparent,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: columnOrders.length,
                      itemBuilder: (context, index) {
                        final order = columnOrders[index];
                        return Draggable<String>(
                          data: order.id,
                          feedback: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 280,
                              child: _KanbanOrderCard(
                                order: order,
                                isDragging: true,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _KanbanOrderCard(order: order),
                          ),
                          child: _KanbanOrderCard(order: order),
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
}

class _KanbanOrderCard extends StatelessWidget {
  final PlatformOrder order;
  final bool isDragging;

  const _KanbanOrderCard({required this.order, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDragging ? 12 : 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  "\$${order.finalTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xff059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.customerName,
              style: const TextStyle(fontSize: 14, color: Color(0xff1e293b)),
            ),
            const SizedBox(height: 4),
            Text(
              "From: ${order.restaurantId}",
              style: const TextStyle(fontSize: 11, color: Color(0xff64748b)),
            ),
            const Divider(height: 16),
            Text(
              "${order.items.length} items",
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${DateTime.now().difference(order.timestamp).inMinutes} mins ago",
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        DateTime.now().difference(order.timestamp).inMinutes >
                            30
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. VIEW 3: RESTAURANT APPROVAL MATRIX
// ==========================================

class ComplianceApprovalMatrix extends StatelessWidget {
  const ComplianceApprovalMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdminStateProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Vendor Compliance & Verification Hub",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xff1e293b),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xffe2e8f0))),
                ),
                child: const Text(
                  "Registered Enterprise Entities",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xfff8fafc),
                    ),
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 70,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Internal ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Entity DBA Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Proprietor / Point of Contact',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Federal Tax ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Compliance Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Action Audit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: controller.restaurants.map((restaurant) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              restaurant.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(restaurant.ownerName)),
                          DataCell(
                            Text(
                              restaurant.complianceTaxId,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          DataCell(_buildStatusBadge(restaurant.status)),
                          DataCell(_buildActionButtons(context, restaurant)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RestaurantStatus status) {
    Color bg, text;
    String label;
    switch (status) {
      case RestaurantStatus.approved:
        bg = const Color(0xffdcfce7);
        text = const Color(0xff15803d);
        label = "VERIFIED";
        break;
      case RestaurantStatus.pending:
        bg = const Color(0xfffef9c3);
        text = const Color(0xffa16207);
        label = "AWAITING AUDIT";
        break;
      case RestaurantStatus.suspended:
        bg = const Color(0xfffee2e2);
        text = const Color(0xffb91c1c);
        label = "SUSPENDED";
        break;
      case RestaurantStatus.rejected:
        bg = const Color(0xfff1f5f9);
        text = const Color(0xff475569);
        label = "REJECTED";
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Restaurant restaurant) {
    final controller = AdminStateProvider.of(context);
    if (restaurant.status == RestaurantStatus.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: "Approve Vendor",
            onPressed: () => controller.reviewRestaurantApplication(
              restaurant.id,
              RestaurantStatus.approved,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: "Reject Vendor",
            onPressed: () => controller.reviewRestaurantApplication(
              restaurant.id,
              RestaurantStatus.rejected,
            ),
          ),
        ],
      );
    } else if (restaurant.status == RestaurantStatus.approved) {
      return IconButton(
        icon: const Icon(Icons.gavel, color: Colors.orange),
        tooltip: "Suspend Operations",
        onPressed: () => controller.reviewRestaurantApplication(
          restaurant.id,
          RestaurantStatus.suspended,
        ),
      );
    } else if (restaurant.status == RestaurantStatus.suspended) {
      return IconButton(
        icon: const Icon(Icons.restore, color: Colors.blue),
        tooltip: "Lift Suspension",
        onPressed: () => controller.reviewRestaurantApplication(
          restaurant.id,
          RestaurantStatus.approved,
        ),
      );
    }
    return const SizedBox.shrink(); // Rejected has no actions
  }
}

// ==========================================
// 8. VIEW 4: MENU ENGINEERING PANEL
// ==========================================

class MenuEngineeringPanel extends StatefulWidget {
  const MenuEngineeringPanel({super.key});

  @override
  State<MenuEngineeringPanel> createState() => _MenuEngineeringPanelState();
}

class _MenuEngineeringPanelState extends State<MenuEngineeringPanel> {
  String _selectedRestaurantId = 'RST-101';
  final _formKey = GlobalKey<FormState>();

  // Form Field States
  String _itemName = '';
  String _itemDesc = '';
  double _itemPrice = 0.0;
  MenuCategory _itemCategory = MenuCategory.mains;
  bool _itemAvailable = true;

  @override
  Widget build(BuildContext context) {
    final controller = AdminStateProvider.of(context);
    final activeRestaurants = controller.restaurants
        .where((r) => r.status == RestaurantStatus.approved)
        .toList();
    final filteredCatalog = controller.menuCatalog
        .where((m) => m.restaurantId == _selectedRestaurantId)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Menu Ontology & Pricing Engine",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xff1e293b),
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
            // Left Pane: Catalog Browser
            Expanded(
              flex: 5,
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xffe2e8f0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xffe2e8f0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Target Database: ",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedRestaurantId,
                                items: activeRestaurants
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r.id,
                                        child: Text("${r.name} (${r.id})"),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedRestaurantId = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredCatalog.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filteredCatalog[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xfff1f5f9),
                              child: Icon(
                                Icons.fastfood,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${item.category.name.toUpperCase()} | ${item.description}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "\$${item.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xff0f172a),
                                  ),
                                ),
                                Text(
                                  item.isAvailable ? "IN STOCK" : "86'd (OUT)",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.isAvailable
                                        ? Colors.green
                                        : Colors.red,
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
            const SizedBox(width: 24),
            // Right Pane: Editor Form
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
                            "Inject New Menu Topology",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Nomenclature (Item Name)",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Required Field" : null,
                            onSaved: (v) => _itemName = v!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Gastronomic Description",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (v) =>
                                v!.isEmpty ? "Required Field" : null,
                            onSaved: (v) => _itemDesc = v!,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Fiat Price Metric (\$)",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.attach_money),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      double.tryParse(v ?? '') == null
                                      ? "Invalid Numerics"
                                      : null,
                                  onSaved: (v) => _itemPrice = double.parse(v!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<MenuCategory>(
                                  decoration: const InputDecoration(
                                    labelText: "Taxonomy Category",
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _itemCategory,
                                  items: MenuCategory.values
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c.name.toUpperCase()),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _itemCategory = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text("Digital Availability Status"),
                            subtitle: const Text(
                              "Toggle instantly removes item from public APIs",
                            ),
                            value: _itemAvailable,
                            activeColor: const Color(0xff10b981),
                            onChanged: (v) =>
                                setState(() => _itemAvailable = v),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0f172a),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  final newItem = MenuItem(
                                    id: 'MNU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                    restaurantId: _selectedRestaurantId,
                                    name: _itemName,
                                    description: _itemDesc,
                                    price: _itemPrice,
                                    category: _itemCategory,
                                    isAvailable: _itemAvailable,
                                  );

                                  controller.saveMenuItem(newItem);
                                  _formKey.currentState!.reset();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "SKU Successfully provisioned to edge servers.",
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                      backgroundColor: Color(0xff1e293b),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Commit Artifact to Production Catalog",
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
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 9. VIEW 5: DISCOUNT RULES ENGINE
// ==========================================

class PromotionRulesEngine extends StatefulWidget {
  const PromotionRulesEngine({super.key});

  @override
  State<PromotionRulesEngine> createState() => _PromotionRulesEngineState();
}

class _PromotionRulesEngineState extends State<PromotionRulesEngine> {
  final _promoFormKey = GlobalKey<FormState>();

  String _code = "";
  DiscountType _type = DiscountType.percentage;
  double _value = 0.0;
  double _minOrder = 0.0;
  int _daysValid = 30;

  @override
  Widget build(BuildContext context) {
    final controller = AdminStateProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Global Promotions & Subsidies Engine",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xff1e293b),
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
            // Promos Ledger
            Expanded(
              flex: 5,
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xffe2e8f0)),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.discountRules.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final rule = controller.discountRules[index];
                    final isExpired = DateTime.now().isAfter(
                      rule.expirationDate,
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: rule.isActive && !isExpired
                              ? const Color(0xffdcfce7)
                              : const Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.confirmation_number,
                          color: rule.isActive && !isExpired
                              ? const Color(0xff15803d)
                              : Colors.grey,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            rule.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "EXPIRED",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "${rule.type == DiscountType.percentage ? '${rule.value}% Off' : '\$${rule.value} Flat'} (Min Spend: \$${rule.minimumOrderValue})",
                          ),
                          Text(
                            "Valid until: ${rule.expirationDate.toLocal().toString().substring(0, 10)} | Redemptions: ${rule.usageCount}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: rule.isActive,
                        activeColor: const Color(0xff10b981),
                        onChanged: isExpired
                            ? null
                            : (v) => controller.toggleDiscountRule(rule.id),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Generator Form
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
                    key: _promoFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Compile Promotion Contract",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Voucher Trigger Hash (Code)",
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => v!.isEmpty ? "Code required" : null,
                          onSaved: (v) => _code = v!.toUpperCase(),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<DiscountType>(
                          decoration: const InputDecoration(
                            labelText: "Subsidization Vector Type",
                            border: OutlineInputBorder(),
                          ),
                          value: _type,
                          items: const [
                            DropdownMenuItem(
                              value: DiscountType.percentage,
                              child: Text("Relative Percentage Deduct (%)"),
                            ),
                            DropdownMenuItem(
                              value: DiscountType.flatAmount,
                              child: Text("Absolute Fiat Value Deduct (\$oca)"),
                            ),
                          ],
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Deduction Magnitude",
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    double.tryParse(v ?? '') == null
                                    ? "Error"
                                    : null,
                                onSaved: (v) => _value = double.parse(v!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Activation Threshold (\$)",
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    double.tryParse(v ?? '') == null
                                    ? "Error"
                                    : null,
                                onSaved: (v) => _minOrder = double.parse(v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Time-to-Live Duration (Days)",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: "30",
                          validator: (v) =>
                              int.tryParse(v ?? '') == null ? "Error" : null,
                          onSaved: (v) => _daysValid = int.parse(v!),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff8b5cf6),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.flash_on),
                            label: const Text(
                              "Broadcast Rule to Checkout Nodes",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              if (_promoFormKey.currentState!.validate()) {
                                _promoFormKey.currentState!.save();

                                final newRule = DiscountRule(
                                  id: 'DSC-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                                  code: _code,
                                  type: _type,
                                  value: _value,
                                  minimumOrderValue: _minOrder,
                                  expirationDate: DateTime.now().add(
                                    Duration(days: _daysValid),
                                  ),
                                );

                                controller.saveDiscountRule(newRule);
                                _promoFormKey.currentState!.reset();
                              }
                            },
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
      ),
    );
  }
}
