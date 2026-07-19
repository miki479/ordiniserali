import 'package:flutter/material.dart';

/// Progressive-disclosure wrapper: the registration/login form reveals one
/// field at a time as the previous one is filled in, rather than dumping the
/// whole form on the person at once.
class StepReveal extends StatelessWidget {
  const StepReveal({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: visible ? 1 : 0,
        child: visible ? child : const SizedBox(width: double.infinity),
      ),
    );
  }
}
