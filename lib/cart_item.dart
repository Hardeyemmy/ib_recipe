class CartItem {
  final String recipeId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.recipeId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}
