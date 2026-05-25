import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEMES
// ============================================================================

enum UserRole { patient, doctor, admin }

enum AppointmentStatus { scheduled, completed, cancelled, noShow }

enum Specialty {
  general,
  cardiology,
  neurology,
  pediatrics,
  orthopedics,
  dermatology,
}

class AppColors {
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFFCCFBF1); // Teal 50
  static const Color secondary = Color(0xFF3B82F6); // Blue 500
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
}

class AppTextStyles {
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
    letterSpacing: -0.5,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textMain,
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    color: AppColors.textMuted,
  );
}

// ============================================================================
// 2. UTILITIES & FORMATTERS (No external 'intl' package)
// ============================================================================

class DateUtils {
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
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String formatMonthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';
  static String formatShortDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';
  static String formatFullDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}';

  static String formatTime(DateTime date) {
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int daysInMonth(int year, int month) {
    if (month == 2) {
      bool isLeapYear =
          (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
      return isLeapYear ? 29 : 28;
    }
    const days = [31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }
}

// ============================================================================
// 3. EXCEPTIONS
// ============================================================================

abstract class ClinicException implements Exception {
  final String message;
  ClinicException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends ClinicException {
  NetworkException([String msg = "Connection timeout."]) : super(msg);
}

class ScheduleConflictException extends ClinicException {
  ScheduleConflictException([
    String msg =
        "This time slot is no longer available. Please select another time.",
  ]) : super(msg);
}

class ValidationException extends ClinicException {
  ValidationException([String msg = "Invalid input data."]) : super(msg);
}

// ============================================================================
// 4. DOMAIN MODELS
// ============================================================================

abstract class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final String avatarUrl;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.avatarUrl,
  });
  String get fullName => '$firstName $lastName';
}

class Patient extends User {
  final String medicalHistory;
  final String bloodGroup;

  Patient({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String avatarUrl,
    required this.medicalHistory,
    required this.bloodGroup,
  }) : super(
         id: id,
         firstName: firstName,
         lastName: lastName,
         email: email,
         role: UserRole.patient,
         avatarUrl: avatarUrl,
       );
}

class Doctor extends User {
  final Specialty specialty;
  final double rating;
  final int reviews;
  final String bio;
  final double consultationFee;

  Doctor({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String avatarUrl,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.bio,
    required this.consultationFee,
  }) : super(
         id: id,
         firstName: firstName,
         lastName: lastName,
         email: email,
         role: UserRole.doctor,
         avatarUrl: avatarUrl,
       );

  String get specialtyString {
    final str = specialty.toString().split('.').last;
    return str[0].toUpperCase() + str.substring(1);
  }
}

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime startTime;
  final Duration duration;
  final String reasonForVisit;
  AppointmentStatus status;
  final String? doctorNotes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.startTime,
    this.duration = const Duration(minutes: 30),
    required this.reasonForVisit,
    this.status = AppointmentStatus.scheduled,
    this.doctorNotes,
    required this.createdAt,
  });

  DateTime get endTime => startTime.add(duration);

  Appointment copyWith({AppointmentStatus? status, String? doctorNotes}) {
    return Appointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      startTime: startTime,
      duration: duration,
      reasonForVisit: reasonForVisit,
      status: status ?? this.status,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      createdAt: createdAt,
    );
  }
}

// ============================================================================
// 5. MOCK BACKEND ENGINE & CONFLICT DETECTION
// ============================================================================

class MockClinicBackend {
  static final MockClinicBackend _instance = MockClinicBackend._internal();
  factory MockClinicBackend() => _instance;
  MockClinicBackend._internal() {
    _seedDatabase();
  }

  final math.Random _random = math.Random();

  final List<Doctor> _doctors = [];
  final List<Patient> _patients = [];
  final List<Appointment> _appointments = [];

  // Public unnamed constructor removed; seeding moved to `_internal()`.

