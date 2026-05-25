import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEMES
// ============================================================================

enum PaymentStatus { pending, processing, failed, retrying, success }

enum OrderStatus { created, paid, shipped, delivered, cancelled }

enum CheckoutStep { cart, shipping, payment, review }

class AppColors {
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF312E81); // Indigo 900
  static const Color secondary = Color(0xFF10B981); // Emerald 500
  static const Color background = Color(0xFFF9FAFB); // Gray 50
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827); // Gray 900
  static const Color textSecondary = Color(0xFF6B7280); // Gray 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color border = Color(0xFFE5E7EB); // Gray 200
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}

// ============================================================================
// 2. UTILITIES & FORMATTERS
// ============================================================================

class Formatters {
  static String currency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String maskCard(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    return '•••• •••• •••• ${cardNumber.substring(cardNumber.length - 4)}';
  }
}

/// Custom TextInputFormatter for Credit Card Numbers
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Custom TextInputFormatter for Card Expiry (MM/YY)
class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// ============================================================================
// 3. EXCEPTIONS
// ============================================================================

abstract class CommerceException implements Exception {
  final String message;
  CommerceException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends CommerceException {
  NetworkException([
    String msg = "Network unavailable. Please check your connection.",
  ]) : super(msg);
}

class OutOfStockException extends CommerceException {
  OutOfStockException([String msg = "One or more items are out of stock."])
    : super(msg);
}

class PaymentDeclinedException extends CommerceException {
  PaymentDeclinedException([
    String msg = "Your payment was declined by the bank.",
  ]) : super(msg);
}

class PaymentTimeoutException extends CommerceException {
  PaymentTimeoutException([String msg = "The payment gateway timed out."])
    : super(msg);
}

// ============================================================================
// 4. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.stock = 10,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
  double get total => product.price * quantity;
}

class ShippingAddress {
  final String fullName;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;

  ShippingAddress({
    required this.fullName,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  bool get isValid =>
      fullName.isNotEmpty &&
      streetAddress.isNotEmpty &&
      city.isNotEmpty &&
      zipCode.isNotEmpty;
  String get formatted => '$fullName\n$streetAddress\n$city, $state $zipCode';
}

class PaymentMethod {
  final String cardNumber;
  final String expiry;
  final String cvv;
  final String cardholderName;

  PaymentMethod({
    required this.cardNumber,
    required this.expiry,
    required this.cvv,
    required this.cardholderName,
  });
}

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final ShippingAddress address;
  OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.address,
    this.status = OrderStatus.created,
    required this.createdAt,
  });

  double get total => subtotal + tax + shipping;
}

// ============================================================================
// 5. MOCK BACKEND SERVICE
// ============================================================================

class MockCommerceApi {
  static final MockCommerceApi _instance = MockCommerceApi._internal();
  factory MockCommerceApi() => _instance;
  MockCommerceApi._internal();

  final math.Random _random = math.Random();

  // Database Mock
  final List<Product> _inventory = [
    Product(
      id: 'P001',
      name: 'Sony Alpha a7 III',
      description: 'Mirrorless Digital Camera with 28-70mm Lens.',
      price: 1998.00,
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=500&q=80',
      stock: 5,
    ),
    Product(
      id: 'P002',
      name: 'Apple MacBook Pro 16"',
      description: 'M2 Max chip, 32GB RAM, 1TB SSD. Space Gray.',
      price: 3499.00,
      imageUrl:
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=500&q=80',
      stock: 2,
    ),
    Product(
      id: 'P003',
      name: 'Bose QuietComfort 45',
      description: 'Wireless Bluetooth Noise Cancelling Headphones.',
      price: 329.00,
      imageUrl:
          'https://images.unsplash.com/photo-1546435770-a3e426bf472b?auto=format&fit=crop&w=500&q=80',
      stock: 15,
    ),
    Product(
      id: 'P004',
      name: 'Keychron Q1 Pro',
      description: 'Custom Wireless Mechanical Keyboard.',
      price: 199.00,
      imageUrl:
          'https://images.unsplash.com/photo-1595225476474-87563907a212?auto=format&fit=crop&w=500&q=80',
      stock: 0,
    ), // Out of stock example
    Product(
      id: 'P005',
      name: 'Herman Miller Aeron',
      description: 'Ergonomic Office Chair. Size B.',
      price: 1695.00,
      imageUrl:
          'https://images.unsplash.com/photo-1505843490538-5133c6c7d0e1?auto=format&fit=crop&w=500&q=80',
      stock: 8,
    ),
  ];

