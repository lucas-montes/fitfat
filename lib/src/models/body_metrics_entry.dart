/// Plain domain model for one day's body metrics entry (weight and/or height).
final class BodyMetricsEntry {
  final String id;
  final DateTime day; // start-of-day
  final double? weightKg;
  final double? heightCm;
  final DateTime createdAt;

  const BodyMetricsEntry({
    required this.id,
    required this.day,
    this.weightKg,
    this.heightCm,
    required this.createdAt,
  });
}
