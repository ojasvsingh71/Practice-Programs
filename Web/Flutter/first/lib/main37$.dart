/// ============================================================================
/// SUBSCRIPTION MANAGER APP - ZERO DEPENDENCY VERSION
/// Features: Built-in State Management, Renewal Tracking, Spend Summaries,
/// In-App Reminders, Custom Date Formatting, and Native Widgets.
/// ============================================================================

import 'dart:async';
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


/// ============================================================================
/// 1. ENTRY POINT & APP CONFIGURATION
/// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SubscriptionManagerApp(appState: AppState()));
}

class SubscriptionManagerApp extends StatelessWidget {
  final AppState appState;

  const SubscriptionManagerApp({Key? key, required this.appState})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'SubTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: DashboardScreen(appState: appState),
        );
      },
    );
  }
}

/// ============================================================================
/// 2. THEME & STYLING (Deep Purple / Modern aesthetic)
/// ============================================================================
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.deepPurple,
      primaryColor: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardColor: Colors.white,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.deepPurple,
      primaryColor: Colors.deepPurpleAccent,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardColor: const Color(0xFF1E293B),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// ============================================================================
/// 3. DATA MODELS & UTILS
/// ============================================================================
enum BillingCycle { weekly, monthly, yearly }

class Subscription {
  final String id;
  final String name;
  final double cost;
  final BillingCycle cycle;
  final DateTime nextRenewal;
  final String category;
  final String notes;
  final bool isActive;

  Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.cycle,
    required this.nextRenewal,
    this.category = 'Entertainment',
    this.notes = '',
    this.isActive = true,
  });

  Subscription copyWith({
    String? id,
    String? name,
    double? cost,
    BillingCycle? cycle,
    DateTime? nextRenewal,
    String? category,
    String? notes,
    bool? isActive,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      cycle: cycle ?? this.cycle,
      nextRenewal: nextRenewal ?? this.nextRenewal,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Calculates the equivalent monthly cost for summary purposes
  double get normalizedMonthlyCost {
    switch (cycle) {
      case BillingCycle.weekly:
        return cost * 4.33; // Average weeks in a month
      case BillingCycle.monthly:
        return cost;
      case BillingCycle.yearly:
        return cost / 12.0;
    }
  }
}

/// Native Date Utilities
class DateUtilsNative {
  static const List<String> _months = [
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

  static String format(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = normalizeDate(from);
    to = normalizeDate(to);
    return to.difference(from).inDays;
  }
}

/// ============================================================================
/// 4. STATE MANAGEMENT (PURE CHANGENOTIFIER)
/// ============================================================================
class AppState extends ChangeNotifier {
  final List<Subscription> _subscriptions = [];
  Timer? _renewalCheckerTimer;

  AppState() {
    _seedInitialData();
    _processAutoRenewals();
    _startReminderService();
  }

  @override
  void dispose() {
    _renewalCheckerTimer?.cancel();
    super.dispose();
  }

  // --- Getters ---
  List<Subscription> get activeSubscriptions {
    final list = _subscriptions.where((s) => s.isActive).toList();
    list.sort((a, b) => a.nextRenewal.compareTo(b.nextRenewal));
    return list;
  }

  List<Subscription> get cancelledSubscriptions {
    final list = _subscriptions.where((s) => !s.isActive).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  double get totalMonthlySpend {
    return activeSubscriptions.fold(
      0,
      (sum, sub) => sum + sub.normalizedMonthlyCost,
    );
  }

  double get totalYearlySpend {
    return totalMonthlySpend * 12;
  }

  // --- Actions ---
  void addSubscription(Subscription sub) {
    _subscriptions.add(sub);
    notifyListeners();
  }

  void updateSubscription(Subscription updatedSub) {
    final index = _subscriptions.indexWhere((s) => s.id == updatedSub.id);
    if (index != -1) {
      _subscriptions[index] = updatedSub;
      notifyListeners();
    }
  }

  void deleteSubscription(String id) {
    _subscriptions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void toggleStatus(Subscription sub) {
    updateSubscription(sub.copyWith(isActive: !sub.isActive));
  }

  // --- Logic ---
  /// Automatically rolls over past-due subscriptions to their next billing cycle
  void _processAutoRenewals() {
    final now = DateUtilsNative.normalizeDate(DateTime.now());
    bool changed = false;

    for (int i = 0; i < _subscriptions.length; i++) {
      var sub = _subscriptions[i];
      if (sub.isActive && sub.nextRenewal.isBefore(now)) {
        DateTime updatedRenewal = _calculateNextCycle(
          sub.nextRenewal,
          sub.cycle,
        );

        // Catch up if it's multiple cycles behind
        while (updatedRenewal.isBefore(now)) {
          updatedRenewal = _calculateNextCycle(updatedRenewal, sub.cycle);
        }

        _subscriptions[i] = sub.copyWith(nextRenewal: updatedRenewal);
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  DateTime _calculateNextCycle(DateTime current, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return current.add(const Duration(days: 7));
      case BillingCycle.monthly:
        // Handles month overflow (e.g. Jan 31 -> Feb 28) natively by Dart
        return DateTime(current.year, current.month + 1, current.day);
      case BillingCycle.yearly:
        return DateTime(current.year + 1, current.month, current.day);
    }
  }

  /// Simulates a background service checking for imminent renewals
  void _startReminderService() {
    _renewalCheckerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      for (var sub in activeSubscriptions) {
        final daysLeft = DateUtilsNative.daysBetween(now, sub.nextRenewal);
        if (daysLeft == 3 && now.hour == 10 && now.minute == 0) {
          // Trigger simulated system alert logic
          debugPrint(
            "APP ALERT: ${sub.name} renews in 3 days! Consider cancelling if not needed.",
          );
        }
      }
    });
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _subscriptions.addAll([
      Subscription(
        id: UniqueKey().toString(),
        name: 'Netflix Premium',
        cost: 22.99,
        cycle: BillingCycle.monthly,
        nextRenewal: now.add(const Duration(days: 2)),
        category: 'Entertainment',
      ),
      Subscription(
        id: UniqueKey().toString(),
        name: 'Spotify Duo',
        cost: 14.99,
        cycle: BillingCycle.monthly,
        nextRenewal: now.add(const Duration(days: 12)),
        category: 'Music',
      ),
      Subscription(
        id: UniqueKey().toString(),
        name: 'Amazon Prime',
        cost: 139.00,
        cycle: BillingCycle.yearly,
        nextRenewal: now.add(const Duration(days: 45)),
        category: 'Shopping',
      ),
      Subscription(
        id: UniqueKey().toString(),
        name: 'Gym Membership',
        cost: 45.00,
        cycle: BillingCycle.monthly,
        nextRenewal: now.subtract(
          const Duration(days: 5),
        ), // Will auto-rollover
        category: 'Health',
        isActive: false, // Cancelled sub
      ),
    ]);
  }
}

/// ============================================================================
/// 5. USER INTERFACE (SCREENS)
/// ============================================================================

class DashboardScreen extends StatefulWidget {
  final AppState appState;

  const DashboardScreen({Key? key, required this.appState}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Subscriptions',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 4,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [_buildActiveTab(), _buildCancelledTab()],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormScreen(appState: widget.appState),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab() {
    return Column(
      children: [
        SpendSummaryCard(appState: widget.appState),
        Expanded(
          child: widget.appState.activeSubscriptions.isEmpty
              ? const Center(
                  child: Text('No active subscriptions. Your wallet is happy!'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemCount: widget.appState.activeSubscriptions.length,
                  itemBuilder: (context, index) {
                    return SubscriptionCard(
                      subscription: widget.appState.activeSubscriptions[index],
                      appState: widget.appState,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCancelledTab() {
    if (widget.appState.cancelledSubscriptions.isEmpty) {
      return const Center(child: Text('No cancelled subscriptions.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.appState.cancelledSubscriptions.length,
      itemBuilder: (context, index) {
        return SubscriptionCard(
          subscription: widget.appState.cancelledSubscriptions[index],
          appState: widget.appState,
        );
      },
    );
  }
}

/// ============================================================================
/// 6. CUSTOM WIDGETS
/// ============================================================================

class SpendSummaryCard extends StatelessWidget {
  final AppState appState;

  const SpendSummaryCard({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthly = appState.totalMonthlySpend;
    final yearly = appState.totalYearlySpend;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Average Monthly Spend',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${monthly.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Projected Yearly',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '\$${yearly.toStringAsFixed(2)} / yr',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final AppState appState;

  const SubscriptionCard({
    Key? key,
    required this.subscription,
    required this.appState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = DateUtilsNative.daysBetween(
      DateTime.now(),
      subscription.nextRenewal,
    );

    Color getRiskColor() {
      if (!subscription.isActive) return Colors.grey;
      if (daysLeft <= 3) return Colors.redAccent;
      if (daysLeft <= 7) return Colors.orangeAccent;
      return Colors.green;
    }

    return Dismissible(
      key: Key(subscription.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        appState.deleteSubscription(subscription.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${subscription.name} deleted')));
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetailsModal(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildCategoryIcon(getRiskColor()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: subscription.isActive
                              ? null
                              : TextDecoration.lineThrough,
                          color: subscription.isActive ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.isActive
                            ? 'Renews: ${DateUtilsNative.format(subscription.nextRenewal)}'
                            : 'Inactive',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${subscription.cost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: subscription.isActive
                            ? theme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/${subscription.cycle.name.substring(0, 2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    if (subscription.isActive)
                      _buildUrgencyBadge(daysLeft, getRiskColor()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Color color) {
    IconData icon;
    switch (subscription.category.toLowerCase()) {
      case 'entertainment':
        icon = Icons.movie;
        break;
      case 'music':
        icon = Icons.music_note;
        break;
      case 'shopping':
        icon = Icons.shopping_bag;
        break;
      case 'health':
        icon = Icons.fitness_center;
        break;
      case 'software':
        icon = Icons.computer;
        break;
      default:
        icon = Icons.credit_card;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildUrgencyBadge(int daysLeft, Color color) {
    String text = daysLeft == 0 ? 'TODAY' : '$daysLeft days left';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  subscription.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${subscription.cost.toStringAsFixed(2)} / ${subscription.cycle.name}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                _buildDetailRow(
                  Icons.category,
                  'Category',
                  subscription.category,
                ),
                if (subscription.isActive)
                  _buildDetailRow(
                    Icons.calendar_month,
                    'Next Renewal',
                    DateUtilsNative.format(subscription.nextRenewal),
                  ),
                _buildDetailRow(
                  Icons.auto_graph,
                  'Monthly Impact',
                  '\$${subscription.normalizedMonthlyCost.toStringAsFixed(2)}/mo',
                ),
                if (subscription.notes.isNotEmpty)
                  _buildDetailRow(Icons.notes, 'Notes', subscription.notes),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormScreen(
                                appState: appState,
                                subscription: subscription,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          subscription.isActive ? Icons.cancel : Icons.restore,
                        ),
                        label: Text(
                          subscription.isActive ? 'Cancel Sub' : 'Reactivate',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: subscription.isActive
                              ? Colors.redAccent
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          appState.toggleStatus(subscription);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 7. FORM SCREEN (Add/Edit)
/// ============================================================================

class FormScreen extends StatefulWidget {
  final AppState appState;
  final Subscription? subscription;

  const FormScreen({Key? key, required this.appState, this.subscription})
    : super(key: key);

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _notesController;

  BillingCycle _selectedCycle = BillingCycle.monthly;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Entertainment';

  final List<String> _categories = [
    'Entertainment',
    'Music',
    'Shopping',
    'Health',
    'Software',
    'Utilities',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.subscription?.name ?? '',
    );
    _costController = TextEditingController(
      text: widget.subscription != null
          ? widget.subscription!.cost.toString()
          : '',
    );
    _notesController = TextEditingController(
      text: widget.subscription?.notes ?? '',
    );

    if (widget.subscription != null) {
      _selectedCycle = widget.subscription!.cycle;
      _selectedDate = widget.subscription!.nextRenewal;
      _selectedCategory = widget.subscription!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newSub = Subscription(
        id: widget.subscription?.id ?? UniqueKey().toString(),
        name: _nameController.text,
        cost: double.parse(_costController.text),
        cycle: _selectedCycle,
        nextRenewal: _selectedDate,
        category: _selectedCategory,
        notes: _notesController.text,
        isActive: widget.subscription?.isActive ?? true,
      );

      if (widget.subscription == null) {
        widget.appState.addSubscription(newSub);
      } else {
        widget.appState.updateSubscription(newSub);
      }

      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subscription == null
              ? 'Add Subscription'
              : 'Edit Subscription',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Name ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name (e.g. Netflix)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.subscriptions),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // --- Cost & Cycle Row ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Cost',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<BillingCycle>(
                      value: _selectedCycle,
                      decoration: InputDecoration(
                        labelText: 'Cycle',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: BillingCycle.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            c.name[0].toUpperCase() + c.name.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCycle = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Next Renewal Date ---
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Next Renewal Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateUtilsNative.format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Category ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 20),

              // --- Notes ---
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 40),

              // --- Save Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SAVE SUBSCRIPTION',
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
      ),
    );
  }
}
