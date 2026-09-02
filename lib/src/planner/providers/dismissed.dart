import 'package:flutter_riverpod/flutter_riverpod.dart';

final class DismissedTaskIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String id) => state = {...state, id};
  void remove(String id) => state = state.where((e) => e != id).toSet();
  void clear(String id) => remove(id);
}

final dismissedTaskIdsProvider =
    NotifierProvider<DismissedTaskIds, Set<String>>(DismissedTaskIds.new);
