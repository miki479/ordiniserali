import 'package:flutter/material.dart';

/// Replaces the web app's custom `#toast` element: a floating, auto-dismissing
/// message anchored to the bottom, themed via [SnackBarThemeData].
void showAppToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      duration: const Duration(milliseconds: 2600),
      margin: const EdgeInsets.only(bottom: 24, left: 40, right: 40),
    ),
  );
}