  // Represents the user's saved cart on the server
  final List<CartItem> _cloudCart = [];

  Future<void> _simulateLatency([int min = 500, int max = 1500]) async {
    await Future.delayed(
      Duration(milliseconds: min + _random.nextInt(max - min)),
    );
  }

  Future<List<Product>> getProducts() async {
    await _simulateLatency();
    return List.from(_inventory);
  }

  /// Merges local guest cart with the cloud cart upon authentication
  Future<List<CartItem>> mergeCarts(List<CartItem> localCart) async {
    await _simulateLatency(800, 2000); // Merging takes time

    for (var localItem in localCart) {
      final existingIdx = _cloudCart.indexWhere(
        (c) => c.product.id == localItem.product.id,
      );
      if (existingIdx >= 0) {
        // Merge quantities
        _cloudCart[existingIdx].quantity += localItem.quantity;
      } else {
        // Add new item
        _cloudCart.add(
          CartItem(product: localItem.product, quantity: localItem.quantity),
        );
      }
    }
    return List.from(_cloudCart);
  }

  /// Complex Payment Processor simulating real-world failures
  Future<String> processPayment(double amount, PaymentMethod method) async {
    await _simulateLatency(1500, 3000); // Payment gateway delay

    // 1. Validate Card Number format roughly
    if (method.cardNumber.replaceAll(' ', '').length < 15) {
      throw PaymentDeclinedException("Invalid card number length.");
    }

    // 2. Simulate Random Network Drop (10% chance)
    if (_random.nextDouble() < 0.1) {
      throw NetworkException("Connection to payment gateway lost.");
    }

    // 3. Simulate Gateway Timeout (10% chance)
    if (_random.nextDouble() < 0.1) {
      throw PaymentTimeoutException(
        "Payment gateway is taking too long to respond.",
      );
    }

    // 4. Simulate Bank Decline based on arbitrary logic (e.g., CVV ends in 9)
    if (method.cvv.endsWith('9')) {
      throw PaymentDeclinedException(
        "Card declined by issuing bank (Insufficient Funds or Blocked).",
      );
    }

    // Success
    return "TXN_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}";
  }

  Future<Order> createOrder(
    List<CartItem> items,
    ShippingAddress address,
    String transactionId,
  ) async {
    await _simulateLatency();

    // Deduct stock
    for (var item in items) {
      final inventoryItem = _inventory.firstWhere(
        (p) => p.id == item.product.id,
      );
      if (inventoryItem.stock < item.quantity) {
        throw OutOfStockException(
          "${inventoryItem.name} only has ${inventoryItem.stock} left.",
        );
      }
      inventoryItem.stock -= item.quantity;
    }

    final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    final order = Order(
      id: "ORD-${_random.nextInt(999999).toString().padLeft(6, '0')}",
      items: items,
      subtotal: subtotal,
      tax: subtotal * 0.08,
      shipping: subtotal > 1000 ? 0.0 : 25.0,
      address: address,
      status: OrderStatus.paid,
      createdAt: DateTime.now(),
    );

    // Clear cloud cart after successful order
    _cloudCart.clear();

    return order;
  }
}

// ============================================================================
// 6. STATE MANAGEMENT (Custom Redux/Provider Store)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockCommerceApi _api = MockCommerceApi();

  // Inventory State
  List<Product> products = [];
  bool isLoadingProducts = true;

  // Auth State
  User? currentUser;
  bool isMergingCart = false;

  // Cart State
  List<CartItem> cart = [];

  // Checkout State
  ShippingAddress? shippingAddress;
  PaymentMethod? paymentMethod;
  Order? lastOrder;

  AppState() {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    isLoadingProducts = true;
    notifyListeners();
    try {
      products = await _api.getProducts();
    } catch (e) {
      // Handle error visually in a real app
    } finally {
      isLoadingProducts = false;
      notifyListeners();
    }
  }

  // --- Cart Operations ---
  void addToCart(Product product) {
    if (product.stock <= 0) return;

    final index = cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (cart[index].quantity < product.stock) {
        cart[index].quantity++;
      }
    } else {
      cart.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = cart.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        removeFromCart(productId);
      } else if (newQuantity <= cart[index].product.stock) {
        cart[index].quantity = newQuantity;
        notifyListeners();
      }
    }
  }

  double get cartSubtotal => cart.fold(0, (sum, item) => sum + item.total);
  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);

  // --- Auth & Merge ---
  Future<void> login(String email, String password) async {
    isMergingCart = true;
    notifyListeners();

    // Fake authentication
    await Future.delayed(const Duration(seconds: 1));
    currentUser = User(id: 'U_882', name: 'Jane Doe', email: email);

    // Trigger Cart Merge Engine
    try {
      final mergedCart = await _api.mergeCarts(cart);
      cart = mergedCart;
    } catch (e) {
      // Fallback: keep local cart on failure
    } finally {
      isMergingCart = false;
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    cart.clear(); // Clear local cart on logout
    notifyListeners();
  }

  // --- Checkout Pipeline Setters ---
  void setAddress(ShippingAddress addr) {
    shippingAddress = addr;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    paymentMethod = method;
    notifyListeners();
  }

  void clearCheckout() {
    shippingAddress = null;
    paymentMethod = null;
    cart.clear();
    notifyListeners();
  }
}

