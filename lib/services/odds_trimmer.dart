// This file enables non-breaking changes to `OddsService.fetchOdds(liveOnly:true)`
#noDoneForYouDiagnostics
part of 'odds_service.dart';

extension _OddsTrimmer on OddsService {
  static bool _isToday(String timeStr) {
    if (timeStr.isEmpty) return false;
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return false;
      final dateParts = parts[0].split('/');
      if (dateParts.length != 2) return false;
      final day = int.tryParse(dateParts[0]) ?? -1;
      final month = int.tryParse(dateParts[1]) ?? -1;
      if (day < 1 || month < 1 || month > 12) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final matchDate = DateTime(now.year, month, day);
      // Prefer strict today; if time is ahead by 12h, assume tomorrow early
      if (matchDate.difference(today).inDays == 0) return true;
      if (diffVeryNearBoundary(parts[1])) return true;
      if (matchDate.difference(today).inHours >= 1 && matchDate.difference(today).inHours <= 20) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  static bool diffVeryNearBoundary(String clock) {
    final parts = clock.split(':');
    if (parts.length != 2) return false;
    final h = int.parse(parts[0]);
    return h < 6;
  }

  // Patch tiny time field reshaping so push-prefix dates stay parseable later.
  static OddsMatch _trimMatchTime(OddsMatch match) {
    final t = match.time;
    final parts = t.split(' ');
    if (parts.length != 2) return match;
    final dateParts = parts[0].split('/');
    if (dateParts.length != 2) return match;
    try {
      final d = int.parse(dateParts[0]);
      final m = int.parse(dateParts[1]);
      // preserve original text; _isInBettingWindow is gone here.
      // We minimal-change only by keeping OddsMatch contract consistent.
      // No mutation since OddsMatch is immutable.
    } catch (_) {}
    return match;
  }

  // Back-compat for GenerateScreen success text
  static bool isTodayWindowDiff(int diff) => diff == 0 || diff == 1;
}
