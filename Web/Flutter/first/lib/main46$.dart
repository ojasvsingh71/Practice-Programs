import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// ENTRY POINT
// ============================================================================

// Per-file Color compatibility shim (replaces deprecated `withOpacity` usage)
extension ColorWithValues on Color {
  Color withValues(double opacity) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int b = value & 0xFF;
    return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FoodieWorkspaceApp());
}

// ============================================================================
// DATA MODELS & SCHEMAS
// ============================================================================

enum IngredientCategory {
  produce,
  meatSeafood,
  dairy,
  pantry,
  bakery,
  spicesOil,
}

enum CulinaryCategory { breakfast, lunch, dinner, snack, dessert }

enum MealSlotType { breakfast, lunch, dinner }

class Ingredient {
  final String name;
  final double quantity;
  final String unit;
  final IngredientCategory category;

  const Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
  });

  String get categoryString =>
      category.toString().split('.').last.toUpperCase();

  Ingredient copyWith({double? quantity}) {
    return Ingredient(
      name: name,
      quantity: quantity ?? this.quantity,
      unit: unit,
      category: category,
    );
  }
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final CulinaryCategory category;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final bool isFavorite;
  final String imageUrl;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    this.isFavorite = false,
    this.imageUrl = '',
  });

  int get totalTime => prepTimeMinutes + cookTimeMinutes;
  String get categoryName => category.toString().split('.').last;

  Recipe toggleFavorite() {
    return Recipe(
      id: id,
      title: title,
      description: description,
      category: category,
      ingredients: ingredients,
      instructions: instructions,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      isFavorite: !isFavorite,
      imageUrl: imageUrl,
    );
  }
}

class MealPlanSlot {
  final String dayOfWeek; // e.g., "Monday", "Tuesday"
  final MealSlotType slotType;
  final String? recipeId; // Null implies unassigned/empty slot

  const MealPlanSlot({
    required this.dayOfWeek,
    required this.slotType,
    this.recipeId,
  });

  String get slotName => slotType.toString().split('.').last.toUpperCase();
}

class ManualGroceryItem {
  final String id;
  final String name;
  final IngredientCategory category;
  final bool isChecked;

  const ManualGroceryItem({
    required this.id,
    required this.name,
    required this.category,
    this.isChecked = false,
  });

  ManualGroceryItem toggle() {
    return ManualGroceryItem(
      id: id,
      name: name,
      category: category,
      isChecked: !isChecked,
    );
  }
}

// ============================================================================
// CENTRAL APP STATE ARCHITECTURE (MANAGEMENT ENGINE)
// ============================================================================

class RecipeWorkspaceState extends ChangeNotifier {
  // Pre-seeded local relational data infrastructure
  final List<Recipe> _recipes = [];
  final List<MealPlanSlot> _mealPlanMatrix = [];
  final List<ManualGroceryItem> _manualGroceryList = [];

  // App Runtime Filters
  String _recipeSearchQuery = '';
  CulinaryCategory? _selectedCategoryFilter;

  RecipeWorkspaceState() {
    _seedInitialDataStructures();
  }

  // --- Getters ---
  List<Recipe> get allRecipes => List.unmodifiable(_recipes);
  List<MealPlanSlot> get mealPlanMatrix => List.unmodifiable(_mealPlanMatrix);
  List<ManualGroceryItem> get manualGroceryList =>
      List.unmodifiable(_manualGroceryList);
  String get recipeSearchQuery => _recipeSearchQuery;
  CulinaryCategory? get selectedCategoryFilter => _selectedCategoryFilter;

