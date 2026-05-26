import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
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

enum AccountType { checking, savings, credit, investment, loan }

enum TransactionType {
  deposit,
  withdrawal,
  transferIn,
  transferOut,
  payment,
  fee,
}

enum TransactionStatus { pending, completed, failed, reversed }

enum CardStatus { active, frozen, cancelled, expired }

enum ThemeModeType { light, dark, system }

/// Defines the core color palette for the Smart Wallet App.
class AppColors {
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color accent = Color(0xFF3B82F6); // Blue 500
  static const Color accentDark = Color(0xFF2563EB); // Blue 600

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  static const Color backgroundDark = Color(0xFF020617);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color cardVisa = Color(0xFF1A1F71);
  static const Color cardMastercard = Color(0xFFEB001B);
}

/// Centralized layout constants for consistent UI.
class AppLayout {
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
}

// ============================================================================
// 2. UTILITIES & FORMATTERS
// ============================================================================

/// Custom formatters since we are not using the `intl` package.
class Formatters {
  static String currency(double amount, {String symbol = '\$'}) {
    final bool isNegative = amount < 0;
    final double absAmount = amount.abs();
    final String fixed = absAmount.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');

    // Add commas to the integer part
    String integerPart = parts[0];
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }

    final String result = '$symbol$formattedInteger.${parts[1]}';
    return isNegative ? '-$result' : result;
  }

  static String date(DateTime date) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  static String time(DateTime date) {
    String hour = date.hour > 12
        ? (date.hour - 12).toString()
        : date.hour.toString();
    if (hour == '0') hour = '12';
    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String maskCardNumber(String number) {
    if (number.length < 4) return number;
    return '•••• •••• •••• ${number.substring(number.length - 4)}';
  }
}

/// Robust form validators
class Validators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? amount(String? value, {double? maxAmount}) {
    if (value == null || value.isEmpty) return 'Enter amount';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Invalid number';
    if (numValue <= 0) return 'Amount must be greater than zero';
    if (maxAmount != null && numValue > maxAmount)
      return 'Exceeds available balance';
    return null;
  }
}

// ============================================================================
// 3. EXCEPTIONS
// ============================================================================

class AppBaseException implements Exception {
  final String message;
  final String? code;
  AppBaseException(this.message, {this.code});
  @override
  String toString() => '[$code] $message';
}

class NetworkException extends AppBaseException {
  NetworkException([String msg = 'Connection timeout. Please try again.'])
    : super(msg, code: 'ERR_NETWORK');
}

class AuthException extends AppBaseException {
  AuthException([String msg = 'Invalid credentials.'])
    : super(msg, code: 'ERR_AUTH');
}

class InsufficientFundsException extends AppBaseException {
  InsufficientFundsException([
    String msg = 'Insufficient funds for this transaction.',
  ]) : super(msg, code: 'ERR_FUNDS');
}

class LimitExceededException extends AppBaseException {
  LimitExceededException([String msg = 'Transaction exceeds daily limits.'])
    : super(msg, code: 'ERR_LIMIT');
}

// ============================================================================
// 4. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String avatarUrl;
  final DateTime lastLogin;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.lastLogin,
  });

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }
}

class Account {
  final String id;
  final String userId;
  final String accountName;
  final String accountNumber;
  final String routingNumber;
  final AccountType type;
  final double balance;
  final double availableBalance;
  final String currency;

  Account({
    required this.id,
    required this.userId,
    required this.accountName,
    required this.accountNumber,
    required this.routingNumber,
    required this.type,
    required this.balance,
    required this.availableBalance,
    this.currency = 'USD',
  });

  Account copyWith({double? balance, double? availableBalance}) {
    return Account(
      id: id,
      userId: userId,
      accountName: accountName,
      accountNumber: accountNumber,
      routingNumber: routingNumber,
      type: type,
      balance: balance ?? this.balance,
      availableBalance: availableBalance ?? this.availableBalance,
      currency: currency,
    );
  }
}

class Transaction {
  final String id;
  final String accountId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String description;
  final String? merchantName;
  final String? category;
  final DateTime timestamp;
  final String referenceNumber;

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    this.merchantName,
    this.category,
    required this.timestamp,
    required this.referenceNumber,
  });

  bool get isCredit =>
      type == TransactionType.deposit || type == TransactionType.transferIn;
}

