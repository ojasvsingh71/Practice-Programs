import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Per-file Color compatibility shim (replaces deprecated `withOpacity` usage)
extension ColorWithValues on Color {
  Color withValues(double opacity) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int b = value & 0xFF;
    return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
  }
}

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum OrderStatus {
  pending,
  paymentFailed,
  preparing,
  riderAssigned,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

enum PaymentMethod { creditCard, wallet, cashOnDelivery }

class AppColors {
  static const Color primary = Color(0xFFFC8019); // Food Delivery Orange
  static const Color primaryDark = Color(0xFFD9650B);
  static const Color background = Color(0xFFF3F4F6); // Light Gray
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF1F2937); // Slate 800
  static const Color textMuted = Color(0xFF6B7280); // Slate 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color mapBg = Color(0xFFE5E7EB);
  static const Color mapRoad = Color(0xFFFFFFFF);
  static const Color mapRoute = Color(0xFF3B82F6);
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
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textMain,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );
  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );
}

// ============================================================================
// 2. EXCEPTIONS & UTILS
// ============================================================================

abstract class DeliveryException implements Exception {
  final String message;
  DeliveryException(this.message);
  @override
  String toString() => message;
}

class PaymentFailedException extends DeliveryException {
  PaymentFailedException([String m = "Payment was declined by the bank."])
    : super(m);
}

class NetworkException extends DeliveryException {
  NetworkException([String m = "Network timeout. Connection lost."]) : super(m);
}

class CartConflictException extends DeliveryException {
  CartConflictException([
    String m = "You can only order from one restaurant at a time.",
  ]) : super(m);
}

class Formatters {
  static String currency(double amount) => '\$${amount.toStringAsFixed(2)}';
  static String time(DateTime d) {
    int h = d.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} $p';
  }
}

// ============================================================================
// 3. DOMAIN MODELS & GEOMETRY
// ============================================================================

class GeoCoord {
  final double x;
  final double y;
  const GeoCoord(this.x, this.y);
  double distanceTo(GeoCoord other) =>
      math.sqrt(math.pow(other.x - x, 2) + math.pow(other.y - y, 2));
  GeoCoord lerp(GeoCoord other, double t) =>
      GeoCoord(x + (other.x - x) * t, y + (other.y - y) * t);
}

class User {
  final String id;
  final String name;
  final String phone;
  final GeoCoord defaultLocation;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.defaultLocation,
  });
}

class Rider {
  final String id;
  final String name;
  final String vehicle;
  final String phone;
  final double rating;
  final String avatar;

  Rider({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.phone,
    required this.rating,
    required this.avatar,
  });
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isVeg;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isVeg,
  });
}

class Restaurant {
  final String id;
  final String name;
  final String tags;
  final double rating;
  final int deliveryTimeMins;
  final double deliveryFee;
  final String heroImage;
  final GeoCoord location;
  final List<MenuItem> menu;

  Restaurant({
    required this.id,
    required this.name,
    required this.tags,
    required this.rating,
    required this.deliveryTimeMins,
    required this.deliveryFee,
    required this.heroImage,
    required this.location,
    required this.menu,
  });
}

class CartItem {
  final MenuItem item;
  int quantity;
  CartItem({required this.item, this.quantity = 1});
  double get total => item.price * quantity;
}

class Order {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double grandTotal;
  final GeoCoord deliveryLocation;
  final GeoCoord restaurantLocation;

  OrderStatus status;
  Rider? assignedRider;
  GeoCoord? riderLocation;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.grandTotal,
    required this.deliveryLocation,
    required this.restaurantLocation,
    this.status = OrderStatus.pending,
    this.assignedRider,
    this.riderLocation,
    required this.createdAt,
  });

  Order copyWith({
    OrderStatus? status,
    Rider? assignedRider,
    GeoCoord? riderLocation,
  }) {
    return Order(
      id: id,
      userId: userId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      grandTotal: grandTotal,
      deliveryLocation: deliveryLocation,
      restaurantLocation: restaurantLocation,
      status: status ?? this.status,
      assignedRider: assignedRider ?? this.assignedRider,
      riderLocation: riderLocation ?? this.riderLocation,
      createdAt: createdAt,
    );
  }
}

// ============================================================================
// 4. MOCK BACKEND ENGINE & DISPATCHER
// ============================================================================

