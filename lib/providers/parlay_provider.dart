import 'package:flutter/material.dart';
import '../models/parlay.dart';
import '../models/parlay_leg.dart';

class ParlayProvider extends ChangeNotifier {
  final List<Parlay> _parlays = [];
  double _bankroll = 7500000; // Rp7.5M

  List<Parlay> get parlays => _parlays;
  double get bankroll => _bankroll;

  List<Parlay> get activeParlays =>
      _parlays.where((p) => p.overallStatus == 'PENDING').toList();

  List<Parlay> get completedParlays =>
      _parlays.where((p) => p.overallStatus != 'PENDING').toList();

  int get totalWins =>
      _parlays.where((p) => p.overallStatus == 'WIN').length;

  int get totalLoses =>
      _parlays.where((p) => p.overallStatus == 'LOSE').length;

  double get totalProfit =>
      _parlays.where((p) => p.overallStatus != 'PENDING').fold(
            0.0,
            (sum, p) => sum + p.profit,
          );

  double get winRate => _parlays.isEmpty
      ? 0
      : totalWins / (totalWins + totalLoses);

  // Leg-level stats
  int get totalLegs =>
      _parlays.expand((p) => p.legs).length;

  int get totalLegWins =>
      _parlays.expand((p) => p.legs).where((l) => l.status == 'win').length;

  int get totalLegLoses =>
      _parlays.expand((p) => p.legs).where((l) => l.status == 'lose').length;

  double get legWinRate => totalLegs == 0
      ? 0
      : totalLegWins / totalLegs;

  // Market breakdown
  Map<String, int> get marketWins {
    final result = <String, int>{};
    for (final leg in _parlays.expand((p) => p.legs)) {
      if (leg.status == 'win') {
        result[leg.market] = (result[leg.market] ?? 0) + 1;
      }
    }
    return result;
  }

  Map<String, int> get marketTotals {
    final result = <String, int>{};
    for (final leg in _parlays.expand((p) => p.legs)) {
      result[leg.market] = (result[leg.market] ?? 0) + 1;
    }
    return result;
  }

  void addParlay(Parlay parlay) {
    _parlays.insert(0, parlay);
    _bankroll -= parlay.stake;
    notifyListeners();
  }

  void updateLegResult(
    String parlayId,
    int legIndex,
    int homeScore,
    int awayScore,
  ) {
    final parlay = _parlays.firstWhere((p) => p.id == parlayId);
    final leg = parlay.legs[legIndex];
    leg.homeScore = homeScore;
    leg.awayScore = awayScore;

    // Evaluate result based on market
    leg.status = _evaluateLeg(leg, homeScore, awayScore);

    // If parlay completed, update bankroll
    if (parlay.overallStatus == 'WIN') {
      _bankroll += parlay.estimatedPayout;
    } else if (parlay.overallStatus == 'REFUND') {
      _bankroll += parlay.stake;
    }

    notifyListeners();
  }

  String _evaluateLeg(ParlayLeg leg, int hs, int as_) {
    switch (leg.market) {
      case '1X2':
        if (leg.pick.contains('Home')) return hs > as_ ? 'win' : (hs == as_ ? 'push' : 'lose');
        if (leg.pick.contains('Away')) return as_ > hs ? 'win' : (hs == as_ ? 'push' : 'lose');
        return hs == as_ ? 'win' : 'lose'; // Draw pick
      case 'AH':
        final hcp = leg.handicap ?? 0;
        if (leg.pick.contains('Home')) {
          final diff = (hs - as_) + hcp;
          if (diff > 0) return 'win';
          if (diff == 0) return 'push';
          return 'lose';
        } else {
          final diff = (as_ - hs) - hcp;
          if (diff > 0) return 'win';
          if (diff == 0) return 'push';
          return 'lose';
        }
      case 'O/U':
        final total = hs + as_;
        final line = leg.line ?? 2.5;
        if (leg.pick.contains('Over')) {
          if (total > line) return 'win';
          if (total == line) return 'push';
          return 'lose';
        } else {
          if (total < line) return 'win';
          if (total == line) return 'push';
          return 'lose';
        }
      case 'Odd/Even':
        final total = hs + as_;
        final isEven = total % 2 == 0;
        if (leg.pick.contains('Even')) return isEven ? 'win' : 'lose';
        return isEven ? 'lose' : 'win';
      default:
        return 'pending';
    }
  }

  void setBankroll(double value) {
    _bankroll = value;
    notifyListeners();
  }
}