class BankCard {
  final String id;
  final String accountId;
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final String cvv;
  final CardStatus status;
  final bool isVirtual;

  BankCard({
    required this.id,
    required this.accountId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    required this.cvv,
    required this.status,
    required this.isVirtual,
  });
}

// ============================================================================
// 5. MOCK BACKEND SERVICE
// ============================================================================

/// Simulates a complex, latency-heavy backend with comprehensive business logic.
class MockBankingBackend {
  static final MockBankingBackend _instance = MockBankingBackend._internal();
  factory MockBankingBackend() => _instance;
  MockBankingBackend._internal();

  final math.Random _random = math.Random();

  // In-Memory Database Tables
  User? _sessionUser;
  final List<Account> _accounts = [];
  final List<Transaction> _transactions = [];
  final List<BankCard> _cards = [];

  // Configuration
  final double _dailyTransferLimit = 15000.0;
  double _todayTransferTotal = 0.0;

  Future<void> _simulateNetwork() async {
    int delay = 600 + _random.nextInt(1200);
    await Future.delayed(Duration(milliseconds: delay));
    // 3% chance to simulate a network dropout
    if (_random.nextDouble() < 0.03) throw NetworkException();
  }

  Future<User> login(String username, String password) async {
    await _simulateNetwork();

    if (username.trim().isEmpty || password.trim().isEmpty) {
      throw AuthException('Username and password are required.');
    }
    if (password != 'password123' && password != 'admin') {
      throw AuthException('Incorrect username or password.');
    }

    _sessionUser = User(
      id: 'USR-882910',
      firstName: 'Jonathan',
      lastName: 'Doe',
      email: 'jonathan.doe@example.com',
      phone: '+1 (555) 019-2837',
      avatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
      lastLogin: DateTime.now(),
    );

    _generateSeedData();
    return _sessionUser!;
  }

  Future<void> logout() async {
    await _simulateNetwork();
    _sessionUser = null;
    _accounts.clear();
    _transactions.clear();
    _cards.clear();
  }

