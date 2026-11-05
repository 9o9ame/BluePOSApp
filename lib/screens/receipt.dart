import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Generates invoices exclusively from server-confirmed, tenant-scoped sale details.
/// The OS print/share sheet is used; no unapproved thermal-printer integration.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.app, required this.saleUlid});
  final AppController app;
  final String saleUlid;
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool busy = true, exporting = false;
  String? error;
  Map<String, dynamic> sale = {};
  @override
  void initState() { super.initState(); fetch(); }

  Future<void> fetch() async {
    if (widget.saleUlid.length != 26) {
      setState(() {busy = false; error = 'Invalid sale reference.';}); return;
    }
    setState(() {busy = true; error = null;});
    try {
      final result = await widget.app.api.get('/api/sales/${widget.saleUlid}');
      final data = objectOf(result);
      if (mounted) setState(() => sale = data.containsKey('ulid') ? data : objectOf(data['data']));
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<Uint8List> makePdf() async {
    if (sale.isEmpty) throw const ApiFailure('NO_RECEIPT', 'Invoice has not loaded.', 0);
    final doc = pw.Document(title: 'BluePOS ${field(sale['document_number'])}');
    final items = recordsOf(sale['items']);
    pw.Widget text(String label, dynamic value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(field(value, '—'), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ]));
    doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28), build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('BLUEPOS — SALES INVOICE',
          style: pw.TextStyle(fontSize: 20, color: PdfColors.blue900,
            fontWeight: pw.FontWeight.bold))),
        pw.Text(widget.app.tenantName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('${widget.app.branchName} · ${widget.app.warehouseName}',
          style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 17),
        text('Invoice', sale['document_number']),
        text('Date', sale['sale_date']),
        text('Status', sale['status']),
        if (field(sale['customer_name']).isNotEmpty)
          text('Customer', sale['customer_name']),
        pw.SizedBox(height: 15),
        pw.Table.fromTextArray(
          headers: ['Item', 'Qty', 'Unit price', 'Net'],
          data: items.map((row) => [
            field(objectOf(row['product'])['name'], field(row['line_kind'], 'Item')),
            field(row['quantity']), field(row['unit_price']),
            field(row['net_amount'], field(row['line_total'])),
          ]).toList(),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
          cellStyle: const pw.TextStyle(fontSize: 9),
          columnWidths: {0: const pw.FlexColumnWidth(3)},
        ),
        pw.SizedBox(height: 20),
        text('Subtotal', sale['subtotal']),
        text('Discount', sale['total_discount_amount']),
        text('Tax', sale['tax_amount']),
        text('Grand total (${widget.app.currency})', sale['grand_total']),
        text('Received', sale['paid_amount']),
        text('Balance due', sale['balance_due']),
        pw.SizedBox(height: 25),
        pw.Center(child: pw.Text('Thank you for your business',
          style: pw.TextStyle(color: PdfColors.blue900, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('Generated from BluePOS authorized server records.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
      ],
    ));
    return doc.save();
  }

  Future<void> export(bool share) async {
    if (exporting || busy || sale.isEmpty) return;
    setState(() => exporting = true);
    try {
      final pdf = await makePdf();
      if (share) {
        await Printing.sharePdf(bytes: pdf,
          filename: 'BluePOS-Invoice-${field(sale['document_number'], 'Invoice').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-')}.pdf');
      } else {
        await Printing.layoutPdf(onLayout: (_) async => pdf,
          name: 'BluePOS ${field(sale['document_number'])}');
      }
    } catch (e) { if (mounted) await showApiError(context, e); }
    finally { if (mounted) setState(() => exporting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = recordsOf(sale['items']);
    return Scaffold(appBar: AppBar(title: const Text('Sales receipt'),
      actions: [IconButton(onPressed: fetch, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (busy) pageLoading()
        else if (error != null) FailureState(message: error!, retry: fetch)
        else Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: BlueposBrandMark(size: 64)),
          const SizedBox(height: 10),
          Text(widget.app.tenantName, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          Text('${widget.app.branchName} · ${widget.app.warehouseName}',
            textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
          const Divider(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(field(sale['document_number']), style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(field(sale['sale_date'])),
          ]),
          const Divider(height: 26),
          ...lines.map((line) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(field(objectOf(line['product'])['name'], 'Item'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${field(line['quantity'])} × ${field(line['unit_price'])}',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              ])),
              Text(money(line['net_amount'], widget.app.currency),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            ]))),
          const Divider(height: 24),
          _amount('Subtotal', sale['subtotal']),
          _amount('Discount', sale['total_discount_amount']),
          _amount('Tax', sale['tax_amount']),
          const Divider(height: 18),
          _amount('Net amount', sale['grand_total'], strong: true),
          _amount('Received', sale['paid_amount']),
          _amount('Balance due', sale['balance_due']),
          const SizedBox(height: 19),
          FilledButton.icon(onPressed: exporting ? null : () => export(false),
            icon: const Icon(Icons.print_outlined), label: const Text('Print receipt')),
          const SizedBox(height: 9),
          OutlinedButton.icon(onPressed: exporting ? null : () => export(true),
            icon: const Icon(Icons.share_outlined), label: const Text('Share as PDF')),
        ])),
        const SizedBox(height: 18),
      ]),
    );
  }

  Widget _amount(String label, dynamic value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: strong ? 17 : 13,
        fontWeight: strong ? FontWeight.w900 : FontWeight.normal))),
      Text(money(value, widget.app.currency), style: TextStyle(fontSize: strong ? 19 : 13,
        fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
    ]));
}