class MockDeliveryBackend {
  static final MockDeliveryBackend _instance = MockDeliveryBackend._internal();
  factory MockDeliveryBackend() => _instance;
  MockDeliveryBackend._internal() {
    _seedData();
  }

  final math.Random _random = math.Random();
  final List<Restaurant> _restaurants = [];

  // Public unnamed constructor removed; seeding occurs in `_internal()`.

  void _seedData() {
    _restaurants.addAll([
      Restaurant(
        id: 'R1',
        name: 'Burger Joint',
        tags: 'American • Burgers • Fast Food',
        rating: 4.5,
        deliveryTimeMins: 25,
        deliveryFee: 2.99,
        heroImage:
            'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80',
        location: const GeoCoord(20, 80),
        menu: [
          MenuItem(
            id: 'M1',
            name: 'Classic Cheeseburger',
            description: 'Angus beef, cheddar, lettuce, tomato, house sauce.',
            price: 8.99,
            isVeg: false,
            imageUrl:
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80',
          ),
          MenuItem(
            id: 'M2',
            name: 'Double Bacon Smash',
            description: 'Two smashed patties, crispy bacon, american cheese.',
            price: 12.49,
            isVeg: false,
            imageUrl:
                'https://images.unsplash.com/photo-1594212202875-8eb64b07fb81?auto=format&fit=crop&w=400&q=80',
          ),
          MenuItem(
            id: 'M3',
            name: 'Truffle Fries',
            description: 'Crispy fries tossed in truffle oil and parmesan.',
            price: 4.99,
            isVeg: true,
            imageUrl:
                'https://images.unsplash.com/photo-1573081405052-a56763eb8cce?auto=format&fit=crop&w=400&q=80',
          ),
        ],
      ),
      Restaurant(
        id: 'R2',
        name: 'Sushi Zen',
        tags: 'Japanese • Sushi • Asian',
        rating: 4.8,
        deliveryTimeMins: 40,
        deliveryFee: 4.99,
        heroImage:
            'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=800&q=80',
        location: const GeoCoord(80, 20),
        menu: [
          MenuItem(
            id: 'M4',
            name: 'Spicy Tuna Roll',
            description: 'Fresh tuna, spicy mayo, cucumber.',
            price: 7.99,
            isVeg: false,
            imageUrl:
                'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=400&q=80',
          ),
          MenuItem(
            id: 'M5',
            name: 'Dragon Roll',
            description: 'Shrimp tempura topped with eel and avocado.',
            price: 14.99,
            isVeg: false,
            imageUrl:
                'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?auto=format&fit=crop&w=400&q=80',
          ),
          MenuItem(
            id: 'M6',
            name: 'Edamame',
            description: 'Steamed soybeans with sea salt.',
            price: 3.99,
            isVeg: true,
            imageUrl:
                'https://images.unsplash.com/photo-1512852955513-886fb5c39174?auto=format&fit=crop&w=400&q=80',
          ),
        ],
      ),
      Restaurant(
        id: 'R3',
        name: 'Pizza Paradiso',
        tags: 'Italian • Pizza • Comfort',
        rating: 4.2,
        deliveryTimeMins: 35,
        deliveryFee: 1.99,
        heroImage:
            'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=800&q=80',
        location: const GeoCoord(70, 80),
        menu: [
          MenuItem(
            id: 'M7',
            name: 'Margherita',
            description: 'San marzano tomato sauce, fresh mozzarella, basil.',
            price: 14.00,
            isVeg: true,
            imageUrl:
                'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=400&q=80',
          ),
          MenuItem(
            id: 'M8',
            name: 'Pepperoni Inferno',
            description: 'Double pepperoni, hot honey drizzle.',
            price: 17.50,
            isVeg: false,
            imageUrl:
                'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
          ),
        ],
      ),
    ]);
  }