  void _generateSeedData() {
    _accounts.clear();
    _transactions.clear();
    _cards.clear();

    // Generate Accounts
    final checking = Account(
      id: 'ACC-001',
      userId: _sessionUser!.id,
      accountName: 'Premium Checking',
      accountNumber: '4455667788990001',
      routingNumber: '011000015',
      type: AccountType.checking,
      balance: 8450.75,
      availableBalance: 8450.75,
    );
    final savings = Account(
      id: 'ACC-002',
      userId: _sessionUser!.id,
      accountName: 'High-Yield Savings',
      accountNumber: '4455667788990002',
      routingNumber: '011000015',
      type: AccountType.savings,
      balance: 42500.00,
      availableBalance: 42500.00,
    );

    _accounts.addAll([checking, savings]);

    // Generate Cards
    _cards.add(
      BankCard(
        id: 'CRD-001',
        accountId: checking.id,
        cardNumber: '4532889912345678',
        cardHolderName: _sessionUser!.fullName.toUpperCase(),
        expiryDate: '12/28',
        cvv: '492',
        status: CardStatus.active,
        isVirtual: false,
      ),
    );
    _cards.add(
      BankCard(
        id: 'CRD-002',
        accountId: checking.id,
        cardNumber: '4532889999990000',
        cardHolderName: _sessionUser!.fullName.toUpperCase(),
        expiryDate: '05/26',
        cvv: '111',
        status: CardStatus.active,
        isVirtual: true,
      ),
    );

    // Generate 50 realistic historical transactions
    DateTime cursor = DateTime.now();
    final List<String> merchants = [
      'Amazon',
      'Starbucks',
      'Uber',
      'Whole Foods',
      'Netflix',
      'Spotify',
      'Apple Store',
      'Gas Station',
      'Gym',
    ];
    final List<String> categories = [
      'Shopping',
      'Food',
      'Transport',
      'Groceries',
      'Entertainment',
      'Health',
    ];

    for (int i = 0; i < 50; i++) {
      cursor = cursor.subtract(Duration(hours: _random.nextInt(48) + 2));
      bool isDeposit = _random.nextDouble() > 0.8;

      String merchant = merchants[_random.nextInt(merchants.length)];
      double amount = isDeposit
          ? (_random.nextDouble() * 2000 + 500)
          : (_random.nextDouble() * 150 + 5);

      _transactions.add(
        Transaction(
          id: 'TXN-${_random.nextInt(999999).toString().padLeft(6, '0')}',
          accountId: _random.nextBool() ? checking.id : savings.id,
          type: isDeposit ? TransactionType.deposit : TransactionType.payment,
          status: TransactionStatus.completed,
          amount: amount,
          description: isDeposit ? 'Payroll Deposit' : 'POS Debit - $merchant',
          merchantName: isDeposit ? 'Employer Inc' : merchant,
          category: isDeposit
              ? 'Income'
              : categories[_random.nextInt(categories.length)],
          timestamp: cursor,
          referenceNumber: 'REF${_random.nextInt(999999999)}',
        ),
      );
    }

    // Sort transactions latest first
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<Account>> fetchAccounts() async {
    await _simulateNetwork();
    return List.unmodifiable(_accounts);
  }

  Future<List<Transaction>> fetchTransactions({
    String? accountId,
    int limit = 20,
  }) async {
    await _simulateNetwork();
    Iterable<Transaction> result = _transactions;
    if (accountId != null) {
      result = result.where((tx) => tx.accountId == accountId);
    }
    return result.take(limit).toList();
  }

  Future<List<BankCard>> fetchCards() async {
    await _simulateNetwork();
    return List.unmodifiable(_cards);
  }

  Future<Transaction> processTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String memo = '',
  }) async {
    await _simulateNetwork();

    if (amount <= 0)
      throw AppBaseException('Transfer amount must be greater than zero.');
    if (_todayTransferTotal + amount > _dailyTransferLimit) {
      throw LimitExceededException(
        'This transfer exceeds your daily limit of ${Formatters.currency(_dailyTransferLimit)}',
      );
    }

    int fromIdx = _accounts.indexWhere((a) => a.id == fromAccountId);
    int toIdx = _accounts.indexWhere((a) => a.id == toAccountId);

    if (fromIdx == -1) throw AppBaseException('Source account not found.');

    // Check balance
    if (_accounts[fromIdx].availableBalance < amount) {
      throw InsufficientFundsException();
    }

    // Process atomic update
    _accounts[fromIdx] = _accounts[fromIdx].copyWith(
      balance: _accounts[fromIdx].balance - amount,
      availableBalance: _accounts[fromIdx].availableBalance - amount,
    );

    if (toIdx != -1) {
      _accounts[toIdx] = _accounts[toIdx].copyWith(
        balance: _accounts[toIdx].balance + amount,
        availableBalance: _accounts[toIdx].availableBalance + amount,
      );
    }

    _todayTransferTotal += amount;

    final txOut = Transaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      accountId: fromAccountId,
      type: TransactionType.transferOut,
      status: TransactionStatus.completed,
      amount: amount,
      description: memo.isEmpty ? 'Internal Transfer' : memo,
      category: 'Transfer',
      timestamp: DateTime.now(),
      referenceNumber: 'REF${_random.nextInt(999999999)}',
    );

    _transactions.insert(0, txOut);
    return txOut;
  }
}

// ============================================================================
// 6. STATE MANAGEMENT (Custom Redux/Provider Hybrid)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockBankingBackend _api = MockBankingBackend();

  User? user;
  List<Account> accounts = [];
  List<Transaction> transactions = [];
  List<BankCard> cards = [];

  bool isInitializing = true;
  bool isGlobalLoading = false;
  String? globalError;

  AppState() {
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Simulate splash screen loading
    isInitializing = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isGlobalLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    globalError = message;
    notifyListeners();
  }

  void clearError() {
    if (globalError != null) {
      globalError = null;
      notifyListeners();
    }
  }

  Future<bool> authenticate(String username, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      user = await _api.login(username, password);
      await loadDashboardData();
      return true;
    } on AppBaseException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _api.logout();
    user = null;
    accounts.clear();
    transactions.clear();
    cards.clear();
    _setLoading(false);
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _setError(null);
    try {
      final accsFuture = _api.fetchAccounts();
      final txsFuture = _api.fetchTransactions();
      final cardsFuture = _api.fetchCards();

      final results = await Future.wait([accsFuture, txsFuture, cardsFuture]);

      accounts = results[0] as List<Account>;
      transactions = results[1] as List<Transaction>;
      cards = results[2] as List<BankCard>;
    } catch (e) {
      _setError('Failed to load dashboard data. Pull to refresh.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> executeTransfer(
    String fromId,
    String toId,
    double amount,
    String memo,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.processTransfer(
        fromAccountId: fromId,
        toAccountId: toId,
        amount: amount,
        memo: memo,
      );
      await loadDashboardData(); // Refresh state post-transaction
      return true;
    } on AppBaseException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  double get totalNetWorth {
    return accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }
}

