import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// 1. MAIN SYSTEM INITIALIZATION
/// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0E12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CryptoTrackerApp());
}

class CryptoTrackerApp extends StatelessWidget {
  const CryptoTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CryptoStateProvider(
      child: MaterialApp(
        title: 'Aegis Crypto Portfolio',
        debugShowCheckedModeBanner: false,
        theme: CryptoTheme.darkCore,
        home: const AppNavigationShell(),
      ),
    );
  }
}

/// ============================================================================
/// 2. CORE SYSTEM ARCHITECTURE & THEME
/// ============================================================================
class CryptoTheme {
  static const Color background = Color(0xFF0D0E12);
  static const Color surface = Color(0xFF161820);
  static const Color surfaceLight = Color(0xFF222533);
  static const Color accent = Color(0xFF3861FB);
  static const Color cryptoGreen = Color(0xFF16C784);
  static const Color cryptoRed = Color(0xFFEA3943);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF858EA2);

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
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D0E12),
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cryptoRed, width: 1.5),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        background: background,
        error: cryptoRed,
      ),
    );
  }
}

/// ============================================================================
/// 3. HIGH-FIDELITY COMPREHENSIVE DATA MODELS
/// ============================================================================
enum TransactionType { buy, sell }

class Coin {
  final String id;
  final String name;
  final String symbol;
  double currentPrice;
  double priceChange24h;
  double percentChange24h;
  final List<double> history7d;
  final Color marketColor;

  Coin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.currentPrice,
    required this.priceChange24h,
    required this.percentChange24h,
    required this.history7d,
    required this.marketColor,
  });

  Coin copyWith({
    double? price,
    double? change24h,
    double? pctChange24h,
    List<double>? hist,
  }) {
    return Coin(
      id: id,
      name: name,
      symbol: symbol,
      currentPrice: price ?? currentPrice,
      priceChange24h: change24h ?? priceChange24h,
      percentChange24h: pctChange24h ?? percentChange24h,
      history7d: hist ?? history7d,
      marketColor: marketColor,
    );
  }
}

class Transaction {
  final String id;
  final String coinId;
  final TransactionType type;
  final double amount;
  final double priceAtTransaction;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.coinId,
    required this.type,
    required this.amount,
    required this.priceAtTransaction,
    required this.timestamp,
  });
}

class PortfolioAsset {
  final Coin coin;
  final double totalQuantity;
  final double totalCostBasis;

  PortfolioAsset({
    required this.coin,
    required this.totalQuantity,
    required this.totalCostBasis,
  });

  double get currentHoldingValue => totalQuantity * coin.currentPrice;
  double get totalProfitLoss => currentHoldingValue - totalCostBasis;
  double get profitLossPercentage =>
      totalCostBasis == 0 ? 0.0 : (totalProfitLoss / totalCostBasis) * 100;
  double get averageBuyPrice =>
      totalQuantity == 0 ? 0.0 : totalCostBasis / totalQuantity;
}

class VolatilityAlert {
  final String id;
  final String coinId;
  final double thresholdPercentage;
  final bool alertOnDrop;
  bool isActive;

  VolatilityAlert({
    required this.id,
    required this.coinId,
    required this.thresholdPercentage,
    required this.alertOnDrop,
    this.isActive = true,
  });
}

/// ============================================================================
/// 4. REPOSITORIES & INTERNAL SYSTEM SEED DATA
/// ============================================================================
class MarketSeedRepository {
  static List<Coin> generateMarketData() {
    final Random rand = Random();
    List<Map<String, dynamic>> rawDefinitions = [
      {
        'id': 'btc',
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'price': 64250.0,
        'color': const Color(0xFFF7931A),
      },
      {
        'id': 'eth',
        'name': 'Ethereum',
        'symbol': 'ETH',
        'price': 3450.0,
        'color': const Color(0xFF627EEA),
      },
      {
        'id': 'sol',
        'name': 'Solana',
        'symbol': 'SOL',
        'price': 142.25,
        'color': const Color(0xFF14F195),
      },
      {
        'id': 'ada',
        'name': 'Cardano',
        'symbol': 'ADA',
        'price': 0.48,
        'color': const Color(0xFF0033AD),
      },
      {
        'id': 'dot',
        'name': 'Polkadot',
        'symbol': 'DOT',
        'price': 6.20,
        'color': const Color(0xFFE6007A),
      },
      {
        'id': 'link',
        'name': 'Chainlink',
        'symbol': 'LINK',
        'price': 15.75,
        'color': const Color(0xFF375BD2),
      },
      {
        'id': 'avax',
        'name': 'Avalanche',
        'symbol': 'AVAX',
        'price': 28.40,
        'color': const Color(0xFFE84142),
      },
      {
        'id': 'matic',
        'name': 'Polygon',
        'symbol': 'MATIC',
        'price': 0.68,
        'color': const Color(0xFF8247E5),
      },
      {
        'id': 'atom',
        'name': 'Cosmos',
        'symbol': 'ATOM',
        'price': 8.10,
        'color': const Color(0xFF2E3148),
      },
      {
        'id': 'uni',
        'name': 'Uniswap',
        'symbol': 'UNI',
        'price': 7.95,
        'color': const Color(0xFFFF007A),
      },
    ];

    return rawDefinitions.map((def) {
      double basePrice = def['price'];
      List<double> history = [];
      double trackingPrice = basePrice * 0.92;
      for (int i = 0; i < 30; i++) {
        trackingPrice =
            trackingPrice * (1.0 + (rand.nextDouble() * 0.06 - 0.029));
        history.add(trackingPrice);
      }
      history.add(basePrice);

      double prev24hPrice = history[history.length - 5];
      double rawChange = basePrice - prev24hPrice;
      double pctChange = (rawChange / prev24hPrice) * 100;

      return Coin(
        id: def['id'],
        name: def['name'],
        symbol: def['symbol'],
        currentPrice: basePrice,
        priceChange24h: rawChange,
        percentChange24h: pctChange,
        history7d: history,
        marketColor: def['color'],
      );
    }).toList();
  }

