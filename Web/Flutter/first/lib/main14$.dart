import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. CONSTANTS, ENUMS & THEME
// ============================================================================

enum WeatherCondition { clear, partlyCloudy, cloudy, rain, thunderstorm, snow }

enum UnitSystem { metric, imperial }

class AppColors {
  static const Color backgroundDark = Color(0xFF0B132B);
  static const Color surfaceDark = Color(0xFF1C2541);
  static const Color surfaceHighlight = Color(0xFF3A506B);

  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color clearSky = Color(0xFF38BDF8);
  static const Color rainSky = Color(0xFF475569);
  static const Color cloudSky = Color(0xFF64748B);
  static const Color nightSky = Color(0xFF0F172A);

  static const Color accent = Color(0xFFFBBF24); // Sun yellow
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

class AppStyles {
  static const TextStyle tempHuge = TextStyle(
    fontSize: 84,
    fontWeight: FontWeight.w200,
    color: AppColors.textMain,
    letterSpacing: -2,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textMain,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );
}

// ============================================================================
// 2. UTILS & EXCEPTIONS
// ============================================================================

abstract class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends WeatherException {
  NetworkException([String m = "Network timeout. Connection lost."]) : super(m);
}

class LocationException extends WeatherException {
  LocationException([String m = "Failed to acquire GPS location."]) : super(m);
}

class ServerException extends WeatherException {
  ServerException([String m = "Weather API returned an error."]) : super(m);
}

class Formatters {
  static String temp(double temp, UnitSystem sys) => '${temp.round()}°';
  static String time(DateTime d) {
    int h = d.hour;
    String p = h >= 12 ? 'PM' : 'AM';
    if (h == 0)
      h = 12;
    else if (h > 12)
      h -= 12;
    return '$h $p';
  }

  static String dayOfWeek(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  static String timeSince(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ============================================================================
// 3. DOMAIN MODELS
// ============================================================================

class GeoLocation {
  final double lat;
  final double lon;
  final String cityName;
  const GeoLocation({
    required this.lat,
    required this.lon,
    required this.cityName,
  });
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final WeatherCondition condition;
  final int pop; // Probability of precipitation (0-100)

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.pop,
  });
}

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final WeatherCondition condition;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
  });
}

class WeatherData {
  final GeoLocation location;
  final DateTime lastUpdated;
  final double currentTemp;
  final double feelsLike;
  final WeatherCondition condition;
  final String conditionDesc;

  // Details
  final int humidity;
  final double windSpeed;
  final int uvIndex;
  final int visibility;
  final int pressure;

  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  WeatherData({
    required this.location,
    required this.lastUpdated,
    required this.currentTemp,
    required this.feelsLike,
    required this.condition,
    required this.conditionDesc,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.visibility,
    required this.pressure,
    required this.hourly,
    required this.daily,
  });
}

class CachedResponse<T> {
  final T data;
  final DateTime timestamp;
  CachedResponse(this.data) : timestamp = DateTime.now();
  bool isValid(Duration ttl) => DateTime.now().difference(timestamp) < ttl;
}

// ============================================================================
// 4. MOCK API, GEO-SERVICE & CACHE ENGINE
// ============================================================================

class CustomCacheManager {
  final Map<String, CachedResponse<WeatherData>> _store = {};

  void write(String key, WeatherData data) =>
      _store[key] = CachedResponse(data);

  CachedResponse<WeatherData>? read(String key) => _store[key];

  void invalidate(String key) => _store.remove(key);
}

class MockLocationService {
  final StreamController<GeoLocation> _locationStream =
      StreamController<GeoLocation>.broadcast();
  GeoLocation _currentLocation = const GeoLocation(
    lat: 40.7128,
    lon: -74.0060,
    cityName: 'New York',
  );

  Stream<GeoLocation> get locationUpdates => _locationStream.stream;
  GeoLocation get currentLocation => _currentLocation;

  Future<void> changeLocation(GeoLocation newLoc) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate GPS lock
    _currentLocation = newLoc;
    _locationStream.sink.add(newLoc);
  }
}

