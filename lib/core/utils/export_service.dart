import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../state/group_state.dart';

class ExportService {
  static Future<void> exportToPdf(GroupState groupState) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Group Expense History', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Description', 'Payer', 'Category', 'Amount'],
                data: groupState.expenses.map((e) {
                  final payerName = groupState.members.firstWhere((m) => m.id == e.payerId).name;
                  return [
                    e.createdAt.toString().split(' ')[0],
                    e.description,
                    payerName,
                    e.category.name,
                    'Rs. ${e.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expenses_${groupState.groupId}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Here is the expense history PDF.');
  }

  static Future<void> exportToCsv(GroupState groupState) async {
    List<List<dynamic>> rows = [];
    rows.add(['Date', 'Description', 'Payer', 'Category', 'Amount', 'Split Type']);

    for (var e in groupState.expenses) {
      final payerName = groupState.members.firstWhere((m) => m.id == e.payerId).name;
      rows.add([
        e.createdAt.toString().split(' ')[0],
        e.description,
        payerName,
        e.category.name,
        e.amount,
        e.splitType.name,
      ]);
    }

    final csvData = csv.encode(rows);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expenses_${groupState.groupId}.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'Here is the expense history CSV.');
  }
}
