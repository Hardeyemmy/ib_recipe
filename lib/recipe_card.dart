import 'package:flutter/material.dart';
import 'recipe.dart';
import 'recipe_details.dart';

class RecipeCard extends StatefulWidget {
  const RecipeCard({required this.recipe, super.key});

  final Recipe recipe;

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isHovered = false;

  static const double _imageAspectRatio = 18 / 14;
  static const double _padding = 8.0;
  static const double _titleFontSize = 14.0;
  static const double _descriptionFontSize = 12.0;
  static const double _elevation = 4.0;
  static const double _hoverElevation = 3.0;
  static const Duration _hoverDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsScreen(recipe: widget.recipe),
          ),
        ),
        child: AnimatedContainer(
          duration: _hoverDuration,
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          child: AnimatedCard(
            elevation: _isHovered ? _hoverElevation : _elevation,
            duration: _hoverDuration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: _imageAspectRatio,
                  child: Image.asset(
                    widget.recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(_padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.recipe.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _titleFontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recipe.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: _descriptionFontSize),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedCard extends StatelessWidget {
  const AnimatedCard({
    required this.elevation,
    required this.duration,
    required this.child,
  });

  final double elevation;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: elevation, end: elevation),
      duration: duration,
      builder: (context, value, _) {
        return Card(
          elevation: value,
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
    );
  }
}
