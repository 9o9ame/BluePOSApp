import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'auth_reference_chrome.dart';

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
    final style = BpReferenceStyle.of(context);
    final lines = recordsOf(sale['items']);
    final payments = recordsOf(sale['payments']);
    return Scaffold(
      backgroundColor: style.page,
      appBar: const BpReferenceSubpageAppBar(title: 'Sales Invoice Detail'),
      bottomNavigationBar: !busy && error == null
        ? BpReferenceWorkflowActions(
            leftKey: const ValueKey('sale-detail-print'),
            rightKey: const ValueKey('sale-detail-share'),
            leftLabel: 'Print',
            rightLabel: 'Share Invoice',
            leftIcon: Icons.print_outlined,
            rightIcon: Icons.share_outlined,
            rightColor: const Color(0xFF006DF6),
            onLeft: exporting ? null : () => export(false),
            onRight: exporting ? null : () => export(true),
          )
        : null,
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        RefreshIndicator(onRefresh: fetch, child: ListView(
          key: const ValueKey('reference-sale-invoice-detail'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
          children: [
            if (busy) pageLoading()
            else if (error != null) FailureState(message: error!, retry: fetch)
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: style.card(radius: 16),
                child: Row(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: style.scheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.storefront_rounded,
                      size: 26, color: style.scheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field(sale['document_number'], 'Sales invoice'),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w900, color: style.ink)),
                      Text(field(sale['customer_name'], 'Walk-in customer'),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: style.muted, fontSize: 11)),
                      Text(field(sale['sale_date']),
                        style: TextStyle(color: style.muted, fontSize: 10)),
                    ])),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.scheme.primary.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(12)),
                    child: Text(field(sale['status'], 'Unknown'),
                      style: TextStyle(color: style.ink,
                        fontWeight: FontWeight.w800, fontSize: 11))),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: style.card(radius: 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(flex: 5, child: Text('Product',
                      style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w900, color: style.ink))),
                    Expanded(child: Text('Qty', textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w900, color: style.ink))),
                    Expanded(flex: 2, child: Text('Rate',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w900, color: style.ink))),
                    Expanded(flex: 3, child: Text('Amount',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w900, color: style.ink))),
                  ]),
                  const Divider(height: 15),
                  for (final line in lines) ...[
                    Row(children: [
                      Expanded(flex: 5, child: Row(children: [
                        Container(width: 27, height: 30,
                          decoration: BoxDecoration(
                            color: style.scheme.primary.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.shopping_basket_outlined,
                            size: 16, color: style.scheme.primary)),
                        const SizedBox(width: 5),
                        Expanded(child: Text(
                          field(objectOf(line['product'])['name'],
                            field(line['line_kind'], 'Item')),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w700, color: style.ink))),
                      ])),
                      Expanded(child: Text(bpReferenceDecimalLabel(line['quantity']),
                        textAlign: TextAlign.end, maxLines: 1,
                        style: TextStyle(fontSize: 10, color: style.ink))),
                      Expanded(flex: 2, child: Text(
                        bpReferenceDecimalLabel(line['unit_price']),
                        textAlign: TextAlign.end, maxLines: 1,
                        style: TextStyle(fontSize: 10, color: style.ink))),
                      Expanded(flex: 3, child: Text(
                        bpReferenceDecimalLabel(field(line['net_amount'],
                          field(line['line_total']))),
                        textAlign: TextAlign.end, maxLines: 1,
                        style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w800, color: style.ink))),
                    ]),
                    const Divider(height: 12),
                  ],
                  if (lines.isEmpty)
                    Text('No invoice items in the server response.',
                      style: TextStyle(color: style.muted, fontSize: 11)),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 9),
                decoration: style.card(radius: 14),
                child: Column(children: [
                  _amount('Subtotal', sale['subtotal']),
                  _amount('Discount', sale['total_discount_amount']),
                  _amount('Tax', sale['tax_amount']),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 9),
                    decoration: BoxDecoration(
                      color: style.dark ? const Color(0xFF19452E)
                        : const Color(0xFFD9F7DC),
                      borderRadius: BorderRadius.circular(11)),
                    child: Row(children: [
                      Expanded(child: Text('Grand Total',
                        style: TextStyle(fontSize: 15,
                          color: style.ink, fontWeight: FontWeight.w900))),
                      Text(money(sale['grand_total'], widget.app.currency),
                        style: TextStyle(fontSize: 15,
                          color: style.ink, fontWeight: FontWeight.w900)),
                    ])),
                  _amount('Received', sale['paid_amount']),
                  _amount('Balance due', sale['balance_due']),
                ]),
              ),
              if (payments.isNotEmpty) ...[
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: style.card(radius: 14),
                  child: Row(children: [
                    Icon(Icons.account_balance_wallet_outlined,
                      color: style.green, size: 27),
                    const SizedBox(width: 9),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payments.length == 1
                          ? 'Payment: ${field(payments.first['method'])}'
                          : '${payments.length} recorded payments',
                          style: TextStyle(color: style.ink,
                            fontWeight: FontWeight.w800, fontSize: 11)),
                        Text('Received: ${money(sale['paid_amount'],
                          widget.app.currency)}',
                          style: TextStyle(color: style.muted, fontSize: 10)),
                      ])),
                    Icon(Icons.check_circle_rounded, color: style.green),
                  ]),
                ),
              ],
            ],
          ],
        )),
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
