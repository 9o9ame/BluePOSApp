import 'package:flutter/material.dart';
import '../core/session.dart';
import 'sale.dart';

/// Reference screen 33 uses the existing authorized POS invoice editor.
/// Never maintain a second client totals, stock or posting implementation.
class SalesInvoiceEntryScreen extends StatelessWidget {
  const SalesInvoiceEntryScreen({super.key, required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Sales Invoice')),
    body: SaleScreen(app: app),
  );
}
