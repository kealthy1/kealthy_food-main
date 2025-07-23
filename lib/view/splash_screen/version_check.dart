import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  static const String appStoreId =
      "6740621148"; // Replace with your actual App Store ID

  static Future<String?> _fetchLatestVersion() async {
    // DEBUG
    print("🔍 [VersionCheckService] _fetchLatestVersion() called...");

    try {
      final url =
          Uri.parse("https://itunes.apple.com/in/lookup?id=$appStoreId");
      print("🌐 [VersionCheckService] GET → $url");

      final response = await http.get(url);
      print("📥 [VersionCheckService] Response code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print("📄 [VersionCheckService] Response body: $jsonData");

        if (jsonData['resultCount'] > 0) {
          final storeVersion = jsonData['results'][0]['version'];
          print(
              "✅ [VersionCheckService] Latest App Store version: $storeVersion");
          return storeVersion;
        } else {
          print(
              "⚠️ [VersionCheckService] resultCount=0, no app found in the App Store for this ID.");
        }
      } else {
        print(
            "❌ [VersionCheckService] Failed to fetch version. HTTP status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [VersionCheckService] Error fetching latest version: $e");
    }

    // If we got here, something failed
    return null;
  }

  static Future<String> _getCurrentVersion() async {
    print("🔍 [VersionCheckService] _getCurrentVersion() called...");
    final packageInfo = await PackageInfo.fromPlatform();
    print(
        "✅ [VersionCheckService] Current installed version: ${packageInfo.version}");
    return packageInfo.version;
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    print("🔔 [VersionCheckService] checkForUpdate() called...");
    String currentVersion = await _getCurrentVersion();
    String? latestVersion = await _fetchLatestVersion();

    print(
        "🔖 [VersionCheckService] currentVersion=$currentVersion | latestVersion=$latestVersion");

    if (latestVersion == null) {
      print(
          "⚠️ [VersionCheckService] latestVersion is null. No update dialog will show.");
      return;
    }

    bool needsUpdate = _isUpdateAvailable(currentVersion, latestVersion);
    print("🤔 [VersionCheckService] _isUpdateAvailable=$needsUpdate");

    if (needsUpdate) {
      print("💡 [VersionCheckService] Showing update dialog...");
      await _showUpdateDialog(context, latestVersion);
    } else {
      print("✅ [VersionCheckService] No update required.");
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    // DEBUG
    print(
        "🔍 [VersionCheckService] _isUpdateAvailable() → Comparing $currentVersion to $latestVersion");

    final currentParts = currentVersion.split('.').map(int.tryParse).toList();
    final latestParts = latestVersion.split('.').map(int.tryParse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      final latestPart = latestParts[i] ?? 0;
      final currentPart = i < currentParts.length ? (currentParts[i] ?? 0) : 0;

      if (latestPart > currentPart) {
        // A higher number in the same position means a newer version
        return true;
      } else if (latestPart < currentPart) {
        // Current version is actually ahead (which typically shouldn't happen in production)
        return false;
      }
      // If they are equal, continue comparing next position
    }
    return false;
  }

  static Future<void> _showUpdateDialog(
      BuildContext context, String latestVersion) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Small delay for smooth transition
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => WillPopScope(
        onWillPop: () async {
          print("🚫 [VersionCheckService] Back button pressed, ignoring...");
          return false;
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Update Available",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Lottie.asset(
                'lib/assets/animations/Download App Update.json',
                width: 200,
                height: 200,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 12),
              Text(
                "A new version ($latestVersion) is available. Please update to continue.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  const storeUrl =
                      "https://apps.apple.com/in/app/id$appStoreId";
                  print(
                      "➡️ [VersionCheckService] Opening App Store URL: $storeUrl");
                  launchUrl(
                    Uri.parse(storeUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Text(
                  "Update Now",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    print("🕒 [VersionCheckService] Update bottom sheet closed.");
  }
}
