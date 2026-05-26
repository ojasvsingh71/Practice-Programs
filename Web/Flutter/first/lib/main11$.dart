import 'dart:math' as math;
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
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum UserRole { member, librarian, admin }

enum BookStatus { available, outOfStock, reserved }

enum TransactionStatus { issued, returned, lost }

enum BookCategory { fiction, nonFiction, science, history, technology, fantasy }

class AppColors {
  static const Color primary = Color(0xFF0F766E); // Deep Teal (Classic Library)
  static const Color primaryDark = Color(0xFF134E4A);
  static const Color accent = Color(0xFFD97706); // Gold/Bronze

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceHighlight = Color(0xFFF1F5F9);

  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
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
  static const TextStyle penalty = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.error,
  );
}

// ============================================================================
// 2. EXCEPTIONS & UTILITIES
// ============================================================================

class LibraryException implements Exception {
  final String message;
  LibraryException(this.message);
  @override
  String toString() => message;
}

class AuthException extends LibraryException {
  AuthException([String m = "Authentication failed."]) : super(m);
}

class BookUnavailableException extends LibraryException {
  BookUnavailableException([String m = "Book is currently out of stock."])
    : super(m);
}

class LimitExceededException extends LibraryException {
  LimitExceededException([
    String m = "User has reached the maximum allowed issued books.",
  ]) : super(m);
}

class PenaltyLockException extends LibraryException {
  PenaltyLockException([
    String m = "Account locked due to unpaid overdue penalties.",
  ]) : super(m);
}

class NetworkException extends LibraryException {
  NetworkException([String m = "Network timeout."]) : super(m);
}

class DateUtils {
  static String format(DateTime d) => '${d.month}/${d.day}/${d.year}';
  static int daysBetween(DateTime from, DateTime to) =>
      to.difference(from).inDays;
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String avatarUrl;

  // Member Specific
  int maxAllowedBooks;
  double penaltyBalance;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    this.maxAllowedBooks = 3,
    this.penaltyBalance = 0.0,
  });

  bool get isLocked => penaltyBalance > 10.0; // Locked if fines > $10
}

class Book {
  final String id;
  final String isbn;
  final String title;
  final String author;
  final String description;
  final BookCategory category;
  final String coverUrl;
  final int totalCopies;
  int availableCopies;

  Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.coverUrl,
    required this.totalCopies,
    required this.availableCopies,
  });

  BookStatus get status =>
      availableCopies > 0 ? BookStatus.available : BookStatus.outOfStock;
}

class Transaction {
  final String id;
  final String bookId;
  final String userId;
  final DateTime issueDate;
  final DateTime dueDate;
  DateTime? returnDate;
  TransactionStatus status;
  double penaltyPaid;

  Transaction({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.status = TransactionStatus.issued,
    this.penaltyPaid = 0.0,
  });

  bool get isOverdue =>
      status == TransactionStatus.issued && DateTime.now().isAfter(dueDate);
  int get overdueDays =>
      isOverdue ? DateUtils.daysBetween(dueDate, DateTime.now()) : 0;
  double get currentPenalty =>
      isOverdue ? overdueDays * 1.50 : 0.0; // $1.50 per day late
}

// ============================================================================
// 4. MOCK BACKEND ENGINE & RULES
// ============================================================================

class MockLibraryBackend {
  static final MockLibraryBackend _instance = MockLibraryBackend._internal();
  factory MockLibraryBackend() => _instance;
  MockLibraryBackend._internal() {
    _seedData();
  }

  final math.Random _random = math.Random();
  final Map<String, User> _users = {};
  final Map<String, Book> _books = {};
  final List<Transaction> _transactions = [];

  // Default constructor removed — use singleton factory MockLibraryBackend()

