/// Static activity level used to scale BMR into TDEE when the user is not
/// computing activity from workouts + steps.
enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  /// Standard PAL multiplier applied to BMR.
  final double multiplier;

  const ActivityLevel(this.multiplier);
}
