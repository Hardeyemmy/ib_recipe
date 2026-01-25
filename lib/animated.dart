import 'package:flutter/material.dart';

class AnimatedCard extends StatelessWidget {
  const AnimatedCard(
      {required this.elevation,
      required this.duration,
      required this.child,
      super.key});

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
