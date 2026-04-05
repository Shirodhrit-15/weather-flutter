// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/assets/secrets.dart';
import 'package:weather_app/assets/weather_detail_card.dart';
import 'package:weather_app/pages/login_page.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  double temp = 0;
  String weatherDescription = '';
  double humidity = 0;
  double windSpeed = 0;
  double pressure = 0;
  double feelsLike = 0;
  String weatherIcon = '';
  List<dynamic> forecastData = [];
  bool isLoading = false;
  String errorMessage = '';
  String cityName = 'Kolkata';

  // 🌅 Sunrise / Sunset
  String sunriseTime = '';
  String sunsetTime = '';

  // ☀️ UV Index
  double uvIndex = 0;
  double lat = 0;
  double lon = 0;

  // 📅 5-day forecast (one entry per day)
  List<Map<String, dynamic>> dailyForecast = [];

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      await _getCurrentWeather();
      await _getForecastData();
      await _getUVIndex();
    } catch (e) {
      setState(
        () => errorMessage = "Could not load weather. Check your connection.",
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _getCurrentWeather() async {
    final res = await http
        .get(
          Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$openWeatherAPIKey&units=metric',
          ),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        temp = (data['main']['temp'] as num).toDouble();
        weatherDescription = data['weather'][0]['description'];
        humidity = (data['main']['humidity'] as num).toDouble();
        windSpeed = (data['wind']['speed'] as num).toDouble();
        pressure = (data['main']['pressure'] as num).toDouble();
        feelsLike = (data['main']['feels_like'] as num).toDouble();
        weatherIcon = data['weather'][0]['icon'];
        lat = (data['coord']['lat'] as num).toDouble();
        lon = (data['coord']['lon'] as num).toDouble();

        // 🌅 Sunrise & Sunset (convert from Unix timestamp)
        final sunriseTs = data['sys']['sunrise'] as int;
        final sunsetTs = data['sys']['sunset'] as int;
        sunriseTime = _formatUnixTime(sunriseTs);
        sunsetTime = _formatUnixTime(sunsetTs);
      });
    } else {
      throw Exception("City not found");
    }
  }

  Future<void> _getForecastData() async {
    final res = await http
        .get(
          Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$openWeatherAPIKey&units=metric',
          ),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<dynamic> list = data['list'];
      setState(() => forecastData = list);

      // 📅 Build 5-day daily forecast (pick one entry per day at noon)
      final Map<String, Map<String, dynamic>> dayMap = {};
      for (final item in list) {
        final dt = DateTime.parse(item['dt_txt']);
        final dayKey = '${dt.year}-${dt.month}-${dt.day}';
        // Prefer the 12:00 entry, else take first available
        if (!dayMap.containsKey(dayKey) || dt.hour == 12) {
          dayMap[dayKey] = {
            'date': dt,
            'temp_max': (item['main']['temp_max'] as num).toDouble(),
            'temp_min': (item['main']['temp_min'] as num).toDouble(),
            'icon': item['weather'][0]['icon'],
            'description': item['weather'][0]['description'],
          };
        }
      }

      setState(() {
        dailyForecast = dayMap.values.toList().take(5).toList();
      });
    }
  }

  // ☀️ UV Index using One Call API
  Future<void> _getUVIndex() async {
    if (lat == 0 && lon == 0) return;
    final res = await http
        .get(
          Uri.parse(
            'https://api.openweathermap.org/data/2.5/uvi?lat=$lat&lon=$lon&appid=$openWeatherAPIKey',
          ),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => uvIndex = (data['value'] as num).toDouble());
    }
  }

  // 🕐 Convert Unix timestamp to AM/PM time
  String _formatUnixTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $suffix';
  }

  // 🕐 Format forecast hour to AM/PM
  String formatHour(String dtTxt) {
    final dt = DateTime.parse(dtTxt);
    final hour = dt.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour $suffix';
  }

  // 📅 Format day name (Mon, Tue...)
  String formatDayName(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    if (dt.day == now.day) return 'Today';
    if (dt.day == now.day + 1) return 'Tomorrow';
    return days[dt.weekday - 1];
  }

  // ☀️ UV label
  String getUVLabel(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  Color getUVColor(double uv) {
    if (uv <= 2) return Colors.green;
    if (uv <= 5) return Colors.yellow[700]!;
    if (uv <= 7) return Colors.orange;
    if (uv <= 10) return Colors.red;
    return Colors.purple;
  }

  // 🌤 Weather icon mapping
  IconData getWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) return Icons.wb_sunny;
    if (iconCode.startsWith('02')) return Icons.wb_cloudy;
    if (iconCode.startsWith('03') || iconCode.startsWith('04'))
      return Icons.cloud;
    if (iconCode.startsWith('09')) return Icons.grain;
    if (iconCode.startsWith('10')) return Icons.umbrella;
    if (iconCode.startsWith('11')) return Icons.thunderstorm;
    if (iconCode.startsWith('13')) return Icons.ac_unit;
    if (iconCode.startsWith('50')) return Icons.foggy;
    return Icons.cloud;
  }

  // 🔍 City search dialog
  void _showCitySearch() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.blue[900],
            title: const Text(
              'Search City',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter city name...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    setState(() => cityName = controller.text.trim());
                    Navigator.pop(context);
                    _loadWeatherData();
                  }
                },
                child: Text(
                  'Search',
                  style: TextStyle(color: Colors.blue[900]),
                ),
              ),
            ],
          ),
    );
  }

  // 🚪 Logout confirmation dialog
  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.blue[900],
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'WEATHER WATCH',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              cityName,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showCitySearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWeatherData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[400]!, Colors.blue[900]!],
          ),
        ),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : errorMessage.isNotEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.white70,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadWeatherData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// ── MAIN CARD ──────────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    getWeatherIcon(weatherIcon),
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${temp.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      fontSize: 68,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    weatherDescription.capitalize(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Feels like ${feelsLike.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// ── SUNRISE / SUNSET & UV INDEX ────────────────
                        Row(
                          children: [
                            // Sunrise & Sunset card
                            Expanded(
                              child: _glassCard(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            const Icon(
                                              Icons.wb_twilight,
                                              color: Colors.orangeAccent,
                                              size: 28,
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Sunrise',
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              sunriseTime,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 1,
                                          height: 50,
                                          color: Colors.white24,
                                        ),
                                        Column(
                                          children: [
                                            const Icon(
                                              Icons.nightlight_round,
                                              color: Colors.blueAccent,
                                              size: 28,
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Sunset',
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              sunsetTime,
                                              style: const TextStyle(
                                                color: Colors.white,
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
                            ),

                            const SizedBox(width: 12),

                            // UV Index card
                            Expanded(
                              child: _glassCard(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.wb_sunny,
                                      color: Colors.yellowAccent,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'UV Index',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      uvIndex.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getUVColor(
                                          uvIndex,
                                        ).withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: getUVColor(
                                            uvIndex,
                                          ).withOpacity(0.6),
                                        ),
                                      ),
                                      child: Text(
                                        getUVLabel(uvIndex),
                                        style: TextStyle(
                                          color: getUVColor(uvIndex),
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

                        const SizedBox(height: 25),

                        /// ── HOURLY FORECAST ────────────────────────────
                        const Text(
                          "Hourly Forecast",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                forecastData.length > 8
                                    ? 8
                                    : forecastData.length,
                            itemBuilder: (context, index) {
                              final item = forecastData[index];
                              final fTemp = (item['main']['temp'] as num)
                                  .toStringAsFixed(0);
                              final iconCode = item['weather'][0]['icon'];

                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatHour(item['dt_txt']),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Icon(
                                      getWeatherIcon(iconCode),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "$fTemp°C",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// ── 5-DAY FORECAST ─────────────────────────────
                        const Text(
                          "5-Day Forecast",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        _glassCard(
                          child: Column(
                            children:
                                dailyForecast.map((day) {
                                  final dt = day['date'] as DateTime;
                                  final icon = day['icon'] as String;
                                  final desc =
                                      (day['description'] as String)
                                          .capitalize();
                                  final tMax = (day['temp_max'] as double)
                                      .toStringAsFixed(0);
                                  final tMin = (day['temp_min'] as double)
                                      .toStringAsFixed(0);
                                  final isLast = dailyForecast.last == day;

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          // Day name
                                          SizedBox(
                                            width: 90,
                                            child: Text(
                                              formatDayName(dt),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          // Icon + description
                                          Icon(
                                            getWeatherIcon(icon),
                                            color: Colors.white70,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              desc,
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Temp range
                                          Text(
                                            '$tMax° / $tMin°',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isLast)
                                        Divider(
                                          color: Colors.white.withOpacity(0.15),
                                          height: 20,
                                        ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// ── DETAILS GRID ───────────────────────────────
                        const Text(
                          "Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.8,
                          children: [
                            WeatherDetailCard(
                              icon: Icons.water_drop,
                              label: 'Humidity',
                              value: '${humidity.toInt()}%',
                            ),
                            WeatherDetailCard(
                              icon: Icons.air,
                              label: 'Wind Speed',
                              value: '${windSpeed.toStringAsFixed(1)} m/s',
                            ),
                            WeatherDetailCard(
                              icon: Icons.compress,
                              label: 'Pressure',
                              value: '${pressure.toInt()} hPa',
                            ),
                            WeatherDetailCard(
                              icon: Icons.thermostat,
                              label: 'Feels Like',
                              value: '${feelsLike.toStringAsFixed(1)}°C',
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  /// Reusable glassmorphism card
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