class MockWeatherApi {
  static final MockWeatherApi _instance = MockWeatherApi._internal();
  factory MockWeatherApi() => _instance;
  MockWeatherApi._internal();

  final math.Random _rand = math.Random();
  final CustomCacheManager _cache = CustomCacheManager();
  final Duration _ttl = const Duration(minutes: 15); // Cache valid for 15 mins

  /// Fetches weather with strict caching, network simulation, and automatic fallback.
  Future<WeatherData> fetchWeather(
    GeoLocation loc, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${loc.lat}_${loc.lon}';

    // 1. Check Cache
    if (!forceRefresh) {
      final cached = _cache.read(cacheKey);
      if (cached != null && cached.isValid(_ttl)) {
        return cached.data;
      }
    }

    // 2. Simulate Network Request
    await Future.delayed(Duration(milliseconds: 800 + _rand.nextInt(1000)));

    // Simulate 15% random network drop for realism
    if (_rand.nextDouble() < 0.15) {
      final cached = _cache.read(cacheKey);
      if (cached != null) {
        // Return stale cache but throw an exception we can catch for warnings
        throw StaleCacheException(cached.data);
      }
      throw NetworkException("Failed to reach weather servers.");
    }

    // 3. Generate Mock Data
    final now = DateTime.now();
    final baseTemp =
        15.0 + _rand.nextDouble() * 20.0; // Random temp between 15-35
    final condition =
        WeatherCondition.values[_rand.nextInt(WeatherCondition.values.length)];

    // Hourly Generation (24 hours)
    final hourly = List.generate(24, (i) {
      final t = now.add(Duration(hours: i));
      // Sinusoidal temp curve for day/night
      final tempDrift = math.sin((t.hour - 6) * math.pi / 12) * 8.0;
      return HourlyForecast(
        time: t,
        temperature: baseTemp + tempDrift + (_rand.nextDouble() * 2 - 1),
        condition: WeatherCondition
            .values[_rand.nextInt(WeatherCondition.values.length)],
        pop: _rand.nextInt(100),
      );
    });

    // Daily Generation (7 days)
    final daily = List.generate(7, (i) {
      final baseDailyTemp = baseTemp + (_rand.nextDouble() * 10 - 5);
      return DailyForecast(
        date: now.add(Duration(days: i)),
        minTemp: baseDailyTemp - 5 - _rand.nextDouble() * 5,
        maxTemp: baseDailyTemp + 5 + _rand.nextDouble() * 5,
        condition: WeatherCondition
            .values[_rand.nextInt(WeatherCondition.values.length)],
      );
    });

    final data = WeatherData(
      location: loc,
      lastUpdated: now,
      currentTemp: baseTemp,
      feelsLike: baseTemp + (_rand.nextDouble() * 4 - 2),
      condition: condition,
      conditionDesc: _getConditionDesc(condition),
      humidity: 30 + _rand.nextInt(60),
      windSpeed: _rand.nextDouble() * 25,
      uvIndex: _rand.nextInt(11),
      visibility: 5 + _rand.nextInt(5), // km
      pressure: 1000 + _rand.nextInt(30),
      hourly: hourly,
      daily: daily,
    );

    // Write to Cache
    _cache.write(cacheKey, data);
    return data;
  }

  String _getConditionDesc(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.clear:
        return 'Clear Sky';
      case WeatherCondition.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherCondition.cloudy:
        return 'Overcast';
      case WeatherCondition.rain:
        return 'Light Rain';
      case WeatherCondition.thunderstorm:
        return 'Thunderstorms';
      case WeatherCondition.snow:
        return 'Light Snow';
    }
  }
}

class StaleCacheException implements Exception {
  final WeatherData staleData;
  StaleCacheException(this.staleData);
}

// ============================================================================
// 5. STATE MANAGEMENT
// ============================================================================

class WeatherState extends ChangeNotifier {
  final MockWeatherApi _api = MockWeatherApi();
  final MockLocationService locationService = MockLocationService();

