import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  static const String appStoreId = "6740621148"; // Replace with your actual App Store ID

  static Future<String?> _fetchLatestVersion() async {
    // DEBUG
    print("🔍 [VersionCheckService] _fetchLatestVersion() called...");

    try {
      // You can remove "/in/" if you're unsure about the region:
      // final url = Uri.parse("https://itunes.apple.com/lookup?id=$appStoreId");
      final url = Uri.parse("https://itunes.apple.com/in/lookup?id=$appStoreId");
      print("🌐 [VersionCheckService] GET → $url");

      final response = await http.get(url);
      print("📥 [VersionCheckService] Response code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print("📄 [VersionCheckService] Response body: $jsonData");

        if (jsonData['resultCount'] > 0) {
          final storeVersion = jsonData['results'][0]['version'];
          print("✅ [VersionCheckService] Latest App Store version: $storeVersion");
          return storeVersion;
        } else {
          print("⚠️ [VersionCheckService] resultCount=0, no app found in the App Store for this ID.");
        }
      } else {
        print("❌ [VersionCheckService] Failed to fetch version. HTTP status: ${response.statusCode}");
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
    print("✅ [VersionCheckService] Current installed version: ${packageInfo.version}");
    return packageInfo.version;
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    print("🔔 [VersionCheckService] checkForUpdate() called...");
    String currentVersion = await _getCurrentVersion();
    String? latestVersion = await _fetchLatestVersion();

    print("🔖 [VersionCheckService] currentVersion=$currentVersion | latestVersion=$latestVersion");

    if (latestVersion == null) {
      print("⚠️ [VersionCheckService] latestVersion is null. No update dialog will show.");
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
    print("🔍 [VersionCheckService] _isUpdateAvailable() → Comparing $currentVersion to $latestVersion");

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

  static Future<void> _showUpdateDialog(BuildContext context, String latestVersion) async {
    await showDialog(
      barrierDismissible: false, // Prevent accidental dismiss
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          print("🚫 [VersionCheckService] Back button pressed, ignoring...");
          return false; // Prevent back button from closing
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),),
          title: Text(
            "Update Available",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "A new version ($latestVersion) is available. Please update to continue.",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                const storeUrl = "https://apps.apple.com/in/app/id$appStoreId";
                print("➡️ [VersionCheckService] Opening App Store URL: $storeUrl");
                launchUrl(
                  Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Text(
                "Update Now",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    print("🕒 [VersionCheckService] Update dialog closed.");
  }
}