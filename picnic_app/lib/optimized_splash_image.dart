import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';

class OptimizedSplashImage extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const OptimizedSplashImage({
    super.key,
    required this.ref,
  });

  @override
  ConsumerState<OptimizedSplashImage> createState() =>
      _OptimizedSplashImageState();
}

class _OptimizedSplashImageState extends ConsumerState<OptimizedSplashImage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Image.asset(
            'assets/splash.webp',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (!ref.watch(appInitializationProvider).isInitialized)
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