  static List<Transaction> generateMockLedger() {
    return [
      Transaction(
        id: 'tx_01',
        coinId: 'btc',
        type: TransactionType.buy,
        amount: 0.45,
        priceAtTransaction: 61200.0,
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Transaction(
        id: 'tx_02',
        coinId: 'eth',
        type: TransactionType.buy,
        amount: 2.5,
        priceAtTransaction: 3100.0,
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Transaction(
        id: 'tx_03',
        coinId: 'sol',
        type: TransactionType.buy,
        amount: 15.0,
        priceAtTransaction: 130.0,
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Transaction(
        id: 'tx_04',
        coinId: 'eth',
        type: TransactionType.sell,
        amount: 0.5,
        priceAtTransaction: 3500.0,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}

/// ============================================================================
/// 5. CENTRAL STATE MANAGEMENT & ENGINE CONTROLLER
/// ============================================================================
class CryptoPortfolioController extends ChangeNotifier {
  List<Coin> _marketCoins = [];
  List<Transaction> _transactionLedger = [];
  List<VolatilityAlert> _activeAlerts = [];
  Timer? _volatilityLoopTimer;
  final Random _randomEngine = Random();

  // Internal visual notification broker queue
  final StreamController<String> _alertStreamBroker =
      StreamController<String>.broadcast();

  CryptoPortfolioController() {
    _marketCoins = MarketSeedRepository.generateMarketData();
    _transactionLedger = MarketSeedRepository.generateMockLedger();
    _seedDefaultAlertingThresholds();
    _startSimulatedVolatilityEngine();
  }

  // Getters
  List<Coin> get marketCoins => _marketCoins;
  List<Transaction> get transactions => _transactionLedger;
  List<VolatilityAlert> get alerts => _activeAlerts;
  Stream<String> get alertStream => _alertStreamBroker.stream;

  List<PortfolioAsset> get portfolioAssets {
    Map<String, List<Transaction>> structuralMap = {};
    for (var tx in _transactionLedger) {
      structuralMap.putIfAbsent(tx.coinId, () => []).add(tx);
    }

    List<PortfolioAsset> consolidatedAssets = [];

    structuralMap.forEach((coinId, txList) {
      final coinLookup = _marketCoins.firstWhere(
        (element) => element.id == coinId,
        orElse: () => Coin(
          id: 'err',
          name: 'Unknown',
          symbol: '???',
          currentPrice: 0.0,
          priceChange24h: 0.0,
          percentChange24h: 0.0,
          history7d: [0.0],
          marketColor: Colors.grey,
        ),
      );

      if (coinLookup.id == 'err') return;

      double netQuantity = 0.0;
      double aggregateCostBasis = 0.0;

      // Dynamic calculation engine mapping internal transaction histories
      for (var tx in txList) {
        if (tx.type == TransactionType.buy) {
          netQuantity += tx.amount;
          aggregateCostBasis += (tx.amount * tx.priceAtTransaction);
        } else {
          // Accounting standard: Reducing asset via average cost reduction method
          double averagePriceBeforeSell = netQuantity == 0
              ? 0
              : aggregateCostBasis / netQuantity;
          netQuantity -= tx.amount;
          aggregateCostBasis -= (tx.amount * averagePriceBeforeSell);
          if (netQuantity < 0) netQuantity = 0;
          if (aggregateCostBasis < 0) aggregateCostBasis = 0;
        }
      }

      if (netQuantity > 0) {
        consolidatedAssets.add(
          PortfolioAsset(
            coin: coinLookup,
            totalQuantity: netQuantity,
            totalCostBasis: aggregateCostBasis,
          ),
        );
      }
    });

    return consolidatedAssets;
  }

  double get totalPortfolioValue {
    double runningValue = 0.0;
    for (var asset in portfolioAssets) {
      runningValue += asset.currentHoldingValue;
    }
    return runningValue;
  }

  double get totalCostBasis {
    double runningBasis = 0.0;
    for (var asset in portfolioAssets) {
      runningBasis += asset.totalCostBasis;
    }
    return runningBasis;
  }

  double get aggregateProfitLoss => totalPortfolioValue - totalCostBasis;

  double get aggregateProfitLossPercentage {
    double basis = totalCostBasis;
    if (basis == 0) return 0.0;
    return (aggregateProfitLoss / basis) * 100;
  }

  /// --------------------------------------------------------------------------
  /// TRANSACTION OPERATIONS
  /// --------------------------------------------------------------------------
  void executeTransaction({
    required String coinId,
    required TransactionType type,
    required double amount,
    required double executingPrice,
  }) {
    final newTx = Transaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      coinId: coinId,
      type: type,
      amount: amount,
      priceAtTransaction: executingPrice,
      timestamp: DateTime.now(),
    );

    _transactionLedger.insert(0, newTx);
    notifyListeners();
  }

  void purgeTransaction(String txId) {
    _transactionLedger.removeWhere((tx) => tx.id == txId);
    notifyListeners();
  }

  /// --------------------------------------------------------------------------
  /// RISK & VOLATILITY WARNING MECHANICS
  /// --------------------------------------------------------------------------
  void configureAlert(String coinId, double threshold, bool notifyOnDrop) {
    _activeAlerts.add(
      VolatilityAlert(
        id: 'alt_${DateTime.now().microsecondsSinceEpoch}',
        coinId: coinId,
        thresholdPercentage: threshold,
        alertOnDrop: notifyOnDrop,
      ),
    );
    notifyListeners();
  }

  void toggleAlertStatus(String alertId) {
    int targetIdx = _activeAlerts.indexWhere((a) => a.id == alertId);
    if (targetIdx != -1) {
      _activeAlerts[targetIdx].isActive = !_activeAlerts[targetIdx].isActive;
      notifyListeners();
    }
  }

  void removeAlert(String alertId) {
    _activeAlerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  void _seedDefaultAlertingThresholds() {
    _activeAlerts.add(
      VolatilityAlert(
        id: 'def_alt_1',
        coinId: 'btc',
        thresholdPercentage: 1.5,
        alertOnDrop: false,
      ),
    );
    _activeAlerts.add(
      VolatilityAlert(
        id: 'def_alt_2',
        coinId: 'eth',
        thresholdPercentage: 2.0,
        alertOnDrop: true,
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// ENGINE SIMULATOR (Background execution loop via internal ticking engine)
  /// --------------------------------------------------------------------------
  void _startSimulatedVolatilityEngine() {
    _volatilityLoopTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      bool executionStateModified = false;

      _marketCoins = _marketCoins.map((asset) {
        // High frequency micro fluctuation engine simulation bounds (-2.2% to +2.5%)
        double randomStepPercent = (_randomEngine.nextDouble() * 0.047) - 0.022;

        // Inject a 7% probability chance macro spike event
        if (_randomEngine.nextDouble() < 0.07) {
          randomStepPercent =
              (_randomEngine.nextBool() ? 1.0 : -1.0) *
              (0.03 + _randomEngine.nextDouble() * 0.045);
        }

        double structuralOldPrice = asset.currentPrice;
        double structuralNewPrice =
            structuralOldPrice * (1.0 + randomStepPercent);
        if (structuralNewPrice < 0.001) structuralNewPrice = 0.001;

        double delta24h =
            asset.priceChange24h + (structuralNewPrice - structuralOldPrice);
        double baselinePrice = structuralNewPrice - delta24h;
        double pctChange24h = baselinePrice == 0
            ? 0.0
            : (delta24h / baselinePrice) * 100;

        List<double> revisedHist = List.from(asset.history7d);
        revisedHist.removeAt(0);
        revisedHist.add(structuralNewPrice);

        // Evaluate active conditions for tracking metrics alert configuration limits
        _evaluateSystemAlertingLimits(
          asset.id,
          randomStepPercent * 100,
          structuralNewPrice,
          asset.symbol,
        );

        executionStateModified = true;
        return asset.copyWith(
          price: structuralNewPrice,
          change24h: delta24h,
          pctChange24h: pctChange24h,
          hist: revisedHist,
        );
      }).toList();

      if (executionStateModified) {
        notifyListeners();
      }
    });
  }

  void _evaluateSystemAlertingLimits(
    String coinId,
    double instantDeltaPercentage,
    double targetPrice,
    String label,
  ) {
    for (var systemAlert in _activeAlerts) {
      if (systemAlert.coinId == coinId && systemAlert.isActive) {
        double absoluteThreshold = systemAlert.thresholdPercentage;
        if (systemAlert.alertOnDrop &&
            instantDeltaPercentage < 0 &&
            instantDeltaPercentage.abs() >= absoluteThreshold) {
          _alertStreamBroker.add(
            '🚨 VOLATILITY DIVERGENCE: $label dropped ${instantDeltaPercentage.toStringAsFixed(2)}% hitting \$${targetPrice.toStringAsFixed(2)}!',
          );
        } else if (!systemAlert.alertOnDrop &&
            instantDeltaPercentage > 0 &&
            instantDeltaPercentage >= absoluteThreshold) {
          _alertStreamBroker.add(
            '🚀 MOMENTUM SPIKE: $label surged +${instantDeltaPercentage.toStringAsFixed(2)}% hitting \$${targetPrice.toStringAsFixed(2)}!',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _volatilityLoopTimer?.cancel();
    _alertStreamBroker.close();
    super.dispose();
  }
}

/// Dynamic dependency injection interface wrapping internal framework runtime data state
class CryptoStateProvider extends StatefulWidget {
  final Widget child;
  const CryptoStateProvider({Key? key, required this.child}) : super(key: key);

  static CryptoPortfolioController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedCryptoState>()!
        .systemController;
  }

  @override
  _CryptoStateProviderState createState() => _CryptoStateProviderState();
}

class _CryptoStateProviderState extends State<CryptoStateProvider> {
  late CryptoPortfolioController _stateController;
  StreamSubscription? _systemNotificationRouterSubscription;

  @override
  void initState() {
    super.initState();
    _stateController = CryptoPortfolioController();

    // Bind the cross-cutting application global messaging system to standard interface notification modals
    _systemNotificationRouterSubscription = _stateController.alertStream.listen(
      (realtimeMessage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: CryptoTheme.surfaceLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 85, left: 16, right: 16),
              duration: const Duration(milliseconds: 2500),
              content: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      realtimeMessage,
                      style: const TextStyle(
                        color: CryptoTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _systemNotificationRouterSubscription?.cancel();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _stateController,
      builder: (context, child) {
        return _InheritedCryptoState(
          systemController: _stateController,
          child: widget.child,
        );
      },
    );
  }
}

class _InheritedCryptoState extends InheritedWidget {
  final CryptoPortfolioController systemController;

  const _InheritedCryptoState({
    Key? key,
    required this.systemController,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedCryptoState oldWidget) => true;
}

/// ============================================================================
/// 6. NAVIGATION MANAGEMENT SYSTEM
/// ============================================================================
class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({Key? key}) : super(key: key);

  @override
  _AppNavigationShellState createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _activeShellIndex = 0;

  final List<Widget> _navigationDestinations = [
    const PortfolioDashboardScreen(),
    const LiveMarketScreen(),
    const TransactionLedgerScreen(),
    const RiskAlertScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _activeShellIndex,
        children: _navigationDestinations,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeShellIndex,
        onTap: (targetIndex) => setState(() => _activeShellIndex = targetIndex),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.donut_large_outlined),
            activeIcon: Icon(Icons.donut_large),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Markets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_outlined),
            activeIcon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 7. PORTFOLIO DASHBOARD MODULE
/// ============================================================================
class PortfolioDashboardScreen extends StatelessWidget {
  const PortfolioDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = CryptoStateProvider.of(context);
    final holdingAssets = controller.portfolioAssets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aegis Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: CryptoTheme.accent),
            onPressed: () => _displayTransactionModalLauncher(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            await Future.delayed(const Duration(milliseconds: 600)),
        color: CryptoTheme.accent,
        backgroundColor: CryptoTheme.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            _renderMetricAggregationsSummaryCard(controller),
            const SizedBox(height: 24),
            if (holdingAssets.isNotEmpty) ...[
              const ViewSectionTitle(title: 'Asset Allocation Matrix'),
              const SizedBox(height: 16),
              _renderAllocationVisualizationComposite(holdingAssets),
              const SizedBox(height: 28),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ViewSectionTitle(title: 'Asset Allocations Held'),
                TextButton(
                  onPressed: () => _displayTransactionModalLauncher(context),
                  child: const Text(
                    '+ Add Order',
                    style: TextStyle(
                      color: CryptoTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (holdingAssets.isEmpty)
              _renderEmptyAllocationPlaceholder(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: holdingAssets.length,
                separatorBuilder: (c, i) =>
                    const Divider(color: CryptoTheme.surfaceLight, height: 1),
                itemBuilder: (context, index) {
                  final asset = holdingAssets[index];
                  return _renderAssetHoldingGridRow(context, asset);
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _renderMetricAggregationsSummaryCard(
    CryptoPortfolioController dataState,
  ) {
    final isPositive = dataState.aggregateProfitLoss >= 0;

    // Generate an arbitrary historic profile mock baseline for visualization mapping arrays
    List<double> cumulativeMockProfilePoints = [
      dataState.totalPortfolioValue * 0.88,
      dataState.totalPortfolioValue * 0.91,
      dataState.totalPortfolioValue * 0.85,
      dataState.totalPortfolioValue * 0.94,
      dataState.totalPortfolioValue * 0.99,
      dataState.totalPortfolioValue * 0.93,
      dataState.totalPortfolioValue,
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CryptoTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CryptoTheme.surfaceLight, width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET PORTFOLIO VALUATION',
            style: TextStyle(
              color: CryptoTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${dataState.totalPortfolioValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (isPositive
                              ? CryptoTheme.cryptoGreen
                              : CryptoTheme.cryptoRed)
                          .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive
                          ? CryptoTheme.cryptoGreen
                          : CryptoTheme.cryptoRed,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}\$${dataState.aggregateProfitLoss.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isPositive
                            ? CryptoTheme.cryptoGreen
                            : CryptoTheme.cryptoRed,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${isPositive ? '+' : ''}${dataState.aggregateProfitLossPercentage.toStringAsFixed(2)}%) All Time',
                style: TextStyle(
                  color: isPositive
                      ? CryptoTheme.cryptoGreen
                      : CryptoTheme.cryptoRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: CryptoTheme.surfaceLight, height: 1),
          const SizedBox(height: 16),
          const Text(
            'AGGREGATE PERFORMANCE TREND (7D)',
            style: TextStyle(
              color: CryptoTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: CustomPaint(
              painter: PortfolioTrendLinePainter(
                dataPoints: cumulativeMockProfilePoints,
                lineColor: isPositive
                    ? CryptoTheme.cryptoGreen
                    : CryptoTheme.cryptoRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderAllocationVisualizationComposite(List<PortfolioAsset> assets) {
    double grandTotal = 0;
    for (var a in assets) {
      grandTotal += a.currentHoldingValue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CryptoTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: AllocationDonutChartPainter(assets: assets),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: assets.take(4).map((asset) {
                double computedRatio = grandTotal == 0
                    ? 0.0
                    : (asset.currentHoldingValue / grandTotal) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: asset.coin.marketColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        asset.coin.symbol,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${computedRatio.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CryptoTheme.textSecondary,
                          fontWeight: FontWeight.w600,
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

  Widget _renderEmptyAllocationPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: CryptoTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: CryptoTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No asset allocations tracked yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Execute your initial buy execution to track metrics.',
            style: TextStyle(fontSize: 13, color: CryptoTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CryptoTheme.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _displayTransactionModalLauncher(context),
            child: const Text('Log First Transaction'),
          ),
        ],
      ),
    );
  }

  Widget _renderAssetHoldingGridRow(
    BuildContext context,
    PortfolioAsset asset,
  ) {
    final yieldsProfit = asset.totalProfitLoss >= 0;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoinSpecificationDetailsView(coin: asset.coin),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: asset.coin.marketColor.withOpacity(0.15),
              child: Text(
                asset.coin.symbol.substring(
                  0,
                  min(2, asset.coin.symbol.length),
                ),
                style: TextStyle(
                  color: asset.coin.marketColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.coin.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${asset.totalQuantity.toStringAsFixed(4)} ${asset.coin.symbol}',
                    style: const TextStyle(
                      color: CryptoTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${asset.currentHoldingValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      yieldsProfit
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: yieldsProfit
                          ? CryptoTheme.cryptoGreen
                          : CryptoTheme.cryptoRed,
                      size: 16,
                    ),
                    Text(
                      '${yieldsProfit ? '+' : ''}${asset.profitLossPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: yieldsProfit
                            ? CryptoTheme.cryptoGreen
                            : CryptoTheme.cryptoRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _displayTransactionModalLauncher(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => const OrderExecutionModalWorkflow(),
    );
  }
}

/// ============================================================================
/// 8. LIVE MARKET MODULE
/// ============================================================================
class LiveMarketScreen extends StatefulWidget {
  const LiveMarketScreen({Key? key}) : super(key: key);

  @override
  _LiveMarketScreenState createState() => _LiveMarketScreenState();
}

class _LiveMarketScreenState extends State<LiveMarketScreen> {
  String _searchFilterCriteriaString = '';
  String _activeSortingParameter = 'cap'; // Options: cap, alpha, change

  @override
  Widget build(BuildContext context) {
    final controller = CryptoStateProvider.of(context);

    // Core functional search/filtering query evaluation pipelines
    List<Coin> processedList = controller.marketCoins.where((coin) {
      final matchesName = coin.name.toLowerCase().contains(
        _searchFilterCriteriaString.toLowerCase(),
      );
      final matchesSymbol = coin.symbol.toLowerCase().contains(
        _searchFilterCriteriaString.toLowerCase(),
      );
      return matchesName || matchesSymbol;
    }).toList();

    // Sort evaluation pipeline execution
    if (_activeSortingParameter == 'alpha') {
      processedList.sort((a, b) => a.name.compareTo(b.name));
    } else if (_activeSortingParameter == 'change') {
      processedList.sort(
        (a, b) => b.percentChange24h.compareTo(a.percentChange24h),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Matrix'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: TextField(
                  onChanged: (input) =>
                      setState(() => _searchFilterCriteriaString = input),
                  decoration: const InputDecoration(
                    hintText: 'Search asset or contract symbol...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: CryptoTheme.textSecondary,
                      size: 20,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _renderSortingToggleChips(
                        label: 'Market Cap Rank',
                        paramValue: 'cap',
                      ),
                      _renderSortingToggleChips(
                        label: 'Alphabetical',
                        paramValue: 'alpha',
                      ),
                      _renderSortingToggleChips(
                        label: '24h Net Performance',
                        paramValue: 'change',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: processedList.length,
        separatorBuilder: (c, i) =>
            const Divider(color: CryptoTheme.surfaceLight, height: 1),
        itemBuilder: (context, index) {
          final coin = processedList[index];
          return _renderLiveMarketItemRow(coin);
        },
      ),
    );
  }

  Widget _renderSortingToggleChips({
    required String label,
    required String paramValue,
  }) {
    final isSelected = _activeSortingParameter == paramValue;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : CryptoTheme.textSecondary,
          ),
        ),
        selected: isSelected,
        selectedColor: CryptoTheme.accent,
        backgroundColor: CryptoTheme.surface,
        onSelected: (state) {
          if (state) setState(() => _activeSortingParameter = paramValue);
        },
      ),
    );
  }

  Widget _renderLiveMarketItemRow(Coin asset) {
    final performanceIsPositive = asset.percentChange24h >= 0;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoinSpecificationDetailsView(coin: asset),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 32,
              decoration: BoxDecoration(
                color: asset.marketColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CryptoTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          asset.symbol,
                          style: const TextStyle(
                            color: CryptoTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 18,
                    width: 90,
                    child: CustomPaint(
                      painter: SparklineMiniPainter(
                        dataPoints: asset.history7d,
                        traceColor: performanceIsPositive
                            ? CryptoTheme.cryptoGreen
                            : CryptoTheme.cryptoRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  asset.currentPrice > 100
                      ? '\$${asset.currentPrice.toStringAsFixed(2)}'
                      : '\$${asset.currentPrice.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (performanceIsPositive
                                ? CryptoTheme.cryptoGreen
                                : CryptoTheme.cryptoRed)
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${performanceIsPositive ? '+' : ''}${asset.percentChange24h.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: performanceIsPositive
                          ? CryptoTheme.cryptoGreen
                          : CryptoTheme.cryptoRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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

/// ============================================================================
/// 9. DEEP INTEGRATED SPECIFICATION DETAILED SCREEN (Asset Profiles)
/// ============================================================================
class CoinSpecificationDetailsView extends StatefulWidget {
  final Coin coin;
  const CoinSpecificationDetailsView({Key? key, required this.coin})
    : super(key: key);

  @override
  _CoinSpecificationDetailsViewState createState() =>
      _CoinSpecificationDetailsViewState();
}

class _CoinSpecificationDetailsViewState
    extends State<CoinSpecificationDetailsView> {
  int _activeTimeframeAnchorDays = 7;

  @override
  Widget build(BuildContext context) {
    final controller = CryptoStateProvider.of(context);

    // Synchronize latest pricing references directly from dynamic data state engine mappings
    final dynamicCoinReference = controller.marketCoins.firstWhere(
      (c) => c.id == widget.coin.id,
      orElse: () => widget.coin,
    );
    final isPositive = dynamicCoinReference.percentChange24h >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${dynamicCoinReference.name} Profile Network'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dynamicCoinReference.marketColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                dynamicCoinReference.symbol,
                style: TextStyle(
                  color: dynamicCoinReference.marketColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              dynamicCoinReference.currentPrice > 100
                  ? '\$${dynamicCoinReference.currentPrice.toStringAsFixed(2)}'
                  : '\$${dynamicCoinReference.currentPrice.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isPositive
                      ? CryptoTheme.cryptoGreen
                      : CryptoTheme.cryptoRed,
                ),
                Text(
                  '${isPositive ? '+' : ''}${dynamicCoinReference.percentChange24h.toStringAsFixed(2)}% (24h)',
                  style: TextStyle(
                    color: isPositive
                        ? CryptoTheme.cryptoGreen
                        : CryptoTheme.cryptoRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Timeframe Selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _renderTimeframeButton('24H', 1),
              _renderTimeframeButton('7D', 7),
              _renderTimeframeButton('30D', 30),
            ],
          ),
          const SizedBox(height: 20),

          // Large High-Fidelity Chart Canvas
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: CryptoTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CryptoTheme.surfaceLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CustomPaint(
                painter: PortfolioTrendLinePainter(
                  dataPoints: dynamicCoinReference.history7d
                      .take(
                        _activeTimeframeAnchorDays == 1
                            ? 5
                            : _activeTimeframeAnchorDays == 7
                            ? 15
                            : 30,
                      )
                      .toList(),
                  lineColor: dynamicCoinReference.marketColor,
                  fillGradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicCoinReference.marketColor.withOpacity(0.3),
                      dynamicCoinReference.marketColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const ViewSectionTitle(title: 'Market Statistics Matrix'),
          const SizedBox(height: 12),
          _renderStatGridBlock(dynamicCoinReference),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CryptoTheme.accent,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (c) => OrderExecutionModalWorkflow(
                  preselectedCoinId: dynamicCoinReference.id,
                ),
              );
            },
            icon: const Icon(Icons.swap_horizontal_circle_outlined),
            label: const Text(
              'Execute New Order Block',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _renderTimeframeButton(String label, int days) {
    final active = _activeTimeframeAnchorDays == days;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : CryptoTheme.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: active,
      selectedColor: CryptoTheme.accent,
      backgroundColor: CryptoTheme.surface,
      onSelected: (st) {
        if (st) setState(() => _activeTimeframeAnchorDays = days);
      },
    );
  }

  Widget _renderStatGridBlock(Coin coin) {
    return Container(
      decoration: BoxDecoration(
        color: CryptoTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _renderStatRow('Circulating Token Name', coin.name),
          const Divider(color: CryptoTheme.surfaceLight),
          _renderStatRow('Asset Contract Symbol', coin.symbol),
          const Divider(color: CryptoTheme.surfaceLight),
          _renderStatRow(
            'Absolute 24h Variance',
            '\$${coin.priceChange24h.toStringAsFixed(4)}',
            valColor: coin.priceChange24h >= 0
                ? CryptoTheme.cryptoGreen
                : CryptoTheme.cryptoRed,
          ),
          const Divider(color: CryptoTheme.surfaceLight),
          _renderStatRow(
            'System Integration Node',
            'AEGIS-MOCK-${coin.id.toUpperCase()}',
          ),
        ],
      ),
    );
  }

  Widget _renderStatRow(String parameter, String value, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            parameter,
            style: const TextStyle(
              color: CryptoTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valColor ?? CryptoTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 10. TRANSACTION LEDGER MODULE
/// ============================================================================
class TransactionLedgerScreen extends StatelessWidget {
  const TransactionLedgerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = CryptoStateProvider.of(context);
    final historyLedgerList = controller.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Execution Ledger')),
      body: historyLedgerList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt,
                    size: 48,
                    color: CryptoTheme.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ledger history blank',
                    style: TextStyle(
                      color: CryptoTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyLedgerList.length,
              itemBuilder: (context, index) {
                final transactionNode = historyLedgerList[index];

                // Locate targeted structural coin context parameters
                final baseCoin = controller.marketCoins.firstWhere(
                  (c) => c.id == transactionNode.coinId,
                  orElse: () => Coin(
                    id: 'err',
                    name: 'Asset Purged',
                    symbol: '???',
                    currentPrice: 0,
                    priceChange24h: 0,
                    percentChange24h: 0,
                    history7d: [],
                    marketColor: Colors.grey,
                  ),
                );

                final isBuy = transactionNode.type == TransactionType.buy;
                final aggregateTotalCashValue =
                    transactionNode.amount * transactionNode.priceAtTransaction;

                return Dismissible(
                  key: Key(transactionNode.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: CryptoTheme.cryptoRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    controller.purgeTransaction(transactionNode.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Transaction block purged from structural ledger.',
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: CryptoTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: CryptoTheme.surfaceLight,
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(
                        isBuy
                            ? Icons.add_chart_outlined
                            : Icons.pie_chart_outline_outlined,
                        color: isBuy ? CryptoTheme.cryptoGreen : Colors.orange,
                      ),
                      title: Text(
                        '${isBuy ? 'BUILT RECORD' : 'LIQUIDATED ORDER'} • ${baseCoin.symbol}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Units: ${transactionNode.amount.toString()} @ \$${transactionNode.priceAtTransaction.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transactionNode.timestamp
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                            style: const TextStyle(
                              color: CryptoTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '${isBuy ? '-' : '+'}\$${aggregateTotalCashValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isBuy
                              ? CryptoTheme.textPrimary
                              : CryptoTheme.cryptoGreen,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// ============================================================================
/// 11. VOLATILITY ALERT CONFIGURATION MODULE
/// ============================================================================
class RiskAlertScreen extends StatefulWidget {
  const RiskAlertScreen({Key? key}) : super(key: key);

  @override
  _RiskAlertScreenState createState() => _RiskAlertScreenState();
}

class _RiskAlertScreenState extends State<RiskAlertScreen> {
  String _alertTargetCoinId = 'btc';
  final TextEditingController _percentageThresholdFormController =
      TextEditingController(text: '3.0');
  bool _triggerOnDropValueBooleanState = false;

  @override
  void dispose() {
    _percentageThresholdFormController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CryptoStateProvider.of(context);
    final activeAlertRegistry = controller.alerts;

    return Scaffold(
      appBar: AppBar(title: const Text('Volatility Radar Alerting')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: CryptoTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CryptoTheme.surfaceLight),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROVISION NEW VOLATILITY RADAR TARGET',
                    style: TextStyle(
                      color: CryptoTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Select Target Underlying Cryptographic Token',
                    style: TextStyle(
                      fontSize: 12,
                      color: CryptoTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    dropdownColor: CryptoTheme.surface,
                    value: _alertTargetCoinId,
                    items: controller.marketCoins.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.name} (${c.symbol})'),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _alertTargetCoinId = val ?? 'btc'),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Instant Divergence Variance Target (%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: CryptoTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _percentageThresholdFormController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'E.g., 3.5% variance gap limit',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invert Radar Vector direction',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'True triggers on crash, False triggers on spikes',
                            style: TextStyle(
                              fontSize: 11,
                              color: CryptoTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _triggerOnDropValueBooleanState,
                        activeColor: CryptoTheme.accent,
                        onChanged: (st) => setState(
                          () => _triggerOnDropValueBooleanState = st,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CryptoTheme.accent,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      double? parsableInput = double.tryParse(
                        _percentageThresholdFormController.text,
                      );
                      if (parsableInput == null || parsableInput <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Invalid threshold entry specification format.',
                            ),
                          ),
                        );
                        return;
                      }
                      controller.configureAlert(
                        _alertTargetCoinId,
                        parsableInput,
                        _triggerOnDropValueBooleanState,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'High frequency radar scanning pipeline successfully established.',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Provision Scanning Engine',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const ViewSectionTitle(
              title: 'Active High Frequency Scanning Pipeline Nodes',
            ),
            const SizedBox(height: 12),
            if (activeAlertRegistry.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No custom tracking listeners deployed.',
                    style: TextStyle(color: CryptoTheme.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeAlertRegistry.length,
                itemBuilder: (context, idx) {
                  final alertConfigItem = activeAlertRegistry[idx];
                  final tokenContext = controller.marketCoins.firstWhere(
                    (element) => element.id == alertConfigItem.coinId,
                  );

                  return Card(
                    color: CryptoTheme.surface,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(
                        alertConfigItem.alertOnDrop
                            ? Icons.trending_down
                            : Icons.trending_up,
                        color: alertConfigItem.alertOnDrop
                            ? CryptoTheme.cryptoRed
                            : CryptoTheme.cryptoGreen,
                      ),
                      title: Text(
                        '${tokenContext.name} (${tokenContext.symbol}) Runtime Monitor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Triggers scanning loop if asset swings ${alertConfigItem.alertOnDrop ? 'down' : 'up'} by >= ${alertConfigItem.thresholdPercentage}% within a single engine tick block.',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: alertConfigItem.isActive,
                            onChanged: (v) => controller.toggleAlertStatus(
                              alertConfigItem.id,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: CryptoTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () =>
                                controller.removeAlert(alertConfigItem.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// 12. ORDER EXECUTION WORKFLOW FRAMEWORK MODAL INTERFACES
/// ============================================================================
class OrderExecutionModalWorkflow extends StatefulWidget {
  final String? preselectedCoinId;
  const OrderExecutionModalWorkflow({Key? key, this.preselectedCoinId})
    : super(key: key);

  @override
  _OrderExecutionModalWorkflowState createState() =>
      _OrderExecutionModalWorkflowState();
}

class _OrderExecutionModalWorkflowState
    extends State<OrderExecutionModalWorkflow> {
  late String _targetAssetSelectionId;
  TransactionType _workflowTypeSelection = TransactionType.buy;
  final TextEditingController _tokenQuantityInputFormController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetAssetSelectionId = widget.preselectedCoinId ?? 'btc';
  }

  @override
  void dispose() {
    _tokenQuantityInputFormController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CryptoStateProvider.of(context);
    final contextCoin = controller.marketCoins.firstWhere(
      (c) => c.id == _targetAssetSelectionId,
    );

    double incomingQuantityParsableEvaluation =
        double.tryParse(_tokenQuantityInputFormController.text) ?? 0.0;
    double aggregateSimulatedCashRequirement =
        incomingQuantityParsableEvaluation * contextCoin.currentPrice;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        decoration: const BoxDecoration(
          color: CryptoTheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ORDER INTAKE ENGINE WORKFLOW',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: CryptoTheme.surface,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Segmented Control Architecture
              Row(
                children: [
                  Expanded(
                    child: _renderWorkflowSegmentButton(
                      label: 'BUY ORDER',
                      type: TransactionType.buy,
                      activeColor: CryptoTheme.cryptoGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _renderWorkflowSegmentButton(
                      label: 'LIQUIDATE',
                      type: TransactionType.sell,
                      activeColor: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Select Underlying Asset Index Node',
                style: TextStyle(
                  fontSize: 12,
                  color: CryptoTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                dropdownColor: CryptoTheme.surface,
                value: _targetAssetSelectionId,
                items: controller.marketCoins.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${c.name} (${c.symbol}) @ \$${c.currentPrice.toStringAsFixed(2)}',
                    ),
                  );
                }).toList(),
                onChanged: (val) =>
                    setState(() => _targetAssetSelectionId = val ?? 'btc'),
              ),
              const SizedBox(height: 20),

              Text(
                'Asset Block Volume Capacity Units (${contextCoin.symbol})',
                style: const TextStyle(
                  fontSize: 12,
                  color: CryptoTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _tokenQuantityInputFormController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (input) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: contextCoin.symbol,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CryptoTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CryptoTheme.surfaceLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimated Ledger Total Settlement',
                      style: TextStyle(
                        color: CryptoTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${aggregateSimulatedCashRequirement.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CryptoTheme.cryptoGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _workflowTypeSelection == TransactionType.buy
                      ? CryptoTheme.cryptoGreen
                      : Colors.orange,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (incomingQuantityParsableEvaluation <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Allocation validation fault: block volume capacity cannot be lower than zero.',
                        ),
                      ),
                    );
                    return;
                  }
                  controller.executeTransaction(
                    coinId: _targetAssetSelectionId,
                    type: _workflowTypeSelection,
                    amount: incomingQuantityParsableEvaluation,
                    executingPrice: contextCoin.currentPrice,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ledger verification sequence verified. Cryptographic transaction block integrated.',
                      ),
                    ),
                  );
                },
                child: Text(
                  'COMMIT ASSET INGESTION BLOCKS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _workflowTypeSelection == TransactionType.buy
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderWorkflowSegmentButton({
    required String label,
    required TransactionType type,
    required Color activeColor,
  }) {
    final active = _workflowTypeSelection == type;
    return GestureDetector(
      onTap: () => setState(() => _workflowTypeSelection = type),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: active ? activeColor : CryptoTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : CryptoTheme.surfaceLight,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: active ? CryptoTheme.background : CryptoTheme.textPrimary,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 13. REUSABLE ATOMIC INTERFACE ELEMENTS
/// ============================================================================
class ViewSectionTitle extends StatelessWidget {
  final String title;
  const ViewSectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: CryptoTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

/// ============================================================================
/// 14. CANVAS HARDWARE GRAPH RENDERING PIPELINES
/// ============================================================================
class PortfolioTrendLinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final Gradient? fillGradient;

  PortfolioTrendLinePainter({
    required this.dataPoints,
    required this.lineColor,
    this.fillGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    double peakLimitMax = dataPoints.reduce(max);
    double valleyLimitMin = dataPoints.reduce(min);
    double structuralPriceGapRange = peakLimitMax - valleyLimitMin;
    if (structuralPriceGapRange == 0) structuralPriceGapRange = 1.0;

    double spatialStepHorizontalX = size.width / (dataPoints.length - 1);

    Path trajectoryPath = Path();
    List<Offset> structuralVectorCoordinates = [];

    for (int i = 0; i < dataPoints.length; i++) {
      double localizedX = i * spatialStepHorizontalX;
      double normalRatioY =
          (dataPoints[i] - valleyLimitMin) / structuralPriceGapRange;
      double localizedY = size.height - (normalRatioY * size.height);

      Offset elementCoordinate = Offset(localizedX, localizedY);
      structuralVectorCoordinates.add(elementCoordinate);

      if (i == 0) {
        trajectoryPath.moveTo(localizedX, localizedY);
      } else {
        trajectoryPath.lineTo(localizedX, localizedY);
      }
    }

    // Secondary vector mapping path generation for tracking gradient bounds
    if (fillGradient != null) {
      Path gradientClosurePath = Path.from(trajectoryPath);
      gradientClosurePath.lineTo(size.width, size.height);
      gradientClosurePath.lineTo(0, size.height);
      gradientClosurePath.close();

      Paint gradientPaintContext = Paint()
        ..shader = fillGradient!.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(gradientClosurePath, gradientPaintContext);
    }

    Paint linePaintContext = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(trajectoryPath, linePaintContext);
  }

  @override
  bool shouldRepaint(covariant PortfolioTrendLinePainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints ||
      oldDelegate.lineColor != lineColor;
}

class SparklineMiniPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color traceColor;

  SparklineMiniPainter({required this.dataPoints, required this.traceColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    double maxPoint = dataPoints.reduce(max);
    double minPoint = dataPoints.reduce(min);
    double range = maxPoint - minPoint;
    if (range == 0) range = 1.0;

    double xInterval = size.width / (dataPoints.length - 1);
    Path tracePath = Path();

    for (int i = 0; i < dataPoints.length; i++) {
      double currentX = i * xInterval;
      double normalizedY = (dataPoints[i] - minPoint) / range;
      double currentY = size.height - (normalizedY * size.height);

      if (i == 0) {
        tracePath.moveTo(currentX, currentY);
      } else {
        tracePath.lineTo(currentX, currentY);
      }
    }

    Paint paintContext = Paint()
      ..color = traceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawPath(tracePath, paintContext);
  }

  @override
  bool shouldRepaint(covariant SparklineMiniPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}

class AllocationDonutChartPainter extends CustomPainter {
  final List<PortfolioAsset> assets;
  AllocationDonutChartPainter({required this.assets});

  @override
  void paint(Canvas canvas, Size size) {
    double grandTotalValueAccumulation = 0;
    for (var a in assets) {
      grandTotalValueAccumulation += a.currentHoldingValue;
    }
    if (grandTotalValueAccumulation == 0) return;

    double currentRadialOffsetTrajectoryAngle = -pi / 2;
    Rect boundedDrawingContainerRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    for (var asset in assets) {
      double sectorSweepingAllocationRatio =
          (asset.currentHoldingValue / grandTotalValueAccumulation) * 2 * pi;

      Paint structuralArcPaintBrush = Paint()
        ..color = asset.coin.marketColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..isAntiAlias = true;

      canvas.drawArc(
        boundedDrawingContainerRect,
        currentRadialOffsetTrajectoryAngle,
        sectorSweepingAllocationRatio,
        false,
        structuralArcPaintBrush,
      );

      currentRadialOffsetTrajectoryAngle += sectorSweepingAllocationRatio;
    }
  }

  @override
  bool shouldRepaint(covariant AllocationDonutChartPainter oldDelegate) =>
      oldDelegate.assets != assets;
}
