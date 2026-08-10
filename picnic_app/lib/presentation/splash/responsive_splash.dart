import 'package:flutter/material.dart';

class ResponsiveSplash extends StatelessWidget {
  const ResponsiveSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('responsive-splash-background'),
      color: const Color(0xFF8B6CF6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 440,
            maxHeight: 960,
          ),
          child: FittedBox(
            key: const Key('responsive-splash-fitted-box'),
            fit: BoxFit.contain,
            child: Image.asset(
              'assets/splash_key.png',
              key: const Key('responsive-splash-key-image'),
            ),
          ),
        ),
      ),
    );
  }
}
