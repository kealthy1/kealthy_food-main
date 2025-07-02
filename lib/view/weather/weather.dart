import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Replace with your actual OpenWeatherMap API key
const String apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  final position = await Geolocator.getCurrentPosition();
  final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric');

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Failed to load weather');
  }

  final data = jsonDecode(response.body);
  return WeatherData.fromJson(data);
});

class WeatherPage extends ConsumerWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Weather Update")),
      body: weatherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (weather) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weather.city,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Image.network(
                  'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                  width: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  "${weather.temp.toStringAsFixed(1)} °C",
                  style: const TextStyle(fontSize: 40),
                ),
                Text(
                  weather.description,
                  style: const TextStyle(
                      fontSize: 18, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WeatherData {
  final String city;
  final double temp;
  final String description;
  final String icon;

  WeatherData({
    required this.city,
    required this.temp,
    required this.description,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['name'],
      temp: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
    );
  }
}
