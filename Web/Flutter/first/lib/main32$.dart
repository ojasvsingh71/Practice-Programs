import 'dart:async';
import 'dart:math';
import 'dart:ui';
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
/// 1. SYSTEM INITIALIZATION & CORE RUNTIME
/// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0C10),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const EquitiesTerminalApp());
}

class EquitiesTerminalApp extends StatelessWidget {
  const EquitiesTerminalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarketStateProvider(
      child: MaterialApp(
        title: 'Equinox Terminal',
        debugShowCheckedModeBanner: false,
        theme: EquinoxTheme.darkCore,
        home: const TerminalNavigationShell(),
      ),
    );
  }
}

/// ============================================================================
/// 2. THEME & VISUAL DESIGN SYSTEM
/// ============================================================================
class EquinoxTheme {
  static const Color background = Color(0xFF0A0C10);
  static const Color surface = Color(0xFF14171F);
  static const Color surfaceLight = Color(0xFF222735);
  static const Color accent = Color(0xFF00C087); // Institutional Green
  static const Color bullGreen = Color(0xFF00C087);
  static const Color bearRed = Color(0xFFFF4D4F);
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF8B94A5);

  static ThemeData get darkCore {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0C10),
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: surfaceLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 3. HIGH-FIDELITY DATA MODELS
/// ============================================================================
class OHLC {
  final DateTime timestamp;
  double open;
  double high;
  double low;
  double close;
  double volume;

  OHLC({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0.0,
  });

  bool get isBullish => close >= open;
}

class Stock {
  final String symbol;
  final String companyName;
  final String sector;
  final double baseVolatility;
  final List<OHLC> history; // Represents daily/hourly candles

  Stock({
    required this.symbol,
    required this.companyName,
    required this.sector,
    required this.baseVolatility,
    required this.history,
  });

  double get currentPrice => history.last.close;

  double get previousClose => history.length > 1
      ? history[history.length - 2].close
      : history.last.open;

  double get absoluteChange => currentPrice - previousClose;

  double get percentChange => (absoluteChange / previousClose) * 100;
}

class Watchlist {
  final String id;
  final String name;
  final List<String> symbols;

  Watchlist({required this.id, required this.name, required this.symbols});
}

class PriceAlert {
  final String id;
  final String symbol;
  final double targetPrice;
  final bool triggerOnCrossAbove;
  bool isActive;

  PriceAlert({
    required this.id,
    required this.symbol,
    required this.targetPrice,
    required this.triggerOnCrossAbove,
    this.isActive = true,
  });
}

/// ============================================================================
/// 4. REPOSITORIES & MARKET SEEDING
/// ============================================================================
class MarketDataSeeder {
  static final Random _rng = Random();

  static List<Stock> seedMarket() {
    return [
      _generateStockProfile(
        'NVDA',
        'NVIDIA Corporation',
        'Semiconductors',
        0.045,
        125.40,
      ),
      _generateStockProfile(
        'AAPL',
        'Apple Inc.',
        'Consumer Electronics',
        0.015,
        189.20,
      ),
      _generateStockProfile(
        'MSFT',
        'Microsoft Corp.',
        'Software',
        0.018,
        415.50,
      ),
      _generateStockProfile(
        'TSLA',
        'Tesla, Inc.',
        'Auto Manufacturers',
        0.052,
        175.80,
      ),
      _generateStockProfile(
        'AMD',
        'Advanced Micro Devices',
        'Semiconductors',
        0.048,
        164.20,
      ),
      _generateStockProfile(
        'AMZN',
        'Amazon.com, Inc.',
        'Retail',
        0.022,
        182.10,
      ),
      _generateStockProfile(
        'META',
        'Meta Platforms',
        'Internet',
        0.028,
        495.00,
      ),
      _generateStockProfile(
        'GOOGL',
        'Alphabet Inc.',
        'Internet',
        0.019,
        174.30,
      ),
      _generateStockProfile(
        'PLTR',
        'Palantir Technologies',
        'Software',
        0.060,
        24.15,
      ),
      _generateStockProfile(
        'COIN',
        'Coinbase Global',
        'Financials',
        0.075,
        245.80,
      ),
    ];
  }

