import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../l10n/app_localizations.dart';

/// Team-lead-only actions shown at the bottom of the order screen: export
/// tonight's orders to PDF, or wipe them to reopen the service.
class CapolineaZone extends StatelessWidget {
  const CapolineaZone({
    super.key,
    required this.generatingPdf,
    required this.onDownloadPdf,
    required this.onDeleteAll,
  });

  final bool generatingPdf;
  final VoidCallback onDownloadPdf;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 26),
      padding: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.capolineaSectionLabel),
          FilledButton.icon(
            onPressed: generatingPdf ? null : onDownloadPdf,
            icon: generatingPdf
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colors.paper,
                    ),
                  )
                : const Icon(Icons.file_download_outlined, size: 18),
            label: Text(generatingPdf ? l10n.pdfBtnGenerating : l10n.pdfBtn),
            style: FilledButton.styleFrom(
              backgroundColor: colors.olive,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onDeleteAll,
            style: TextButton.styleFrom(foregroundColor: colors.tomatoDeep),
            child: Text(
              l10n.deleteAllBtn,
              style: const TextStyle(
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
