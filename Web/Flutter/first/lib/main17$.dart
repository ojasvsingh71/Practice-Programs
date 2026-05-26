import 'package:flutter/material.dart';
import 'dart:math';
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
  runApp(const InventoryControlApp());
}

class InventoryControlApp extends StatelessWidget {
  const InventoryControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MyStateProvider(
      child: MaterialApp(
        title: 'InvenTrack Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff1e3a8a),
            brightness: Brightness.light,
            primary: const Color(0xff2563eb),
            secondary: const Color(0xff0d9488),
            error: const Color(0xffdc2626),
            background: const Color(0xfff8fafc),
          ),
          cardColor: Colors.white,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        home: const MainNavigationHub(),
      ),
    );
  }
}

// ==========================================
// 1. DATA MODELS & ENUMS
// ==========================================

enum TransactionType { restock, sale, adjustment, reconciliation }

class Supplier {
  final String id;
  final String name;
  final String contactName;
  final String email;
  final String phone;
  final String category;

  Supplier({
    required this.id,
    required this.name,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.category,
  });

  Supplier copyWith({
    String? name,
    String? contactName,
    String? email,
    String? phone,
    String? category,
  }) {
    return Supplier(
      id: this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      category: category ?? this.category,
    );
  }
}

class Product {
  final String id;
  final String sku;
  final String name;
  final String description;
  final String category;
  final int currentStock;
  final int minThreshold;
  final double costPrice;
  final double sellingPrice;
  final String supplierId;
  final String warehouseLocation;
  final DateTime lastUpdated;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.category,
    required this.currentStock,
    required this.minThreshold,
    required this.costPrice,
    required this.sellingPrice,
    required this.supplierId,
    required this.warehouseLocation,
    required this.lastUpdated,
  });

  bool get isLowStock => currentStock <= minThreshold;

  Product copyWith({
    String? sku,
    String? name,
    String? description,
    String? category,
    int? currentStock,
    int? minThreshold,
    double? costPrice,
    double? sellingPrice,
    String? supplierId,
    String? warehouseLocation,
    DateTime? lastUpdated,
  }) {
    return Product(
      id: this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minThreshold: minThreshold ?? this.minThreshold,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      supplierId: supplierId ?? this.supplierId,
      warehouseLocation: warehouseLocation ?? this.warehouseLocation,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

class StockTransaction {
  final String id;
  final String productId;
  final TransactionType type;
  final int quantityChanged;
  final int stockAfter;
  final DateTime timestamp;
  final String notes;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantityChanged,
    required this.stockAfter,
    required this.timestamp,
    required this.notes,
  });
}

class ReconciliationItem {
  final String productId;
  final int expectedQty;
  final int physicalQty;
  final String notes;

  ReconciliationItem({
    required this.productId,
    required this.expectedQty,
    required this.physicalQty,
    required this.notes,
  });

  int get variance => physicalQty - expectedQty;
}

class ReconciliationAudit {
  final String id;
  final DateTime datePerformed;
  final List<ReconciliationItem> items;
  final String notes;
  final String performedBy;

  ReconciliationAudit({
    required this.id,
    required this.datePerformed,
    required this.items,
    required this.notes,
    required this.performedBy,
  });
}

// ==========================================
// 2. STATE MANAGEMENT (IN-MEMORY DATABASE)
// ==========================================

class InventoryController extends ChangeNotifier {
  final List<Product> _products = [];
  final List<Supplier> _suppliers = [];
  final List<StockTransaction> _transactions = [];
  final List<ReconciliationAudit> _audits = [];

  List<Product> get products => List.unmodifiable(_products);
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  List<StockTransaction> get transactions => List.unmodifiable(_transactions);
  List<ReconciliationAudit> get audits => List.unmodifiable(_audits);

  InventoryController() {
    _seedMockData();
  }

