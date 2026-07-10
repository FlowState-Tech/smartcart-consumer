import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/planning/domain/entities.dart';

class BasketPdfExporter {
  static Future<Uint8List> export({
    required String listName,
    required List<ProductItem> items,
    required double total,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SmartCart — Lista de compras', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Canasta: $listName'),
          pw.SizedBox(height: 8),
          pw.Text('Fecha: ${DateTime.now().toLocal()}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Producto', 'Marca', 'Cant.', 'Precio'],
            data: items
                .map((i) => [
                      i.name,
                      i.brand,
                      '${i.quantity.value.toInt()} ${i.quantity.unit}',
                      'S/ ${i.price.toStringAsFixed(2)}',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Total: S/ ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
