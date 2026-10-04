import 'package:fitfat/src/models/units.dart';
import 'package:fitfat/src/ui/units.dart';
import 'package:flutter_test/flutter_test.dart';

/// Weekly tonnage crosses into five figures, so `formatVolume` compacts to metric
/// tonnes at 1000 kg. The threshold is the whole feature, and it sits on a
/// boundary, so both sides of it are pinned.
void main() {
  group('formatVolume', () {
    test('stays in kg below a tonne', () {
      expect(formatVolume(0, WeightUnit.kg), '0.0 kg');
      expect(formatVolume(482.5, WeightUnit.kg), '482.5 kg');
      expect(formatVolume(999.9, WeightUnit.kg), '999.9 kg');
    });

    test('switches to tonnes at exactly 1000 kg', () {
      expect(formatVolume(1000, WeightUnit.kg), '1.0 t');
      expect(formatVolume(1000.4, WeightUnit.kg), '1.0 t');
    });

    test('compacts large volumes', () {
      expect(formatVolume(48210, WeightUnit.kg), '48.2 t');
      expect(formatVolume(1234, WeightUnit.kg), '1.2 t');
    });

    test('respects the display unit below the threshold', () {
      // 100 kg is 220.5 lb, and must be shown in lb for an lb user.
      expect(formatVolume(100, WeightUnit.lb), '220.5 lb');
      expect(formatVolume(100, WeightUnit.kg), '100.0 kg');
    });

    test('compacts a lb user by magnitude, not by their unit', () {
      // The threshold is on stored kg, so 1000 kg becomes 1.0 t rather than
      // waiting for 2205 lb. Otherwise a lb user sees a five-figure number in a
      // tile a third of the screen wide.
      expect(formatVolume(1000, WeightUnit.lb), '1.0 t');
      expect(formatVolume(2204.6, WeightUnit.lb), '2.2 t');
    });

    test('negative volumes keep the sign', () {
      expect(formatVolume(-1500, WeightUnit.kg), '-1.5 t');
      expect(formatVolume(-500, WeightUnit.kg), '-500.0 kg');
    });
  });
}
