import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/session_controller.dart';
import '../../providers/session_state.dart';

/// "Is this still you?" — shown when a device is already linked to an
/// account but hasn't confirmed its identity recently (see
/// [kIdentityReconfirmWindow]), instead of silently trusting it forever.
class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  bool _busy = false;

  Future<void> _handle(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    final profile = session is SessionNeedsWelcomeBack ? session.profile : null;

    final greeting = profile != null
        ? l10n.welcomeBackGreeting(profile.nome, profile.cognome)
        : l10n.welcomeBackGeneric;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👋', style: TextStyle(fontSize: 38)),
                const SizedBox(height: 8),
                Text(
                  greeting,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(
                    color: colors.wineDeep,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.welcomeBackSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _handle(
                            () => ref
                                .read(sessionControllerProvider.notifier)
                                .confirmWelcomeBack(),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.wine,
                      foregroundColor: colors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      l10n.welcomeBackYes,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _handle(
                            () => ref
                                .read(sessionControllerProvider.notifier)
                                .rejectWelcomeBack(),
                          ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.inkSoft,
                      side: BorderSide(color: colors.line, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      l10n.welcomeBackNo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