  void _seedDatabase() {
    // Seed Doctors
    _doctors.addAll([
      Doctor(
        id: 'DOC_1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
        email: 's.jenkins@clinic.com',
        avatarUrl: 'https://i.pravatar.cc/150?u=s',
        specialty: Specialty.cardiology,
        rating: 4.9,
        reviews: 124,
        bio: 'Board-certified cardiologist with 15 years of experience.',
        consultationFee: 150.0,
      ),
      Doctor(
        id: 'DOC_2',
        firstName: 'Michael',
        lastName: 'Chen',
        email: 'm.chen@clinic.com',
        avatarUrl: 'https://i.pravatar.cc/150?u=m',
        specialty: Specialty.general,
        rating: 4.7,
        reviews: 342,
        bio: 'General practitioner focusing on holistic family medicine.',
        consultationFee: 80.0,
      ),
      Doctor(
        id: 'DOC_3',
        firstName: 'Emily',
        lastName: 'Rodriguez',
        email: 'e.rodriguez@clinic.com',
        avatarUrl: 'https://i.pravatar.cc/150?u=e',
        specialty: Specialty.dermatology,
        rating: 4.8,
        reviews: 89,
        bio: 'Specializes in cosmetic and medical dermatology.',
        consultationFee: 120.0,
      ),
      Doctor(
        id: 'DOC_4',
        firstName: 'James',
        lastName: 'Wilson',
        email: 'j.wilson@clinic.com',
        avatarUrl: 'https://i.pravatar.cc/150?u=j',
        specialty: Specialty.orthopedics,
        rating: 4.6,
        reviews: 210,
        bio: 'Orthopedic surgeon specializing in sports injuries.',
        consultationFee: 200.0,
      ),
    ]);

    // Seed Patients
    _patients.add(
      Patient(
        id: 'PAT_1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        avatarUrl: 'https://i.pravatar.cc/150?u=pat1',
        medicalHistory: 'Hypertension, Mild Asthma.',
        bloodGroup: 'O+',
      ),
    );

    // Seed realistic appointments for Doctor 1 today to demonstrate timeline
    final today = DateTime.now();
    _appointments.addAll([
      Appointment(
        id: 'APP_1',
        patientId: 'PAT_X',
        doctorId: 'DOC_1',
        startTime: DateTime(today.year, today.month, today.day, 9, 0),
        duration: const Duration(minutes: 30),
        reasonForVisit: 'Routine checkup',
        status: AppointmentStatus.completed,
        createdAt: today.subtract(const Duration(days: 7)),
      ),
      Appointment(
        id: 'APP_2',
        patientId: 'PAT_Y',
        doctorId: 'DOC_1',
        startTime: DateTime(today.year, today.month, today.day, 10, 0),
        duration: const Duration(minutes: 60),
        reasonForVisit: 'Echocardiogram followup',
        status: AppointmentStatus.completed,
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      Appointment(
        id: 'APP_3',
        patientId: 'PAT_1',
        doctorId: 'DOC_1',
        startTime: DateTime(today.year, today.month, today.day, 13, 30),
        duration: const Duration(minutes: 30),
        reasonForVisit: 'Palpitations',
        status: AppointmentStatus.scheduled,
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  Future<void> _simulateLatency([int min = 400, int max = 1200]) async {
    await Future.delayed(
      Duration(milliseconds: min + _random.nextInt(max - min)),
    );
  }

  // --- Auth API ---
  Future<User> login(String username, UserRole role) async {
    await _simulateLatency();
    if (role == UserRole.patient) return _patients.first;
    if (role == UserRole.doctor) return _doctors.first;
    throw Exception("Invalid credentials");
  }

  // --- Data Fetching API ---
  Future<List<Doctor>> getDoctors({Specialty? filter}) async {
    await _simulateLatency();
    if (filter != null)
      return _doctors.where((d) => d.specialty == filter).toList();
    return List.from(_doctors);
  }

  Future<List<Appointment>> getAppointmentsForUser(
    String userId,
    UserRole role,
  ) async {
    await _simulateLatency();
    List<Appointment> results;
    if (role == UserRole.patient) {
      results = _appointments.where((a) => a.patientId == userId).toList();
    } else {
      results = _appointments.where((a) => a.doctorId == userId).toList();
    }
    results.sort((a, b) => a.startTime.compareTo(b.startTime));
    return results;
  }

  Future<Patient> getPatientDetails(String patientId) async {
    await _simulateLatency(200, 500);
    return _patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => Patient(
        id: patientId,
        firstName: 'Unknown',
        lastName: 'Patient',
        email: '',
        avatarUrl: '',
        medicalHistory: 'N/A',
        bloodGroup: 'N/A',
      ),
    );
  }

  // --- Core Scheduling & Conflict Detection Engine ---

  /// Checks if a proposed time slot overlaps with any existing ACTIVE appointments for a doctor.
  bool _hasScheduleConflict(
    String doctorId,
    DateTime start,
    Duration duration,
  ) {
    final end = start.add(duration);

    return _appointments.any((app) {
      if (app.doctorId != doctorId || app.status == AppointmentStatus.cancelled)
        return false;

      final appStart = app.startTime;
      final appEnd = app.endTime;

      // Conflict condition: (StartA < EndB) and (EndA > StartB)
      return start.isBefore(appEnd) && end.isAfter(appStart);
    });
  }

  Future<List<DateTime>> getAvailableSlots(
    String doctorId,
    DateTime date,
  ) async {
    await _simulateLatency(300, 600);
    // Generate standard clinic slots: 9 AM to 5 PM, 30 min intervals
    List<DateTime> slots = [];
    final startOfDay = DateTime(date.year, date.month, date.day, 9, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 17, 0);
    const duration = Duration(minutes: 30);

    DateTime current = startOfDay;
    while (current.isBefore(endOfDay)) {
      // Exclude lunch break (12 PM - 1 PM)
      if (current.hour == 12) {
        current = current.add(const Duration(hours: 1));
        continue;
      }

      // Check conflict
      if (!_hasScheduleConflict(doctorId, current, duration) &&
          current.isAfter(DateTime.now())) {
        slots.add(current);
      }
      current = current.add(duration);
    }
    return slots;
  }

  Future<Appointment> bookAppointment(
    String patientId,
    String doctorId,
    DateTime startTime,
    String reason,
  ) async {
    await _simulateLatency(1000, 2000); // Simulate heavy DB transaction

    const duration = Duration(minutes: 30);

    // CRITICAL: Concurrency Check / Conflict Detection before committing
    if (_hasScheduleConflict(doctorId, startTime, duration)) {
      throw ScheduleConflictException();
    }

    final newApp = Appointment(
      id: 'APP_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      doctorId: doctorId,
      startTime: startTime,
      duration: duration,
      reasonForVisit: reason,
      createdAt: DateTime.now(),
    );

    _appointments.add(newApp);
    return newApp;
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus, {
    String? notes,
  }) async {
    await _simulateLatency(500, 1000);
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      _appointments[index] = _appointments[index].copyWith(
        status: newStatus,
        doctorNotes: notes,
      );
    }
  }
}

// ============================================================================
// 6. STATE MANAGEMENT (Custom AppStore)
// ============================================================================

class AppState extends ChangeNotifier {
  final MockClinicBackend _api = MockClinicBackend();

  User? currentUser;
  bool isGlobalLoading = false;
  String? globalError;

  // Patient State
  List<Doctor> directoryDoctors = [];
  List<Appointment> myAppointments = []; // For both Patient & Doctor

  // Booking Wizard State
  Doctor? selectedDoctor;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedTimeSlot;
  List<DateTime> availableSlots = [];
  bool isFetchingSlots = false;

  void _setLoading(bool val) {
    isGlobalLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    globalError = err;
    notifyListeners();
  }

  Future<void> login(String username, UserRole role) async {
    _setLoading(true);
    _setError(null);
    try {
      currentUser = await _api.login(username, role);
      await refreshAppointments();
      if (role == UserRole.patient) await fetchDoctors();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    currentUser = null;
    myAppointments.clear();
    directoryDoctors.clear();
    _resetBookingState();
    notifyListeners();
  }

  Future<void> refreshAppointments() async {
    if (currentUser == null) return;
    myAppointments = await _api.getAppointmentsForUser(
      currentUser!.id,
      currentUser!.role,
    );
    notifyListeners();
  }

  // --- Patient Booking Flow ---

  Future<void> fetchDoctors({Specialty? filter}) async {
    directoryDoctors = await _api.getDoctors(filter: filter);
    notifyListeners();
  }

  void startBookingFlow(Doctor doctor) {
    _resetBookingState();
    selectedDoctor = doctor;
    _fetchSlotsForDate(selectedDate);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    selectedTimeSlot = null;
    _fetchSlotsForDate(date);
    notifyListeners();
  }

  void selectTimeSlot(DateTime slot) {
    selectedTimeSlot = slot;
    notifyListeners();
  }

  Future<void> _fetchSlotsForDate(DateTime date) async {
    if (selectedDoctor == null) return;
    isFetchingSlots = true;
    notifyListeners();
    try {
      availableSlots = await _api.getAvailableSlots(selectedDoctor!.id, date);
    } finally {
      isFetchingSlots = false;
      notifyListeners();
    }
  }

  Future<bool> confirmBooking(String reason) async {
    if (selectedDoctor == null || selectedTimeSlot == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      await _api.bookAppointment(
        currentUser!.id,
        selectedDoctor!.id,
        selectedTimeSlot!,
        reason,
      );
      await refreshAppointments(); // update dashboard
      _resetBookingState();
      return true;
    } on ScheduleConflictException catch (e) {
      _setError(e.message);
      // Automatically refresh slots because one was taken
      await _fetchSlotsForDate(selectedDate);
      return false;
    } catch (e) {
      _setError("Failed to book appointment. Please try again.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _resetBookingState() {
    selectedDoctor = null;
    selectedDate = DateTime.now();
    selectedTimeSlot = null;
    availableSlots.clear();
  }

  // --- Doctor Flow ---
  Future<Patient> getPatientDetails(String patientId) async {
    return await _api.getPatientDetails(patientId);
  }

  Future<void> completeAppointment(String appId, String notes) async {
    _setLoading(true);
    await _api.updateAppointmentStatus(
      appId,
      AppointmentStatus.completed,
      notes: notes,
    );
    await refreshAppointments();
    _setLoading(false);
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
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ClinicApp());
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: AppState(),
      child: MaterialApp(
        title: 'Nexus Health',
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
            systemOverlayStyle: SystemUiOverlayStyle.dark,
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
    if (state.currentUser!.role == UserRole.patient)
      return const PatientNavigation();
    return const DoctorNavigation();
  }
}

// ============================================================================
// 8. AUTH SCREEN
// ============================================================================

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nexus Health',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'Smart Clinic Management',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 64),

                if (state.isGlobalLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: () =>
                        state.login('Patient User', UserRole.patient),
                    child: const Text(
                      'PORTAL: PATIENT LOG IN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        state.login('Doctor User', UserRole.doctor),
                    child: const Text(
                      'PORTAL: DOCTOR LOG IN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 9. PATIENT FLOW (Dash, Directory, Booking Wizard)
// ============================================================================

class PatientNavigation extends StatefulWidget {
  const PatientNavigation({Key? key}) : super(key: key);

  @override
  State<PatientNavigation> createState() => _PatientNavigationState();
}

class _PatientNavigationState extends State<PatientNavigation> {
  int _currentIndex = 0;
  final _screens = [
    const PatientDashboard(),
    const DoctorDirectoryScreen(),
    const PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser as Patient;

    final upcoming = state.myAppointments
        .where(
          (a) =>
              a.status == AppointmentStatus.scheduled &&
              a.startTime.isAfter(DateTime.now()),
        )
        .toList();
    final past = state.myAppointments
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: state.refreshAppointments,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good morning,',
                              style: AppTextStyles.bodyMuted,
                            ),
                            Text(user.firstName, style: AppTextStyles.h1),
                          ],
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(user.avatarUrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('Upcoming Appointment', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    if (upcoming.isEmpty)
                      _buildEmptyState(
                        'No upcoming appointments',
                        'Find a doctor to book your next visit.',
                        Icons.event_available,
                      )
                    else
                      _AppointmentCard(
                        appointment: upcoming.first,
                        isDoctorView: false,
                      ),

                    const SizedBox(height: 32),
                    const Text('Recent History', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    if (past.isEmpty)
                      const Text(
                        'No past appointments.',
                        style: AppTextStyles.bodyMuted,
                      )
                    else
                      ...past
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AppointmentCard(
                                appointment: a,
                                isDoctorView: false,
                              ),
                            ),
                          )
                          .toList(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String sub, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primaryLight),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(sub, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}

class DoctorDirectoryScreen extends StatelessWidget {
  const DoctorDirectoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Doctor')),
      body: Column(
        children: [
          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: Specialty.values
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(s.toString().split('.').last.toUpperCase()),
                        selected: false,
                        onSelected: (_) => state.fetchDoctors(filter: s),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.directoryDoctors.length,
              itemBuilder: (context, index) {
                final doc = state.directoryDoctors[index];
                return _DoctorCard(doctor: doc);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppStore.of(context, listen: false).startBookingFlow(doctor);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingWizardScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                doctor.avatarUrl,
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
                  Text('Dr. ${doctor.lastName}', style: AppTextStyles.h3),
                  Text(
                    doctor.specialtyString,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${doctor.rating} (${doctor.reviews} reviews)',
                        style: AppTextStyles.bodyMuted,
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
// 10. BOOKING WIZARD & CUSTOM CALENDAR
// ============================================================================

class BookingWizardScreen extends StatefulWidget {
  const BookingWizardScreen({Key? key}) : super(key: key);

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _handleConfirm(AppState state) async {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for visit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await state.confirmBooking(_reasonCtrl.text);
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppointmentSuccessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final doc = state.selectedDoctor;

    if (doc == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Info Mini
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(doc.avatarUrl),
                      radius: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr. ${doc.fullName}', style: AppTextStyles.h3),
                        Text(
                          doc.specialtyString,
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),

                // Calendar Component
                const Text('Select Date', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                const CustomCalendarWidget(),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),

                // Time Slots
                const Text('Available Slots', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                if (state.isFetchingSlots)
                  const Center(child: CircularProgressIndicator())
                else if (state.availableSlots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No slots available for this date.',
                      style: TextStyle(color: AppColors.error),
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: state.availableSlots.map((slot) {
                      final isSelected = state.selectedTimeSlot == slot;
                      return ChoiceChip(
                        label: Text(DateUtils.formatTime(slot)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textMain,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => state.selectTimeSlot(slot),
                      );
                    }).toList(),
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),
                const Text('Reason for Visit', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Briefly describe your symptoms or reason for visit...',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textMuted),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // padding for bottom button
              ],
            ),
          ),

          // Bottom Action Bar & Error Overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.globalError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppColors.error,
                    child: Text(
                      state.globalError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Container(
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
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            state.selectedTimeSlot == null ||
                                state.isGlobalLoading
                            ? null
                            : () => _handleConfirm(state),
                        child: state.isGlobalLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CONFIRM BOOKING',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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

/// Custom Calendar built entirely from scratch
class CustomCalendarWidget extends StatelessWidget {
  const CustomCalendarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final selectedDate = state.selectedDate;
    final now = DateTime.now();

    // We only display the current month for this demo scope
    final int daysInMonth = DateUtils.daysInMonth(now.year, now.month);
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final int firstWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun

    // Generate grid items
    List<Widget> gridItems = [];

    // Day headers
    const headers = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (var h in headers) {
      gridItems.add(
        Center(
          child: Text(
            h,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    // Empty slots before first day
    for (int i = 1; i < firstWeekday; i++) {
      gridItems.add(const SizedBox());
    }

    // Actual days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
      final isSelected = DateUtils.isSameDay(date, selectedDate);
      final isToday = DateUtils.isSameDay(date, now);

      gridItems.add(
        GestureDetector(
          onTap: isPast ? null : () => state.selectDate(date),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isToday ? AppColors.primaryLight : Colors.transparent),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isPast
                      ? AppColors.textMuted.withOpacity(0.3)
                      : (isSelected ? Colors.white : AppColors.textMain),
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Text(DateUtils.formatMonthYear(now), style: AppTextStyles.h3),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: gridItems,
          ),
        ],
      ),
    );
  }
}

class AppointmentSuccessScreen extends StatelessWidget {
  const AppointmentSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your appointment has been successfully scheduled. You will receive a reminder before your visit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('BACK TO DASHBOARD'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text("Patient Profile & Medical History Settings here."),
      ),
    );
  }
}

// ============================================================================
// 11. DOCTOR FLOW (Dashboard, Timeline, Detail)
// ============================================================================

class DoctorNavigation extends StatefulWidget {
  const DoctorNavigation({Key? key}) : super(key: key);

  @override
  State<DoctorNavigation> createState() => _DoctorNavigationState();
}

class _DoctorNavigationState extends State<DoctorNavigation> {
  int _currentIndex = 0;
  final _screens = [const DoctorDashboard(), const ScheduleTimelineScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_timeline),
            label: 'Schedule',
          ),
        ],
      ),
    );
  }
}

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final user = state.currentUser as Doctor;

    final todayApps = state.myAppointments
        .where((a) => DateUtils.isSameDay(a.startTime, DateTime.now()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => state.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshAppointments,
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
                    Text('Dr. ${user.lastName}', style: AppTextStyles.h1),
                    Text(user.specialtyString, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatMetric(val: '${todayApps.length}', label: 'Today'),
                  _StatMetric(
                    val:
                        '${todayApps.where((a) => a.status == AppointmentStatus.completed).length}',
                    label: 'Completed',
                  ),
                  _StatMetric(val: '4.8', label: 'Rating'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Next Patient', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            if (todayApps
                .where((a) => a.status == AppointmentStatus.scheduled)
                .isEmpty)
              const Text(
                'No more scheduled patients today.',
                style: AppTextStyles.bodyMuted,
              )
            else
              _AppointmentCard(
                appointment: todayApps
                    .where((a) => a.status == AppointmentStatus.scheduled)
                    .first,
                isDoctorView: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatMetric extends StatelessWidget {
  final String val;
  final String label;
  const _StatMetric({required this.val, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

// ============================================================================
// 12. CUSTOM DOCTOR TIMELINE ENGINE
// ============================================================================

class ScheduleTimelineScreen extends StatelessWidget {
  const ScheduleTimelineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final todayApps = state.myAppointments
        .where((a) => DateUtils.isSameDay(a.startTime, DateTime.now()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Timeline')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                DateUtils.formatFullDate(DateTime.now()),
                style: AppTextStyles.h2,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 800, // Fixed height for 9AM - 5PM scale
              child: Stack(
                children: [
                  // Draw Background Timeline Grid
                  CustomPaint(
                    size: const Size(double.infinity, 800),
                    painter: _TimelineGridPainter(),
                  ),
                  // Draw Appointment Blocks
                  ...todayApps
                      .map((a) => _buildTimelineBlock(context, a))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBlock(BuildContext context, Appointment app) {
    // Math logic to position block based on time (9 AM = offset 0)
    final startHour = app.startTime.hour;
    final startMin = app.startTime.minute;

    // Scale: 1 hour = 100 pixels
    final offsetHours = (startHour - 9) + (startMin / 60.0);
    final topOffset = offsetHours * 100.0;
    final height = (app.duration.inMinutes / 60.0) * 100.0;

    final isCompleted = app.status == AppointmentStatus.completed;

    return Positioned(
      top: topOffset,
      left: 70, // offset for time labels
      right: 24,
      height: height,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(appointment: app),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.surface : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: isCompleted ? AppColors.textMuted : AppColors.primary,
                width: 4,
              ),
            ),
            boxShadow: [
              if (!isCompleted)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${DateUtils.formatTime(app.startTime)} - ${DateUtils.formatTime(app.endTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted
                      ? AppColors.textMuted
                      : AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Patient ID: ${app.patientId}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppColors.textMuted : AppColors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 50) // only show reason if block is tall enough
                Text(
                  app.reasonForVisit,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.2)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 9 AM to 5 PM
    for (int i = 0; i <= 8; i++) {
      double y = i * 100.0;

      // Draw Line
      canvas.drawLine(Offset(60, y), Offset(size.width, y), linePaint);

      // Draw Time Text
      int hour = 9 + i;
      String ampm = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : hour;

      textPainter.text = TextSpan(
        text: '$displayHour:00 $ampm',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(16, y - 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 13. DOCTOR APPOINTMENT DETAIL / NOTES
// ============================================================================

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;
  const AppointmentDetailScreen({Key? key, required this.appointment})
    : super(key: key);

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _notesCtrl = TextEditingController();
  Patient? _patient;

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = widget.appointment.doctorNotes ?? '';
    _fetchPatient();
  }

  void _fetchPatient() async {
    final state = AppStore.of(context, listen: false);
    final p = await state.getPatientDetails(widget.appointment.patientId);
    if (mounted) setState(() => _patient = p);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);
    final isCompleted =
        widget.appointment.status == AppointmentStatus.completed;

    return Scaffold(
      appBar: AppBar(title: const Text('Consultation Details')),
      body: _patient == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(_patient!.avatarUrl),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_patient!.fullName, style: AppTextStyles.h2),
                          Text(
                            'Blood Group: ${_patient!.bloodGroup}',
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  const Text('Medical History', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      _patient!.medicalHistory,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Reason for Visit', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    widget.appointment.reasonForVisit,
                    style: AppTextStyles.body,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  const Text(
                    'Doctor Notes & Prescription',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 8,
                    enabled: !isCompleted,
                    decoration: InputDecoration(
                      hintText: 'Record observations and prescriptions here...',
                      filled: true,
                      fillColor: isCompleted
                          ? AppColors.background
                          : AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isGlobalLoading
                            ? null
                            : () async {
                                await state.completeAppointment(
                                  widget.appointment.id,
                                  _notesCtrl.text,
                                );
                                if (mounted) Navigator.pop(context);
                              },
                        child: state.isGlobalLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'MARK COMPLETED',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CONSULTATION COMPLETED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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
// 14. SHARED UI WIDGETS
// ============================================================================

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isDoctorView;

  const _AppointmentCard({
    required this.appointment,
    required this.isDoctorView,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = appointment.status == AppointmentStatus.scheduled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surface,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateUtils.formatShortDate(appointment.startTime),
                style: TextStyle(
                  color: isActive ? Colors.white70 : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateUtils.formatTime(appointment.startTime),
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person,
                color: isActive ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDoctorView
                      ? 'Patient ID: ${appointment.patientId}'
                      : 'Doctor ID: ${appointment.doctorId}',
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textMain,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.notes,
                color: isActive ? Colors.white70 : AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appointment.reasonForVisit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (isDoctorView && isActive) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AppointmentDetailScreen(appointment: appointment),
                  ),
                ),
                child: const Text(
                  'BEGIN CONSULTATION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