// InheritedNotifier to inject state deeply
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
  runApp(const ECommerceApp());
}

class ECommerceApp extends StatelessWidget {
  const ECommerceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Checkout',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Helvetica Neue',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        home: const CatalogScreen(),
      ),
    );
  }
}

// ============================================================================
// 8. CATALOG SCREEN (PRODUCTS)
// ============================================================================

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text(
              'Nexus Electronics',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [_UserAvatarWidget(), _CartBadgeWidget()],
          ),
          if (state.isLoadingProducts)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.products.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No products found.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _ProductCard(product: state.products[index]),
                  childCount: state.products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserAvatarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.currentUser != null) {
      return IconButton(
        icon: const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, size: 18, color: Colors.white),
        ),
        onPressed: () => _showProfileDialog(context, state),
      );
    }
    return IconButton(
      icon: const Icon(Icons.login),
      onPressed: () => _showLoginDialog(context, state),
    );
  }

  void _showLoginDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Login to merge cart'),
        content: state.isMergingCart
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : const Text('Simulate login to test cart merging engine.'),
        actions: state.isMergingCart
            ? []
            : [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await state.login("user@nexus.com", "password");
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Login'),
                ),
              ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.currentUser!.name),
        content: Text(state.currentUser!.email),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              state.logout();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartBadgeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
        if (state.cartCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${state.cartCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final bool outOfStock = product.stock <= 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'img_${product.id}',
                      child: Image.network(product.imageUrl, fit: BoxFit.cover),
                    ),
                    if (outOfStock)
                      Container(
                        color: Colors.white.withOpacity(0.7),
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.currency(product.price),
                          style: AppTextStyles.price.copyWith(fontSize: 16),
                        ),
                        if (!outOfStock)
                          InkWell(
                            onTap: () {
                              state.addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} added to cart',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
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

// ============================================================================
// 9. PRODUCT DETAIL SCREEN
// ============================================================================

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final bool outOfStock = product.stock <= 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(actions: [_CartBadgeWidget()]),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 350,
              child: Hero(
                tag: 'img_${product.id}',
                child: Image.network(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(product.name, style: AppTextStyles.h1),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        Formatters.currency(product.price),
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: outOfStock
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      outOfStock
                          ? 'Out of Stock'
                          : '${product.stock} units available',
                      style: TextStyle(
                        color: outOfStock
                            ? AppColors.error
                            : AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: AppTextStyles.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: ElevatedButton(
          onPressed: outOfStock
              ? null
              : () {
                  state.addToCart(product);
                  Navigator.pop(context);
                },
          child: Text(
            outOfStock ? 'UNAVAILABLE' : 'ADD TO CART',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 10. CART SCREEN
// ============================================================================

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: state.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: AppTextStyles.h2),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final item = state.cart[index];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: AppTextStyles.h3,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.currency(item.product.price),
                                  style: AppTextStyles.price,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => state.updateQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => state.updateQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _CartSummary(state: state),
              ],
            ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final AppState state;
  const _CartSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final subtotal = state.cartSubtotal;
    final tax = subtotal * 0.08;
    final shipping = subtotal > 1000 ? 0.0 : 25.0;
    final total = subtotal + tax + shipping;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: AppTextStyles.bodySmall),
                Text(Formatters.currency(subtotal), style: AppTextStyles.body),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Tax', style: AppTextStyles.bodySmall),
                Text(Formatters.currency(tax), style: AppTextStyles.body),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping', style: AppTextStyles.bodySmall),
                Text(
                  shipping == 0 ? 'FREE' : Formatters.currency(shipping),
                  style: AppTextStyles.body,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: AppTextStyles.h2),
                Text(
                  Formatters.currency(total),
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (state.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login first to checkout'),
                      ),
                    );
                    return; // In real app, route to auth flow
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutWizard()),
                  );
                },
                child: const Text(
                  'PROCEED TO CHECKOUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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

// ============================================================================
// 11. CHECKOUT WIZARD ENGINE
// ============================================================================

class CheckoutWizard extends StatefulWidget {
  const CheckoutWizard({Key? key}) : super(key: key);

  @override
  State<CheckoutWizard> createState() => _CheckoutWizardState();
}

class _CheckoutWizardState extends State<CheckoutWizard> {
  int _currentStep = 0;

  // Form Keys
  final _addressFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();

  // Address Controllers
  final _nameCtrl = TextEditingController(text: 'John Doe');
  final _streetCtrl = TextEditingController(text: '123 Silicon Valley Blvd');
  final _cityCtrl = TextEditingController(text: 'San Francisco');
  final _stateCtrl = TextEditingController(text: 'CA');
  final _zipCtrl = TextEditingController(text: '94105');

  // Payment Controllers
  final _cardCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  void _onStepContinue() {
    final state = AppStore.of(context, listen: false);

    if (_currentStep == 0) {
      if (_addressFormKey.currentState!.validate()) {
        state.setAddress(
          ShippingAddress(
            fullName: _nameCtrl.text,
            streetAddress: _streetCtrl.text,
            city: _cityCtrl.text,
            state: _stateCtrl.text,
            zipCode: _zipCtrl.text,
          ),
        );
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      if (_paymentFormKey.currentState!.validate()) {
        state.setPaymentMethod(
          PaymentMethod(
            cardNumber: _cardCtrl.text,
            expiry: _expCtrl.text,
            cvv: _cvvCtrl.text,
            cardholderName:
                _nameCtrl.text, // Assume same as shipping for simplicity
          ),
        );
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 2) {
      // Trigger complex payment flow overlay
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaymentProcessingScreen()),
      );
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Checkout')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(isLastStep ? 'PLACE ORDER' : 'CONTINUE'),
                  ),
                ),
                const SizedBox(width: 16),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: details.onStepCancel,
                      child: const Text('BACK'),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Shipping'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: Form(
              key: _addressFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _streetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateCtrl,
                          decoration: const InputDecoration(labelText: 'State'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _zipCtrl,
                    decoration: const InputDecoration(labelText: 'ZIP Code'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Payment'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: Form(
              key: _paymentFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Simulate Failure: End CVV with "9" to test bank decline logic.',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _cardCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CardNumberFormatter(),
                      LengthLimitingTextInputFormatter(19),
                    ],
                    validator: (v) =>
                        v!.length < 19 ? 'Invalid card number' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expCtrl,
                          decoration: const InputDecoration(labelText: 'MM/YY'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CardExpiryFormatter(),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          validator: (v) =>
                              v!.length < 5 ? 'Invalid expiry' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvCtrl,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (v) =>
                              v!.length < 3 ? 'Invalid CVV' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 2,
            content: _ReviewOrderWidget(),
          ),
        ],
      ),
    );
  }
}

