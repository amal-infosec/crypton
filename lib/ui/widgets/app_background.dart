import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF080808), Color(0xFF0F0F11)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Subtle purple glow positioned at the top right
        Positioned(
          top: -200, right: -200,
          child: Container(
            width: 800, height: 800,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF7C3AED).withOpacity(0.03), Colors.transparent],
              ),
            ),
          ),
        ),
        // Foreground content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
