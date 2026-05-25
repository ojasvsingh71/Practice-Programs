import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const NexusEventsApp());
}

class NexusEventsApp extends StatelessWidget {
  const NexusEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const EventStateProvider(
      child: MaterialApp(
        title: 'Nexus Event Management',
        debugShowCheckedModeBanner: false,
        home: MasterEventTerminal(),
      ),
    );
  }
}

// ==========================================
// 1. GLOBAL ENUMS & CONSTANTS
// ==========================================

enum EventCategory { tech, music, business, workshop, networking }

enum TicketTier { general, vip, earlyBird }

enum AppSection { discovery, myTickets, notifications, adminDashboard }

const List<String> locations = [
  'Moscone Center, SF',
  'Jacob Javits, NYC',
  'ExCeL London',
  'Marina Bay Sands, SG',
  'Tokyo International Forum',
];

// ==========================================
// 2. CORE DATA MODELS
// ==========================================

class EventModel {
  final String id;
  final String title;
  final EventCategory category;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int maxCapacity;
  int currentRegistrations;
  final double basePrice;
  final String description;

  EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    this.currentRegistrations = 0,
    required this.basePrice,
    required this.description,
  });

  bool get isSoldOut => currentRegistrations >= maxCapacity;
  double get fillPercentage => currentRegistrations / maxCapacity;
}

class Attendee {
  final String name;
  final String email;
  final String company;

  const Attendee({
    required this.name,
    required this.email,
    required this.company,
  });
}

class Ticket {
  final String ticketId;
  final EventModel event;
  final Attendee attendee;
  final TicketTier tier;
  final double amountPaid;
  final DateTime issuedAt;
  bool isCheckedIn;

  Ticket({
    required this.ticketId,
    required this.event,
    required this.attendee,
    required this.tier,
    required this.amountPaid,
    required this.issuedAt,
    this.isCheckedIn = false,
  });

  String get qrHash =>
      "${ticketId}_${event.id}_${attendee.email}".hashCode.toString();
}

class SystemNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  SystemNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

// ==========================================
// 3. ENTERPRISE STATE MANAGEMENT ENGINE
// ==========================================

class EventEngineController extends ChangeNotifier {
  final List<EventModel> _masterEventDatabase = [];
  final List<Ticket> _userWallet = [];
  final List<Ticket> _globalRegistrations = []; // For Admin View
  final List<SystemNotification> _notifications = [];

  // Navigation State
  AppSection currentSection = AppSection.discovery;
  EventModel? viewingEvent;

  EventEngineController() {
    _seedEnterpriseMockData();
    _startReminderDaemon();
  }

