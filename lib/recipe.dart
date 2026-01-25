class Recipe {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<Ingredient> ingredients;

  Recipe(
      {required this.id,
      required this.name,
      required this.imageUrl,
      required this.description,
      required this.ingredients});
}

class Ingredient {
  final String name;
  final String description;

  Ingredient({required this.name, required this.description});
}