/// InheritedWidget for dependency injection of our State Container
class AppProvider extends InheritedNotifier<AppState> {
  const AppProvider({Key? key, required AppState state, required Widget child})
    : super(key: key, notifier: state, child: child);

  static AppState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<AppProvider>()!
          .notifier!;
    } else {
      final provider =
          context.getElementForInheritedWidgetOfExactType<AppProvider>()?.widget
              as AppProvider;
      return provider.notifier!;
    }
  }
}

// ============================================================================
// 7. CUSTOM WIDGETS & PAINTERS
// ============================================================================

/// A premium, highly customizable primary button.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom text field with standard banking app styling.
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: AppColors.backgroundLight,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusMd),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

/// Advanced CustomPainter to draw a beautiful, smoothed line chart for balance history.
class SmoothLineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final Color gradientStart;
  final Color gradientEnd;

  SmoothLineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final double maxVal = dataPoints.reduce(math.max);
    final double minVal = dataPoints.reduce(math.min);
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    final double stepX =
        size.width / (dataPoints.length - 1 > 0 ? dataPoints.length - 1 : 1);

    final path = Path();
    final fillPath = Path();

    List<Offset> points = [];
    for (int i = 0; i < dataPoints.length; i++) {
      double x = i * stepX;
      // Invert Y axis (0 is top in Canvas)
      double normalizedY = (dataPoints[i] - minVal) / range;
      double y =
          size.height -
          (normalizedY * size.height * 0.8) -
          (size.height * 0.1); // add padding
      points.add(Offset(x, y));
    }

    // Bezier curve smoothing
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
    }

    // Paint Gradient Fill
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
        gradientStart,
        gradientEnd,
      ])
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Paint Stroke Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant SmoothLineChartPainter oldDelegate) => true;
}

// ============================================================================
// 8. MAIN ENTRY POINT & APP ROOT
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait for banking app safety/layout consistency
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(SmartWalletApp());
  });
}

class SmartWalletApp extends StatelessWidget {
  final AppState _appState = AppState();

  SmartWalletApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppProvider(
      state: _appState,
      child: MaterialApp(
        title: 'Smart Wallet Pro',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        home: const AppRouter(),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      fontFamily: 'Roboto', // Default standard font
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        background: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
      ),
    );
  }
}

/// Handles initial routing based on authentication state
class AppRouter extends StatelessWidget {
  const AppRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);

    if (state.isInitializing) {
      return const SplashScreen();
    }
    if (state.user == null) {
      return const LoginScreen();
    }
    return const MainNavigationScaffold();
  }
}

// ============================================================================
// 9. SCREENS (SPLASH, AUTH, NAVIGATION)
// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
    _scale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, child) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),
                  Text(
                    "SmartWallet",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Pro Edition",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.accent,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController(text: 'demo_user');
  final _passCtrl = TextEditingController(text: 'password123');

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      AppProvider.of(
        context,
        listen: false,
      ).authenticate(_userCtrl.text, _passCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppLayout.paddingLg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Welcome Back",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Securely login to your SmartWallet account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (state.globalError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.globalError!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.error,
                            ),
                            onPressed: state.clearError,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomTextField(
                    label: "Username",
                    controller: _userCtrl,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: "Password",
                    controller: _passCtrl,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: AppColors.accentDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: "Secure Login",
                    isLoading: state.isGlobalLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.textSecondaryLight),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          "Open Account",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({Key? key}) : super(key: key);

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransferScreen(),
    const CardsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
            color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accentDark,
          unselectedItemColor: AppColors.textSecondaryLight,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_rounded),
              label: 'Transfer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_rounded),
              label: 'Cards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 10. DASHBOARD SCREEN