  void _seedData() {
    // Users
    final u1 = User(
      id: 'MEM_001',
      name: 'Alex Reader',
      email: 'alex@library.com',
      role: UserRole.member,
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
      penaltyBalance: 0.0,
    );
    final u2 = User(
      id: 'MEM_002',
      name: 'Sam Overdue',
      email: 'sam@library.com',
      role: UserRole.member,
      avatarUrl: 'https://i.pravatar.cc/150?u=sam',
      penaltyBalance: 12.50,
    ); // Locked
    final lib = User(
      id: 'LIB_001',
      name: 'Marian Librarian',
      email: 'admin@library.com',
      role: UserRole.librarian,
      avatarUrl: 'https://i.pravatar.cc/150?u=marian',
    );
    _users.addAll({u1.id: u1, u2.id: u2, lib.id: lib});

    // Books
    final b1 = Book(
      id: 'BK_1',
      isbn: '978-0743273565',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      description: 'A story of the Jazz Age in New York.',
      category: BookCategory.fiction,
      coverUrl:
          'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=400&q=80',
      totalCopies: 5,
      availableCopies: 4,
    );
    final b2 = Book(
      id: 'BK_2',
      isbn: '978-0132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      description: 'A Handbook of Agile Software Craftsmanship.',
      category: BookCategory.technology,
      coverUrl:
          'https://images.unsplash.com/photo-1555662800-87311b3a156c?auto=format&fit=crop&w=400&q=80',
      totalCopies: 2,
      availableCopies: 0,
    );
    final b3 = Book(
      id: 'BK_3',
      isbn: '978-0441013593',
      title: 'Dune',
      author: 'Frank Herbert',
      description: 'Set on the desert planet Arrakis.',
      category: BookCategory.science,
      coverUrl:
          'https://images.unsplash.com/photo-1541963463532-d68292c34b19?auto=format&fit=crop&w=400&q=80',
      totalCopies: 3,
      availableCopies: 3,
    );
    final b4 = Book(
      id: 'BK_4',
      isbn: '978-0062316097',
      title: 'Sapiens',
      author: 'Yuval Noah Harari',
      description: 'A Brief History of Humankind.',
      category: BookCategory.history,
      coverUrl:
          'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=400&q=80',
      totalCopies: 4,
      availableCopies: 4,
    );
    _books.addAll({b1.id: b1, b2.id: b2, b3.id: b3, b4.id: b4});

    // Transactions (Historical & Active)
    final now = DateTime.now();
    // Alex's active book (Normal)
    _transactions.add(
      Transaction(
        id: 'TXN_1',
        bookId: 'BK_1',
        userId: 'MEM_001',
        issueDate: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 9)),
      ),
    );
    // Sam's overdue book (Generates Penalty)
    _transactions.add(
      Transaction(
        id: 'TXN_2',
        bookId: 'BK_2',
        userId: 'MEM_002',
        issueDate: now.subtract(const Duration(days: 20)),
        dueDate: now.subtract(const Duration(days: 6)),
      ),
    );
    // Someone else has Clean Code
    _transactions.add(
      Transaction(
        id: 'TXN_3',
        bookId: 'BK_2',
        userId: 'MEM_999',
        issueDate: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 12)),
      ),
    );
  }

  Future<void> _latency([int ms = 600]) async =>
      await Future.delayed(Duration(milliseconds: ms + _random.nextInt(400)));

  // --- Auth API ---
  Future<User> login(String email) async {
    await _latency(800);
    final user = _users.values.firstWhere(
      (u) => u.email == email,
      orElse: () => throw AuthException(),
    );
    return user;
  }

  // --- Read API ---
  Future<List<Book>> getCatalog() async {
    await _latency();
    return _books.values.toList();
  }

  Future<List<User>> getMembers() async {
    await _latency();
    return _users.values.where((u) => u.role == UserRole.member).toList();
  }

  Future<List<Transaction>> getUserTransactions(String userId) async {
    await _latency();
    return _transactions.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  // --- Write API (Circulation Rules) ---
  Future<Transaction> issueBook(String userId, String bookId) async {
    await _latency(1200);

    final user = _users[userId];
    final book = _books[bookId];
    if (user == null || book == null)
      throw LibraryException("Invalid reference.");

    // Rule 1: Penalty Lock
    if (user.isLocked) throw PenaltyLockException();

    // Rule 2: Limit Check
    final activeIssues = _transactions
        .where(
          (t) => t.userId == userId && t.status == TransactionStatus.issued,
        )
        .length;
    if (activeIssues >= user.maxAllowedBooks) throw LimitExceededException();

    // Rule 3: Availability Check
    if (book.availableCopies <= 0) throw BookUnavailableException();

    // Execute
    book.availableCopies--;
    final txn = Transaction(
      id: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      bookId: bookId,
      userId: userId,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(
        const Duration(days: 14),
      ), // Standard 2 week checkout
    );
    _transactions.add(txn);
    return txn;
  }

  Future<void> returnBook(String transactionId) async {
    await _latency(1200);

    final txn = _transactions.firstWhere((t) => t.id == transactionId);
    if (txn.status != TransactionStatus.issued)
      throw LibraryException("Book is not currently issued.");

    final user = _users[txn.userId]!;
    final book = _books[txn.bookId]!;

    // Process Penalties
    if (txn.isOverdue) {
      user.penaltyBalance += txn.currentPenalty;
    }

    // Execute Return
    txn.status = TransactionStatus.returned;
    txn.returnDate = DateTime.now();
    book.availableCopies++;
  }

  Future<void> payPenalty(String userId, double amount) async {
    await _latency(1500); // Payment processing delay
    final user = _users[userId];
    if (user == null) throw LibraryException("User not found.");
    if (user.penaltyBalance < amount)
      throw LibraryException("Amount exceeds balance.");

    user.penaltyBalance -= amount;
  }

  // Proxies
  Book getBook(String id) => _books[id]!;
  User getUser(String id) => _users[id]!;
}

