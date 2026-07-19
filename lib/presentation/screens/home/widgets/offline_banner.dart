import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Pinned above everything else while offline: an order that "succeeds"
/// without a connection would never actually reach the kitchen, so this
/// needs to be impossible to miss.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: const Color(0xFFB3261E),
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.of(context).padding.top + 8,
        14,
        8,
      ),
      child: Text(
        l10n.offlineBanner,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