  void _seedMockData() {
    // Seed Suppliers
    _suppliers.addAll([
      Supplier(
        id: 'SUP-001',
        name: 'Apex Electronics Logistics',
        contactName: 'Alex Mercer',
        email: 'orders@apexelectronics.com',
        phone: '+1-555-0192',
        category: 'Electronics',
      ),
      Supplier(
        id: 'SUP-002',
        name: 'Global Tech Components',
        contactName: 'Sarah Jenkins',
        email: 'sales@globaltech.io',
        phone: '+1-555-0143',
        category: 'Components',
      ),
      Supplier(
        id: 'SUP-003',
        name: 'Quantum Distribution',
        contactName: 'David Vance',
        email: 'dvance@quantumdist.com',
        phone: '+1-555-0188',
        category: 'Networking',
      ),
    ]);

    // Seed Products
    _products.addAll([
      Product(
        id: 'PRD-001',
        sku: 'ELX-X100-BK',
        name: 'CoreX Pro Processor v1',
        description: 'High performance processing unit for computing grids.',
        category: 'Components',
        currentStock: 45,
        minThreshold: 15,
        costPrice: 120.0,
        sellingPrice: 199.99,
        supplierId: 'SUP-002',
        warehouseLocation: 'Aisle 3A-Shelf 2',
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Product(
        id: 'PRD-002',
        sku: 'NET-SW24-POE',
        name: '24-Port Managed PoE Switch',
        description: 'Enterprise gigabit dynamic routing switch.',
        category: 'Networking',
        currentStock: 8,
        minThreshold: 10,
        costPrice: 250.0,
        sellingPrice: 420.00,
        supplierId: 'SUP-003',
        warehouseLocation: 'Aisle 1C-Shelf 4',
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Product(
        id: 'PRD-003',
        sku: 'ELX-RAM16GB',
        name: 'HyperDDR5 16GB RAM Stick',
        description: '6000MHz ultra low latency system memory module.',
        category: 'Components',
        currentStock: 120,
        minThreshold: 30,
        costPrice: 45.0,
        sellingPrice: 75.00,
        supplierId: 'SUP-002',
        warehouseLocation: 'Aisle 3A-Shelf 1',
        lastUpdated: DateTime.now(),
      ),
      Product(
        id: 'PRD-004',
        sku: 'CAB-CAT6-100',
        name: 'Cat6 Shielded Cable 100ft',
        description: 'Heavy duty outdoor rated ethernet deployment roll.',
        category: 'Networking',
        currentStock: 3,
        minThreshold: 5,
        costPrice: 15.5,
        sellingPrice: 34.99,
        supplierId: 'SUP-003',
        warehouseLocation: 'Aisle 5B-Shelf 1',
        lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Product(
        id: 'PRD-005',
        sku: 'DISP-4K-27',
        name: 'UltraSharp 27" 4K Monitor',
        description: 'IPS panel with 99% sRGB color accuracy tuning.',
        category: 'Electronics',
        currentStock: 14,
        minThreshold: 4,
        costPrice: 180.0,
        sellingPrice: 299.99,
        supplierId: 'SUP-001',
        warehouseLocation: 'Aisle 2B-Shelf 3',
        lastUpdated: DateTime.now(),
      ),
    ]);

    // Seed some transactions
    for (var p in _products) {
      _transactions.add(
        StockTransaction(
          id: 'TX-${Random().nextInt(100000)}',
          productId: p.id,
          type: TransactionType.restock,
          quantityChanged: p.currentStock,
          stockAfter: p.currentStock,
          timestamp: DateTime.now().subtract(const Duration(days: 6)),
          notes: "Initial inventory provisioning assignment.",
        ),
      );
    }
  }

  // --- Core Product Operations ---
  void addProduct(Product product) {
    _products.add(product);
    _logTransaction(
      product.id,
      TransactionType.restock,
      product.currentStock,
      product.currentStock,
      "Initial stock initialization upon creation.",
    );
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final idx = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (idx != -1) {
      final oldProduct = _products[idx];
      _products[idx] = updatedProduct;

      if (oldProduct.currentStock != updatedProduct.currentStock) {
        final diff = updatedProduct.currentStock - oldProduct.currentStock;
        _logTransaction(
          updatedProduct.id,
          diff > 0 ? TransactionType.restock : TransactionType.adjustment,
          diff,
          updatedProduct.currentStock,
          "Manual administrative stock override adjustment.",
        );
      }
      notifyListeners();
    }
  }

  void adjustStockValue(
    String productId,
    int delta,
    TransactionType type,
    String note,
  ) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final current = _products[idx];
      int targetStock = max(0, current.currentStock + delta);
      int effectiveDelta = targetStock - current.currentStock;

      _products[idx] = current.copyWith(currentStock: targetStock);
      _logTransaction(productId, type, effectiveDelta, targetStock, note);
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _transactions.removeWhere((t) => t.productId == id);
    notifyListeners();
  }

  // --- Supplier Operations ---
  void addSupplier(Supplier supplier) {
    _suppliers.add(supplier);
    notifyListeners();
  }

  void updateSupplier(Supplier updatedSupplier) {
    final idx = _suppliers.indexWhere((s) => s.id == updatedSupplier.id);
    if (idx != -1) {
      _suppliers[idx] = updatedSupplier;
      notifyListeners();
    }
  }

  // --- Stock Reconciliation Processing ---
  void processReconciliation(
    List<ReconciliationItem> items,
    String auditNotes,
    String auditor,
  ) {
    final auditId = 'AUD-${DateTime.now().millisecondsSinceEpoch}';

    for (var item in items) {
      if (item.variance != 0) {
        adjustStockValue(
          item.productId,
          item.variance,
          TransactionType.reconciliation,
          "System reconciliation dynamic variance alignment correction. Audit ID: $auditId",
        );
      }
    }

    _audits.add(
      ReconciliationAudit(
        id: auditId,
        datePerformed: DateTime.now(),
        items: items,
        notes: auditNotes,
        performedBy: auditor,
      ),
    );
    notifyListeners();
  }

  void _logTransaction(
    String pId,
    TransactionType type,
    int change,
    int absolute,
    String notes,
  ) {
    _transactions.insert(
      0,
      StockTransaction(
        id: 'TX-${DateTime.now().microsecondsSinceEpoch.toString().substring(10)}',
        productId: pId,
        type: type,
        quantityChanged: change,
        stockAfter: absolute,
        timestamp: DateTime.now(),
        notes: notes,
      ),
    );
  }

  // --- Computations & Analytical Metrics ---
  double get totalInventoryAssetValue {
    return _products.fold(
      0,
      (sum, item) => sum + (item.currentStock * item.costPrice),
    );
  }

  double get projectRetailMarketValue {
    return _products.fold(
      0,
      (sum, item) => sum + (item.currentStock * item.sellingPrice),
    );
  }

  int get activeLowStockAlertCount {
    return _products.where((p) => p.isLowStock).length;
  }

  Supplier? getSupplierById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Simple InheritedWidget setup to act as an un-opinionated state management provider container
class MyStateProvider extends StatefulWidget {
  final Widget child;
  const MyStateProvider({super.key, required this.child});

  static InventoryController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedStateProvider>();
    assert(result != null, 'No MyStateProvider found in context hierarchy');
    return result!.controller;
  }

  @override
  State<MyStateProvider> createState() => _MyStateProviderState();
}

class _MyStateProviderState extends State<MyStateProvider> {
  late InventoryController controller;

  @override
  void initState() {
    super.initState();
    controller = InventoryController();
    controller.addListener(_stateListener);
  }

  void _stateListener() {
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_stateListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedStateProvider(controller: controller, child: widget.child);
  }
}

class _InheritedStateProvider extends InheritedWidget {
  final InventoryController controller;
  const _InheritedStateProvider({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedStateProvider oldWidget) => true;
}

// ==========================================
// 3. MAIN NAVIGATION CONTROLLER HUB
// ==========================================

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentNavigationIndex = 0;

  final List<Widget> _appViewScreens = [
    const DashboardOverviewScreen(),
    const InventoryRosterScreen(),
    const VendorSupplierScreen(),
    const InventoryAuditReconciliationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = MyStateProvider.of(context);
    final alertCount = controller.activeLowStockAlertCount;

    return Scaffold(
      body: Row(
        children: [
          // Layout side rail optimized for system management displays
          NavigationRail(
            selectedIndex: _currentNavigationIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentNavigationIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xff0f172a),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            indicatorColor: const Color(0xff2563eb),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.warehouse, color: Color(0xff38bdf8), size: 36),
                const SizedBox(height: 8),
                const Text(
                  "INVEN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  "SYS PRO",
                  style: TextStyle(
                    color: Color(0xff38bdf8),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Stock Master'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: Text('Suppliers'),
              ),
              NavigationRailDestination(
                icon: Badge(
                  label: Text('$alertCount'),
                  isLabelVisible: alertCount > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.published_with_changes_outlined),
                ),
                selectedIcon: const Icon(Icons.published_with_changes),
                label: const Text('Reconciliation'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.black12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _appViewScreens[_currentNavigationIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// removed unused color alias

// ==========================================
// 4. SCREEN 1: ANALYTICS DASHBOARD SCREEN
// ==========================================

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MyStateProvider.of(context);
    final totalItems = state.products.fold(0, (sum, p) => sum + p.currentStock);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          'Executive Inventory Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.orange,
            ),
            onPressed: () {
              if (state.activeLowStockAlertCount > 0) {
                _displayLowStockSummarySheet(context, state);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Operational Status Nominal: No immediate low-stock systemic triggers found.",
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row metrics metrics panel
            LayoutBuilder(
              builder: (context, constraints) {
                // responsive width handling removed; using Wrap for responsiveness
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _AnalyticsMetricContainer(
                      title: 'Total Capital Asset Cost',
                      value:
                          '\$${state.totalInventoryAssetValue.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      accentColor: const Color(0xff2563eb),
                      subtitle: 'Aggregated raw base valuation',
                    ),
                    _AnalyticsMetricContainer(
                      title: 'Estimated Market Value',
                      value:
                          '\$${state.projectRetailMarketValue.toStringAsFixed(2)}',
                      icon: Icons.trending_up,
                      accentColor: const Color(0xff0d9488),
                      subtitle: 'Projected turnover yield capacity',
                    ),
                    _AnalyticsMetricContainer(
                      title: 'Total Stocked Units',
                      value: '$totalItems Items',
                      icon: Icons.inventory,
                      accentColor: const Color(0xff4f46e5),
                      subtitle: 'Quantity units in warehouse storage',
                    ),
                    _AnalyticsMetricContainer(
                      title: 'Active Critical Alerts',
                      value: '${state.activeLowStockAlertCount}',
                      icon: Icons.gpp_maybe,
                      accentColor: state.activeLowStockAlertCount > 0
                          ? const Color(0xffdc2626)
                          : Colors.green,
                      subtitle: 'Items dipping past fallback threshold',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            if (state.activeLowStockAlertCount > 0) ...[
              Card(
                color: const Color(0xfffef2f2),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xfffca5a5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xffdc2626),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "System Alert Protocol Triggered: ${state.activeLowStockAlertCount} SKU items require replenishment pipeline updates.",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff991b1b),
                              ),
                            ),
                            const Text(
                              "Critical stock failure window active. Review minimum operating requirements below.",
                              style: TextStyle(
                                color: Color(0xffb91c1c),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffdc2626),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _displayLowStockSummarySheet(context, state),
                        child: const Text("Deploy Audit Actions"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          "Recent Warehouse Log Transactions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1e293b),
                          ),
                        ),
                      ),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: min(6, state.transactions.length),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final tx = state.transactions[idx];
                            final prod = state.getProductById(tx.productId);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTransactionColor(
                                  tx.type,
                                ).withOpacity(0.1),
                                child: Icon(
                                  _getTransactionIcon(tx.type),
                                  color: _getTransactionColor(tx.type),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                prod?.name ?? "Unknown SKU Allocation",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.notes,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    tx.timestamp
                                        .toIso8601String()
                                        .substring(0, 19)
                                        .replaceAll('T', ' '),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${tx.quantityChanged > 0 ? '+' : ''}${tx.quantityChanged}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: _getTransactionColor(tx.type),
                                    ),
                                  ),
                                  Text(
                                    "Total: ${tx.stockAfter}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
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
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          "Product Distribution Metrics",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1e293b),
                          ),
                        ),
                      ),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: state.products.map((p) {
                              final percent = totalItems > 0
                                  ? (p.currentStock / totalItems)
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "${p.currentStock} units (${(percent * 100).toStringAsFixed(1)}%)",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: percent,
                                      backgroundColor: Colors.grey.shade200,
                                      color: p.isLowStock
                                          ? Colors.red
                                          : const Color(0xff0d9488),
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.restock:
        return Colors.green;
      case TransactionType.sale:
        return Colors.blue;
      case TransactionType.adjustment:
        return Colors.orange;
      case TransactionType.reconciliation:
        return Colors.purple;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.restock:
        return Icons.add_business;
      case TransactionType.sale:
        return Icons.point_of_sale;
      case TransactionType.adjustment:
        return Icons.tune;
      case TransactionType.reconciliation:
        return Icons.fact_check;
    }
  }

  void _displayLowStockSummarySheet(
    BuildContext ctx,
    InventoryController state,
  ) {
    showModalBottomSheet(
      context: ctx,
      builder: (context) {
        final lows = state.products.where((p) => p.isLowStock).toList();
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Critical Low Stock Log Matrix (${lows.length})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: lows.length,
                  itemBuilder: (c, i) {
                    final item = lows[i];
                    final sup = state.getSupplierById(item.supplierId);
                    return Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Supplier: ${sup?.name ?? 'Unassigned'}\nLocation: ${item.warehouseLocation}",
                        ),
                        trailing: Text(
                          "Qty: ${item.currentStock} / Min: ${item.minThreshold}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w900,
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
      },
    );
  }
}

class _AnalyticsMetricContainer extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String subtitle;

  const _AnalyticsMetricContainer({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 6),
        ],
        border: Border(left: BorderSide(color: accentColor, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: accentColor, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. SCREEN 2: INVENTORY ROSTER (STOCK MANAGEMENT)
// ==========================================

class InventoryRosterScreen extends StatefulWidget {
  const InventoryRosterScreen({super.key});

  @override
  State<InventoryRosterScreen> createState() => _InventoryRosterScreenState();
}

class _InventoryRosterScreenState extends State<InventoryRosterScreen> {
  String searchString = "";
  String categorySelection = "All Frameworks";

  @override
  Widget build(BuildContext context) {
    final state = MyStateProvider.of(context);

    // Derived categories dynamic parser
    final parsingCategories = [
      "All Frameworks",
      ...state.products.map((p) => p.category).toSet().toList(),
    ];

    final matchedProducts = state.products.where((p) {
      final matchText =
          p.name.toLowerCase().contains(searchString.toLowerCase()) ||
          p.sku.toLowerCase().contains(searchString.toLowerCase());
      final matchCat =
          categorySelection == "All Frameworks" ||
          p.category == categorySelection;
      return matchText && matchCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          'Global Stock Ledger Database',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text("Initialize Product SKU"),
            onPressed: () => _openProductFormWorkflow(context, null),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter matrix management pane
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText:
                          "Query product system registries by dynamic string signature name or SKU data...",
                    ),
                    onChanged: (v) => setState(() => searchString = v),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButtonFormField<String>(
                  value: categorySelection,
                  decoration: const InputDecoration(
                    constraints: BoxConstraints(maxWidth: 220),
                    labelText: "Category Sorting",
                  ),
                  items: parsingCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => categorySelection = v ?? "All Frameworks"),
                ),
              ],
            ),
          ),
          Expanded(
            child: matchedProducts.isEmpty
                ? const Center(
                    child: Text(
                      "No systemic product metrics matched database search execution vector.",
                    ),
                  )
                : ListView.builder(
                    itemCount: matchedProducts.length,
                    itemBuilder: (context, index) {
                      final p = matchedProducts[index];
                      final supplier = state.getSupplierById(p.supplierId);
                      return Card(
                        child: ListTile(
                          onTap: () => _showProductExtendedDetails(context, p),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: p.isLowStock
                                  ? Colors.red.shade100
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              p.isLowStock
                                  ? Icons.warning_amber_rounded
                                  : Icons.inventory_2,
                              color: p.isLowStock
                                  ? Colors.red
                                  : const Color(0xff2563eb),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.sku,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "Supplier: ${supplier?.name ?? 'None Assigned'} | Location Allocation: ${p.warehouseLocation}\nRetail Strategy Unit Cost: \$${p.sellingPrice.toStringAsFixed(2)}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${p.currentStock} Units Available",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: p.isLowStock
                                          ? Colors.red
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                  Text(
                                    "Threshold: ${p.minThreshold}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit')
                                    _openProductFormWorkflow(context, p);
                                  if (action == 'adjust')
                                    _openQuickAdjustmentDialog(context, p);
                                  if (action == 'delete')
                                    state.deleteProduct(p.id);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'adjust',
                                    child: Text('Fast Delta Shift'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modify Profile Registry'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Wipe Entry System Data',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
        ],
      ),
    );
  }

  void _openQuickAdjustmentDialog(BuildContext ctx, Product p) {
    final state = MyStateProvider.of(ctx);
    final formKey = GlobalKey<FormState>();
    int delta = 0;
    String note = "";

    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: Text("Fast Stock Multiplier Shift: ${p.sku}"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Quantity Offset Delta",
                  hintText: "Use negative data metrics for reduction (e.g. -5)",
                ),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v ?? '') == null
                    ? "Requires integer numerical values"
                    : null,
                onSaved: (v) => delta = int.parse(v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Justification Administrative Notes",
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Explicit process declaration validation criteria mandatory"
                    : null,
                onSaved: (v) => note = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abruptly Abort"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                state.adjustStockValue(
                  p.id,
                  delta,
                  TransactionType.adjustment,
                  note,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Execute State Update Commit"),
          ),
        ],
      ),
    );
  }

  void _openProductFormWorkflow(BuildContext ctx, Product? template) {
    showDialog(
      context: ctx,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: ProductMaintenanceWizardForm(editTargetProduct: template),
        ),
      ),
    );
  }

  void _showProductExtendedDetails(BuildContext ctx, Product p) {
    final state = MyStateProvider.of(ctx);
    final history = state.transactions
        .where((t) => t.productId == p.id)
        .toList();

    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: Text("SKU Diagnostic Ledger Context: ${p.name}"),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Product Identification: ${p.id}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Stock Execution Placement Zone: ${p.warehouseLocation}"),
              Text(
                "Financial Base Asset Cost: \$${p.costPrice.toStringAsFixed(2)} | Target Consumer Listing: \$${p.sellingPrice.toStringAsFixed(2)}",
              ),
              const Divider(height: 24),
              const Text(
                "Transaction Execution Log Audit History Tracking:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          "No transaction mutation logs mapped to this structural profile segment yet.",
                        ),
                      )
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (c, i) {
                          final h = history[i];
                          return Card(
                            color: Colors.grey.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.notes,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        h.timestamp.toString().substring(0, 16),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${h.quantityChanged > 0 ? '+' : ''}${h.quantityChanged}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Exit Diagnostics"),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. PRODUCT CREATION/EDIT WIZARD WIDGET
// ==========================================

class ProductMaintenanceWizardForm extends StatefulWidget {
  final Product? editTargetProduct;
  const ProductMaintenanceWizardForm({super.key, this.editTargetProduct});

  @override
  State<ProductMaintenanceWizardForm> createState() =>
      _ProductMaintenanceWizardFormState();
}

class _ProductMaintenanceWizardFormState
    extends State<ProductMaintenanceWizardForm> {
  final _formKey = GlobalKey<FormState>();

  late String sku, name, description, category, warehouseLocation, supplierId;
  late int currentStock, minThreshold;
  late double costPrice, sellingPrice;

  @override
  Widget build(BuildContext context) {
    final controller = MyStateProvider.of(context);
    final parsingSuppliers = controller.suppliers;
    final holdsProduct = widget.editTargetProduct;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              holdsProduct == null
                  ? "Provision New Systemic SKU Ledger"
                  : "Refine Existing Inventory Record Manifest",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: holdsProduct?.sku,
                    decoration: const InputDecoration(
                      labelText: "System Universal SKU Code Identifier",
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? "Unique serialization structure parameter constraint required"
                        : null,
                    onSaved: (v) => sku = v!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: holdsProduct?.name,
                    decoration: const InputDecoration(
                      labelText: "Commercial Entity Variant Name",
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? "Validation naming assignment token required"
                        : null,
                    onSaved: (v) => name = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: holdsProduct?.description,
              decoration: const InputDecoration(
                labelText: "Product Operational Specification Details",
              ),
              maxLines: 2,
              onSaved: (v) => description = v ?? "",
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: holdsProduct?.category,
                    decoration: const InputDecoration(
                      labelText: "Dynamic Class Group Category",
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? "Structural category cluster identity required"
                        : null,
                    onSaved: (v) => category = v!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        holdsProduct?.supplierId ??
                        (parsingSuppliers.isNotEmpty
                            ? parsingSuppliers.first.id
                            : null),
                    decoration: const InputDecoration(
                      labelText: "Designated Vendor Procurement Source",
                    ),
                    items: parsingSuppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => supplierId = v ?? "",
                    onSaved: (v) => supplierId = v ?? "",
                    validator: (v) => (v == null || v.isEmpty)
                        ? "Vendor attribution trace route validation binding required"
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: holdsProduct?.currentStock.toString(),
                    decoration: const InputDecoration(
                      labelText: "Initial Core Stock Unit Inventory Count",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? "Numerical base verification parameters mandatory"
                        : null,
                    onSaved: (v) => currentStock = int.parse(v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: holdsProduct?.minThreshold.toString(),
                    decoration: const InputDecoration(
                      labelText: "Automated Fallback Trigger Limit Threshold",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? "Numerical fallback metrics limit mandatory"
                        : null,
                    onSaved: (v) => minThreshold = int.parse(v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: holdsProduct?.costPrice.toString(),
                    decoration: const InputDecoration(
                      labelText: "Raw Wholesale Valuation Point Unit Cost (\$)",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? "Financial floating notation numeric configuration required"
                        : null,
                    onSaved: (v) => costPrice = double.parse(v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: holdsProduct?.sellingPrice.toString(),
                    decoration: const InputDecoration(
                      labelText:
                          "Consumer Ledger Target Market Listing Price (\$)",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? "Financial floating notation numeric configuration required"
                        : null,
                    onSaved: (v) => sellingPrice = double.parse(v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: holdsProduct?.warehouseLocation,
              decoration: const InputDecoration(
                labelText:
                    "Warehouse Spatial Allocation Placement Sequence Zone",
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? "Explicit space vector allocation logging parameter matrix mandatory"
                  : null,
              onSaved: (v) => warehouseLocation = v!,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Discard Data Parameters"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0d9488),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      if (holdsProduct == null) {
                        final created = Product(
                          id: 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          sku: sku,
                          name: name,
                          description: description,
                          category: category,
                          currentStock: currentStock,
                          minThreshold: minThreshold,
                          costPrice: costPrice,
                          sellingPrice: sellingPrice,
                          supplierId: supplierId,
                          warehouseLocation: warehouseLocation,
                          lastUpdated: DateTime.now(),
                        );
                        controller.addProduct(created);
                      } else {
                        final trackingUpdate = holdsProduct.copyWith(
                          sku: sku,
                          name: name,
                          description: description,
                          category: category,
                          currentStock: currentStock,
                          minThreshold: minThreshold,
                          costPrice: costPrice,
                          sellingPrice: sellingPrice,
                          supplierId: supplierId,
                          warehouseLocation: warehouseLocation,
                        );
                        controller.updateProduct(trackingUpdate);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Commit Permanent State Database Entry Transaction",
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
// 7. SCREEN 3: VENDOR/SUPPLIER PROFILE REGISTRY
// ==========================================

class VendorSupplierScreen extends StatefulWidget {
  const VendorSupplierScreen({super.key});

  @override
  State<VendorSupplierScreen> createState() => _VendorSupplierScreenState();
}

class _VendorSupplierScreenState extends State<VendorSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  Supplier? executionSelectedTrackSupplier;

  // Temporary Form Parameters
  String name = '', contact = '', email = '', phone = '', category = '';

  @override
  Widget build(BuildContext context) {
    final state = MyStateProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          'Authorized Supply Chain Vendor Registry Panel',
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
              child: ListView.builder(
                itemCount: state.suppliers.length,
                itemBuilder: (context, idx) {
                  final s = state.suppliers[idx];
                  final itemsManagedCount = state.products
                      .where((p) => p.supplierId == s.id)
                      .length;

                  return Card(
                    color: executionSelectedTrackSupplier?.id == s.id
                        ? Colors.blue.shade50
                        : Colors.white,
                    child: ListTile(
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Operations Point Representative: ${s.contactName} | Channel Email: ${s.email}\nPhone Core String Link: ${s.phone}",
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff0f172a),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$itemsManagedCount SKUs Managed",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          executionSelectedTrackSupplier = s;
                          _formKey.currentState?.reset();
                        });
                      },
                    ),
                  );
                },
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
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        executionSelectedTrackSupplier == null
                            ? "Establish Brand New Pipeline Vendor Node"
                            : "Modify Registry Parameters: ${executionSelectedTrackSupplier!.id}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1e293b),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: Key(
                          's_name_${executionSelectedTrackSupplier?.id}',
                        ),
                        initialValue: executionSelectedTrackSupplier?.name,
                        decoration: const InputDecoration(
                          labelText: "Corporate Supplier Entity Legal Name",
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Legal entity nomenclature designation required"
                            : null,
                        onSaved: (v) => name = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: Key(
                          's_cont_${executionSelectedTrackSupplier?.id}',
                        ),
                        initialValue:
                            executionSelectedTrackSupplier?.contactName,
                        decoration: const InputDecoration(
                          labelText:
                              "Primary Communications Contact Liaison Officer",
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Point person identifier sequence required"
                            : null,
                        onSaved: (v) => contact = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: Key(
                          's_mail_${executionSelectedTrackSupplier?.id}',
                        ),
                        initialValue: executionSelectedTrackSupplier?.email,
                        decoration: const InputDecoration(
                          labelText:
                              "Automated Digital Mailing Pipeline Network Address",
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? "Valid electronic communications parsing schema sequence validation error"
                            : null,
                        onSaved: (v) => email = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: Key(
                          's_phone_${executionSelectedTrackSupplier?.id}',
                        ),
                        initialValue: executionSelectedTrackSupplier?.phone,
                        decoration: const InputDecoration(
                          labelText: "Telephony Route Core Intercept Value",
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Communications hardware trace value required"
                            : null,
                        onSaved: (v) => phone = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: Key('s_cat_${executionSelectedTrackSupplier?.id}'),
                        initialValue: executionSelectedTrackSupplier?.category,
                        decoration: const InputDecoration(
                          labelText:
                              "Material Logistics Framework Classification Category",
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Industrial categorization identifier trace required"
                            : null,
                        onSaved: (v) => category = v!,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (executionSelectedTrackSupplier != null)
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  executionSelectedTrackSupplier = null;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: const Text("Exit Focus Matrix"),
                            )
                          else
                            const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2563eb),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                if (executionSelectedTrackSupplier == null) {
                                  state.addSupplier(
                                    Supplier(
                                      id: 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                                      name: name,
                                      contactName: contact,
                                      email: email,
                                      phone: phone,
                                      category: category,
                                    ),
                                  );
                                } else {
                                  state.updateSupplier(
                                    executionSelectedTrackSupplier!.copyWith(
                                      name: name,
                                      contactName: contact,
                                      email: email,
                                      phone: phone,
                                      category: category,
                                    ),
                                  );
                                }
                                setState(() {
                                  executionSelectedTrackSupplier = null;
                                  _formKey.currentState?.reset();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Vendor supply channel dynamic profile metadata database transaction committed successfully.",
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              executionSelectedTrackSupplier == null
                                  ? "Commit Supplier Entry Node"
                                  : "Apply Schema Override Updates",
                            ),
                          ),
                        ],
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
}

// ==========================================
// 8. SCREEN 4: INVENTORY AUDIT & STOCK RECONCILIATION
// ==========================================

class InventoryAuditReconciliationScreen extends StatefulWidget {
  const InventoryAuditReconciliationScreen({super.key});

  @override
  State<InventoryAuditReconciliationScreen> createState() =>
      _InventoryAuditReconciliationScreenState();
}

class _InventoryAuditReconciliationScreenState
    extends State<InventoryAuditReconciliationScreen> {
  final Map<String, int> activeWorkingPhysicalAuditCountMap = {};
  final Map<String, TextEditingController> auditNotesControllerMappingBuffer =
      {};
  final _metaAuditFormGlobalTrackingKey = GlobalKey<FormState>();

  String dynamicAuditorName = "";
  String aggregateAuditNotes = "";

  @override
  Widget build(BuildContext context) {
    final state = MyStateProvider.of(context);

    // Synchronize current database status models to avoid mismatch bounds errors
    for (var p in state.products) {
      activeWorkingPhysicalAuditCountMap.putIfAbsent(
        p.id,
        () => p.currentStock,
      );
      auditNotesControllerMappingBuffer.putIfAbsent(
        p.id,
        () => TextEditingController(
          text: "Verified baseline structural alignment.",
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          'Live Warehouse Audit & Reconciliation Desk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _displayAuditHistorySystemLogs(context, state),
            tooltip: "View History Records Summary Logs",
          ),
          const SizedBox(width: 16),
        ],
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
                    "Physical Discrepancy Verification Count Entry Data Board",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Modify values below to record live floor assessment figures. Target variance indices adjust balance equations automatically on execution.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        final p = state.products[index];
                        final currentWorkingQty =
                            activeWorkingPhysicalAuditCountMap[p.id] ??
                            p.currentStock;
                        final currentComputedVariance =
                            currentWorkingQty - p.currentStock;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "SKU: ${p.sku} | Location Marker: ${p.warehouseLocation}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            activeWorkingPhysicalAuditCountMap[p
                                                .id] = max(
                                              0,
                                              currentWorkingQty - 1,
                                            );
                                          });
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "$currentWorkingQty",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            activeWorkingPhysicalAuditCountMap[p
                                                    .id] =
                                                currentWorkingQty + 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "System Count",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        "${p.currentStock}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentComputedVariance == 0
                                          ? Colors.green.shade50
                                          : currentComputedVariance > 0
                                          ? Colors.blue.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      currentComputedVariance == 0
                                          ? "Balanced"
                                          : "Variance: ${currentComputedVariance > 0 ? '+' : ''}$currentComputedVariance",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: currentComputedVariance == 0
                                            ? Colors.green.shade800
                                            : currentComputedVariance > 0
                                            ? Colors.blue.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
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
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _metaAuditFormGlobalTrackingKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Finalize Audit Verification Seal",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Auditor Authorized Signature Token Name",
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Signatory cryptographic verification track name required"
                          : null,
                      onSaved: (v) => dynamicAuditorName = v!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText:
                            "Comprehensive Batch Audit Meta Comments Summary",
                      ),
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Operational structural assessment notes target criteria mandatory"
                          : null,
                      onSaved: (v) => aggregateAuditNotes = v!,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4f46e5),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (_metaAuditFormGlobalTrackingKey.currentState!
                              .validate()) {
                            _metaAuditFormGlobalTrackingKey.currentState!
                                .save();

                            final List<ReconciliationItem>
                            reconciliationPayload = [];

                            state.products.forEach((p) {
                              final physicalValue =
                                  activeWorkingPhysicalAuditCountMap[p.id] ??
                                  p.currentStock;
                              reconciliationPayload.add(
                                ReconciliationItem(
                                  productId: p.id,
                                  expectedQty: p.currentStock,
                                  physicalQty: physicalValue,
                                  notes:
                                      auditNotesControllerMappingBuffer[p.id]
                                          ?.text ??
                                      "Batch processed configuration.",
                                ),
                              );
                            });

                            state.processReconciliation(
                              reconciliationPayload,
                              aggregateAuditNotes,
                              dynamicAuditorName,
                            );

                            // Reset local component states completely
                            setState(() {
                              activeWorkingPhysicalAuditCountMap.clear();
                              _metaAuditFormGlobalTrackingKey.currentState
                                  ?.reset();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Warehouse structural ledger balance realignment matrix processing complete.",
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Commit Reconciliation Pipeline Adjustments",
                          style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  void _displayAuditHistorySystemLogs(
    BuildContext ctx,
    InventoryController state,
  ) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text(
          "Historical Inventory Verification Audit Logs Database",
        ),
        content: SizedBox(
          width: 650,
          height: 400,
          child: state.audits.isEmpty
              ? const Center(
                  child: Text(
                    "No historically preserved balance audit records detected inside database logs archive.",
                  ),
                )
              : ListView.builder(
                  itemCount: state.audits.length,
                  itemBuilder: (c, i) {
                    final audit = state.audits[i];
                    final varianceCalculatedSum = audit.items.fold(
                      0,
                      (sum, item) => sum + item.variance.abs(),
                    );

                    return Card(
                      color: Colors.grey.shade50,
                      child: ExpansionTile(
                        title: Text(
                          "Session ID Token Reference: ${audit.id}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          "Executed By: ${audit.performedBy} on timestamp ${audit.datePerformed.toIso8601String().substring(0, 16)}\nCumulative absolute error tracking metrics: $varianceCalculatedSum units variance",
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Auditor Statement Ledger Note: ${audit.notes}",
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Impacted Item Variations Matrix:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                ...audit.items.map((item) {
                                  final innerProd = state.getProductById(
                                    item.productId,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          innerProd?.name ??
                                              "Wiped Registry Item Line Entry",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          "Expected: ${item.expectedQty} | Physical: ${item.physicalQty} (Var: ${item.variance})",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: item.variance == 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Exit Archives Viewer"),
          ),
        ],
      ),
    );
  }
}
