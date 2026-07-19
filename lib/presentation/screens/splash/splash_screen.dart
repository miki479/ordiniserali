import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shown while Firebase reports the initial auth state, avoiding a flash of
/// the login screen for people who are already signed in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_controller.value);
            return Opacity(
              opacity: 0.65 + (0.35 * t),
              child: Transform.scale(scale: 1 + (0.06 * t), child: child),
            );
          },
          child: const Text('🍝', style: TextStyle(fontSize: 38)),
        ),
      ),
    );
  }
}
