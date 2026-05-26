import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
// Per-file Color compatibility shim (replaces deprecated withOpacity usage)
extension ColorWithValues on Color {
  Color withValues(double opacity) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int b = value & 0xFF;
    return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
  }
}


// Minimal `intl` shim (per-file) to avoid external dependency
class NumberFormat {
  final String? _symbol;
  final int? _decimalDigits;
  // ignore: unused_field
  final bool _isDecimalPattern;
  NumberFormat.currency({String symbol = '', int decimalDigits = 2})
    : _symbol = symbol,
      _decimalDigits = decimalDigits,
      _isDecimalPattern = false;
  NumberFormat.decimalPattern()
    : _symbol = null,
      _decimalDigits = null,
      _isDecimalPattern = true;

  String format(num value) {
    final negative = value < 0;
    final abs = value.abs();
    final int decimals = _decimalDigits ?? (abs % 1 == 0 ? 0 : 2);
    final fixed = abs.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? '.' + parts[1] : '';
    final withCommas = _addCommas(intPart);
    final out = '${_symbol ?? ''}$withCommas$fracPart';
    return negative ? '-$out' : out;
  }

  static String _addCommas(String s) {
    final rev = s.split('').reversed.toList();
    final buf = <String>[];
    for (var i = 0; i < rev.length; i++) {
      if (i != 0 && i % 3 == 0) buf.add(',');
      buf.add(rev[i]);
    }
    return buf.reversed.join();
  }
}

class DateFormat {
  final String pattern;
  DateFormat(this.pattern);
  String format(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    if (pattern.contains('HH') ||
        pattern.contains('mm') ||
        pattern.contains('ss')) {
      return pattern
          .replaceAll('HH', two(dt.hour))
          .replaceAll('mm', two(dt.minute))
          .replaceAll('ss', two(dt.second));
    }
    if (pattern.contains('MMM')) {
      const months = [
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
      return pattern
          .replaceAll('MMM', months[dt.month - 1])
          .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
          .replaceAll('yyyy', dt.year.toString());
    }
    return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)}';
  }
}

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const FaunaCareApp());
}

class FaunaCareApp extends StatelessWidget {
  const FaunaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const PetCareStateProvider(
      child: MaterialApp(
        title: 'Fauna: Enterprise Pet Management',
        debugShowCheckedModeBanner: false,
        home: MasterPetDashboard(),
      ),
    );
  }
}

// ==========================================
// 1. DATA PARADIGMS & BIOLOGICAL STRUCTURES
// ==========================================

enum AppSection { dashboard, petRoster, clinicalMatrix, dietarySchedule }

enum Species { dog, cat, avian, reptile, smallMammal }

enum ClinicalEventType { vaccination, checkup, surgery, grooming }

class PetProfile {
  final String id;
  final String name;
  final Species species;
  final String breed;
  final DateTime dateOfBirth;
  final double weightKg;
  final Color themeColor;

  const PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.dateOfBirth,
    required this.weightKg,
    required this.themeColor,
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
  }
}

class ClinicalRecord {
  final String id;
  final String petId;
  final String title;
  final ClinicalEventType type;
  final DateTime scheduledDate;
  final String providerName;
  final bool isCompleted;

  const ClinicalRecord({
    required this.id,
    required this.petId,
    required this.title,
    required this.type,
    required this.scheduledDate,
    required this.providerName,
    this.isCompleted = false,
  });