  Future<void> _latency([int ms = 800]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(500)));

  Future<User> login() async {
    await _latency();
    return User(
      id: 'U1',
      name: 'John Customer',
      phone: '+1 555-0198',
      defaultLocation: const GeoCoord(50, 50),
    );
  }

  Future<List<Restaurant>> getRestaurants() async {
    await _latency();
    return List.from(_restaurants);
  }

  /// Complex Payment Engine with intentional random failure simulation
  Future<String> processPayment(double amount) async {
    await _latency(2000); // Payment gateway delay

    // 30% chance to simulate a payment failure or network timeout
    double chance = _random.nextDouble();
    if (chance < 0.1) {
      throw NetworkException("Connection to payment gateway lost.");
    } else if (chance < 0.3) {
      throw PaymentFailedException("Insufficient funds or card declined.");
    }

    return 'TXN_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Async Dispatcher: Manages the lifecycle of an active order and streams live updates
  Stream<Order> startLiveOrderTracking(Order initialOrder) async* {
    Order currentOrder = initialOrder.copyWith(status: OrderStatus.preparing);
    yield currentOrder;

    // 1. Preparing Food
    await Future.delayed(const Duration(seconds: 4));

    // 2. Assign Rider
    final rider = Rider(
      id: 'RD1',
      name: 'Mike T.',
      vehicle: 'Honda Scooter',
      phone: '+1 555-8888',
      rating: 4.8,
      avatar: 'M',
    );
    // Start rider somewhere near the restaurant
    GeoCoord riderLoc = GeoCoord(
      currentOrder.restaurantLocation.x + (_random.nextDouble() * 10 - 5),
      currentOrder.restaurantLocation.y + (_random.nextDouble() * 10 - 5),
    );

    currentOrder = currentOrder.copyWith(
      status: OrderStatus.riderAssigned,
      assignedRider: rider,
      riderLocation: riderLoc,
    );
    yield currentOrder;
    await Future.delayed(const Duration(seconds: 2));

    // 3. Rider travels to Restaurant (Interpolated movement)
    yield* _simulateMovement(
      currentOrder,
      riderLoc,
      currentOrder.restaurantLocation,
      OrderStatus.riderAssigned,
      3,
    );

    // 4. Picked Up
    currentOrder = currentOrder.copyWith(
      status: OrderStatus.pickedUp,
      riderLocation: currentOrder.restaurantLocation,
    );
    yield currentOrder;
    await Future.delayed(const Duration(seconds: 2));

    // 5. On The Way (Interpolated movement to Customer)
    yield* _simulateMovement(
      currentOrder,
      currentOrder.restaurantLocation,
      currentOrder.deliveryLocation,
      OrderStatus.onTheWay,
      8,
    );

    // 6. Delivered
    currentOrder = currentOrder.copyWith(
      status: OrderStatus.delivered,
      riderLocation: currentOrder.deliveryLocation,
    );
    yield currentOrder;
  }

  Stream<Order> _simulateMovement(
    Order order,
    GeoCoord start,
    GeoCoord end,
    OrderStatus status,
    int durationSecs,
  ) async* {
    int frames = durationSecs * 10; // 10 updates per second
    for (int i = 0; i <= frames; i++) {
      double t = i / frames;
      // Smooth step easing
      double smoothT = t * t * (3 - 2 * t);
      GeoCoord current = start.lerp(end, smoothT);

      yield order.copyWith(status: status, riderLocation: current);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

// ============================================================================
// 5. STATE MANAGEMENT (InheritedNotifier pattern)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockDeliveryBackend _api = MockDeliveryBackend();

  User? currentUser;
  bool isGlobalLoading = false;
  String? globalError;

  // Data
  List<Restaurant> restaurants = [];

  // Cart State
  String? cartRestaurantId;
  String? cartRestaurantName;
  GeoCoord? cartRestaurantLocation;
  List<CartItem> cartItems = [];

  // Live Order State
  Order? activeOrder;
  StreamSubscription? _orderSub;

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  Future<void> initApp() async {
    _setLoading(true);
    try {
      currentUser = await _api.login();
      restaurants = await _api.getRestaurants();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // --- Cart Engine ---
  void addToCart(Restaurant restaurant, MenuItem item) {
    if (cartRestaurantId != null && cartRestaurantId != restaurant.id) {
      throw CartConflictException();
    }

    cartRestaurantId = restaurant.id;
    cartRestaurantName = restaurant.name;
    cartRestaurantLocation = restaurant.location;

    final index = cartItems.indexWhere((i) => i.item.id == item.id);
    if (index >= 0) {
      cartItems[index].quantity++;
    } else {
      cartItems.add(CartItem(item: item, quantity: 1));
    }
    notifyListeners();
  }

  void updateQuantity(String itemId, int delta) {
    final index = cartItems.indexWhere((i) => i.item.id == itemId);
    if (index >= 0) {
      cartItems[index].quantity += delta;
      if (cartItems[index].quantity <= 0) {
        cartItems.removeAt(index);
      }
      if (cartItems.isEmpty) {
        clearCart();
      } else {
        notifyListeners();
      }
    }
  }

  void clearCart() {
    cartRestaurantId = null;
    cartRestaurantName = null;
    cartRestaurantLocation = null;
    cartItems.clear();
    notifyListeners();
  }

  double get cartSubtotal => cartItems.fold(0.0, (sum, i) => sum + i.total);
  int get cartItemCount => cartItems.fold(0, (sum, i) => sum + i.quantity);

  // --- Checkout Engine ---
  Future<bool> processCheckout() async {
    _setLoading(true);
    _setError(null);

    // Calculate final totals
    final restaurant = restaurants.firstWhere((r) => r.id == cartRestaurantId);
    final subtotal = cartSubtotal;
    final delivery = restaurant.deliveryFee;
    final tax = subtotal * 0.08;
    final total = subtotal + delivery + tax;

    try {
      // 1. Process Payment
      await _api.processPayment(total);

      // 2. Create Order
      final order = Order(
        id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser!.id,
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        items: List.from(cartItems),
        subtotal: subtotal,
        deliveryFee: delivery,
        tax: tax,
        grandTotal: total,
        deliveryLocation: currentUser!.defaultLocation,
        restaurantLocation: restaurant.location,
        createdAt: DateTime.now(),
      );

      clearCart();

      // 3. Mount Live Tracker Stream
      activeOrder = order;
      _orderSub?.cancel();
      _orderSub = _api.startLiveOrderTracking(order).listen((updatedOrder) {
        activeOrder = updatedOrder;
        notifyListeners();
      });

      return true;
    } on DeliveryException catch (e) {
      _setError(e.message);
      return false; // Tells UI to show error / retry prompt
    } finally {
      _setLoading(false);
    }
  }

  void clearActiveOrder() {
    _orderSub?.cancel();
    activeOrder = null;
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
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FoodDeliveryApp());
}

class FoodDeliveryApp extends StatelessWidget {
  const FoodDeliveryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    state.initApp(); // Auto bootup

    return AppStore(
      state: state,
      child: MaterialApp(
        title: 'Nexus Eats',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textMain,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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

    if (state.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Force route to Active Tracker if an order is live
    if (state.activeOrder != null &&
        state.activeOrder!.status != OrderStatus.delivered) {
      return const LiveTrackingScreen();
    }

    return const MainDiscoveryScreen();
  }
}

// ============================================================================
// 7. HOME / DISCOVERY SCREEN
// ============================================================================

class MainDiscoveryScreen extends StatelessWidget {
  const MainDiscoveryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Home',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down),
                        const Spacer(),
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search restaurants or dishes...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    _CategoryAvatar(icon: '🍔', label: 'Burgers'),
                    _CategoryAvatar(icon: '🍕', label: 'Pizza'),
                    _CategoryAvatar(icon: '🍣', label: 'Sushi'),
                    _CategoryAvatar(icon: '🥗', label: 'Healthy'),
                    _CategoryAvatar(icon: '🍩', label: 'Dessert'),
                  ],
                ),
              ),
            ),
          ),

          // Restaurant List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: const Text('Featured Restaurants', style: AppStyles.h2),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final restaurant = state.restaurants[index];
              return _RestaurantCard(restaurant: restaurant);
            }, childCount: state.restaurants.length),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ), // Bottom padding
        ],
      ),
      floatingActionButton: state.cartItemCount > 0
          ? const _CartFloatingBar()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  final String icon;
  final String label;
  const _CategoryAvatar({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    restaurant.heroImage,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: AppStyles.h2),
                  const SizedBox(height: 4),
                  Text(restaurant.tags, style: AppStyles.caption),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.deliveryTimeMins} mins',
                        style: AppStyles.caption,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.delivery_dining,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.currency(restaurant.deliveryFee),
                        style: AppStyles.caption,
                      ),
                    ],
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

