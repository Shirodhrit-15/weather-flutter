import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late double temp = 0;
  late String weatherDescription = '';
  late double humidity = 0;
  late double windSpeed = 0;
  late double pressure = 0;
  late double feelsLike = 0;
  late String weatherIcon = '';
  List<dynamic> forecastData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() => isLoading = true);
    await Future.wait([_getCurrentWeather(), _getForecastData()]);
    setState(() => isLoading = false);
  }

  Future<void> _getCurrentWeather() async {
    const cityName = 'Kolkata';
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$openWeatherAPIKey&units=metric',
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.getBody(res));
        setState(() {
          temp = (data['main']['temp'] as num).toDouble();
          weatherDescription = data['weather'][0]['description'];
          humidity = (data['main']['humidity'] as num).toDouble();
          windSpeed = (data['wind']['speed'] as num).toDouble();
          pressure = (data['main']['pressure'] as num).toDouble();
          feelsLike = (data['main']['feels_like'] as num).toDouble();
          weatherIcon = data['weather'][0]['icon'];
        });
      } else {
        debugPrint('Error ${res.statusCode}: Unable to fetch weather data.');
      }
    } catch (e) {
      debugPrint('Current weather error: $e');
    }
  }

  Future<void> _getForecastData() async {
    const cityName = 'Kolkata';
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$openWeatherAPIKey&units=metric',
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          forecastData = data['list'];
        });
      } else {
        debugPrint('Error ${res.statusCode}: Unable to fetch forecast data.');
      }
    } catch (e) {
      debugPrint('Forecast error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Weather Card
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        color: const Color(0xFF333333),
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    '${temp.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(
                                    weatherIcon == '10d'
                                        ? Icons.thunderstorm
                                        : weatherIcon == '01d'
                                        ? Icons.sunny
                                        : Icons.cloud,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    weatherDescription.capitalize(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Hourly Forecast
                    const SizedBox(height: 20),
                    const Text(
                      "Hourly Forecast",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Horizontal scrolling for hourly forecast
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            forecastData.map((item) {
                              final time = DateTime.parse(item['dt_txt']);
                              final temp = (item['main']['temp'] as num)
                                  .toStringAsFixed(0);
                              return Container(
                                width: 80, // Adjust width of each item
                                height:
                                    100, // Adjust height to make it fit with padding
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(
                                  4,
                                ), // Reduced padding to fit content
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${time.hour}:00',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Icon(
                                      Icons
                                          .cloud, // You can replace with dynamic icons
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '$temp°C',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Additional Information
                    const Text(
                      "Additional Information",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        AdditionalInfoItem(
                          icon: Icons.water_drop,
                          label: 'Humidity',
                          value: humidity.toString(),
                        ),
                        AdditionalInfoItem(
                          icon: Icons.wind_power,
                          label: 'Wind Speed',
                          value: windSpeed.toString(),
                        ),
                        AdditionalInfoItem(
                          icon: Icons.air,
                          label: 'Pressure',
                          value: pressure.toString(),
                        ),
                        AdditionalInfoItem(
                          icon: Icons.thermostat,
                          label: 'Feels Like',
                          value: feelsLike.toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
