import 'package:fitfat/src/dashboard/screens/dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replaces the `CalorieBar.geometryFor` coverage deleted with the widget.
///
/// What mattered there was still true after the redesign: the fill clamps at the
/// end of the track, and crossing the target is detectable separately from the
/// fill so the colour can change.
void main() {
  group('macroRowState', () {
    test('fills proportionally below the target', () {
      expect(
        macroRowState(consumed: 1500, target: 3000).ratio,
        closeTo(0.5, 1e-9),
      );
      expect(
        macroRowState(consumed: 300, target: 3000).ratio,
        closeTo(0.1, 1e-9),
      );
      expect(macroRowState(consumed: 0, target: 3000).ratio, 0);
    });

    test('clamps the fill at the end of the track however far over', () {
      expect(macroRowState(consumed: 3900, target: 3000).ratio, 1.0);
      expect(macroRowState(consumed: 99999, target: 3000).ratio, 1.0);
    });

    test('reports crossing the target, which the fill alone cannot show', () {
      expect(macroRowState(consumed: 3001, target: 3000).over, isTrue);
      expect(macroRowState(consumed: 2999, target: 3000).over, isFalse);
      // Exactly on target is not over.
      expect(macroRowState(consumed: 3000, target: 3000).over, isFalse);
    });

    test('a zero target yields an empty bar and never claims to be over', () {
      // Clamped carbs can drive a target to 0; dividing by it would be NaN and
      // "consumed > 0" would wrongly read as overshooting.
      final state = macroRowState(consumed: 50, target: 0);
      expect(state.ratio, 0);
      expect(state.over, isFalse);
    });

    test('a negative target is treated as unset, not as overshoot', () {
      final state = macroRowState(consumed: 50, target: -100);
      expect(state.ratio, 0);
      expect(state.over, isFalse);
    });
  });
}