class ParlayLeg {
  final String league;
  final String homeTeam;
  final String awayTeam;
  final String market; // 1X2, AH, O/U, Odd/Even
  final String pick; // e.g. "Home", "Away", "Over 2.5", "Even"
  final double odds;
  final double? handicap; // for AH
  final double? line; // for O/U
  int? homeScore;
  int? awayScore;
  String status; // pending, win, lose, push, refund

  ParlayLeg({
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    required this.market,
    required this.pick,
    required this.odds,
    this.handicap,
    this.line,
    this.homeScore,
    this.awayScore,
    this.status = 'pending',
  });

  double get totalGoals => (homeScore ?? 0).toDouble() + (awayScore ?? 0).toDouble();

  double get effectiveOdds =>
      status == 'refund' || status == 'push' ? 1.0 : odds;

  Map<String, dynamic> toJson() => {
        'league': league,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'market': market,
        'pick': pick,
        'odds': odds,
        'handicap': handicap,
        'line': line,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'status': status,
      };

  factory ParlayLeg.fromJson(Map<String, dynamic> json) => ParlayLeg(
        league: json['league'],
        homeTeam: json['homeTeam'],
        awayTeam: json['awayTeam'],
        market: json['market'],
        pick: json['pick'],
        odds: (json['odds'] as num).toDouble(),
        handicap: json['handicap'] != null
            ? (json['handicap'] as num).toDouble()
            : null,
        line:
            json['line'] != null ? (json['line'] as num).toDouble() : null,
        homeScore: json['homeScore'],
        awayScore: json['awayScore'],
        status: json['status'] ?? 'pending',
      );
}