  List<Recipe> get filteredRecipes {
    return _recipes.where((recipe) {
      final matchesSearch =
          recipe.title.toLowerCase().contains(
            _recipeSearchQuery.toLowerCase(),
          ) ||
          recipe.description.toLowerCase().contains(
            _recipeSearchQuery.toLowerCase(),
          );
      final matchesCategory =
          _selectedCategoryFilter == null ||
          recipe.category == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // --- Filtering Mutations ---
  void updateSearchQuery(String query) {
    _recipeSearchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(CulinaryCategory? cat) {
    _selectedCategoryFilter = cat;
    notifyListeners();
  }

  // --- Recipe Management Pipelines ---
  void addCustomRecipe(Recipe newRecipe) {
    _recipes.add(newRecipe);
    notifyListeners();
  }

  void removeRecipe(String id) {
    _recipes.removeWhere((r) => r.id == id);
    // Clear out residual invalid associations within the plan Matrix
    for (int i = 0; i < _mealPlanMatrix.length; i++) {
      if (_mealPlanMatrix[i].recipeId == id) {
        _mealPlanMatrix[i] = MealPlanSlot(
          dayOfWeek: _mealPlanMatrix[i].dayOfWeek,
          slotType: _mealPlanMatrix[i].slotType,
          recipeId: null,
        );
      }
    }
    notifyListeners();
  }

  void toggleRecipeFavoriteStatus(String id) {
    final index = _recipes.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recipes[index] = _recipes[index].toggleFavorite();
      notifyListeners();
    }
  }

  // --- Meal Planner Architecture Mutations ---
  void assignRecipeToSlot(String day, MealSlotType slot, String? recipeId) {
    final index = _mealPlanMatrix.indexWhere(
      (m) => m.dayOfWeek == day && m.slotType == slot,
    );
    if (index != -1) {
      _mealPlanMatrix[index] = MealPlanSlot(
        dayOfWeek: day,
        slotType: slot,
        recipeId: recipeId,
      );
      notifyListeners();
    }
  }

  void clearEntireWeeklyPlan() {
    final days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    _mealPlanMatrix.clear();
    for (var day in days) {
      for (var slot in MealSlotType.values) {
        _mealPlanMatrix.add(
          MealPlanSlot(dayOfWeek: day, slotType: slot, recipeId: null),
        );
      }
    }
    notifyListeners();
  }

  // --- Smart Grocery Engine Combinator ---
  // Compiles, normalizes, and groups all items from the current active meal plan
  Map<IngredientCategory, List<Ingredient>> computeAggregatedGroceryList() {
    final Map<String, Ingredient> structuralMap = {};

    // 1. Process active recipe requirements
    for (var slot in _mealPlanMatrix) {
      if (slot.recipeId != null) {
        final targetRecipe = _recipes.firstWhere(
          (r) => r.id == slot.recipeId,
          orElse: () => const Recipe(
            id: '',
            title: '',
            description: '',
            category: CulinaryCategory.lunch,
            ingredients: [],
            instructions: [],
            prepTimeMinutes: 0,
            cookTimeMinutes: 0,
          ),
        );

        if (targetRecipe.id.isNotEmpty) {
          for (var ing in targetRecipe.ingredients) {
            final key =
                "${ing.name.trim().toLowerCase()}_${ing.unit.trim().toLowerCase()}";
            if (structuralMap.containsKey(key)) {
              final existing = structuralMap[key]!;
              structuralMap[key] = existing.copyWith(
                quantity: existing.quantity + ing.quantity,
              );
            } else {
              structuralMap[key] = ing;
            }
          }
        }
      }
    }

    // 2. Format structural dictionary into explicit categorizations
    final Map<IngredientCategory, List<Ingredient>> groupedData = {};
    for (var cat in IngredientCategory.values) {
      groupedData[cat] = [];
    }

    structuralMap.values.forEach((ing) {
      groupedData[ing.category]!.add(ing);
    });

    // Strip categories with zero entries to save space
    groupedData.removeWhere((key, value) => value.isEmpty);
    return groupedData;
  }

  // --- Manual Grocery Extras ---
  void addManualGroceryItem(String name, IngredientCategory category) {
    if (name.trim().isEmpty) return;
    _manualGroceryList.add(
      ManualGroceryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        category: category,
      ),
    );
    notifyListeners();
  }

  void toggleManualItemChecked(String id) {
    final index = _manualGroceryList.indexWhere((item) => item.id == id);
    if (index != -1) {
      _manualGroceryList[index] = _manualGroceryList[index].toggle();
      notifyListeners();
    }
  }

  void purgeCompletedManualItems() {
    _manualGroceryList.removeWhere((item) => item.isChecked);
    notifyListeners();
  }

  // --- Initial Structuring Mock Seed Engine ---
  void _seedInitialDataStructures() {
    // Inject seed recipes
    _recipes.addAll([
      const Recipe(
        id: "rec_1",
        title: "Garlic Butter Shrimp Pasta",
        description:
            "Rich, garlicky shrimp tossed over al dente spaghetti with lemon hints.",
        category: CulinaryCategory.dinner,
        prepTimeMinutes: 10,
        cookTimeMinutes: 15,
        isFavorite: true,
        ingredients: [
          Ingredient(
            name: "Shrimp",
            quantity: 500,
            unit: "g",
            category: IngredientCategory.meatSeafood,
          ),
          Ingredient(
            name: "Spaghetti",
            quantity: 250,
            unit: "g",
            category: IngredientCategory.pantry,
          ),
          Ingredient(
            name: "Butter",
            quantity: 3,
            unit: "tbsp",
            category: IngredientCategory.dairy,
          ),
          Ingredient(
            name: "Garlic Cloves",
            quantity: 6,
            unit: "pcs",
            category: IngredientCategory.produce,
          ),
          Ingredient(
            name: "Lemon Juice",
            quantity: 2,
            unit: "tbsp",
            category: IngredientCategory.produce,
          ),
          Ingredient(
            name: "Red Pepper Flakes",
            quantity: 1,
            unit: "tsp",
            category: IngredientCategory.spicesOil,
          ),
        ],
        instructions: [
          "Boil salted water and cook spaghetti until al dente.",
          "Melt butter in a skillet over medium heat, adding minced garlic and red pepper flakes.",
          "Add shrimp and cook until pink, roughly 2-3 minutes per side.",
          "Toss pasta directly into the skillet, add fresh lemon juice, coat thoroughly, and serve.",
        ],
      ),
      const Recipe(
        id: "rec_2",
        title: "Avocado Toast Breakfast Pack",
        description:
            "Artisanal sourdough toast layered with seasoned mashed avocado and microgreens.",
        category: CulinaryCategory.breakfast,
        prepTimeMinutes: 5,
        cookTimeMinutes: 5,
        isFavorite: false,
        ingredients: [
          Ingredient(
            name: "Sourdough Bread",
            quantity: 2,
            unit: "slices",
            category: IngredientCategory.bakery,
          ),
          Ingredient(
            name: "Hass Avocado",
            quantity: 1,
            unit: "pc",
            category: IngredientCategory.produce,
          ),
          Ingredient(
            name: "Cherry Tomatoes",
            quantity: 5,
            unit: "pcs",
            category: IngredientCategory.produce,
          ),
          Ingredient(
            name: "Olive Oil",
            quantity: 1,
            unit: "tbsp",
            category: IngredientCategory.spicesOil,
          ),
          Ingredient(
            name: "Sea Salt & Pepper",
            quantity: 1,
            unit: "pinch",
            category: IngredientCategory.spicesOil,
          ),
        ],
        instructions: [
          "Toast sourdough bread slices until golden crisp.",
          "Mash the avocado flesh in a bowl with sea salt, pepper, and a dash of olive oil.",
          "Spread evenly over toast and garnish with halved cherry tomatoes.",
        ],
      ),
      const Recipe(
        id: "rec_3",
        title: "Zesty Quinoa Chicken Bowl",
        description:
            "Nutrient-packed meal prep bowl loaded with grilled chicken breasts, fluffy quinoa, and black beans.",
        category: CulinaryCategory.lunch,
        prepTimeMinutes: 15,
        cookTimeMinutes: 20,
        isFavorite: true,
        ingredients: [
          Ingredient(
            name: "Chicken Breast",
            quantity: 400,
            unit: "g",
            category: IngredientCategory.meatSeafood,
          ),
          Ingredient(
            name: "Quinoa",
            quantity: 1,
            unit: "cup",
            category: IngredientCategory.pantry,
          ),
          Ingredient(
            name: "Black Beans",
            quantity: 1,
            unit: "can",
            category: IngredientCategory.pantry,
          ),
          Ingredient(
            name: "Cilantro",
            quantity: 0.5,
            unit: "bunch",
            category: IngredientCategory.produce,
          ),
          Ingredient(
            name: "Lime",
            quantity: 1,
            unit: "pc",
            category: IngredientCategory.produce,
          ),
        ],
        instructions: [
          "Rinse and cook quinoa according to packaging parameters.",
          "Season chicken breast with salt, cumin, and sear thoroughly in a pan until interior reads 165°F.",
          "Slice chicken, assemble bowls with quinoa bases, beans, fresh cilantro, and squeeze fresh lime across surface layout.",
        ],
      ),
    ]);

    // Build empty structural blueprint for 7-day layout matrix
    final days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    for (var day in days) {
      for (var slot in MealSlotType.values) {
        // Preassign a few items to make workspace active immediately
        String? targetId;
        if (day == "Monday" && slot == MealSlotType.breakfast)
          targetId = "rec_2";
        if (day == "Monday" && slot == MealSlotType.dinner) targetId = "rec_1";
        if (day == "Wednesday" && slot == MealSlotType.lunch)
          targetId = "rec_3";

        _mealPlanMatrix.add(
          MealPlanSlot(dayOfWeek: day, slotType: slot, recipeId: targetId),
        );
      }
    }

    // Seed basic manual item tracking
    _manualGroceryList.addAll([
      const ManualGroceryItem(
        id: "m_1",
        name: "Dish Soap",
        category: IngredientCategory.pantry,
      ),
      const ManualGroceryItem(
        id: "m_2",
        name: "Paper Towels",
        category: IngredientCategory.pantry,
        isChecked: true,
      ),
    ]);
  }
}

final RecipeWorkspaceState globalWorkspaceState = RecipeWorkspaceState();

// ============================================================================
// SYSTEM FRAMEWORK APPLICATION WRAPPER
// ============================================================================

class FoodieWorkspaceApp extends StatelessWidget {
  const FoodieWorkspaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: globalWorkspaceState,
      builder: (context, child) {
        return MaterialApp(
          title: 'GourmetPlan Workspace',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF00A86B), // Culinary Emerald Green
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00A86B),
              primary: const Color(0xFF00A86B),
              secondary: const Color(0xFF0F172A),
              surface: Colors.white,
              background: const Color(0xFFF8FAFC),
              error: const Color(0xFFEF4444),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              bodyLarge: TextStyle(
                fontSize: 15,
                color: Color(0xFF334155),
                height: 1.4,
              ),
              bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          home: const WorkspaceDashboardBridge(),
        );
      },
    );
  }
}