  void _seedEnterpriseMockData() {
    final rand = math.Random();
    final now = DateTime.now();

    final titles = [
      'Global Dev Summit',
      'Future AI Con',
      'Synthwave Fest 2026',
      'Venture Capital Mixer',
      'Cloud Architecture Workshop',
      'UX/UI Design Masterclass',
      'Cybersecurity Symposium',
    ];

    for (int i = 0; i < 25; i++) {
      int capacity = [50, 150, 500, 2000, 5000][rand.nextInt(5)];
      int currentReg = rand.nextInt(capacity + 1); // Sometimes sold out

      _masterEventDatabase.add(
        EventModel(
          id: 'EVT-${rand.nextInt(90000) + 10000}',
          title: titles[rand.nextInt(titles.length)],
          category:
              EventCategory.values[rand.nextInt(EventCategory.values.length)],
          location: locations[rand.nextInt(locations.length)],
          startTime: now.add(
            Duration(days: rand.nextInt(60), hours: rand.nextInt(24)),
          ),
          endTime: now.add(
            Duration(days: rand.nextInt(60), hours: rand.nextInt(24) + 4),
          ),
          maxCapacity: capacity,
          currentRegistrations: currentReg,
          basePrice: capacity > 1000 ? 150.0 : 45.0,
          description:
              "Join industry leaders and innovators for an unforgettable experience exploring the bleeding edge of our respective fields. Network, learn, and grow.",
        ),
      );
    }

    // Sort chronologically
    _masterEventDatabase.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _startReminderDaemon() {
    // Simulates checking for upcoming events and sending reminders
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_userWallet.isEmpty) return;

      final upcoming = _userWallet
          .where(
            (t) =>
                t.event.startTime.difference(DateTime.now()).inDays <= 7 &&
                !t.isCheckedIn,
          )
          .toList();

      if (upcoming.isNotEmpty) {
        final target = upcoming[math.Random().nextInt(upcoming.length)];
        _pushNotification(
          "Upcoming Event Reminder",
          "Your event '${target.event.title}' is coming up soon! Have your QR ticket ready.",
        );
      }
    });
  }

  void _pushNotification(String title, String message) {
    _notifications.insert(
      0,
      SystemNotification(
        id: math.Random().nextInt(99999).toString(),
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // --- ACTIONS ---

  void navigateTo(AppSection section) {
    currentSection = section;
    viewingEvent = null;
    notifyListeners();
  }

  void viewEventDetails(EventModel event) {
    viewingEvent = event;
    notifyListeners();
  }

  void closeEventDetails() {
    viewingEvent = null;
    notifyListeners();
  }

  Future<bool> registerForEvent({
    required EventModel event,
    required Attendee attendee,
    required TicketTier tier,
  }) async {
    // 1. Capacity Lock & Validation
    if (event.isSoldOut) return false;

    // Simulate Network/Processing Delay
    await Future.delayed(const Duration(seconds: 2));

    // Double-check capacity post-delay (Concurrency protection)
    if (event.currentRegistrations >= event.maxCapacity) return false;

    // 2. Commit Transaction
    event.currentRegistrations += 1;

    double multiplier = tier == TicketTier.vip
        ? 2.5
        : (tier == TicketTier.earlyBird ? 0.8 : 1.0);

    final newTicket = Ticket(
      ticketId: 'NXS-${math.Random().nextInt(900000) + 100000}',
      event: event,
      attendee: attendee,
      tier: tier,
      amountPaid: event.basePrice * multiplier,
      issuedAt: DateTime.now(),
    );

    _userWallet.add(newTicket);
    _globalRegistrations.add(newTicket); // For admin tracking

    _pushNotification(
      "Registration Successful",
      "You are successfully registered for ${event.title}. Your QR ticket is in your wallet.",
    );

    notifyListeners();
    return true;
  }

  // Admin Action
  bool validateAndCheckInTicket(String scannedTicketId) {
    try {
      final ticket = _globalRegistrations.firstWhere(
        (t) => t.ticketId == scannedTicketId,
      );
      if (ticket.isCheckedIn) return false; // Already checked in
      ticket.isCheckedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false; // Ticket not found
    }
  }

  void markNotificationsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  List<EventModel> get upcomingEvents =>
      List.unmodifiable(_masterEventDatabase);
  List<Ticket> get wallet => List.unmodifiable(_userWallet);
  List<SystemNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  List<Ticket> get allPlatformTickets =>
      List.unmodifiable(_globalRegistrations);
}

// State Injector
class EventStateProvider extends StatefulWidget {
  final Widget child;
  const EventStateProvider({super.key, required this.child});

  static EventEngineController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedEventProvider>();
    assert(result != null, 'EventStateProvider not found in context tree');
    return result!.controller;
  }

  @override
  State<EventStateProvider> createState() => _EventStateProviderState();
}

class _EventStateProviderState extends State<EventStateProvider> {
  late EventEngineController controller;

  @override
  void initState() {
    super.initState();
    controller = EventEngineController();
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
    return _InheritedEventProvider(controller: controller, child: widget.child);
  }
}

class _InheritedEventProvider extends InheritedWidget {
  final EventEngineController controller;
  const _InheritedEventProvider({
    required this.controller,
    required super.child,
  });
  @override
  bool updateShouldNotify(covariant _InheritedEventProvider oldWidget) => true;
}

// ==========================================
// 4. MAIN LAYOUT HUB (SHELL)
// ==========================================

class MasterEventTerminal extends StatelessWidget {
  const MasterEventTerminal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EventStateProvider.of(context);

    Widget activeView;
    if (controller.viewingEvent != null) {
      activeView = RegistrationView(event: controller.viewingEvent!);
    } else {
      switch (controller.currentSection) {
        case AppSection.discovery:
          activeView = const DiscoveryView();
          break;
        case AppSection.myTickets:
          activeView = const TicketWalletView();
          break;
        case AppSection.notifications:
          activeView = const NotificationCenterView();
          break;
        case AppSection.adminDashboard:
          activeView = const AdminScannerDashboard();
          break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Row(
        children: [
          // Left Navigation Sidebar
          Container(
            width: 280,
            color: const Color(0xff0f172a),
            child: Column(
              children: [
                const SizedBox(height: 64),
                const Icon(Icons.hub, color: Color(0xff6366f1), size: 56),
                const SizedBox(height: 16),
                const Text(
                  "NEXUS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  "EVENT PLATFORM",
                  style: TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 64),
                _NavButton(
                  icon: Icons.search,
                  label: "Discover Events",
                  isActive:
                      controller.currentSection == AppSection.discovery &&
                      controller.viewingEvent == null,
                  onTap: () => controller.navigateTo(AppSection.discovery),
                ),
                _NavButton(
                  icon: Icons.local_activity,
                  label: "My Wallet (${controller.wallet.length})",
                  isActive:
                      controller.currentSection == AppSection.myTickets &&
                      controller.viewingEvent == null,
                  onTap: () => controller.navigateTo(AppSection.myTickets),
                ),
                _NavButton(
                  icon: Icons.notifications,
                  label: "Reminders",
                  badgeCount: controller.unreadNotifications.length,
                  isActive:
                      controller.currentSection == AppSection.notifications &&
                      controller.viewingEvent == null,
                  onTap: () {
                    controller.navigateTo(AppSection.notifications);
                    controller.markNotificationsRead();
                  },
                ),
                const Spacer(),
                const Divider(color: Colors.white24),
                _NavButton(
                  icon: Icons.admin_panel_settings,
                  label: "Admin Portal",
                  isActive:
                      controller.currentSection == AppSection.adminDashboard &&
                      controller.viewingEvent == null,
                  onTap: () => controller.navigateTo(AppSection.adminDashboard),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Main Dynamic Content Area
          Expanded(
            child: ClipRRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: activeView,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isActive ? const Color(0xff6366f1) : Colors.transparent,
                width: 4,
              ),
            ),
            color: isActive ? const Color(0xff1e293b) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xff6366f1)
                    : const Color(0xff64748b),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xff94a3b8),
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xffef4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount.toString(),
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
      ),
    );
  }
}

// ==========================================
// 5. VIEW 1: EVENT DISCOVERY (FEED)
// ==========================================

class DiscoveryView extends StatelessWidget {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EventStateProvider.of(context);
    final events = controller.upcomingEvents;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(48.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upcoming Experiences",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Discover and register for premier events worldwide.",
                  style: TextStyle(fontSize: 18, color: Color(0xff64748b)),
                ),
                const SizedBox(height: 48),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    mainAxisSpacing: 32,
                    crossAxisSpacing: 32,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) =>
                      _EventCard(event: events[index]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final controller = EventStateProvider.of(context);

    Color capacityColor = event.fillPercentage > 0.9
        ? const Color(0xffef4444) // Red for nearly full
        : event.fillPercentage > 0.6
        ? const Color(0xfff59e0b) // Orange for filling
        : const Color(0xff10b981); // Green for plenty

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Stub
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffe2e8f0),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    "https://picsum.photos/seed/${event.id}/600/400",
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.2),
                    BlendMode.darken,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.category.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (event.isSoldOut)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffef4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "SOLD OUT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Info Section
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0f172a),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${event.startTime.month}/${event.startTime.day}/${event.startTime.year}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Capacity Indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Capacity",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "${event.currentRegistrations} / ${event.maxCapacity}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: capacityColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: event.fillPercentage,
                          backgroundColor: const Color(0xfff1f5f9),
                          color: capacityColor,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.isSoldOut
                            ? const Color(0xffe2e8f0)
                            : const Color(0xff6366f1),
                        foregroundColor: event.isSoldOut
                            ? const Color(0xff94a3b8)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: event.isSoldOut
                          ? null
                          : () => controller.viewEventDetails(event),
                      child: Text(
                        event.isSoldOut ? "UNAVAILABLE" : "VIEW & REGISTER",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. VIEW 2: EVENT DETAILS & REGISTRATION FORM
// ==========================================

class RegistrationView extends StatefulWidget {
  final EventModel event;
  const RegistrationView({super.key, required this.event});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  TicketTier _selectedTier = TicketTier.general;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final controller = EventStateProvider.of(context);
    final event = widget.event;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff0f172a)),
          onPressed: () => controller.closeEventDetails(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(48.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Event Info
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffe0e7ff),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.category.name.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xff4f46e5),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff0f172a),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _DetailPill(
                        icon: Icons.location_on,
                        label: event.location,
                      ),
                      const SizedBox(width: 16),
                      _DetailPill(
                        icon: Icons.calendar_today,
                        label:
                            "${event.startTime.month}/${event.startTime.day} - ${event.endTime.month}/${event.endTime.day}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    "About the Event",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xff64748b),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Real-time Capacity Check
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fafc),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_alt,
                          color: Color(0xff6366f1),
                          size: 32,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Live Capacity Status",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: event.fillPercentage,
                                backgroundColor: const Color(0xffe2e8f0),
                                color: const Color(0xff6366f1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${event.maxCapacity - event.currentRegistrations} spots remaining",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 64),
            // Right: Registration Form
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Secure Your Spot",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Legal Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          labelText: "Company / Organization",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        "Ticket Tier",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TicketTier>(
                        value: _selectedTier,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.loyalty),
                        ),
                        items: TicketTier.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  "${t.name.toUpperCase()} - \$${(event.basePrice * (t == TicketTier.vip ? 2.5 : (t == TicketTier.earlyBird ? 0.8 : 1.0))).toStringAsFixed(2)}",
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedTier = v!),
                      ),
                      const SizedBox(height: 48),
                      if (_isProcessing)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xff6366f1),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6366f1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isProcessing = true);
                                bool success = await controller
                                    .registerForEvent(
                                      event: event,
                                      attendee: Attendee(
                                        name: _nameController.text,
                                        email: _emailController.text,
                                        company: _companyController.text,
                                      ),
                                      tier: _selectedTier,
                                    );
                                if (!mounted) return;
                                setState(() => _isProcessing = false);

                                if (success) {
                                  controller.navigateTo(
                                    AppSection.myTickets,
                                  ); // Kick back to wallet
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Registration Failed. Event may be sold out.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "COMPLETE REGISTRATION",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
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
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xff64748b)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff0f172a),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. VIEW 3: TICKET WALLET & QR GENERATOR
// ==========================================

