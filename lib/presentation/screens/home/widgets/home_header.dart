import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.statusLabel,
    required this.showPanelButton,
    required this.onPanelTap,
    required this.onLogoutTap,
  });

  final String userName;
  final String? statusLabel;
  final bool showPanelButton;
  final VoidCallback onPanelTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 22,
        20,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.wine, colors.wineDeep],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.wineDeep.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('🍝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                l10n.appTitle,
                style: AppTextStyles.display(color: colors.paper, fontSize: 26),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 28),
            child: Text(
              l10n.appTagline.toUpperCase(),
              style: AppTextStyles.mono(
                color: colors.paper.withValues(alpha: 0.65),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: colors.paper,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (statusLabel != null && statusLabel!.isNotEmpty)
                      Text(
                        statusLabel!,
                        style: AppTextStyles.mono(
                          color: colors.paper.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (showPanelButton)
                _HeaderIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: l10n.panelTooltip,
                  onTap: onPanelTap,
                  color: colors.paper,
                ),
              _HeaderIconButton(
                icon: Icons.power_settings_new,
                tooltip: l10n.logoutTooltip,
                onTap: onLogoutTap,
                color: colors.paper,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, color: color.withValues(alpha: 0.85)),
      style: IconButton.styleFrom(
        highlightColor: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}