// ============================================================================
// 5. STATE MANAGEMENT
// ============================================================================

class AppState extends ChangeNotifier {
  final MockLibraryBackend _api = MockLibraryBackend();

  User? currentUser;
  bool isGlobalLoading = false;
  String? globalError;

  // Shared Data
  List<Book> catalog = [];

  // Member State
  List<Transaction> myTransactions = [];

  // Librarian State
  List<User> membersList = [];

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  Future<void> login(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      currentUser = await _api.login(email);
      await refreshData();
    } on LibraryException catch (e) {
      _setError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    currentUser = null;
    catalog.clear();
    myTransactions.clear();
    membersList.clear();
    notifyListeners();
  }

  Future<void> refreshData() async {
    if (currentUser == null) return;
    try {
      catalog = await _api.getCatalog();
      if (currentUser!.role == UserRole.member) {
        myTransactions = await _api.getUserTransactions(currentUser!.id);
      } else {
        membersList = await _api.getMembers();
      }
      notifyListeners();
    } catch (e) {
      _setError("Failed to sync data.");
    }
  }

  // --- Circulation Interactions ---
  Future<bool> librarianIssueBook(String userId, String bookId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.issueBook(userId, bookId);
      await refreshData();
      return true;
    } on LibraryException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> librarianReturnBook(String transactionId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.returnBook(transactionId);
      await refreshData();
      return true;
    } on LibraryException catch (e) {
      _setError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> payMyPenalties() async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.payPenalty(currentUser!.id, currentUser!.penaltyBalance);
      await refreshData();
      return true;
    } catch (e) {
      _setError("Payment failed.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Utility Getters
  Book getBook(String id) => _api.getBook(id);
  User getUser(String id) => _api.getUser(id);
  Future<List<Transaction>> fetchUserTransactions(String userId) =>
      _api.getUserTransactions(userId);
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
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Library',
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
        home: const RootRouter(),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    if (state.currentUser == null) return const AuthScreen();
    if (state.currentUser!.role == UserRole.member)
      return const MemberScaffold();
    return const LibrarianScaffold();
  }
}

// ============================================================================
// 7. AUTH SCREEN
// ============================================================================

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.local_library,
                  size: 100,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'NEXUS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  'LIBRARY NETWORK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 64),

                if (state.globalError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.globalError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.book),
                  label: const Text(
                    'MEMBER LOGIN (Alex)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: state.isGlobalLoading
                      ? null
                      : () => state.login('alex@library.com'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.warning),
                  label: const Text(
                    'MEMBER LOGIN (Locked Sam)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: state.isGlobalLoading
                      ? null
                      : () => state.login('sam@library.com'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text(
                    'LIBRARIAN LOGIN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: state.isGlobalLoading
                      ? null
                      : () => state.login('admin@library.com'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 8. MEMBER FLOW (Dashboard, Catalog)
// ============================================================================

class MemberScaffold extends StatefulWidget {
  const MemberScaffold({Key? key}) : super(key: key);

  @override
  State<MemberScaffold> createState() => _MemberScaffoldState();
}

class _MemberScaffoldState extends State<MemberScaffold> {
  int _currentIndex = 0;
  final _screens = [const MemberDashboard(), const CatalogScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Catalog'),
        ],
      ),
    );
  }
}

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({Key? key}) : super(key: key);

  void _handlePayment(BuildContext context, AppState state) async {
    final success = await state.payMyPenalties();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful. Account unlocked.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser!;
    final activeIssues = state.myTransactions
        .where((t) => t.status == TransactionStatus.issued)
        .toList();
    final pastIssues = state.myTransactions
        .where((t) => t.status == TransactionStatus.returned)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshData,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(user.avatarUrl),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, ${user.name}', style: AppStyles.h1),
                    Text('ID: ${user.id}', style: AppStyles.caption),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Penalty Card
            if (user.penaltyBalance > 0)
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Outstanding Penalties',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${user.penaltyBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    if (user.isLocked) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Your account is locked due to high penalties. You cannot borrow new books.',
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: state.isGlobalLoading
                            ? null
                            : () => _handlePayment(context, state),
                        child: state.isGlobalLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('PAY NOW'),
                      ),
                    ),
                  ],
                ),
              ),

            // Active Books
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Currently Borrowed', style: AppStyles.h2),
                Text(
                  '${activeIssues.length} / ${user.maxAllowedBooks}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeIssues.isEmpty)
              const Text(
                'You have no books currently checked out.',
                style: AppStyles.body,
              )
            else
              ...activeIssues
                  .map(
                    (t) => _TransactionCard(
                      transaction: t,
                      book: state.getBook(t.bookId),
                    ),
                  )
                  .toList(),

            const SizedBox(height: 32),
            const Text('Reading History', style: AppStyles.h2),
            const SizedBox(height: 16),
            if (pastIssues.isEmpty)
              const Text('No past reading history.', style: AppStyles.body)
            else
              ...pastIssues
                  .map(
                    (t) => _TransactionCard(
                      transaction: t,
                      book: state.getBook(t.bookId),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Book book;

  const _TransactionCard({required this.transaction, required this.book});

  @override
  Widget build(BuildContext context) {
    final isActive = transaction.status == TransactionStatus.issued;
    final isOverdue = transaction.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.network(
              book.coverUrl,
              width: 80,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: AppStyles.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(book.author, style: AppStyles.caption),
                  const SizedBox(height: 12),
                  if (isActive) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateUtils.format(transaction.dueDate)}',
                          style: TextStyle(
                            color: isOverdue
                                ? AppColors.error
                                : AppColors.textMuted,
                            fontWeight: isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (isOverdue)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'OVERDUE - \$${transaction.currentPenalty.toStringAsFixed(2)} fine',
                          style: AppStyles.penalty,
                        ),
                      ),
                  ] else ...[
                    Text(
                      'Returned: ${DateUtils.format(transaction.returnDate!)}',
                      style: AppStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Library Catalog')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title, author, or ISBN...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.55,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.catalog.length,
              itemBuilder: (context, index) {
                final book = state.catalog[index];
                return _BookGridItem(book: book);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookGridItem extends StatelessWidget {
  final Book book;
  const _BookGridItem({required this.book});

  @override
  Widget build(BuildContext context) {
    final isAvail = book.status == BookStatus.available;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(book.coverUrl, fit: BoxFit.cover),
                  if (!isAvail)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'OUT OF\nSTOCK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: AppStyles.h3.copyWith(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            book.author,
            style: AppStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isAvail ? '${book.availableCopies} Copies Available' : 'Waitlist',
            style: TextStyle(
              color: isAvail ? AppColors.success : AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final Book book;
  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(book.coverUrl, fit: BoxFit.cover),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(book.title, style: AppStyles.h1)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.category.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By ${book.author}',
                    style: AppStyles.h3.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),

                  // Inventory Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceHighlight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MetaStat(label: 'Total', value: '${book.totalCopies}'),
                        _MetaStat(
                          label: 'Available',
                          value: '${book.availableCopies}',
                          color: book.availableCopies > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        _MetaStat(label: 'ISBN', value: book.isbn),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Synopsis', style: AppStyles.h2),
                  const SizedBox(height: 8),
                  Text(book.description, style: AppStyles.body),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: book.status == BookStatus.available
            ? AppColors.primary
            : AppColors.textMuted,
        onPressed: () {
          // In a real app, member might "Hold/Reserve" here. Actual checkout is done by Librarian.
        },
        icon: const Icon(Icons.bookmark_add, color: Colors.white),
        label: Text(
          book.status == BookStatus.available ? 'PLACE HOLD' : 'NOTIFY ME',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MetaStat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppStyles.caption),
      ],
    );
  }
}

// ============================================================================
// 9. LIBRARIAN FLOW (Circulation Desk, Inventory)
// ============================================================================

class LibrarianScaffold extends StatefulWidget {
  const LibrarianScaffold({Key? key}) : super(key: key);

  @override
  State<LibrarianScaffold> createState() => _LibrarianScaffoldState();
}

class _LibrarianScaffoldState extends State<LibrarianScaffold> {
  int _currentIndex = 0;
  final _screens = [const CirculationDeskScreen(), const LibrarianDashboard()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Circulation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

class LibrarianDashboard extends StatelessWidget {
  const LibrarianDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final usersWithFines = state.membersList
        .where((u) => u.penaltyBalance > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Inventory Overview', style: AppStyles.h2),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AdminStatCard(
                  title: 'Total Titles',
                  value: '${state.catalog.length}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AdminStatCard(
                  title: 'Members',
                  value: '${state.membersList.length}',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Accounts with Penalties', style: AppStyles.h2),
          const SizedBox(height: 16),
          if (usersWithFines.isEmpty)
            const Text('All member accounts are in good standing.')
          else
            ...usersWithFines
                .map(
                  (u) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(u.avatarUrl),
                    ),
                    title: Text(
                      u.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(u.id, style: AppStyles.caption),
                    trailing: Text(
                      '\$${u.penaltyBalance.toStringAsFixed(2)}',
                      style: AppStyles.penalty.copyWith(fontSize: 18),
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. CIRCULATION DESK (Issue / Return / Barcode Scanner)
// ============================================================================

class CirculationDeskScreen extends StatefulWidget {
  const CirculationDeskScreen({Key? key}) : super(key: key);

  @override
  State<CirculationDeskScreen> createState() => _CirculationDeskScreenState();
}

class _CirculationDeskScreenState extends State<CirculationDeskScreen>
    with SingleTickerProviderStateMixin {
  bool _isIssueMode = true; // Toggle between Issue and Return

  // Issue Mode State
  User? _selectedUser;
  Book? _selectedBook;

  // Return Mode State
  Transaction? _selectedTransaction;
  List<Transaction> _activeTransactionsCache = [];

  // Scanner Animation
  late AnimationController _scannerCtrl;

  @override
  void initState() {
    super.initState();
    _scannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _handleIssue(AppState state) async {
    if (_selectedUser == null || _selectedBook == null) return;

    final success = await state.librarianIssueBook(
      _selectedUser!.id,
      _selectedBook!.id,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book successfully issued.'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _selectedUser = null;
        _selectedBook = null;
      });
    } else if (mounted && state.globalError != null) {
      _showErrorModal(state.globalError!);
    }
  }

  void _handleReturn(AppState state) async {
    if (_selectedTransaction == null) return;

    final txn = _selectedTransaction!;
    final success = await state.librarianReturnBook(txn.id);

    if (success && mounted) {
      if (txn.isOverdue) {
        _showPenaltyReceiptModal(txn);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book returned successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      setState(() {
        _selectedTransaction = null;
        _selectedUser = null;
      });
    } else if (mounted && state.globalError != null) {
      _showErrorModal(state.globalError!);
    }
  }

  void _showErrorModal(String err) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error, color: AppColors.error),
            SizedBox(width: 8),
            Text('Transaction Failed'),
          ],
        ),
        content: Text(err),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _showPenaltyReceiptModal(Transaction txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return & Penalty Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book was returned late.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Days Overdue: ${txn.overdueDays}'),
            Text('Penalty Rate: \$1.50 / day'),
            const Divider(),
            Text(
              'Added to Account Balance: \$${txn.currentPenalty.toStringAsFixed(2)}',
              style: AppStyles.h3,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _fetchUserTransactionsForReturn(AppState state, User user) async {
    setState(() {
      _selectedUser = user;
      _selectedTransaction = null;
    });
    final txns = await state.fetchUserTransactions(user.id);
    setState(() {
      _activeTransactionsCache = txns
          .where((t) => t.status == TransactionStatus.issued)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circulation Desk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Toggle
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('ISSUE BOOK'),
                  icon: Icon(Icons.upload),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('RETURN BOOK'),
                  icon: Icon(Icons.download),
                ),
              ],
              selected: {_isIssueMode},
              onSelectionChanged: (val) {
                setState(() {
                  _isIssueMode = val.first;
                  _selectedUser = null;
                  _selectedBook = null;
                  _selectedTransaction = null;
                });
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isIssueMode
                  ? _buildIssueUI(state)
                  : _buildReturnUI(state),
            ),
          ),
        ],
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
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  state.isGlobalLoading ||
                      (_isIssueMode
                          ? (_selectedUser == null || _selectedBook == null)
                          : (_selectedTransaction == null))
                  ? null
                  : () => _isIssueMode
                        ? _handleIssue(state)
                        : _handleReturn(state),
              child: state.isGlobalLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isIssueMode ? 'COMPLETE ISSUE' : 'PROCESS RETURN',
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

  Widget _buildIssueUI(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Identify Member', style: AppStyles.h3),
        const SizedBox(height: 8),
        DropdownButtonFormField<User>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          hint: const Text('Scan Member ID or Select...'),
          value: _selectedUser,
          items: state.membersList
              .map(
                (u) => DropdownMenuItem(
                  value: u,
                  child: Text('${u.id} - ${u.name}'),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedUser = val),
        ),
        if (_selectedUser != null && _selectedUser!.isLocked)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            color: AppColors.error.withOpacity(0.1),
            child: Row(
              children: const [
                Icon(Icons.lock, color: AppColors.error, size: 16),
                SizedBox(width: 8),
                Text(
                  'MEMBER LOCKED - Unpaid Penalties',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),
        const Text('2. Scan Book', style: AppStyles.h3),
        const SizedBox(height: 8),

        // Custom Barcode Scanner Simulation
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarcodeScannerPainter(animation: _scannerCtrl),
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<Book>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          hint: const Text('Scan Book ISBN or Select...'),
          value: _selectedBook,
          items: state.catalog
              .map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: Text('${b.id} - ${b.title}'),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedBook = val),
        ),
        if (_selectedBook != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _selectedBook!.coverUrl,
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBook!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Available: ${_selectedBook!.availableCopies}',
                        style: TextStyle(
                          color: _selectedBook!.availableCopies > 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReturnUI(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Identify Member', style: AppStyles.h3),
        const SizedBox(height: 8),
        DropdownButtonFormField<User>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          hint: const Text('Select Member...'),
          value: _selectedUser,
          items: state.membersList
              .map(
                (u) => DropdownMenuItem(
                  value: u,
                  child: Text('${u.id} - ${u.name}'),
                ),
              )
              .toList(),
          onChanged: (val) => _fetchUserTransactionsForReturn(state, val!),
        ),
        const SizedBox(height: 32),

        if (_selectedUser != null) ...[
          const Text('2. Select Book to Return', style: AppStyles.h3),
          const SizedBox(height: 8),
          if (_activeTransactionsCache.isEmpty)
            const Text(
              'This member has no active book issues.',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else
            ..._activeTransactionsCache.map((txn) {
              final book = state.getBook(txn.bookId);
              final isSelected = _selectedTransaction?.id == txn.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedTransaction = txn),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceHighlight,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${DateUtils.format(txn.dueDate)}',
                              style: TextStyle(
                                color: txn.isOverdue
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                fontWeight: txn.isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (txn.isOverdue)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OVERDUE: \$${txn.currentPenalty.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ],
    );
  }
}

class _BarcodeScannerPainter extends CustomPainter {
  final Animation<double> animation;
  _BarcodeScannerPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Barcode Background
    final paint = Paint()
      ..color = AppColors.textMain
      ..style = PaintingStyle.fill;
    final math.Random rand = math.Random(
      123,
    ); // Static seed for consistent barcode

    double x = 10;
    while (x < size.width - 10) {
      double w = rand.nextDouble() * 5 + 1;
      canvas.drawRect(Rect.fromLTWH(x, 10, w, size.height - 20), paint);
      x += w + rand.nextDouble() * 6;
    }

    // Draw Laser Line
    final laserY = 10 + (size.height - 20) * animation.value;
    final laserPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    canvas.drawLine(Offset(0, laserY), Offset(size.width, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant _BarcodeScannerPainter oldDelegate) => true;
}
