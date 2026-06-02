// ---------------------------------------------------------------------------
// Shared enums used across the app
// ---------------------------------------------------------------------------

/// Biological sex / gender identity used for BMR computation and display.
enum Gender { male, female }

extension GenderLabel on Gender {
  String get label => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
  };
}
