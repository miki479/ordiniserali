import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// The "kitchen ticket" receipt: a live preview of what will be sent, the
/// send/update button, and the brief "sent" stamp shown right after success.
class OrderTicketCard extends StatelessWidget {
  const OrderTicketCard({
    super.key,
    required this.lines,
    required this.emptyPlaceholder,
    required this.statusText,
    required this.showSendButton,
    required this.sendEnabled,
    required this.sending,
    required this.sendLabel,
    required this.onSend,
    required this.stampText,
  });

  final List<String> lines;
  final String? emptyPlaceholder;
  final String statusText;
  final bool showSendButton;
  final bool sendEnabled;
  final bool sending;
  final String sendLabel;
  final VoidCallback? onSend;
  final String? stampText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.ticketLabel,
                style: AppTextStyles.mono(
                  color: colors.inkSoft,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                statusText,
                style: AppTextStyles.mono(
                  color: colors.olive,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: lines.isEmpty
                ? Text(
                    emptyPlaceholder ?? '',
                    style: AppTextStyles.mono(
                      color: colors.inkSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ).copyWith(fontStyle: FontStyle.italic),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '→ ',
                                style: AppTextStyles.mono(
                                  color: colors.tomato,
                                  fontSize: 13,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  line,
                                  style: AppTextStyles.mono(
                                    color: colors.ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          if (showSendButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: sendEnabled && !sending ? onSend : null,
                child: sending
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: colors.paper,
                        ),
                      )
                    : Text(sendLabel),
              ),
            ),
          ],
          if (stampText != null) ...[
            const SizedBox(height: 14),
            _Stamp(text: stampText!, colors: colors),
          ],
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.text, required this.colors});
  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.rotate(
        angle: -0.035,
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: colors.olive, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.mono(
            color: colors.olive,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
