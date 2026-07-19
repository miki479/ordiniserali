import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/pdf_export_service.dart';

final pdfExportServiceProvider = Provider((ref) => const PdfExportService());
