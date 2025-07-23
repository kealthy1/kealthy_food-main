import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

const kGoogleApiKey =
    "AIzaSyD1MUoakZ0mm8WeFv_GK9k_zAWdGk5r1hA"; // Replace this!

void main() {
  runApp(const RoutesWidget());
}

final customTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
      .copyWith(secondaryContainer: Colors.redAccent),
  brightness: Brightness.dark,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.00)),
    ),
    contentPadding: EdgeInsets.symmetric(
      vertical: 12.50,
      horizontal: 10.00,
    ),
  ),
);

class RoutesWidget extends StatelessWidget {
  const RoutesWidget({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: "My App",
        theme: customTheme,
        routes: {
          "/": (_) => const MyApp(),
          "/search": (_) => CustomSearchScaffold(),
        },
      );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

final homeScaffoldKey = GlobalKey<ScaffoldMessengerState>();
final searchScaffoldKey = GlobalKey<ScaffoldMessengerState>();

class _MyAppState extends State<MyApp> {
  Mode _mode = Mode.overlay;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: homeScaffoldKey,
      child: Scaffold(
        appBar: AppBar(title: const Text("My App")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildDropdownMenu(),
              ElevatedButton(
                onPressed: _handlePressButton,
                child: const Text("Search places"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed("/search");
                },
                child: const Text("Custom"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() => DropdownButton<Mode>(
        value: _mode,
        items: const [
          DropdownMenuItem(value: Mode.overlay, child: Text("Overlay")),
          DropdownMenuItem(value: Mode.fullscreen, child: Text("Fullscreen")),
        ],
        onChanged: (m) {
          if (m != null) {
            setState(() {
              _mode = m;
            });
          }
        },
      );

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text(response.errorMessage ?? "Unknown error")),
    );
  }

  Future<void> _handlePressButton() async {
    final p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      onError: onError,
      mode: _mode,
      language: "en",
      decoration: InputDecoration(
        hintText: 'Search',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      components: [Component(Component.country, "us")],
    );

    if (p != null) {
      await displayPrediction(p, homeScaffoldKey.currentState);
    }
  }
}

Future<void> displayPrediction(
    Prediction p, ScaffoldMessengerState? messenger) async {
  final places = GoogleMapsPlaces(
    apiKey: kGoogleApiKey,
    apiHeaders: await const GoogleApiHeaders().getHeaders(),
  );
  final detail = await places.getDetailsByPlaceId(p.placeId!);
  final lat = detail.result.geometry?.location.lat;
  final lng = detail.result.geometry?.location.lng;

  messenger?.showSnackBar(
    SnackBar(content: Text("${p.description} - $lat/$lng")),
  );
}

class CustomSearchScaffold extends PlacesAutocompleteWidget {
  CustomSearchScaffold({super.key})
      : super(
          apiKey: kGoogleApiKey,
          sessionToken: Uuid().generateV4(),
          language: "en",
          components: [Component(Component.country, "us")],
        );

  @override
  _CustomSearchScaffoldState createState() => _CustomSearchScaffoldState();
}

class _CustomSearchScaffoldState extends PlacesAutocompleteState {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const AppBarPlacesAutoCompleteTextField());
    final body = PlacesAutocompleteResult(
      onTap: (p) {
        displayPrediction(p, searchScaffoldKey.currentState);
      },
      logo: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [FlutterLogo()],
      ),
    );

    return ScaffoldMessenger(
      key: searchScaffoldKey,
      child: Scaffold(appBar: appBar, body: body),
    );
  }

  @override
  void onResponseError(PlacesAutocompleteResponse response) {
    super.onResponseError(response);
    searchScaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text(response.errorMessage ?? "Error")),
    );
  }

  @override
  void onResponse(PlacesAutocompleteResponse? response) {
    super.onResponse(response);
    if (response?.predictions.isNotEmpty == true) {
      searchScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text("Got answer")),
      );
    }
  }
}

class Uuid {
  final Random _random = Random();

  String generateV4() {
    final int special = 8 + _random.nextInt(4);

    return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
        '${_bitsDigits(16, 4)}-'
        '4${_bitsDigits(12, 3)}-'
        '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
        '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
  }

  String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

  String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
}