// ============================================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);

    if (state.isGlobalLoading && state.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.primary, // Dark header background
      body: RefreshIndicator(
        onRefresh: state.loadDashboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              expandedHeight: 80,
              floating: true,
              pinned: true,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(state.user?.avatarUrl ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Good Morning,",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      Text(
                        state.user?.firstName ?? "User",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(child: _buildTotalBalance(state)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            // Bottom White Sheet
            SliverFillRemaining(
              hasScrollBody: true,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildAccountsCarousel(state),
                    const SizedBox(height: 24),
                    Expanded(child: _buildRecentTransactions(context, state)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalance(AppState state) {
    // Generate dummy sparkline data for chart
    final List<double> chartData = [
      12000,
      11500,
      13000,
      12800,
      14500,
      14000,
      state.totalNetWorth,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Net Worth",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(state.totalNetWorth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: SmoothLineChartPainter(
                dataPoints: chartData,
                lineColor: AppColors.accent,
                gradientStart: AppColors.accent.withOpacity(0.4),
                gradientEnd: AppColors.accent.withOpacity(0.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            icon: Icons.add_rounded,
            label: "Add Money",
            onTap: () {},
          ),
          _ActionButton(
            icon: Icons.send_rounded,
            label: "Transfer",
            onTap: () {},
          ),
          _ActionButton(
            icon: Icons.receipt_long_rounded,
            label: "Pay Bills",
            onTap: () {},
          ),
          _ActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: "Scan QR",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsCarousel(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "My Accounts",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.accounts.length,
            itemBuilder: (context, index) {
              return _AccountCard(account: state.accounts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, AppState state) {
    final recent = state.transactions.take(8).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FullHistoryScreen(),
                    ),
                  );
                },
                child: const Text("See All"),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: recent.length,
              itemBuilder: (context, index) {
                return _TransactionTile(tx: recent[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.accentDark, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final isChecking = account.type == AccountType.checking;
    final gradient = isChecking
        ? const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isChecking ? Colors.black : AppColors.accent).withOpacity(
              0.3,
            ),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.accountName,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
          Text(
            Formatters.currency(account.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '**** ${account.accountNumber.substring(account.accountNumber.length - 4)}',
                style: const TextStyle(color: Colors.white, letterSpacing: 2),
              ),
              Text(
                account.type.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final bool isCredit = tx.isCredit;

    IconData icon;
    Color iconBg;
    Color iconColor;

    if (tx.type == TransactionType.transferOut ||
        tx.type == TransactionType.payment) {
      icon = Icons.shopping_bag_outlined;
      iconBg = AppColors.warning.withOpacity(0.1);
      iconColor = AppColors.warning;
    } else if (isCredit) {
      icon = Icons.arrow_downward_rounded;
      iconBg = AppColors.success.withOpacity(0.1);
      iconColor = AppColors.success;
    } else {
      icon = Icons.compare_arrows_rounded;
      iconBg = AppColors.accent.withOpacity(0.1);
      iconColor = AppColors.accent;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: tx),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchantName ?? tx.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.category ?? 'General',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${Formatters.currency(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCredit
                        ? AppColors.success
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.date(tx.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
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

// ============================================================================
// 11. TRANSFER SCREEN
// ============================================================================

class TransferScreen extends StatefulWidget {
  const TransferScreen({Key? key}) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  Account? _selectedFrom;
  Account? _selectedTo;
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  void _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFrom == null || _selectedTo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select accounts')));
      return;
    }
    if (_selectedFrom!.id == _selectedTo!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot transfer to the same account')),
      );
      return;
    }

    final state = AppProvider.of(context, listen: false);
    final amount = double.parse(_amountCtrl.text);

    // Show confirmation dialog before executing
    final bool confirm = await _showConfirmationDialog(amount);
    if (!confirm) return;

    final success = await state.executeTransfer(
      _selectedFrom!.id,
      _selectedTo!.id,
      amount,
      _memoCtrl.text,
    );

    if (success) {
      _amountCtrl.clear();
      _memoCtrl.clear();
      setState(() {
        _selectedFrom = null;
        _selectedTo = null;
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer Successful!'),
            backgroundColor: AppColors.success,
          ),
        );
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.globalError ?? 'Transfer failed'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  Future<bool> _showConfirmationDialog(double amount) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Transfer'),
            content: Text(
              'Are you sure you want to transfer ${Formatters.currency(amount)} from ${_selectedFrom!.accountName} to ${_selectedTo!.accountName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);
    final accounts = state.accounts;

    return Scaffold(
      appBar: AppBar(title: const Text("Transfer Funds")),
      body: state.isGlobalLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppLayout.paddingLg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "From Account",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Account>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      value: _selectedFrom,
                      hint: const Text('Select source account'),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                "${a.accountName} (${Formatters.currency(a.availableBalance)})",
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedFrom = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),

                    const SizedBox(height: 24),
                    const Center(
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "To Account",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Account>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      value: _selectedTo,
                      hint: const Text('Select destination account'),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                "${a.accountName} - ****${a.accountNumber.substring(a.accountNumber.length - 4)}",
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTo = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),

                    const SizedBox(height: 32),
                    CustomTextField(
                      label: "Amount",
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                      hint: "0.00",
                      validator: (val) => Validators.amount(
                        val,
                        maxAmount: _selectedFrom?.availableBalance,
                      ),
                    ),

                    const SizedBox(height: 24),
                    CustomTextField(
                      label: "Memo (Optional)",
                      controller: _memoCtrl,
                      hint: "What is this for?",
                    ),

                    const SizedBox(height: 48),
                    PrimaryButton(
                      text: "Review Transfer",
                      onPressed: _submitTransfer,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// 12. FULL HISTORY SCREEN
// ============================================================================

class FullHistoryScreen extends StatelessWidget {
  const FullHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);
    final txs = state.transactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppLayout.paddingMd),
        itemCount: txs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _TransactionTile(tx: txs[index]),
      ),
    );
  }
}

// ============================================================================
// 13. TRANSACTION DETAILS SCREEN
// ============================================================================

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;
  const TransactionDetailScreen({Key? key, required this.transaction})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.isCredit;

    return Scaffold(
      appBar: AppBar(title: const Text("Transaction Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppLayout.paddingLg),
        child: Container(
          padding: const EdgeInsets.all(AppLayout.paddingLg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: isCredit
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                child: Icon(
                  isCredit ? Icons.download_rounded : Icons.storefront_rounded,
                  size: 32,
                  color: isCredit ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                transaction.merchantName ?? transaction.description,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.date(transaction.timestamp) +
                    " at " +
                    Formatters.time(transaction.timestamp),
                style: const TextStyle(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 24),
              Text(
                '${isCredit ? '+' : '-'}${Formatters.currency(transaction.amount)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isCredit
                      ? AppColors.success
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              _DetailRow(
                label: "Status",
                value: transaction.status.name.toUpperCase(),
                isStatus: true,
              ),
              _DetailRow(
                label: "Category",
                value: transaction.category ?? 'N/A',
              ),
              _DetailRow(
                label: "Reference Number",
                value: transaction.referenceNumber,
              ),
              _DetailRow(label: "Description", value: transaction.description),
              const SizedBox(height: 32),
              PrimaryButton(
                text: "Report an Issue",
                onPressed: () {},
                icon: Icons.flag_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isStatus ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: isStatus
                    ? AppColors.success
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 14. CARDS MANAGEMENT SCREEN
// ============================================================================

class CardsScreen extends StatelessWidget {
  const CardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("My Cards")),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppLayout.paddingLg),
        itemCount: state.cards.length,
        itemBuilder: (context, index) {
          final card = state.cards[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _BankCardWidget(card: card),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text("New Virtual Card"),
      ),
    );
  }
}

class _BankCardWidget extends StatelessWidget {
  final BankCard card;
  const _BankCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final bool isVisa = card.cardNumber.startsWith('4');
    final Color cardColor = isVisa
        ? AppColors.cardVisa
        : AppColors.cardMastercard;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.contactless, color: Colors.white, size: 28),
              Text(
                isVisa ? 'VISA' : 'MASTERCARD',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          Text(
            Formatters.maskCardNumber(card.cardNumber),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 3,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CARD HOLDER",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.cardHolderName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "EXPIRES",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.expiryDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 15. PROFILE & SETTINGS SCREEN
// ============================================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);
    final user = state.user;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 32),

            _buildSettingsGroup(
              title: "Account",
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: "Personal Information",
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.security,
                  title: "Security & Biometrics",
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.document_scanner_outlined,
                  title: "Statements & Documents",
                  onTap: () {},
                ),
              ],
            ),

            _buildSettingsGroup(
              title: "Preferences",
              children: [
                _SettingsTile(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: "Appearance",
                  trailing: const Text("System"),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.language,
                  title: "Language",
                  trailing: const Text("English"),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: PrimaryButton(
                text: "Secure Logout",
                onPressed: () {
                  state.logout();
                },
                icon: Icons.logout_rounded,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