  ClinicalRecord copyWith({bool? isCompleted}) {
    return ClinicalRecord(
      id: id,
      petId: petId,
      title: title,
      type: type,
      scheduledDate: scheduledDate,
      providerName: providerName,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class DietarySchedule {
  final String id;
  final String petId;
  final String mealIdentifier;
  final TimeOfDay scheduledTime;
  final String portionSpecification;

  const DietarySchedule({
    required this.id,
    required this.petId,
    required this.mealIdentifier,
    required this.scheduledTime,
    required this.portionSpecification,
  });
}

// ==========================================
// 2. STATE ENGINE & PIPELINES
// ==========================================

class PetCareController extends ChangeNotifier {
  AppSection currentSection = AppSection.dashboard;
  String? focusedPetId;

  final List<PetProfile> _roster = [];
  final List<ClinicalRecord> _medicalMatrix = [];
  final List<DietarySchedule> _dietaryEngine = [];

  PetCareController() {
    _seedEnterpriseData();
  }

  void _seedEnterpriseData() {
    final now = DateTime.now();

    // Seed Profiles
    final p1 = PetProfile(
      id: 'P-001',
      name: 'Maximus',
      species: Species.dog,
      breed: 'Golden Retriever',
      dateOfBirth: DateTime(now.year - 3, 4, 12),
      weightKg: 32.5,
      themeColor: const Color(0xfff59e0b),
    );
    final p2 = PetProfile(
      id: 'P-002',
      name: 'Luna',
      species: Species.cat,
      breed: 'Siamese',
      dateOfBirth: DateTime(now.year - 1, 8, 22),
      weightKg: 4.2,
      themeColor: const Color(0xff8b5cf6),
    );
    _roster.addAll([p1, p2]);

    // Seed Clinical Records (Vaccines & Vets)
    _medicalMatrix.addAll([
      ClinicalRecord(
        id: 'C-101',
        petId: 'P-001',
        title: 'Rabies Booster',
        type: ClinicalEventType.vaccination,
        scheduledDate: now.add(const Duration(days: 14)),
        providerName: 'Apex Veterinary Clinic',
      ),
      ClinicalRecord(
        id: 'C-102',
        petId: 'P-002',
        title: 'FVRCP Immunization',
        type: ClinicalEventType.vaccination,
        scheduledDate: now.subtract(const Duration(days: 45)),
        providerName: 'Apex Veterinary Clinic',
        isCompleted: true,
      ),
      ClinicalRecord(
        id: 'C-103',
        petId: 'P-001',
        title: 'Annual Biometrics Checkup',
        type: ClinicalEventType.checkup,
        scheduledDate: now.add(const Duration(days: 2)),
        providerName: 'Dr. Sarah Jenkins',
      ),
    ]);

    // Seed Dietary Engine
    _dietaryEngine.addAll([
      const DietarySchedule(
        id: 'D-201',
        petId: 'P-001',
        mealIdentifier: 'Morning Kibble',
        scheduledTime: TimeOfDay(hour: 7, minute: 30),
        portionSpecification: '2.5 Cups Dry',
      ),
      const DietarySchedule(
        id: 'D-202',
        petId: 'P-001',
        mealIdentifier: 'Evening Protein',
        scheduledTime: TimeOfDay(hour: 18, minute: 00),
        portionSpecification: '2.5 Cups Dry + Wet Mix',
      ),
      const DietarySchedule(
        id: 'D-203',
        petId: 'P-002',
        mealIdentifier: 'Dawn Grazing',
        scheduledTime: TimeOfDay(hour: 6, minute: 00),
        portionSpecification: '0.5 Cup Dry',
      ),
    ]);
  }

  // Resolvers
  List<PetProfile> get allPets => List.unmodifiable(_roster);

  PetProfile? get focusedPet => focusedPetId != null
      ? _roster.firstWhere((p) => p.id == focusedPetId)
      : null;

  List<ClinicalRecord> get upcomingClinicalEvents {
    final now = DateTime.now();
    final upcoming = _medicalMatrix
        .where(
          (c) =>
              !c.isCompleted &&
              c.scheduledDate.isAfter(now.subtract(const Duration(days: 1))),
        )
        .toList();
    upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return upcoming;
  }

  List<DietarySchedule> getTodayDietarySchedule() {
    final schedule = List<DietarySchedule>.from(_dietaryEngine);
    schedule.sort(
      (a, b) => (a.scheduledTime.hour * 60 + a.scheduledTime.minute).compareTo(
        b.scheduledTime.hour * 60 + b.scheduledTime.minute,
      ),
    );
    return schedule;
  }

  // Mutations
  void navigateTo(AppSection section) {
    currentSection = section;
    focusedPetId = null;
    notifyListeners();
  }

  void openPetProfile(String id) {
    focusedPetId = id;
    currentSection = AppSection.petRoster;
    notifyListeners();
  }

  void markClinicalEventComplete(String id) {
    final index = _medicalMatrix.indexWhere((c) => c.id == id);
    if (index != -1) {
      _medicalMatrix[index] = _medicalMatrix[index].copyWith(isCompleted: true);
      notifyListeners();
    }
  }
}

// Inherited Architecture Setup
class PetCareStateProvider extends StatefulWidget {
  final Widget child;
  const PetCareStateProvider({super.key, required this.child});

  static PetCareController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedPetProvider>();
    return result!.controller;
  }

  @override
  State<PetCareStateProvider> createState() => _PetCareStateProviderState();
}

class _PetCareStateProviderState extends State<PetCareStateProvider> {
  late PetCareController controller;

  @override
  void initState() {
    super.initState();
    controller = PetCareController()..addListener(_onStateEvent);
  }

  void _onStateEvent() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_onStateEvent);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedPetProvider(controller: controller, child: widget.child);
  }
}