  bool isLoading = true;
  String? error;
  bool isUsingStaleData = false;

  WeatherData? weather;
  UnitSystem unitSystem = UnitSystem.metric;

  StreamSubscription? _locSub;

  WeatherState() {
    _init();
  }

  void _init() {
    _locSub = locationService.locationUpdates.listen((loc) {
      fetchWeather(forceRefresh: true);
    });
    fetchWeather();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    super.dispose();
  }

  Future<void> fetchWeather({bool forceRefresh = false}) async {
    isLoading = true;
    error = null;
    isUsingStaleData = false;
    notifyListeners();

    try {
      weather = await _api.fetchWeather(
        locationService.currentLocation,
        forceRefresh: forceRefresh,
      );
    } on StaleCacheException catch (e) {
      weather = e.staleData;
      isUsingStaleData = true;
      error = "Network unavailable. Showing cached data.";
    } on WeatherException catch (e) {
      error = e.message;
    } catch (e) {
      error = "An unexpected error occurred.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleUnits() {
    unitSystem = unitSystem == UnitSystem.metric
        ? UnitSystem.imperial
        : UnitSystem.metric;
    notifyListeners();
  }

  double convertTemp(double c) {
    if (unitSystem == UnitSystem.metric) return c;
    return (c * 9 / 5) + 32;
  }
}

class AppStore extends InheritedNotifier<WeatherState> {
  const AppStore({Key? key, required WeatherState state, required Widget child})
    : super(key: key, notifier: state, child: child);
  static WeatherState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStore>()!.notifier!;
}

// ============================================================================
// 6. MAIN APP & ROUTING
// ============================================================================

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WeatherDashboardApp());
}

