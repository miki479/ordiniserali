import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/food_order.dart';

/// Builds the evening's "comanda" as a PDF and hands it to the OS share
/// sheet — replacing the web app's jsPDF + `navigator.share`/blob-URL dance
/// with a single cross-platform call that also covers desktop/web download.
class PdfExportService {
  const PdfExportService();

  Future<void> shareOrdersPdf({
    required String giorno,
    required List<FoodOrder> orders,
  }) async {
    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = const pw.TextStyle(fontSize: 10);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15 * PdfPageFormat.mm),
        header: (context) => context.pageNumber == 1
            ? pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  'Ordini del giorno:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              )
            : pw.SizedBox(),
        build: (context) => [
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(3.5),
              2: pw.FlexColumnWidth(2.5),
            },
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text('Cognome', style: headerStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text('Ordine', style: headerStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text('Accompagnamento', style: headerStyle),
                  ),
                ],
              ),
              for (var i = 0; i < orders.length; i++)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        '${i + 1}. ${orders[i].cognome.isEmpty ? "Sconosciuto" : orders[i].cognome}',
                        style: cellStyle,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        orders[i].ordine.isEmpty
                            ? 'Nessun ordine'
                            : orders[i].ordine,
                        style: cellStyle,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        orders[i].accompagnamento.firestoreValue.isEmpty
                            ? 'Nessuno'
                            : orders[i].accompagnamento.label,
                        style: cellStyle,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'PRENOTAZIONE PER LE ORE 19:30 N.PASTI (${orders.length}) + PANE',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'comanda_$giorno.pdf');
  }
}
