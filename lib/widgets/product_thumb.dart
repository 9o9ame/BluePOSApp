import 'package:flutter/material.dart';
import '../core/api.dart';

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.api, required this.imageUrl, this.size = 50});
  final BlueposApi api;
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget fallback = Container(width: size, height: size,
      decoration: BoxDecoration(color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(13)),
      child: Icon(Icons.inventory_2_outlined, size: size * .5, color: scheme.primary));
    if (imageUrl.isEmpty) return fallback;
    return ClipRRect(borderRadius: BorderRadius.circular(13), child: FutureBuilder(
      future: api.productImage(imageUrl),
      builder: (ctx, snapshot) => snapshot.hasData && snapshot.data != null
        ? Image.memory(snapshot.data!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (ctx, error, stack) => fallback)
        : fallback,
    ));
  }
}