class TicketWalletView extends StatelessWidget {
  const TicketWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EventStateProvider.of(context);
    final tickets = controller.wallet;

    if (tickets.isEmpty) {
      return const Center(
        child: Text(
          "Your wallet is empty.\nDiscover events to fill it up!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Ticket Wallet",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView.separated(
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 32),
              itemBuilder: (context, index) {
                final t = tickets[index];
                return Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ticket Left (Data)
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t.event.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff0f172a),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: t.tier == TicketTier.vip
                                          ? const Color(0xfffbbf24)
                                          : const Color(0xffe2e8f0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t.tier.name.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: t.tier == TicketTier.vip
                                            ? Colors.black87
                                            : const Color(0xff64748b),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  _TicketInfoBlock(
                                    label: "ATTENDEE",
                                    value: t.attendee.name,
                                  ),
                                  const SizedBox(width: 48),
                                  _TicketInfoBlock(
                                    label: "DATE",
                                    value:
                                        "${t.event.startTime.month}/${t.event.startTime.day}/${t.event.startTime.year}",
                                  ),
                                  const SizedBox(width: 48),
                                  _TicketInfoBlock(
                                    label: "STATUS",
                                    value: t.isCheckedIn
                                        ? "Scanned In"
                                        : "Valid",
                                    color: t.isCheckedIn
                                        ? Colors.grey
                                        : const Color(0xff10b981),
                                  ),
                                ],
                              ),
                              Text(
                                "TKT: ${t.ticketId}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Divider Perforation
                      Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Color(0xffe2e8f0),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                      // Ticket Right (QR)
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xfff8fafc),
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(24),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Standalone Native Procedural QR Generation
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xffcbd5e1),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Opacity(
                                    opacity: t.isCheckedIn ? 0.3 : 1.0,
                                    child: CustomPaint(
                                      painter: _ProceduralQRPainter(
                                        seed: t.qrHash,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "SCAN AT DOOR",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1,
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketInfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _TicketInfoBlock({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xff0f172a),
          ),
        ),
      ],
    );
  }
}

