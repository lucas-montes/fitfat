import 'package:flutter_riverpod/flutter_riverpod.dart';

final class StartupGate extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}

final startupGateProvider = NotifierProvider<StartupGate, bool>(
  StartupGate.new,
);
