/// Plain domain model for a picture attached to an ingredient.
///
/// Rows are ordered per ingredient via [sortOrder]; the gallery renders them
/// in that order and reorder rewrites it densely.
final class IngredientPicture {
  final String id;
  final String ingredientId;
  // Local filesystem path of the saved image.
  final String imagePath;
  final int sortOrder;
  final DateTime createdAt;

  const IngredientPicture({
    required this.id,
    required this.ingredientId,
    required this.imagePath,
    required this.sortOrder,
    required this.createdAt,
  });
}
