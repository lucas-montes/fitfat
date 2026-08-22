/// Plain domain model for a store prices can be recorded at.
final class Store {
  final String id;
  final String name;
  final DateTime createdAt;

  const Store({required this.id, required this.name, required this.createdAt});
}