  static Stock _generateStockProfile(
    String symbol,
    String name,
    String sector,
    double volatility,
    double anchorPrice,
  ) {
    List<OHLC> mockHistory = [];
    double currentP = anchorPrice * 0.85; // Start 15% lower 60 periods ago
    DateTime baseDate = DateTime.now().subtract(const Duration(days: 60));

    for (int i = 0; i < 60; i++) {
      // Standard normal distribution approximation via Box-Muller transform
      double u1 = 1.0 - _rng.nextDouble();
      double u2 = 1.0 - _rng.nextDouble();
      double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

      // Geometric Brownian Motion step formulation
      double drift = 0.0005; // Slight upward bias
      double step =
          currentP * exp((drift - 0.5 * pow(volatility, 2)) + volatility * z0);

      double open = currentP;
      double close = step;
      double high = max(open, close) * (1 + _rng.nextDouble() * 0.02);
      double low = min(open, close) * (1 - _rng.nextDouble() * 0.02);

      mockHistory.add(
        OHLC(
          timestamp: baseDate.add(Duration(days: i)),
          open: open,
          high: high,
          low: low,
          close: close,
          volume: 1000000 + _rng.nextDouble() * 5000000,
        ),
      );

      currentP = close;
    }

    // Override the final close to match the requested anchor exactly
    mockHistory.last.close = anchorPrice;

    return Stock(
      symbol: symbol,
      companyName: name,
      sector: sector,
      baseVolatility: volatility,
      history: mockHistory,
    );
  }
}

/// ============================================================================
/// 5. CENTRAL STATE MANAGEMENT & ENGINE CONTROLLER
/// ============================================================================
class EquitiesStateController extends ChangeNotifier {
  List<Stock> _market = [];
  List<Watchlist> _watchlists = [];
  List<PriceAlert> _alerts = [];
  Timer? _marketClockTimer;
  final Random _rng = Random();

  final StreamController<String> _notificationBroker =
      StreamController<String>.broadcast();

  EquitiesStateController() {
    _market = MarketDataSeeder.seedMarket();
    _seedDefaultData();
    _engageMarketSimulationEngine();
  }

  List<Stock> get market => _market;
  List<Watchlist> get watchlists => _watchlists;
  List<PriceAlert> get alerts => _alerts;
  Stream<String> get notificationStream => _notificationBroker.stream;

