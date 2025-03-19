import 'package:ntp/ntp.dart';

class AvailableSlotsGenerator {
  final int slotDurationMinutes;

  AvailableSlotsGenerator({
    required this.slotDurationMinutes,
  });

  Future<List<Map<String, DateTime>>> getAvailableSlots(
    DateTime startBoundary,
    DateTime endBoundary,
    DateTime currentTime,
    double etaMinutes,
  ) async {
    DateTime etaPlusBreak = currentTime;

    DateTime adjustedStartTime = DateTime(
      etaPlusBreak.year,
      etaPlusBreak.month,
      etaPlusBreak.day,
      ((etaPlusBreak.hour ~/ 3) + 1) * 3,
    );

    if (adjustedStartTime.isBefore(startBoundary)) {
      adjustedStartTime = startBoundary;
    }

    List<Map<String, DateTime>> slots = [];

    while (adjustedStartTime.isBefore(endBoundary)) {
      DateTime slotEndTime = adjustedStartTime.add(const Duration(hours: 3));

      if (slotEndTime.isAfter(endBoundary)) {
        slotEndTime = endBoundary;
      }

      slots.add({"start": adjustedStartTime, "end": slotEndTime});

      adjustedStartTime = slotEndTime;
    }

    return slots;
  }

  Future<Map<String, dynamic>> getSlots(double etaMinutes) async {
    DateTime currentTime = await NTP.now();

    DateTime todayStartBoundary = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      9,
    );

    DateTime todayEndBoundary = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      18,
    );

    DateTime endBoundary = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      15,
    );

    DateTime tomorrowStartBoundary = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day + 1,
      9,
    );

    DateTime tomorrowEndBoundary = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day + 1,
      18,
    );

    if (currentTime.isAfter(endBoundary)) {
      return {
        "slots": await getAvailableSlots(tomorrowStartBoundary,
            tomorrowEndBoundary, currentTime, etaMinutes),
        "message": "No slots today. Book from 9 AM tomorrow!",
      };
    } else if (currentTime.isBefore(todayStartBoundary)) {
      return {
        "slots": await getAvailableSlots(
            todayStartBoundary, todayEndBoundary, currentTime, etaMinutes),
        "message": "Available Time Slots For Today!",
      };
    } else {
      return {
        "slots": await getAvailableSlots(
            todayStartBoundary, todayEndBoundary, currentTime, etaMinutes),
        "message": "Available Time Slots For Today!",
      };
    }
  }
}