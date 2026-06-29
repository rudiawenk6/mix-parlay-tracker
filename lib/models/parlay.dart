import 'parlay_leg.dart';

class Parlay {
  final String id;
  final DateTime date;
  final List<ParlayLeg> legs;
  double stake;
  String note;

  Parlay({
    required this.id,
    required this.date,
    required this.legs,
    this.stake = 55.0,
    this.note = '',
  });

  double get totalOdds {
    double result = 1.0;
    for (final leg in legs) {
      if (leg.status == 'lose') return 0.0;
      result *= leg.effectiveOdds;
    }
    return result;
  }

  double get estimatedPayout => stake * totalOdds;

  int get winCount => legs.where((l) => l.status == 'win').length;
  int get loseCount => legs.where((l) => l.status == 'lose').length;
  int get pushCount =>
      legs.where((l) => l.status == 'push' || l.status == 'refund').length;
  int get pendingCount => legs.where((l) => l.status == 'pending').length;

  String get overallStatus {
    if (loseCount > 0) return 'LOSE';
    if (pendingCount > 0) return 'PENDING';
    if (legs.every((l) => l.status == 'push' || l.status == 'refund')) {
      return 'REFUND';
    }
    return 'WIN';
  }

  double get profit {
    if (overallStatus == 'LOSE') return -stake;
    if (overallStatus == 'PENDING') return 0;
    return estimatedPayout - stake;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'legs': legs.map((l) => l.toJson()).toList(),
        'stake': stake,
        'note': note,
      };

  factory Parlay.fromJson(Map<String, dynamic> json) => Parlay(
        id: json['id'],
        date: DateTime.parse(json['date']),
        legs: (json['legs'] as List)
            .map((l) => ParlayLeg.fromJson(l))
            .toList(),
        stake: (json['stake'] as num).toDouble(),
        note: json['note'] ?? '',
      );
}
