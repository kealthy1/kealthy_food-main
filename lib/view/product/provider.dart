import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final averageStarsProvider =
    FutureProvider.family<double, String>((ref, productName) async {
  try {
    final encodedProductName = Uri.encodeComponent(productName);
    const apiUrl = "https://api-jfnhkjk4nq-uc.a.run.app/rate";
    final fullUrl = '$apiUrl/$encodedProductName';

    print('Fetching rating from: $fullUrl');

    final response = await http.get(Uri.parse(fullUrl));

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['averageStars'] != null) {
        return double.tryParse(data['averageStars'].toString()) ?? 0.0;
      }
    }
    print('⚠️ Invalid API response: Returning 0.0');
    return 0.0; // Default value if API fails
  } catch (e) {
    print('❌ Error fetching average stars: $e');
    return 0.0; // Return default instead of null
  }
});