// SIMULATED QR CODE RENDERER (No External Dependencies)
class _ProceduralQRPainter extends CustomPainter {
  final String seed;
  _ProceduralQRPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final int gridSize = 21; // Standard QR V1 size
    final double cellSize = size.width / gridSize;

    // Hash-based deterministic generator
    final rand = math.Random(seed.hashCode);

    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        // Draw position detection patterns (Corners)
        if ((x < 7 && y < 7) ||
            (x > gridSize - 8 && y < 7) ||
            (x < 7 && y > gridSize - 8)) {
          if ((x == 0 || x == 6 || y == 0 || y == 6) && x < 7 && y < 7)
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          else if ((x > gridSize - 8 &&
                  (x == gridSize - 1 ||
                      x == gridSize - 7 ||
                      y == 0 ||
                      y == 6)) &&
              y < 7)
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          else if ((x < 7 &&
                  (x == 0 ||
                      x == 6 ||
                      y == gridSize - 1 ||
                      y == gridSize - 7)) &&
              y > gridSize - 8)
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          else if ((x >= 2 && x <= 4 && y >= 2 && y <= 4) ||
              (x >= gridSize - 5 && x <= gridSize - 3 && y >= 2 && y <= 4) ||
              (x >= 2 && x <= 4 && y >= gridSize - 5 && y <= gridSize - 3)) {
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          }
          continue;
        }
        // Random data generation based on ticket seed
        if (rand.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 8. VIEW 4: NOTIFICATION CENTER
// ==========================================

class NotificationCenterView extends StatelessWidget {
  const NotificationCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EventStateProvider.of(context);
    final notes = controller._notifications;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Reminders",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 48),
          if (notes.isEmpty)
            const Text(
              "No notifications yet.",
              style: TextStyle(color: Colors.grey, fontSize: 18),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final n = notes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xffe0e7ff),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Color(0xff6366f1),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                style: const TextStyle(
                                  color: Color(0xff64748b),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
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
    );
  }
}

// ==========================================
// 9. VIEW 5: ADMIN DASHBOARD & SCANNER
// ==========================================

class AdminScannerDashboard extends StatefulWidget {
  const AdminScannerDashboard({super.key});