// ============================================================================
// 8. RESTAURANT MENU SCREEN
// ============================================================================

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({Key? key, required this.restaurant})
    : super(key: key);

  void _handleAddToCart(BuildContext context, AppState state, MenuItem item) {
    try {
      state.addToCart(restaurant, item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added to cart'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on CartConflictException {
      _showCartConflictDialog(context, state, item);
    }
  }

  void _showCartConflictDialog(
    BuildContext context,
    AppState state,
    MenuItem item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start new cart?'),
        content: Text(
          'Your cart contains items from ${state.cartRestaurantName}. Do you want to clear it and add this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              state.clearCart();
              state.addToCart(restaurant, item);
              Navigator.pop(ctx);
            },
            child: const Text('Clear & Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(restaurant.heroImage, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(restaurant.name),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.rating} Rating',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${restaurant.deliveryTimeMins} mins',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Menu', style: AppStyles.h2),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = restaurant.menu[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.stop_circle,
                            size: 14,
                            color: item.isVeg
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(height: 4),
                          Text(item.name, style: AppStyles.h3),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currency(item.price),
                            style: AppStyles.price,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: AppStyles.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: -10,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            onPressed: () =>
                                _handleAddToCart(context, state, item),
                            child: const Text(
                              'ADD',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }, childCount: restaurant.menu.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton:
          state.cartRestaurantId == restaurant.id && state.cartItemCount > 0
          ? const _CartFloatingBar()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ============================================================================
// 9. CART & CHECKOUT SCREEN
// ============================================================================

class _CartFloatingBar extends StatelessWidget {
  const _CartFloatingBar();
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.cartItemCount} items | ${Formatters.currency(state.cartSubtotal)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: const [
                  Text(
                    'VIEW CART',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Icon(Icons.shopping_bag, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  void _processCheckout(BuildContext context, AppState state) async {
    final success = await state.processCheckout();
    if (!success && context.mounted && state.globalError != null) {
      _showPaymentFailedDialog(context, state);
    } else if (success && context.mounted) {
      // Pop until home, which will auto-route to Live Tracker because activeOrder is set
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _showPaymentFailedDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error, color: AppColors.error),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(state.globalError ?? 'An unknown error occurred.'),
        actions: [
          TextButton(
            onPressed: () {
              state._setError(null);
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _processCheckout(context, state); // Retry
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.cartItems.isEmpty)
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: Text('Your cart is empty.')),
      );

    final restaurant = state.restaurants.firstWhere(
      (r) => r.id == state.cartRestaurantId,
    );
    final delivery = restaurant.deliveryFee;
    final tax = state.cartSubtotal * 0.08;
    final total = state.cartSubtotal + delivery + tax;

    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Your Order', style: AppStyles.h2),
              const SizedBox(height: 16),
              ...state.cartItems
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () =>
                                      state.updateQuantity(c.item.id, -1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${c.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      state.updateQuantity(c.item.id, 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              c.item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            Formatters.currency(c.total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              const Text('Bill Details', style: AppStyles.h3),
              const SizedBox(height: 16),
              _BillRow(
                label: 'Item Total',
                value: Formatters.currency(state.cartSubtotal),
              ),
              _BillRow(
                label: 'Delivery Fee',
                value: Formatters.currency(delivery),
              ),
              _BillRow(label: 'Taxes', value: Formatters.currency(tax)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Colors.black, thickness: 1),
              ),
              _BillRow(
                label: 'Grand Total',
                value: Formatters.currency(total),
                isBold: true,
              ),

              const SizedBox(height: 120), // Padding for button
            ],
          ),

          if (state.isGlobalLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Processing Payment...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isGlobalLoading
                  ? null
                  : () => _processCheckout(context, state),
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
  final bool isBold;
  const _BillRow({
    required this.label,
    required this.value,
    this.isBold = false,
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
              fontSize: isBold ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. LIVE ORDER TRACKING & CUSTOM MAP PAINTER
// ============================================================================

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final order = state.activeOrder;

    if (order == null)
      return const Scaffold(body: Center(child: Text('No active order.')));

    return Scaffold(
      body: Stack(
        children: [
          // 1. Custom Interactive Map Layer
          Positioned.fill(
            child: CustomPaint(
              painter: _CityMapPainter(
                restaurantLoc: order.restaurantLocation,
                customerLoc: order.deliveryLocation,
                riderLoc: order.riderLocation,
                status: order.status,
              ),
            ),
          ),

          // 2. Status Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusHeader(order.status),
                    const SizedBox(height: 24),
                    _buildStepper(order.status),
                    const SizedBox(height: 24),

                    if (order.assignedRider != null) ...[
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            order.assignedRider!.avatar,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          order.assignedRider!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            Text(
                              ' ${order.assignedRider!.rating} • ${order.assignedRider!.vehicle}',
                            ),
                          ],
                        ),
                        trailing: CircleAvatar(
                          backgroundColor: AppColors.background,
                          child: const Icon(
                            Icons.call,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],

                    if (order.status == OrderStatus.delivered) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => state.clearActiveOrder(),
                          child: const Text('BACK TO HOME'),
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

  Widget _buildStatusHeader(OrderStatus status) {
    String title;
    String sub;
    switch (status) {
      case OrderStatus.pending:
        title = "Awaiting Confirmation";
        sub = "Restaurant is accepting your order.";
        break;
      case OrderStatus.preparing:
        title = "Preparing your food";
        sub = "Your order is being cooked.";
        break;
      case OrderStatus.riderAssigned:
        title = "Rider Assigned";
        sub = "Rider is heading to the restaurant.";
        break;
      case OrderStatus.pickedUp:
        title = "Order Picked Up";
        sub = "Rider has collected your food.";
        break;
      case OrderStatus.onTheWay:
        title = "On The Way";
        sub = "Your food is arriving soon!";
        break;
      case OrderStatus.delivered:
        title = "Delivered!";
        sub = "Enjoy your meal.";
        break;
      default:
        title = "Processing";
        sub = "";
    }
    return Column(
      children: [
        Text(title, style: AppStyles.h1),
        const SizedBox(height: 4),
        Text(sub, style: AppStyles.caption),
      ],
    );
  }

  Widget _buildStepper(OrderStatus status) {
    int currentStep = 0;
    if (status == OrderStatus.preparing) currentStep = 1;
    if (status == OrderStatus.riderAssigned || status == OrderStatus.pickedUp)
      currentStep = 2;
    if (status == OrderStatus.onTheWay) currentStep = 3;
    if (status == OrderStatus.delivered) currentStep = 4;

    return Row(
      children: List.generate(4, (index) {
        bool isActive = index <= currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _CityMapPainter extends CustomPainter {
  final GeoCoord restaurantLoc;
  final GeoCoord customerLoc;
  final GeoCoord? riderLoc;
  final OrderStatus status;

  _CityMapPainter({
    required this.restaurantLoc,
    required this.customerLoc,
    this.riderLoc,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Map Background & Grid
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.mapBg,
    );

    final roadPaint = Paint()
      ..color = AppColors.mapRoad
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), roadPaint);
    }
    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), roadPaint);
    }

    // Viewport scaling to fit coordinate grid (0-100) to screen
    Offset toCanvas(GeoCoord c) {
      return Offset(
        (c.x / 100) * size.width,
        (c.y / 100) * size.height * 0.6,
      ); // Scale y to fit above bottom sheet
    }

    final rPos = toCanvas(restaurantLoc);
    final cPos = toCanvas(customerLoc);

    // 2. Draw Route if rider exists
    if (riderLoc != null) {
      final routePaint = Paint()
        ..color = AppColors.mapRoute
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Determine Path based on status
      GeoCoord startNode;
      GeoCoord endNode;
      if (status == OrderStatus.riderAssigned ||
          status == OrderStatus.preparing) {
        startNode = riderLoc!;
        endNode = restaurantLoc;
      } else {
        startNode = riderLoc!;
        endNode = customerLoc;
      }

      // Draw dashed line for route
      Path path = Path()
        ..moveTo(toCanvas(startNode).dx, toCanvas(startNode).dy)
        ..lineTo(toCanvas(endNode).dx, toCanvas(endNode).dy);
      canvas.drawPath(path, routePaint);
    }

    // 3. Draw Restaurant Marker
    _drawMarker(canvas, rPos, Icons.storefront, AppColors.textMain);

    // 4. Draw Customer Marker
    _drawMarker(canvas, cPos, Icons.home, AppColors.success);

    // 5. Draw Rider Marker
    if (riderLoc != null) {
      _drawRiderMarker(canvas, toCanvas(riderLoc!));
    }
  }

  void _drawMarker(Canvas canvas, Offset pos, IconData icon, Color color) {
    canvas.drawCircle(
      pos,
      16,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      16,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Note: Rendering icons in CustomPaint requires TextPainters. For simplicity, drawing colored circles.
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawRiderMarker(Canvas canvas, Offset pos) {
    canvas.drawCircle(
      pos,
      20,
      Paint()
        ..color = AppColors.primary.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CityMapPainter oldDelegate) => true; // Always repaint for live animation
}