class _ReviewOrderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final addr = state.shippingAddress;
    final pay = state.paymentMethod;

    if (addr == null || pay == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        ...state.cart
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.product.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.currency(item.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        const Divider(height: 32),
        const Text('Shipping To', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(addr.formatted, style: AppTextStyles.bodySmall),
        const Divider(height: 32),
        const Text('Payment Method', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          'Visa ending in ${pay.cardNumber.substring(pay.cardNumber.length - 4)}',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

// ============================================================================
// 12. PAYMENT PROCESSING & RETRY ENGINE
// ============================================================================

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({Key? key}) : super(key: key);

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  PaymentStatus _status = PaymentStatus.pending;
  String _statusMessage = "Initiating secure connection...";
  String _errorMessage = "";
  int _retryCount = 0;
  final int _maxAutoRetries =
      2; // Auto-retry for network drops before asking user

  @override
  void initState() {
    super.initState();
    _startPaymentPipeline();
  }

  Future<void> _startPaymentPipeline() async {
    setState(() {
      _status = _retryCount > 0
          ? PaymentStatus.retrying
          : PaymentStatus.processing;
      _statusMessage = _retryCount > 0
          ? "Retrying connection (Attempt ${_retryCount + 1})..."
          : "Contacting your bank...";
      _errorMessage = "";
    });

    final state = AppStore.of(context, listen: false);
    final api = MockCommerceApi();

    try {
      // Step 1: Process Payment
      final totalAmount = state.cartSubtotal * 1.08; // Roughly including tax
      final txId = await api.processPayment(totalAmount, state.paymentMethod!);

      // Step 2: Create Order
      setState(
        () => _statusMessage = "Payment successful! Generating order...",
      );
      final order = await api.createOrder(
        state.cart,
        state.shippingAddress!,
        txId,
      );

      // Step 3: Complete
      setState(() {
        _status = PaymentStatus.success;
        state.lastOrder = order;
      });

      // Clear checkout data
      state.clearCheckout();

      // Navigate to Success Screen
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          (route) => route.isFirst, // Pop all the way to catalog
        );
      }
    } on NetworkException catch (e) {
      _handleRecoverableError(e.message);
    } on PaymentTimeoutException catch (e) {
      _handleRecoverableError(e.message);
    } on CommerceException catch (e) {
      // Hard failures (e.g. Card Declined, Out of Stock) should not auto-retry
      _handleHardFailure(e.message);
    } catch (e) {
      _handleHardFailure("An unexpected error occurred.");
    }
  }

  void _handleRecoverableError(String msg) async {
    if (_retryCount < _maxAutoRetries) {
      _retryCount++;
      // Exponential backoff
      await Future.delayed(Duration(seconds: _retryCount * 2));
      _startPaymentPipeline();
    } else {
      _handleHardFailure("$msg Maximum retry attempts reached.");
    }
  }

  void _handleHardFailure(String msg) {
    setState(() {
      _status = PaymentStatus.failed;
      _errorMessage = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Prevent user from popping back during processing
    return WillPopScope(
      onWillPop: () async => _status == PaymentStatus.failed,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _buildStateWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildStateWidget() {
    switch (_status) {
      case PaymentStatus.processing:
      case PaymentStatus.retrying:
      case PaymentStatus.pending:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 32),
            Text(
              _statusMessage,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Please do not close the app or press back.",
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      case PaymentStatus.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.secondary,
              size: 100,
            ),
            const SizedBox(height: 32),
            const Text("Success!", style: AppTextStyles.h2),
          ],
        );
      case PaymentStatus.failed:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 80),
            const SizedBox(height: 24),
            const Text("Payment Failed", style: AppTextStyles.h2),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _retryCount = 0; // Reset manual retries
                  _startPaymentPipeline();
                },
                child: const Text("TRY AGAIN"),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "USE A DIFFERENT CARD",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
    }
  }
}

