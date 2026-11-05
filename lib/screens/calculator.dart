import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/common.dart';

/// Local utility calculator. Uses decimal arithmetic, not binary floats.
/// This is NOT a source of financial posting amounts or server-side totals.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = '0';
  String? operation;
  Decimal? left;
  bool nextNumber = false;
  String? error;

  static const buttons = <String>[
    'AC', '⌫', '%', '÷',
    '7', '8', '9', '×',
    '4', '5', '6', '−',
    '1', '2', '3', '+',
    '±', '0', '.', '=',
  ];

  Decimal? get current => Decimal.tryParse(display);

  String _format(Decimal value) {
    final number = value.toStringAsFixed(8);
    if (!number.contains('.')) return number;
    return number.replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  }

  void _press(String key) {
    setState(() {
      error = null;
      if (key == 'AC') {
        display = '0';
        left = null;
        operation = null;
        nextNumber = false;
        return;
      }
      if (key == '⌫') {
        if (nextNumber) return;
        display = display.length > 1
          ? display.substring(0, display.length - 1) : '0';
        if (display == '-' || display.isEmpty) display = '0';
        return;
      }
      if (key == '±') {
        if (display != '0') {
          display = display.startsWith('-')
            ? display.substring(1) : '-$display';
        }
        return;
      }
      if (key == '%') {
        final number = current;
        if (number == null) return;
        display = _format(number * Decimal.parse('0.01'));
        return;
      }
      if (const ['÷', '×', '−', '+'].contains(key)) {
        final number = current;
        if (number == null) return;
        if (left != null && operation != null && !nextNumber) {
          _calculate();
        }
        left = current;
        operation = key;
        nextNumber = true;
        return;
      }
      if (key == '=') {
        _calculate();
        operation = null;
        left = null;
        nextNumber = true;
        return;
      }
      if (key == '.') {
        if (nextNumber) {
          display = '0.';
          nextNumber = false;
        } else if (!display.contains('.')) {
          display += '.';
        }
        return;
      }
      if (!RegExp(r'^[0-9]$').hasMatch(key)) return;
      if (nextNumber) {
        display = key;
        nextNumber = false;
      } else if (display == '0') {
        display = key;
      } else if (display.length < 23) {
        display += key;
      }
    });
  }

  void _calculate() {
    final a = left;
    final b = current;
    if (a == null || b == null || operation == null) return;
    if (operation == '÷' && b == Decimal.zero) {
      error = 'Cannot divide by zero.';
      display = '0';
      return;
    }
    try {
      final result = switch (operation) {
        '+' => a + b,
        '−' => a - b,
        '×' => a * b,
        '÷' => (a / b).toDecimal(scaleOnInfinitePrecision: 8),
        _ => b,
      };
      display = _format(result);
    } catch (_) {
      error = 'Calculation could not be completed.';
      display = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator'),
        actions: [IconButton(
          tooltip: 'Copy result',
          icon: const Icon(Icons.copy_rounded),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: display));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Result copied')));
          },
        )]),
      body: SafeArea(child: LayoutBuilder(builder: (context, size) {
        return ListView(padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Decimal calculator'),
          Surface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(operation == null ? 'Ready' :
                '${left?.toString() ?? ''} $operation',
                style: TextStyle(color: colors.onSurfaceVariant,
                  fontSize: 13)),
              const SizedBox(height: 15),
              FittedBox(fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(display,
                  maxLines: 1,
                  style: TextStyle(color: colors.onSurface,
                    fontWeight: FontWeight.w900, fontSize: 42))),
              if (error != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: TextStyle(
                  color: colors.error, fontSize: 12))),
            ])),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: buttons.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 9, mainAxisSpacing: 9,
              mainAxisExtent: size.maxWidth < 340 ? 61 : 73),
            itemBuilder: (context, index) {
              final key = buttons[index];
              final primary = key == '=';
              final operator = const ['÷', '×', '−', '+'].contains(key);
              return primary
                ? FilledButton(
                    onPressed: () => _press(key),
                    child: Text(key, style: const TextStyle(fontSize: 24)))
                : OutlinedButton(
                    onPressed: () => _press(key),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: operator
                        ? colors.primaryContainer.withValues(alpha: .6)
                        : colors.surface,
                      padding: EdgeInsets.zero),
                    child: Text(key,
                      style: TextStyle(fontSize: 22,
                        fontWeight: operator
                          ? FontWeight.w800 : FontWeight.w600,
                        color: operator ? colors.primary : colors.onSurface)));
            },
          ),
          const SizedBox(height: 18),
          Text('For quick reference only. BluePOS transaction totals are always computed by the server.',
            style: TextStyle(fontSize: 11,
              color: colors.onSurfaceVariant)),
        ]);
      })),
    );
  }
}