// ============================================================================
// MAIN DASHBOARD SYSTEM VIEWBRIDGE MAPPER
// ============================================================================

class WorkspaceDashboardBridge extends StatefulWidget {
  const WorkspaceDashboardBridge({Key? key}) : super(key: key);

  @override
  State<WorkspaceDashboardBridge> createState() =>
      _WorkspaceDashboardBridgeState();
}

class _WorkspaceDashboardBridgeState extends State<WorkspaceDashboardBridge> {
  int _currentNavigationIndex = 0;

  final List<Widget> _workspaceViewports = [
    const RecipeShelfViewport(),
    const WeeklyMealPlannerViewport(),
    const SmartGroceryAggregatorViewport(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNavigationIndex,
        children: _workspaceViewports,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentNavigationIndex,
          onDestinationSelected: (idx) {
            setState(() {
              _currentNavigationIndex = idx;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF00A86B).withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_rounded),
              selectedIcon: Icon(
                Icons.restaurant_menu_rounded,
                color: Color(0xFF00A86B),
              ),
              label: 'Recipes',
            ),
            NavigationDestination(
              icon: Icon(Icons.date_range_rounded),
              selectedIcon: Icon(
                Icons.date_range_rounded,
                color: Color(0xFF00A86B),
              ),
              label: 'Meal Planner',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_basket_rounded),
              selectedIcon: Icon(
                Icons.shopping_basket_rounded,
                color: Color(0xFF00A86B),
              ),
              label: 'Groceries',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VIEWPORT 1: RECIPE SHELF ARCHITECTURE
// ============================================================================

class RecipeShelfViewport extends StatefulWidget {
  const RecipeShelfViewport({Key? key}) : super(key: key);

  @override
  State<RecipeShelfViewport> createState() => _RecipeShelfViewportState();
}

class _RecipeShelfViewportState extends State<RecipeShelfViewport> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recipe Blueprint Shelf",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.playlist_add_circle_rounded,
              color: Color(0xFF00A86B),
              size: 30,
            ),
            onPressed: () => _displayRecipeCreationWizard(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Structural Processing Form Input Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        globalWorkspaceState.updateSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: "Search dishes, tags, ingredients...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF00A86B),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                globalWorkspaceState.updateSearchQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Segment Horizontal Selectors Array
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text("All Folders"),
                          selected:
                              globalWorkspaceState.selectedCategoryFilter ==
                              null,
                          onSelected: (selected) {
                            if (selected)
                              globalWorkspaceState.setCategoryFilter(null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...CulinaryCategory.values.map((cat) {
                          final label = cat.toString().split('.').last;
                          final displayLabel =
                              label[0].toUpperCase() + label.substring(1);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(displayLabel),
                              selected:
                                  globalWorkspaceState.selectedCategoryFilter ==
                                  cat,
                              onSelected: (selected) {
                                globalWorkspaceState.setCategoryFilter(
                                  selected ? cat : null,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dynamic Data List View Output
            Expanded(
              child: AnimatedBuilder(
                animation: globalWorkspaceState,
                builder: (context, child) {
                  final activeList = globalWorkspaceState.filteredRecipes;

                  if (activeList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_clear_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No structural recipes match parameters.",
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: activeList.length,
                    itemBuilder: (context, idx) {
                      final recipe = activeList[idx];
                      return _buildRecipeSystemCard(recipe, theme);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeSystemCard(Recipe recipe, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Colored Architectural Bar Mapping Category Designations
              Container(
                width: 6,
                color: _fetchCategoryColorAssignment(recipe.category),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _fetchCategoryColorAssignment(
                                recipe.category,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              recipe.categoryName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _fetchCategoryColorAssignment(
                                  recipe.category,
                                ),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${recipe.totalTime} mins",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipe.title,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${recipe.ingredients.length} items configured",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00A86B),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  recipe.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                ),
                                color: recipe.isFavorite
                                    ? Colors.red
                                    : Colors.grey,
                                iconSize: 20,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () => globalWorkspaceState
                                    .toggleRecipeFavoriteStatus(recipe.id),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => _displayInspectSheetViewport(
                                  recipe,
                                  context,
                                ),
                                child: const Text(
                                  "Inspect Details →",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Color _fetchCategoryColorAssignment(CulinaryCategory cat) {
    switch (cat) {
      case CulinaryCategory.breakfast:
        return Colors.orange;
      case CulinaryCategory.lunch:
        return Colors.blue;
      case CulinaryCategory.dinner:
        return Colors.deepPurple;
      case CulinaryCategory.snack:
        return Colors.teal;
      case CulinaryCategory.dessert:
        return Colors.pink;
    }
  }

  // --- Dynamic Sub-Modal Form sheet for adding dynamic complex structural records ---
  void _displayRecipeCreationWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const RecipeCreationSheetForm();
      },
    );
  }

  // --- Inspect Detailed Sheet View ---
  void _displayInspectSheetViewport(Recipe recipe, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: theme.textTheme.displayLarge!.copyWith(
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        globalWorkspaceState.removeRecipe(recipe.id);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(recipe.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildMetricsBadge(
                      "Prep Time",
                      "${recipe.prepTimeMinutes}m",
                      Icons.blur_linear_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricsBadge(
                      "Cook Time",
                      "${recipe.cookTimeMinutes}m",
                      Icons.outdoor_grill_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "Ingredients Breakdown",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...recipe.ingredients.map((ing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: Color(0xFF00A86B),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: Text(
                            "${ing.quantity % 1 == 0 ? ing.quantity.toInt() : ing.quantity} ${ing.unit}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(child: Text(ing.name)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ing.categoryString,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                Text("Instructions Matrix", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...recipe.instructions.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFF0F172A),
                          child: Text(
                            "${entry.key + 1}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricsBadge(String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            val,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATEFUL COMPONENT: INTERACTIVE RECIPE FORM WIZARD SHEET
// ============================================================================

class RecipeCreationSheetForm extends StatefulWidget {
  const RecipeCreationSheetForm({Key? key}) : super(key: key);

  @override
  State<RecipeCreationSheetForm> createState() =>
      _RecipeCreationSheetFormState();
}

class _RecipeCreationSheetFormState extends State<RecipeCreationSheetForm> {
  final _formGlobalKey = GlobalKey<FormState>();

  String _title = '';
  String _desc = '';
  CulinaryCategory _culinaryCategory = CulinaryCategory.dinner;
  int _prepTime = 10;
  int _cookTime = 15;

  // Track dynamic list inputs inline
  final List<Ingredient> _ingredientsInWorkflow = [];
  final List<String> _instructionsInWorkflow = [];

  // Temporary row trackers
  final TextEditingController _ingNameController = TextEditingController();
  final TextEditingController _ingQtyController = TextEditingController();
  final TextEditingController _ingUnitController = TextEditingController();
  IngredientCategory _tempIngCategory = IngredientCategory.produce;

  final TextEditingController _instructionRowController =
      TextEditingController();

  @override
  void dispose() {
    _ingNameController.dispose();
    _ingQtyController.dispose();
    _ingUnitController.dispose();
    _instructionRowController.dispose();
    super.dispose();
  }

  void _pushIngredientToStack() {
    if (_ingNameController.text.trim().isEmpty) return;
    final qty = double.tryParse(_ingQtyController.text) ?? 1.0;
    setState(() {
      _ingredientsInWorkflow.add(
        Ingredient(
          name: _ingNameController.text.trim(),
          quantity: qty,
          unit: _ingUnitController.text.trim().isEmpty
              ? "units"
              : _ingUnitController.text.trim(),
          category: _tempIngCategory,
        ),
      );
      _ingNameController.clear();
      _ingQtyController.clear();
      _ingUnitController.clear();
    });
  }

  void _pushInstructionToStack() {
    if (_instructionRowController.text.trim().isEmpty) return;
    setState(() {
      _instructionsInWorkflow.add(_instructionRowController.text.trim());
      _instructionRowController.clear();
    });
  }

  void _executeSubmissionPipeline() {
    if (!_formGlobalKey.currentState!.validate()) return;
    if (_ingredientsInWorkflow.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Configure at least one ingredient token record."),
        ),
      );
      return;
    }
    _formGlobalKey.currentState!.save();

    final uniqueId = "rec_user_${DateTime.now().millisecondsSinceEpoch}";
    final runtimeRecipe = Recipe(
      id: uniqueId,
      title: _title,
      description: _desc,
      category: _culinaryCategory,
      ingredients: List.from(_ingredientsInWorkflow),
      instructions: _instructionsInWorkflow.isEmpty
          ? ["Prepare ingredients and cook to preference."]
          : List.from(_instructionsInWorkflow),
      prepTimeMinutes: _prepTime,
      cookTimeMinutes: _cookTime,
    );

    globalWorkspaceState.addCustomRecipe(runtimeRecipe);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formGlobalKey,
          child: ListView(
            children: [
              const Text(
                "Configure Recipe Structural Token",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Recipe Title",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Title parameter required"
                    : null,
                onSaved: (v) => _title = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Brief Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSaved: (v) => _desc = v ?? '',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CulinaryCategory>(
                value: _culinaryCategory,
                decoration: const InputDecoration(
                  labelText: "Culinary Category Tag",
                  border: OutlineInputBorder(),
                ),
                items: CulinaryCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _culinaryCategory = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Prep Time (Min)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: "10",
                      onSaved: (v) => _prepTime = int.tryParse(v ?? '10') ?? 10,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Cook Time (Min)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: "15",
                      onSaved: (v) => _cookTime = int.tryParse(v ?? '15') ?? 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const Text(
                "Add Ingredients Matrix Elements",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Internal mini form elements targeting localized ingredient structures
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _ingNameController,
                      decoration: const InputDecoration(hintText: "Name"),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _ingQtyController,
                      keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: "Qty", isDense: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _ingUnitController,
                      decoration: const InputDecoration(hintText: "Unit"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<IngredientCategory>(
                      value: _tempIngCategory,
                      isExpanded: true,
                      items: IngredientCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _tempIngCategory = v);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_box_rounded,
                      color: Color(0xFF00A86B),
                      size: 28,
                    ),
                    onPressed: _pushIngredientToStack,
                  ),
                ],
              ),

              // Real-time staging output listing ingredients added so far
              Wrap(
                spacing: 6,
                children: _ingredientsInWorkflow.map((ing) {
                  return Chip(
                    label: Text("${ing.name} (${ing.quantity}${ing.unit})"),
                    onDeleted: () =>
                        setState(() => _ingredientsInWorkflow.remove(ing)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const Text(
                "Add Preparation Steps Sequence",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _instructionRowController,
                      decoration: const InputDecoration(
                        hintText: "Describe step details...",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 28,
                    ),
                    onPressed: _pushInstructionToStack,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ..._instructionsInWorkflow.asMap().entries.map((entry) {
                return ListTile(
                  dense: true,
                  leading: Text("${entry.key + 1}."),
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                      () => _instructionsInWorkflow.removeAt(entry.key),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _executeSubmissionPipeline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Compile & Save Recipe Structural Node",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// VIEWPORT 2: WEEKLY MEAL PLANNER INTERACTION MATRIX
// ============================================================================

class WeeklyMealPlannerViewport extends StatelessWidget {
  const WeeklyMealPlannerViewport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weekly Plan Architecture",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => globalWorkspaceState.clearEntireWeeklyPlan(),
            icon: const Icon(
              Icons.cleaning_services_rounded,
              size: 16,
              color: Colors.red,
            ),
            label: const Text(
              "Wipe Matrix",
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: globalWorkspaceState,
          builder: (context, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              itemBuilder: (context, idx) {
                final currentDay = days[idx];
                return _buildDayPlanningRowContainer(
                  currentDay,
                  theme,
                  context,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayPlanningRowContainer(
    String day,
    ThemeData theme,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Day Title Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              day.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Triple Slot Configuration Array
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: MealSlotType.values.map((slotType) {
                final associatedSlot = globalWorkspaceState.mealPlanMatrix
                    .firstWhere(
                      (m) => m.dayOfWeek == day && m.slotType == slotType,
                      orElse: () =>
                          MealPlanSlot(dayOfWeek: day, slotType: slotType),
                    );

                Recipe? pairedRecipe;
                if (associatedSlot.recipeId != null) {
                  pairedRecipe = globalWorkspaceState.allRecipes.firstWhere(
                    (r) => r.id == associatedSlot.recipeId,
                    orElse: () => const Recipe(
                      id: '',
                      title: 'Unknown Matrix Reference',
                      description: '',
                      category: CulinaryCategory.lunch,
                      ingredients: [],
                      instructions: [],
                      prepTimeMinutes: 0,
                      cookTimeMinutes: 0,
                    ),
                  );
                }

                        return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _fetchSlotColor(slotType).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          associatedSlot.slotName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _fetchSlotColor(slotType),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: pairedRecipe != null
                            ? Text(
                                pairedRecipe.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              )
                            : Text(
                                "No Recipe Assigned",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                      IconButton(
                        icon: Icon(
                          pairedRecipe != null
                              ? Icons.edit_calendar_rounded
                              : Icons.add_circle_outline_rounded,
                        ),
                        color: pairedRecipe != null
                            ? Colors.grey.shade700
                            : const Color(0xFF00A86B),
                        iconSize: 20,
                        onPressed: () => _displaySlotAssignmentSelector(
                          day,
                          slotType,
                          context,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _fetchSlotColor(MealSlotType type) {
    switch (type) {
      case MealSlotType.breakfast:
        return Colors.amber.shade800;
      case MealSlotType.lunch:
        return Colors.blue.shade700;
      case MealSlotType.dinner:
        return Colors.indigo.shade800;
    }
  }

  void _displaySlotAssignmentSelector(
    String day,
    MealSlotType slot,
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Assign Meal Target: $day (${slot.toString().split('.').last.toUpperCase()})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Option to unassign/clear slot completely
                ListTile(
                  leading: const Icon(
                    Icons.label_off_rounded,
                    color: Colors.grey,
                  ),
                  title: const Text("Clear Slot Assignment Record"),
                  onTap: () {
                    globalWorkspaceState.assignRecipeToSlot(day, slot, null);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),

                // Selectable available recipe definitions list mapping frame
                Expanded(
                  child: ListView.builder(
                    itemCount: globalWorkspaceState.allRecipes.length,
                    itemBuilder: (context, idx) {
                      final r = globalWorkspaceState.allRecipes[idx];
                      return ListTile(
                        leading: const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFF00A86B),
                        ),
                        title: Text(r.title),
                        subtitle: Text(
                          r.categoryName.toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          globalWorkspaceState.assignRecipeToSlot(
                            day,
                            slot,
                            r.id,
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// VIEWPORT 3: SMART GROCERY AGGREGATOR ENGINE
// ============================================================================

class SmartGroceryAggregatorViewport extends StatefulWidget {
  const SmartGroceryAggregatorViewport({Key? key}) : super(key: key);

  @override
  State<SmartGroceryAggregatorViewport> createState() =>
      _SmartGroceryAggregatorViewportState();
}

class _SmartGroceryAggregatorViewportState
    extends State<SmartGroceryAggregatorViewport> {
  final TextEditingController _manualItemInputController =
      TextEditingController();
  IngredientCategory _manualSelectedCategory = IngredientCategory.produce;

  @override
  void dispose() {
    _manualItemInputController.dispose();
    super.dispose();
  }

  void _dispatchManualAddition() {
    if (_manualItemInputController.text.trim().isEmpty) return;
    globalWorkspaceState.addManualGroceryItem(
      _manualItemInputController.text,
      _manualSelectedCategory,
    );
    _manualItemInputController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consolidatedMap = globalWorkspaceState.computeAggregatedGroceryList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Smart Grocery Cart",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.grey),
            tooltip: "Purge Checked Extras",
            onPressed: () => globalWorkspaceState.purgeCompletedManualItems(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick-Add Dashboard Overlay Dock for Custom Grocery Additions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualItemInputController,
                          decoration: InputDecoration(
                            hintText: "Add stray item (e.g., Milk, Foil)...",
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_rounded,
                          color: Color(0xFF00A86B),
                          size: 32,
                        ),
                        onPressed: _dispatchManualAddition,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Stray Item Department:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      DropdownButton<IngredientCategory>(
                        value: _manualSelectedCategory,
                        isDense: true,
                        items: IngredientCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.toString().split('.').last.toUpperCase(),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null)
                            setState(() => _manualSelectedCategory = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Base Core List Area showing aggregated datasets alongside dynamic metrics visualizers
            Expanded(
              child: AnimatedBuilder(
                animation: globalWorkspaceState,
                builder: (context, child) {
                  if (consolidatedMap.isEmpty &&
                      globalWorkspaceState.manualGroceryList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 72,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Grocery Manifest is Empty",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Assign structural recipes inside the Weekly Planner View to automatically generate standardized procurement lists here.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Render analytics custom gauge if active aggregated items exist
                      if (consolidatedMap.isNotEmpty) ...[
                        Text(
                          "Supermarket Department Breakdown",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 140,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CustomPaint(
                            painter: SupermarketDistributionChartPainter(
                              metricMap: consolidatedMap,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 1. Process automated relational aggregated list values block
                      if (consolidatedMap.isNotEmpty) ...[
                        Text(
                          "Auto-Compiled From Active Meal Plan",
                          style: theme.textTheme.titleMedium!.copyWith(
                            color: const Color(0xFF00A86B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...consolidatedMap.entries.map((group) {
                          return _buildSupermarketDepartmentSection(
                            group.key,
                            group.value,
                            theme,
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],

                      // 2. Process custom manual array inputs block
                      if (globalWorkspaceState
                          .manualGroceryList
                          .isNotEmpty) ...[
                        Text(
                          "Stray Non-Recipe Items Log",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: globalWorkspaceState.manualGroceryList
                                .map((item) {
                                  return CheckboxListTile(
                                    value: item.isChecked,
                                    title: Text(
                                      item.name,
                                      style: TextStyle(
                                        decoration: item.isChecked
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: item.isChecked
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.category
                                          .toString()
                                          .split('.')
                                          .last
                                          .toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    activeColor: const Color(0xFF00A86B),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (v) => globalWorkspaceState
                                        .toggleManualItemChecked(item.id),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupermarketDepartmentSection(
    IngredientCategory category,
    List<Ingredient> elements,
    ThemeData theme,
  ) {
    final departmentLabel = category.toString().split('.').last.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Text(
              departmentLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14),
            child: Column(
              children: elements.map((ing) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_rounded,
                        size: 14,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ing.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${ing.quantity % 1 == 0 ? ing.quantity.toInt() : ing.quantity.toStringAsFixed(1)} ${ing.unit}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM VISUALIZATION COMPONENT: SUPERMARKET DISTRIBUTION CHART PAINTER
// ============================================================================

class SupermarketDistributionChartPainter extends CustomPainter {
  final Map<IngredientCategory, List<Ingredient>> metricMap;

  const SupermarketDistributionChartPainter({required this.metricMap});

  @override
  void paint(Canvas canvas, Size size) {
    if (metricMap.isEmpty) return;

    // Aggregate overall raw product instance configurations
    int sumTotalItems = 0;
    metricMap.values.forEach((list) => sumTotalItems += list.length);

    final Paint slicePaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Track sequential drawing matrices dimensions parameters
    double startingXOffset = 0.0;
    final double trackWidth = size.width;
    final double trackHeight = 24.0;
    final double verticalCenteringAxisY = (size.height / 2) - (trackHeight / 2);

    int evaluationIndex = 0;

    // Draw segmented distribution row blocks representation
    metricMap.entries.forEach((entry) {
      final itemFraction = entry.value.length / sumTotalItems;
      final currentBlockWidth = trackWidth * itemFraction;

      slicePaint.color = _resolveDepartmentColorPalette(entry.key);

      // Construct segment bounds
      final blockRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          startingXOffset,
          verticalCenteringAxisY,
          currentBlockWidth,
          trackHeight,
        ),
        topLeft: evaluationIndex == 0 ? const Radius.circular(8) : Radius.zero,
        bottomLeft: evaluationIndex == 0
            ? const Radius.circular(8)
            : Radius.zero,
        topRight: evaluationIndex == metricMap.length - 1
            ? const Radius.circular(8)
            : Radius.zero,
        bottomRight: evaluationIndex == metricMap.length - 1
            ? const Radius.circular(8)
            : Radius.zero,
      );

      canvas.drawRRect(blockRect, slicePaint);

      // Render mini tracking textual legends directly below graph node layers configuration layout
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text:
              "${entry.key.toString().split('.').last.substring(0, min(3, entry.key.toString().split('.').last.length)).toUpperCase()} (${entry.value.length})",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: _resolveDepartmentColorPalette(entry.key),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          startingXOffset + 2,
          verticalCenteringAxisY + trackHeight + 8 + (evaluationIndex % 2 * 12),
        ),
      );

      startingXOffset += currentBlockWidth;
      evaluationIndex++;
    });
  }

  Color _resolveDepartmentColorPalette(IngredientCategory cat) {
    switch (cat) {
      case IngredientCategory.produce:
        return Colors.green.shade600;
      case IngredientCategory.meatSeafood:
        return Colors.red.shade600;
      case IngredientCategory.dairy:
        return Colors.blue.shade600;
      case IngredientCategory.pantry:
        return Colors.amber.shade700;
      case IngredientCategory.bakery:
        return Colors.brown.shade500;
      case IngredientCategory.spicesOil:
        return Colors.purple.shade400;
    }
  }

  @override
  bool shouldRepaint(
    covariant SupermarketDistributionChartPainter oldDelegate,
  ) => true;
}

// Extension to safely support blend fallbacks without strict dependency overheads
extension ColorBlendExtension on Color {
  static Color allBlend(Color backing, Color blending) {
    return Color.alphaBlend(blending, backing);
  }
}