class WeatherDashboardApp extends StatelessWidget {
  const WeatherDashboardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStore(
      state: WeatherState(),
      child: MaterialApp(
        title: 'Nexus Weather',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundDark,
          fontFamily: 'Roboto',
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}

// ============================================================================
// 7. DASHBOARD SCREEN & DYNAMIC BACKGROUND
// ============================================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  Color _getBgColor(WeatherCondition? c, DateTime? time) {
    if (c == null || time == null) return AppColors.backgroundDark;
    bool isNight = time.hour < 6 || time.hour > 18;
    if (isNight) return AppColors.nightSky;

    switch (c) {
      case WeatherCondition.clear:
        return AppColors.clearSky;
      case WeatherCondition.partlyCloudy:
        return AppColors.clearSky.withOpacity(0.8);
      case WeatherCondition.cloudy:
        return AppColors.cloudSky;
      case WeatherCondition.rain:
      case WeatherCondition.thunderstorm:
        return AppColors.rainSky;
      case WeatherCondition.snow:
        return AppColors.cloudSky;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStore.of(context);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getBgColor(state.weather?.condition, state.weather?.lastUpdated),
              AppColors.backgroundDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            // 1. Custom Animated Weather Background
            if (state.weather != null)
              Positioned.fill(
                child: WeatherAnimationCanvas(
                  condition: state.weather!.condition,
                ),
              ),

            // 2. Main Content
            SafeArea(
              child: RefreshIndicator(
                color: AppColors.textMain,
                backgroundColor: AppColors.surfaceHighlight,
                onRefresh: () => state.fetchWeather(forceRefresh: true),
                child: state.weather == null && state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : state.weather == null
                    ? _buildErrorState(state)
                    : _buildDashboardContent(context, state),
              ),
            ),

            // 3. App Bar Overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {},
                    ),
                    GestureDetector(
                      onTap: () => _showLocationSheet(context, state),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.locationService.currentLocation.cityName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.thermostat, color: Colors.white),
                      onPressed: () => state.toggleUnits(),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Stale Cache Warning
            if (state.isUsingStaleData && state.error != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WeatherState state) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 200),
        const Icon(Icons.error_outline, size: 80, color: AppColors.error),
        const SizedBox(height: 24),
        Text(
          'Unable to fetch weather',
          textAlign: TextAlign.center,
          style: AppStyles.h2,
        ),
        const SizedBox(height: 8),
        Text(
          state.error ?? 'Unknown error',
          textAlign: TextAlign.center,
          style: AppStyles.caption,
        ),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, WeatherState state) {
    final w = state.weather!;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 80, bottom: 40), // Padding for Appbar
      children: [
        // Hero Section
        Column(
          children: [
            const SizedBox(height: 24),
            Text(
              Formatters.temp(
                state.convertTemp(w.currentTemp),
                state.unitSystem,
              ),
              style: AppStyles.tempHuge,
            ),
            Text(w.conditionDesc, style: AppStyles.h2),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_upward, size: 16, color: Colors.white70),
                Text(
                  Formatters.temp(
                    state.convertTemp(w.daily.first.maxTemp),
                    state.unitSystem,
                  ),
                  style: AppStyles.body,
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: Colors.white70,
                ),
                Text(
                  Formatters.temp(
                    state.convertTemp(w.daily.first.minTemp),
                    state.unitSystem,
                  ),
                  style: AppStyles.body,
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),

        // Hourly Forecast & Chart
        _GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Today', style: AppStyles.h3),
                    Text(
                      'Updated ${Formatters.timeSince(w.lastUpdated)}',
                      style: AppStyles.caption,
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              // Custom Temperature Trend Chart
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: CustomPaint(
                    painter: _HourlyChartPainter(
                      hourlyData: w.hourly.take(12).toList(),
                      state: state,
                    ),
                  ),
                ),
              ),

              // Hourly Icons
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 24,
                  itemBuilder: (ctx, i) {
                    final h = w.hourly[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            i == 0 ? 'Now' : Formatters.time(h.time),
                            style: AppStyles.caption.copyWith(
                              fontWeight: i == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ConditionIcon(condition: h.condition, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.temp(
                              state.convertTemp(h.temperature),
                              state.unitSystem,
                            ),
                            style: AppStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (h.pop > 20)
                            Text(
                              '${h.pop}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.clearSky,
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
        ),
        const SizedBox(height: 16),

        // 7-Day Forecast
        _GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('7-Day Forecast', style: AppStyles.h3),
              ),
              const Divider(color: Colors.white24, height: 1),
              ...w.daily
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              Formatters.dayOfWeek(d.date),
                              style: AppStyles.body,
                            ),
                          ),
                          const SizedBox(width: 16),
                          _ConditionIcon(condition: d.condition, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.temp(
                                    state.convertTemp(d.minTemp),
                                    state.unitSystem,
                                  ),
                                  style: AppStyles.body.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 80,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.blue, Colors.orange],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  Formatters.temp(
                                    state.convertTemp(d.maxTemp),
                                    state.unitSystem,
                                  ),
                                  style: AppStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid Details
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _GridDetailCard(
              icon: Icons.water_drop,
              title: 'HUMIDITY',
              value: '${w.humidity}%',
              desc: 'The dew point is 15° right now.',
            ),
            _GridDetailCard(
              icon: Icons.air,
              title: 'WIND',
              value: '${w.windSpeed.toStringAsFixed(1)}',
              subValue: ' km/h',
              desc: 'Direction: NE',
            ),
            _GridDetailCard(
              icon: Icons.wb_sunny,
              title: 'UV INDEX',
              value: '${w.uvIndex}',
              desc: w.uvIndex > 5
                  ? 'High risk. Use sun protection.'
                  : 'Low risk.',
            ),
            _GridDetailCard(
              icon: Icons.visibility,
              title: 'VISIBILITY',
              value: '${w.visibility}',
              subValue: ' km',
              desc: 'Clear view.',
            ),
          ],
        ),
      ],
    );
  }

  void _showLocationSheet(BuildContext context, WeatherState state) {
    final List<GeoLocation> mockCities = [
      const GeoLocation(lat: 40.7128, lon: -74.0060, cityName: 'New York'),
      const GeoLocation(lat: 51.5074, lon: -0.1278, cityName: 'London'),
      const GeoLocation(lat: 35.6762, lon: 139.6503, cityName: 'Tokyo'),
      const GeoLocation(lat: -33.8688, lon: 151.2093, cityName: 'Sydney'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Locations', style: AppStyles.h2),
            const SizedBox(height: 16),
            ...mockCities
                .map(
                  (city) => ListTile(
                    leading: const Icon(
                      Icons.location_city,
                      color: Colors.white70,
                    ),
                    title: Text(
                      city.cityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing:
                        state.locationService.currentLocation.cityName ==
                            city.cityName
                        ? const Icon(Icons.check, color: AppColors.info)
                        : null,
                    onTap: () {
                      state.locationService.changeLocation(city);
                      Navigator.pop(ctx);
                    },
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. GLASSMORPHISM & UTILITY WIDGETS
// ============================================================================

class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: child,
    );
  }
}

class _GridDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subValue;
  final String desc;
  const _GridDetailCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subValue,
    required this.desc,
  });
  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppStyles.h1),
                if (subValue != null) Text(subValue!, style: AppStyles.body),
              ],
            ),
            const Spacer(),
            Text(
              desc,
              style: AppStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionIcon extends StatelessWidget {
  final WeatherCondition condition;
  final double size;
  const _ConditionIcon({required this.condition, this.size = 24});
  @override
  Widget build(BuildContext context) {
    IconData ic;
    Color c;
    switch (condition) {
      case WeatherCondition.clear:
        ic = Icons.wb_sunny;
        c = AppColors.accent;
        break;
      case WeatherCondition.partlyCloudy:
        ic = Icons.cloud_queue;
        c = Colors.white70;
        break;
      case WeatherCondition.cloudy:
        ic = Icons.cloud;
        c = Colors.white54;
        break;
      case WeatherCondition.rain:
        ic = Icons.water_drop;
        c = AppColors.clearSky;
        break;
      case WeatherCondition.thunderstorm:
        ic = Icons.flash_on;
        c = AppColors.accent;
        break;
      case WeatherCondition.snow:
        ic = Icons.ac_unit;
        c = Colors.white;
        break;
    }
    return Icon(ic, color: c, size: size);
  }
}

// ============================================================================
// 9. CUSTOM BEZIER CHART PAINTER (Hourly Trend)
// ============================================================================

class _HourlyChartPainter extends CustomPainter {
  final List<HourlyForecast> hourlyData;
  final WeatherState state;
  _HourlyChartPainter({required this.hourlyData, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlyData.isEmpty) return;

    final temps = hourlyData
        .map((h) => state.convertTemp(h.temperature))
        .toList();
    final minTemp = temps.reduce(math.min) - 2;
    final maxTemp = temps.reduce(math.max) + 2;
    final range = maxTemp - minTemp == 0 ? 1 : maxTemp - minTemp;

    final stepX = size.width / (hourlyData.length - 1);

    final path = Path();
    for (int i = 0; i < temps.length; i++) {
      double x = i * stepX;
      double normalizedY = (temps[i] - minTemp) / range;
      double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double prevX = (i - 1) * stepX;
        double prevY =
            size.height - (((temps[i - 1] - minTemp) / range) * size.height);

        double controlX1 = prevX + (x - prevX) / 2;
        double controlY1 = prevY;
        double controlX2 = prevX + (x - prevX) / 2;
        double controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw Dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (int i = 0; i < temps.length; i++) {
      double x = i * stepX;
      double normalizedY = (temps[i] - minTemp) / range;
      double y = size.height - (normalizedY * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 10. ADVANCED CUSTOM WEATHER ANIMATION ENGINE
// ============================================================================

class WeatherAnimationCanvas extends StatefulWidget {
  final WeatherCondition condition;
  const WeatherAnimationCanvas({Key? key, required this.condition})
    : super(key: key);

  @override
  State<WeatherAnimationCanvas> createState() => _WeatherAnimationCanvasState();
}

class _WeatherAnimationCanvasState extends State<WeatherAnimationCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(WeatherAnimationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition != widget.condition) {
      _ctrl.forward(from: 0.0);
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            painter: _WeatherFxPainter(
              condition: widget.condition,
              progress: _ctrl.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WeatherFxPainter extends CustomPainter {
  final WeatherCondition condition;
  final double progress; // 0.0 to 1.0 continuously
  final math.Random _rand = math.Random(
    12345,
  ); // Seeded for consistent drop positions

  _WeatherFxPainter({required this.condition, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    switch (condition) {
      case WeatherCondition.rain:
      case WeatherCondition.thunderstorm:
        _drawRain(
          canvas,
          size,
          isHeavy: condition == WeatherCondition.thunderstorm,
        );
        if (condition == WeatherCondition.thunderstorm)
          _drawLightning(canvas, size);
        break;
      case WeatherCondition.clear:
        _drawSun(canvas, size);
        break;
      case WeatherCondition.partlyCloudy:
      case WeatherCondition.cloudy:
        _drawClouds(
          canvas,
          size,
          density: condition == WeatherCondition.cloudy ? 5 : 2,
        );
        if (condition == WeatherCondition.partlyCloudy) _drawSun(canvas, size);
        break;
      case WeatherCondition.snow:
        _drawSnow(canvas, size);
        break;
    }
  }

  void _drawRain(Canvas canvas, Size size, {bool isHeavy = false}) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    int dropCount = isHeavy ? 150 : 50;

    for (int i = 0; i < dropCount; i++) {
      double startX = _rand.nextDouble() * size.width;
      double startY = _rand.nextDouble() * size.height;
      double speed = 1000 + _rand.nextDouble() * 500; // pixels per cycle

      // Calculate current position based on progress
      double currentY = (startY + (progress * speed)) % size.height;

      canvas.drawLine(
        Offset(startX, currentY),
        Offset(startX - 5, currentY + 15),
        paint,
      );
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 100; i++) {
      double startX = _rand.nextDouble() * size.width;
      double startY = _rand.nextDouble() * size.height;
      double speed = 300 + _rand.nextDouble() * 200;

      // Horizontal drift using sine wave
      double drift = math.sin((progress * 2 * math.pi) + i) * 20;
      double currentY = (startY + (progress * speed)) % size.height;

      canvas.drawCircle(
        Offset((startX + drift) % size.width, currentY),
        _rand.nextDouble() * 3 + 1,
        paint,
      );
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.8, size.height * 0.2); // Top right

    // Core
    final corePaint = Paint()
      ..color = AppColors.accent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 40, corePaint);
    canvas.drawCircle(
      center,
      40,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    // Rotating Rays
    final rayPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.3)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi); // Full rotation

    for (int i = 0; i < 12; i++) {
      canvas.drawLine(const Offset(0, -50), const Offset(0, -70), rayPaint);
      canvas.rotate((2 * math.pi) / 12);
    }
    canvas.restore();
  }

  void _drawClouds(Canvas canvas, Size size, {int density = 2}) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    for (int i = 0; i < density; i++) {
      double yPos = size.height * 0.1 + (i * 50);
      double speed = 50 + (i * 20);

      // Moving right slowly
      double currentX =
          (_rand.nextDouble() * size.width + (progress * speed)) %
              (size.width + 200) -
          100;

      // Draw a compound cloud shape
      canvas.drawCircle(Offset(currentX, yPos), 40, paint);
      canvas.drawCircle(Offset(currentX + 40, yPos - 20), 50, paint);
      canvas.drawCircle(Offset(currentX + 80, yPos), 30, paint);
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    // Flash effect: trigger lightning occasionally based on progress
    if (progress > 0.45 && progress < 0.47) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withOpacity(0.4),
      );

      // Draw lightning bolt
      final boltPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.miter;

      Path path = Path()
        ..moveTo(size.width * 0.5, 0)
        ..lineTo(size.width * 0.4, size.height * 0.3)
        ..lineTo(size.width * 0.55, size.height * 0.35)
        ..lineTo(size.width * 0.45, size.height * 0.7);

      canvas.drawPath(path, boltPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherFxPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.condition != condition;
}