  void _seedDefaultData() {
    _watchlists.add(
      Watchlist(
        id: 'wl_01',
        name: 'Mega Cap Tech',
        symbols: ['AAPL', 'MSFT', 'GOOGL', 'AMZN'],
      ),
    );
    _watchlists.add(
      Watchlist(
        id: 'wl_02',
        name: 'High Volatility',
        symbols: ['NVDA', 'TSLA', 'PLTR', 'COIN'],
      ),
    );

    // Seed some mock alerts
    _alerts.add(
      PriceAlert(
        id: 'al_01',
        symbol: 'NVDA',
        targetPrice: 130.0,
        triggerOnCrossAbove: true,
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// STOCHASTIC SIMULATION ENGINE
  /// --------------------------------------------------------------------------
  void _engageMarketSimulationEngine() {
    // Tick every 1.5 seconds to simulate live L2 order book execution
    _marketClockTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      bool marketAltered = false;

      for (int i = 0; i < _market.length; i++) {
        Stock asset = _market[i];

        // Only 40% chance a specific stock ticks on this exact engine loop to simulate varying liquidity
        if (_rng.nextDouble() > 0.4) continue;

        OHLC latestCandle = asset.history.last;

        // Micro-GBM step for intraday volatility
        double u1 = 1.0 - _rng.nextDouble();
        double u2 = 1.0 - _rng.nextDouble();
        double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

        // Micro volatility is scaled down from base (daily) volatility
        double microVol = asset.baseVolatility * 0.15;
        double newClose =
            latestCandle.close * exp(-0.5 * pow(microVol, 2) + microVol * z0);

        // Update the current active candle dynamically
        latestCandle.close = newClose;
        if (newClose > latestCandle.high) latestCandle.high = newClose;
        if (newClose < latestCandle.low) latestCandle.low = newClose;
        latestCandle.volume += _rng.nextDouble() * 5000;

        _evaluateAlertingMatrix(asset.symbol, latestCandle.open, newClose);

        marketAltered = true;
      }

      if (marketAltered) {
        notifyListeners();
      }
    });
  }

  /// --------------------------------------------------------------------------
  /// ALERT ROUTING MATRIX
  /// --------------------------------------------------------------------------
  void _evaluateAlertingMatrix(
    String symbol,
    double oldPrice,
    double newPrice,
  ) {
    for (var alert in _alerts.where((a) => a.symbol == symbol && a.isActive)) {
      bool triggered = false;
      if (alert.triggerOnCrossAbove &&
          oldPrice < alert.targetPrice &&
          newPrice >= alert.targetPrice) {
        triggered = true;
        _notificationBroker.add(
          '📈 ALERT: $symbol crossed above \$${alert.targetPrice.toStringAsFixed(2)}',
        );
      } else if (!alert.triggerOnCrossAbove &&
          oldPrice > alert.targetPrice &&
          newPrice <= alert.targetPrice) {
        triggered = true;
        _notificationBroker.add(
          '📉 ALERT: $symbol crossed below \$${alert.targetPrice.toStringAsFixed(2)}',
        );
      }

      if (triggered) {
        alert.isActive = false; // One-shot trigger
      }
    }
  }

  /// --------------------------------------------------------------------------
  /// EXPOSED MUTATION APIs
  /// --------------------------------------------------------------------------
  void createWatchlist(String name) {
    _watchlists.add(
      Watchlist(
        id: 'wl_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        symbols: [],
      ),
    );
    notifyListeners();
  }

  void toggleSymbolInWatchlist(String watchlistId, String symbol) {
    final wl = _watchlists.firstWhere((w) => w.id == watchlistId);
    if (wl.symbols.contains(symbol)) {
      wl.symbols.remove(symbol);
    } else {
      wl.symbols.add(symbol);
    }
    notifyListeners();
  }

  void registerPriceAlert(String symbol, double targetPrice, bool crossAbove) {
    _alerts.add(
      PriceAlert(
        id: 'al_${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        targetPrice: targetPrice,
        triggerOnCrossAbove: crossAbove,
      ),
    );
    notifyListeners();
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _marketClockTimer?.cancel();
    _notificationBroker.close();
    super.dispose();
  }
}

/// Dependency Injection Wrapper
class MarketStateProvider extends StatefulWidget {
  final Widget child;
  const MarketStateProvider({Key? key, required this.child}) : super(key: key);

  static EquitiesStateController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedMarketState>()!
        .controller;
  }

  @override
  _MarketStateProviderState createState() => _MarketStateProviderState();
}

class _MarketStateProviderState extends State<MarketStateProvider> {
  late EquitiesStateController _controller;
  StreamSubscription? _alertSubscription;

  @override
  void initState() {
    super.initState();
    _controller = EquitiesStateController();

    _alertSubscription = _controller.notificationStream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EquinoxTheme.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            duration: const Duration(seconds: 4),
            content: Text(
              message,
              style: const TextStyle(
                color: EquinoxTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _InheritedMarketState(
          controller: _controller,
          child: widget.child,
        );
      },
    );
  }
}