// ============================================================================
// 13. ORDER SUCCESS & ANIMATION
// ============================================================================

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({Key? key}) : super(key: key);

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final order = state.lastOrder;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: AnimatedCheckmarkPainter(animation: _ctrl),
                  ),
                ),
                const SizedBox(height: 32),
                const Text("Order Confirmed!", style: AppTextStyles.h1),
                const SizedBox(height: 16),
                Text(
                  "Thank you for your purchase.",
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 48),
                if (order != null) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Order ID",
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Paid",
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              Formatters.currency(order.total),
                              style: AppTextStyles.price,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Delivery To",
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              order.address.city,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CONTINUE SHOPPING"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A highly polished custom painter for the success checkmark animation
class AnimatedCheckmarkPainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedCheckmarkPainter({required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint circlePaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final Paint checkPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Circle (progresses 0 -> 0.5)
    double circleProgress = (animation.value / 0.5).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      2 * math.pi * circleProgress,
      false,
      circlePaint,
    );

    // Draw Checkmark (progresses 0.5 -> 1.0)
    if (animation.value > 0.5) {
      double checkProgress = ((animation.value - 0.5) / 0.5).clamp(0.0, 1.0);

      Path checkPath = Path();
      // Start point of check
      Offset p1 = Offset(size.width * 0.3, size.height * 0.5);
      // Bottom point of check
      Offset p2 = Offset(size.width * 0.45, size.height * 0.65);
      // End point of check
      Offset p3 = Offset(size.width * 0.7, size.height * 0.35);

      checkPath.moveTo(p1.dx, p1.dy);

      // Interpolate lines based on progress
      if (checkProgress < 0.5) {
        // Draw first segment of checkmark
        double segmentProgress = checkProgress / 0.5;
        Offset current = Offset.lerp(p1, p2, segmentProgress)!;
        checkPath.lineTo(current.dx, current.dy);
      } else {
        // Draw full first segment and interpolate second segment
        checkPath.lineTo(p2.dx, p2.dy);
        double segmentProgress = (checkProgress - 0.5) / 0.5;
        Offset current = Offset.lerp(p2, p3, segmentProgress)!;
        checkPath.lineTo(current.dx, current.dy);
      }

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedCheckmarkPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value;
}