  @override
  State<AdminScannerDashboard> createState() => _AdminScannerDashboardState();
}

class _AdminScannerDashboardState extends State<AdminScannerDashboard> {
  final _manualScanController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = EventStateProvider.of(context);
    final tickets = controller.allPlatformTickets;

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Admin Access Point",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e293b),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Manual Check-In Override",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _manualScanController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Enter Ticket ID (e.g. NXS-123456)",
                          labelStyle: TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xff6366f1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6366f1),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            bool success = controller.validateAndCheckInTicket(
                              _manualScanController.text.trim(),
                            );
                            _manualScanController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? "Ticket Validated! Attendee Checked In."
                                      : "Invalid Ticket or Already Checked In.",
                                ),
                                backgroundColor: success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          },
                          child: const Text("VALIDATE ENTRY"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Global Registration Ledger",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                    ),
                    child: ListView.separated(
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = tickets.reversed
                            .toList()[index]; // Show newest first
                        return ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: t.isCheckedIn
                                ? const Color(0xff10b981)
                                : const Color(0xffe2e8f0),
                            child: Icon(
                              t.isCheckedIn ? Icons.check : Icons.person,
                              color: t.isCheckedIn ? Colors.white : Colors.grey,
                            ),
                          ),
                          title: Text(
                            t.attendee.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${t.event.title} • ${t.ticketId}"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: t.isCheckedIn
                                  ? const Color(0xffd1fae5)
                                  : const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.isCheckedIn ? "IN VENUE" : "PENDING",
                              style: TextStyle(
                                color: t.isCheckedIn
                                    ? const Color(0xff059669)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
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
    );
  }
}