class _InheritedMarketState extends InheritedWidget {
  final EquitiesStateController controller;
  const _InheritedMarketState({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);
  @override
  bool updateShouldNotify(_InheritedMarketState oldWidget) => true;
}

/// ============================================================================
/// 6. NAVIGATION SHELL
/// ============================================================================
class TerminalNavigationShell extends StatefulWidget {
  const TerminalNavigationShell({Key? key}) : super(key: key);

  @override
  _TerminalNavigationShellState createState() =>
      _TerminalNavigationShellState();
}

class _TerminalNavigationShellState extends State<TerminalNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const WatchlistDashboardScreen(),
    const MarketScreenerScreen(),
    const AlertsManagerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _views),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Terminal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            activeIcon: Icon(Icons.travel_explore),
            label: 'Screener',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 7. WATCHLIST DASHBOARD MODULE
/// ============================================================================
class WatchlistDashboardScreen extends StatefulWidget {
  const WatchlistDashboardScreen({Key? key}) : super(key: key);

  @override
  _WatchlistDashboardScreenState createState() =>
      _WatchlistDashboardScreenState();
}

class _WatchlistDashboardScreenState extends State<WatchlistDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final watchlists = MarketStateProvider.of(context).watchlists;
    _tabController = TabController(length: watchlists.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = MarketStateProvider.of(context);
    final watchlists = controller.watchlists;

    if (_tabController.length != watchlists.length) {
      _tabController.dispose();
      _tabController = TabController(length: watchlists.length, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equinox'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: EquinoxTheme.textPrimary,
            ),
            onPressed: () => _showCreateWatchlistModal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: EquinoxTheme.accent,
          indicatorWeight: 3,
          labelColor: EquinoxTheme.textPrimary,
          unselectedLabelColor: EquinoxTheme.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: watchlists
              .map((wl) => Tab(text: wl.name.toUpperCase()))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: watchlists.map((wl) {
          final mappedStocks = wl.symbols
              .map(
                (sym) => controller.market.firstWhere((s) => s.symbol == sym),
              )
              .toList();

          if (mappedStocks.isEmpty) {
            return const Center(
              child: Text(
                'No assets configured in this module.',
                style: TextStyle(color: EquinoxTheme.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: mappedStocks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildAssetTile(context, mappedStocks[index]);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssetTile(BuildContext context, Stock stock) {
    final isBull = stock.percentChange >= 0;
    final color = isBull ? EquinoxTheme.bullGreen : EquinoxTheme.bearRed;

    // Extract last 20 close prices for the micro sparkline
    final sparklineData = stock.history
        .skip(stock.history.length - 20)
        .map((c) => c.close)
        .toList();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StockDetailScreen(symbol: stock.symbol),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EquinoxTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EquinoxTheme.surfaceLight, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stock.companyName,
                    style: const TextStyle(
                      color: EquinoxTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 35,
                child: CustomPaint(
                  painter: SparklinePainter(
                    data: sparklineData,
                    color: color.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stock.currentPrice.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isBull ? '+' : ''}${stock.percentChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateWatchlistModal(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EquinoxTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Provision Watchlist',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Value Stocks, AI Boom',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: EquinoxTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                MarketStateProvider.of(
                  context,
                ).createWatchlist(textController.text);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'COMMIT',
              style: TextStyle(
                color: EquinoxTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 8. MARKET SCREENER MODULE
/// ============================================================================
class MarketScreenerScreen extends StatefulWidget {
  const MarketScreenerScreen({Key? key}) : super(key: key);

  @override
  _MarketScreenerScreenState createState() => _MarketScreenerScreenState();
}

class _MarketScreenerScreenState extends State<MarketScreenerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = MarketStateProvider.of(context);

    // Complex mapping and filtration pipeline
    final filteredAssets = controller.market.where((s) {
      return s.symbol.toLowerCase().contains(_query.toLowerCase()) ||
          s.companyName.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    // Sort by absolute volume/volatility surrogate (simulated by percent change magnitude)
    filteredAssets.sort(
      (a, b) => b.percentChange.abs().compareTo(a.percentChange.abs()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Screener'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _query = val),
              decoration: const InputDecoration(
                hintText: 'Filter by symbol or corporation...',
                prefixIcon: Icon(
                  Icons.search,
                  color: EquinoxTheme.textSecondary,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAssets.length,
        separatorBuilder: (_, __) =>
            const Divider(color: EquinoxTheme.surfaceLight, height: 1),
        itemBuilder: (context, index) {
          final stock = filteredAssets[index];
          final isBull = stock.percentChange >= 0;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockDetailScreen(symbol: stock.symbol),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: EquinoxTheme.surfaceLight,
              child: Text(
                stock.symbol[0],
                style: const TextStyle(
                  color: EquinoxTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              stock.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              stock.sector,
              style: const TextStyle(
                color: EquinoxTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stock.currentPrice.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${isBull ? '+' : ''}${stock.percentChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isBull
                        ? EquinoxTheme.bullGreen
                        : EquinoxTheme.bearRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================================
/// 9. HIGH-FIDELITY ASSET DETAIL & CANDLESTICK CANVAS
/// ============================================================================
class StockDetailScreen extends StatelessWidget {
  final String symbol;
  const StockDetailScreen({Key? key, required this.symbol}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = MarketStateProvider.of(context);
    final stock = controller.market.firstWhere((s) => s.symbol == symbol);
    final isBull = stock.percentChange >= 0;
    final themeColor = isBull ? EquinoxTheme.bullGreen : EquinoxTheme.bearRed;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () => _showAddToWatchlistSheet(context, stock),
          ),
          IconButton(
            icon: const Icon(Icons.notification_add_outlined),
            onPressed: () => _showAddAlertSheet(context, stock),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Matrix
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    stock.companyName,
                    style: const TextStyle(
                      color: EquinoxTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        stock.currentPrice.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          '${isBull ? '+' : ''}${stock.absoluteChange.toStringAsFixed(2)} (${stock.percentChange.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Custom Hardware-Accelerated Candlestick Graph
            Container(
              height: 300,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: CustomPaint(
                painter: CandlestickPainter(ohlcData: stock.history),
              ),
            ),

            const SizedBox(height: 24),
            // Market Statistics Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FUNDAMENTAL MATRIX',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: EquinoxTheme.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBlock(
                          'Open',
                          stock.history.last.open.toStringAsFixed(2),
                        ),
                      ),
                      Expanded(
                        child: _buildStatBlock(
                          'High',
                          stock.history.last.high.toStringAsFixed(2),
                        ),
                      ),
                      Expanded(
                        child: _buildStatBlock(
                          'Low',
                          stock.history.last.low.toStringAsFixed(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBlock(
                          'Vol (sim)',
                          _formatLargeNumber(stock.history.last.volume),
                        ),
                      ),
                      Expanded(
                        child: _buildStatBlock(
                          'Implied Vol',
                          '${(stock.baseVolatility * 100).toStringAsFixed(1)}%',
                        ),
                      ),
                      Expanded(child: _buildStatBlock('Sector', stock.sector)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: EquinoxTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: EquinoxTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatLargeNumber(double num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(2)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }

  void _showAddToWatchlistSheet(BuildContext context, Stock stock) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EquinoxTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final controller = MarketStateProvider.of(context);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Add ${stock.symbol} to Watchlist',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...controller.watchlists.map((wl) {
                    final isInList = wl.symbols.contains(stock.symbol);
                    return CheckboxListTile(
                      activeColor: EquinoxTheme.accent,
                      checkColor: EquinoxTheme.background,
                      title: Text(
                        wl.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: isInList,
                      onChanged: (val) {
                        controller.toggleSymbolInWatchlist(wl.id, stock.symbol);
                        setModalState(() {}); // Force redraw modal
                      },
                    );
                  }).toList(),
                  if (controller.watchlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16,
                      ),
                      child: Text(
                        'No watchlists available. Create one first.',
                        style: TextStyle(color: EquinoxTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAlertSheet(BuildContext context, Stock stock) {
    final textController = TextEditingController(
      text: stock.currentPrice.toStringAsFixed(2),
    );
    bool crossAbove = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EquinoxTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provision Radar Alert: ${stock.symbol}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Target Strike Price',
                    style: TextStyle(
                      color: EquinoxTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(prefixText: '\$ '),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => crossAbove = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                                color: crossAbove
                                  ? EquinoxTheme.bullGreen.withOpacity(0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: crossAbove
                                    ? EquinoxTheme.bullGreen
                                    : EquinoxTheme.surfaceLight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Crosses Above',
                              style: TextStyle(
                                color: crossAbove
                                    ? EquinoxTheme.bullGreen
                                    : EquinoxTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => crossAbove = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                                color: !crossAbove
                                  ? EquinoxTheme.bearRed.withOpacity(0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: !crossAbove
                                    ? EquinoxTheme.bearRed
                                    : EquinoxTheme.surfaceLight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Crosses Below',
                              style: TextStyle(
                                color: !crossAbove
                                    ? EquinoxTheme.bearRed
                                    : EquinoxTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EquinoxTheme.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final val = double.tryParse(textController.text);
                        if (val != null && val > 0) {
                          MarketStateProvider.of(
                            context,
                          ).registerPriceAlert(stock.symbol, val, crossAbove);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Radar node synthesized successfully.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'ENGAGE ALERT LISTENER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: EquinoxTheme.background,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// ============================================================================
/// 10. ALERTS MANAGEMENT MODULE
/// ============================================================================
class AlertsManagerScreen extends StatelessWidget {
  const AlertsManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = MarketStateProvider.of(context);
    final activeAlerts = controller.alerts;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Radar Nodes')),
      body: activeAlerts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, size: 48, color: EquinoxTheme.surfaceLight),
                  SizedBox(height: 16),
                  Text(
                    'No active price alerts deployed.',
                    style: TextStyle(color: EquinoxTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeAlerts.length,
              itemBuilder: (context, index) {
                final alert = activeAlerts[index];
                final stock = controller.market.firstWhere(
                  (s) => s.symbol == alert.symbol,
                );
                final currentDist = alert.targetPrice - stock.currentPrice;
                final distPercent =
                    (currentDist.abs() / stock.currentPrice) * 100;

                return Card(
                  color: EquinoxTheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: EquinoxTheme.surfaceLight,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      alert.triggerOnCrossAbove
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: alert.triggerOnCrossAbove
                          ? EquinoxTheme.bullGreen
                          : EquinoxTheme.bearRed,
                    ),
                    title: Text(
                      '${alert.symbol} Target: \$${alert.targetPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Currently \$${stock.currentPrice.toStringAsFixed(2)} (${distPercent.toStringAsFixed(1)}% away)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: alert.isActive
                              ? EquinoxTheme.accent.withOpacity(0.2)
                                : EquinoxTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.isActive ? 'LISTENING' : 'TRIGGERED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: alert.isActive
                                  ? EquinoxTheme.accent
                                  : EquinoxTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: EquinoxTheme.textSecondary,
                          ),
                          onPressed: () => controller.removeAlert(alert.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// ============================================================================
/// 11. LOW-LEVEL CUSTOM RENDERING ENGINES
/// ============================================================================

class CandlestickPainter extends CustomPainter {
  final List<OHLC> ohlcData;

  CandlestickPainter({required this.ohlcData});

  @override
  void paint(Canvas canvas, Size size) {
    if (ohlcData.isEmpty) return;

    // Define coordinate bounds
    double maxPrice = ohlcData.map((e) => e.high).reduce(max);
    double minPrice = ohlcData.map((e) => e.low).reduce(min);
    double priceRange = maxPrice - minPrice;
    if (priceRange == 0) priceRange = 1.0;

    // Scaling factors
    // Leave a 10% padding on top and bottom of the chart
    double paddedMin = minPrice - (priceRange * 0.1);
    double paddedMax = maxPrice + (priceRange * 0.1);
    double paddedRange = paddedMax - paddedMin;

    double candleWidth = size.width / ohlcData.length;
    double bodyWidth =
        candleWidth * 0.7; // 70% width for the body, 30% for spacing

    Paint bullPaint = Paint()
      ..color = EquinoxTheme.bullGreen
      ..style = PaintingStyle.fill;

    Paint bearPaint = Paint()
      ..color = EquinoxTheme.bearRed
      ..style = PaintingStyle.fill;

    Paint wickPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < ohlcData.length; i++) {
      OHLC candle = ohlcData[i];
      bool isBull = candle.isBullish;
      Paint currentPaint = isBull ? bullPaint : bearPaint;
      wickPaint.color = currentPaint.color;

      // X coordinates
      double centerX = (i * candleWidth) + (candleWidth / 2);
      double leftX = centerX - (bodyWidth / 2);
      double rightX = centerX + (bodyWidth / 2);

      // Y coordinates (Inverted because Canvas Y increases downwards)
      double highY =
          size.height - ((candle.high - paddedMin) / paddedRange * size.height);
      double lowY =
          size.height - ((candle.low - paddedMin) / paddedRange * size.height);
      double openY =
          size.height - ((candle.open - paddedMin) / paddedRange * size.height);
      double closeY =
          size.height -
          ((candle.close - paddedMin) / paddedRange * size.height);

      double bodyTopY = min(openY, closeY);
      double bodyBottomY = max(openY, closeY);

      // Prevent 0-height bodies (Doji)
      if (bodyBottomY - bodyTopY < 1.0) {
        bodyBottomY = bodyTopY + 1.0;
      }

      // Draw Wick
      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), wickPaint);

      // Draw Body
      canvas.drawRect(
        Rect.fromLTRB(leftX, bodyTopY, rightX, bodyBottomY),
        currentPaint,
      );
    }

    // Draw current price line
    double currentP = ohlcData.last.close;
    double currentY =
        size.height - ((currentP - paddedMin) / paddedRange * size.height);

    Paint currentLinePaint = Paint()
      ..color =
          (ohlcData.last.isBullish
                  ? EquinoxTheme.bullGreen
                  : EquinoxTheme.bearRed)
              .withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Create a dashed line effect natively using a path
    Path dashPath = Path();
    double dashWidth = 5;
    double dashSpace = 5;
    double startX = 0;
    while (startX < size.width) {
      dashPath.moveTo(startX, currentY);
      dashPath.lineTo(startX + dashWidth, currentY);
      startX += dashWidth + dashSpace;
    }
    canvas.drawPath(dashPath, currentLinePaint);
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) => true; // Constant engine repaint mapping
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    double maxVal = data.reduce(max);
    double minVal = data.reduce(min);
    double range = maxVal - minVal;
    if (range == 0) range = 1.0;

    double xStep = size.width / (data.length - 1);

    Path path = Path();
    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      // Normalize and invert Y
      double normalizedY = (data[i] - minVal) / range;
      double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Implement subtle bezier smoothing for aesthetic mapping
        double prevX = (i - 1) * xStep;
        double prevY =
            size.height - (((data[i - 1] - minVal) / range) * size.height);
        double cpX1 = prevX + (xStep / 2);
        double cpY1 = prevY;
        double cpX2 = prevX + (xStep / 2);
        double cpY2 = y;
        path.cubicTo(cpX1, cpY1, cpX2, cpY2, x, y);
      }
    }

    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}