class _InheritedPetProvider extends InheritedWidget {
  final PetCareController controller;
  const _InheritedPetProvider({required this.controller, required super.child});
  @override
  bool updateShouldNotify(covariant _InheritedPetProvider oldWidget) => true;
}

// ==========================================
// 3. MASTER APPLICATION HIERARCHY SHELL
// ==========================================

class MasterPetDashboard extends StatelessWidget {
  const MasterPetDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PetCareStateProvider.of(context);

    Widget viewport;
    if (controller.focusedPetId != null) {
      viewport = PetProfileDetailView(pet: controller.focusedPet!);
    } else {
      switch (controller.currentSection) {
        case AppSection.dashboard:
          viewport = const MainDashboardView();
          break;
        case AppSection.petRoster:
          viewport = const PetRosterView();
          break;
        case AppSection.clinicalMatrix:
          viewport = const ClinicalTimelineView();
          break;
        case AppSection.dietarySchedule:
          viewport = const Center(child: Text("Metabolic Tracking Module"));
          break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Row(
        children: [
          // Navigation Control Pillar
          Container(
            width: 280,
            color: const Color(0xff064e3b),
            child: Column(
              children: [
                const SizedBox(height: 54),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, color: Color(0xff34d399), size: 32),
                    SizedBox(width: 12),
                    Text(
                      "FAUNA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "BIOLOGICAL ASSET MANAGER",
                  style: TextStyle(
                    color: Color(0xff6ee7b7),
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 54),
                _SidebarNav(
                  icon: Icons.dashboard_outlined,
                  label: "System Overview",
                  target: AppSection.dashboard,
                ),
                _SidebarNav(
                  icon: Icons.format_list_bulleted_rounded,
                  label: "Asset Roster",
                  target: AppSection.petRoster,
                ),
                _SidebarNav(
                  icon: Icons.medical_services_outlined,
                  label: "Clinical Matrix",
                  target: AppSection.clinicalMatrix,
                ),
                _SidebarNav(
                  icon: Icons.restaurant_menu,
                  label: "Dietary Engine",
                  target: AppSection.dietarySchedule,
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: viewport,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppSection target;

  const _SidebarNav({
    required this.icon,
    required this.label,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PetCareStateProvider.of(context);
    bool active =
        controller.currentSection == target && controller.focusedPetId == null;

    return InkWell(
      onTap: () => controller.navigateTo(target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: active ? const Color(0xff34d399) : Colors.transparent,
              width: 4,
            ),
          ),
          color: active ? const Color(0xff022c22) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? const Color(0xff34d399) : const Color(0xff94a3b8),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xffcbd5e1),
                fontSize: 14,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. MODULE 1: CONTROL DASHBOARD
// ==========================================

class MainDashboardView extends StatelessWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PetCareStateProvider.of(context);
    final upcomingEvents = controller.upcomingClinicalEvents;
    final meals = controller.getTodayDietarySchedule();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Operations Dashboard",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const Text(
            "Real-time telemetry and metabolic tracking across all registered biological assets.",
            style: TextStyle(fontSize: 14, color: Color(0xff64748b)),
          ),
          const SizedBox(height: 48),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Upcoming Medical
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xffef4444),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Critical Clinical Events",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (upcomingEvents.isEmpty)
                        const Text(
                          "No pending clinical obligations.",
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: upcomingEvents.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 24),
                          itemBuilder: (context, idx) {
                            final event = upcomingEvents[idx];
                            final pet = controller.allPets.firstWhere(
                              (p) => p.id == event.petId,
                            );
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                      CircleAvatar(
                                      backgroundColor: pet.themeColor
                                          .withOpacity(0.2),
                                      child: Icon(
                                        Icons.pets,
                                        color: pet.themeColor,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "${pet.name} | ${DateFormat('MMM dd, yyyy').format(event.scheduledDate)}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff064e3b),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => controller
                                      .markClinicalEventComplete(event.id),
                                  child: const Text(
                                    "MARK DONE",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),

              // Right Column: Today's Dietary Schedule
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Metabolic Replenishment (Today)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: meals.length,
                        itemBuilder: (context, idx) {
                          final meal = meals[idx];
                          final pet = controller.allPets.firstWhere(
                            (p) => p.id == meal.petId,
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xfff8fafc),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xffe2e8f0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff020617),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    meal.scheduledTime.format(context),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meal.mealIdentifier,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${pet.name} — ${meal.portionSpecification}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. MODULE 2: PET ROSTER & PROFILES
// ==========================================

class PetRosterView extends StatelessWidget {
  const PetRosterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PetCareStateProvider.of(context);

    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Biological Asset Roster",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.85,
            ),
            itemCount: controller.allPets.length,
            itemBuilder: (context, idx) {
              final pet = controller.allPets[idx];
              return InkWell(
                onTap: () => controller.openPetProfile(pet.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pet.themeColor.withOpacity(0.1),
                          border: Border.all(color: pet.themeColor, width: 3),
                        ),
                        child: Icon(
                          Icons.pets,
                          size: 48,
                          color: pet.themeColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pet.breed,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PetProfileDetailView extends StatelessWidget {
  final PetProfile pet;
  const PetProfileDetailView({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final controller = PetCareStateProvider.of(context);

    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 28),
                onPressed: () => controller.navigateTo(AppSection.petRoster),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundColor: pet.themeColor.withOpacity(0.2),
                radius: 24,
                child: Icon(Icons.pets, color: pet.themeColor),
              ),
              const SizedBox(width: 16),
              Text(
                "Asset Profile: ${pet.name}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radial Metrics Engine
              Container(
                width: 320,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: CustomPaint(
                        painter: _BiometricRadialPainter(
                          themeColor: pet.themeColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${pet.weightKg}",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: pet.themeColor,
                                ),
                              ),
                              const Text(
                                "KG MASS",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    _ProfileStatBlock(
                      label: "SPECIES",
                      value: pet.species.name.toUpperCase(),
                    ),
                    const Divider(height: 32),
                    _ProfileStatBlock(
                      label: "GENOTYPE / BREED",
                      value: pet.breed,
                    ),
                    const Divider(height: 32),
                    _ProfileStatBlock(
                      label: "AGE",
                      value: "${pet.ageInMonths} Months",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 42),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Biological Event Matrix",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Timeline goes here
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xffe2e8f0)),
                      ),
                      child: const Text(
                        "Integration to master clinical timeline is active. See Clinical Matrix section for full chronological node graph.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xff0f172a),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 6. MODULE 3: CLINICAL TIMELINE RENDERER
// ==========================================

class ClinicalTimelineView extends StatelessWidget {
  const ClinicalTimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Global Clinical Node Graph",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const Text(
            "Chronological tracking of immunizations, surgeries, and routine biological maintenance.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: CustomPaint(
                painter: _ChronologicalTimelinePainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. CUSTOM ENTERPRISE VISUALIZATIONS
// ==========================================

class _BiometricRadialPainter extends CustomPainter {
  final Color themeColor;
  _BiometricRadialPainter({required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = const Color(0xfff1f5f9)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = themeColor
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Static ring for UI architecture demonstration
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      bg,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.3,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChronologicalTimelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xffe2e8f0)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final nodePaint = Paint()
      ..color = const Color(0xff064e3b)
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw central spline
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    final int nodes = 4;
    final double spacing = size.height / (nodes + 1);

    List<String> events = [
      "FVRCP Immunization (Luna)",
      "Biometrics Checkup (Maximus)",
      "Rabies Booster (Maximus)",
      "Dental Prophylaxis (Luna)",
    ];

    for (int i = 1; i <= nodes; i++) {
      double y = spacing * i;
      double cx = size.width / 2;

      // Draw Node
      canvas.drawCircle(Offset(cx, y), 12, nodePaint);
      canvas.drawCircle(Offset(cx, y), 6, Paint()..color = Colors.white);

      // Draw Text Label
      bool isLeft = i % 2 == 0;
      textPainter.text = TextSpan(
        text: events[i - 1],
        style: const TextStyle(
          color: Color(0xff0f172a),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      double tx = isLeft ? cx - textPainter.width - 32 : cx + 32;
      double ty = y - (textPainter.height / 2);

      textPainter.paint(canvas, Offset(tx, ty));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
