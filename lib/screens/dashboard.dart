        if (canViewSales) ...[
          const SizedBox(height: 15),
          if (busy) pageLoading()
          else if (error != null) FailureState(message: error!, retry: reload)
          else Column(children: [
            Row(children: [
              Expanded(child: _statTile('Invoices',
                  branchInvoices?.toString() ?? '—',
                  Icons.description_rounded,
                  const Color(0xFF087EF5), _sales)),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Items Sold',
                  itemsSold ?? '—',
                  Icons.inventory_2_rounded,
                  const Color(0xFFFF9813), _sales)),
            ]),
            ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _statTile('Collections',
                  '—', Icons.verified_rounded,
                  const Color(0xFF0DBB64), _sales)),
                const SizedBox(width: 10),
                Expanded(child: _statTile('Expenses',
                  '—', Icons.receipt_long_rounded,
                  const Color(0xFFEA3864), _sales)),
              ]),
            ],
          ]),
        ],
        if (canCreateSale || canViewProducts || canViewSales) ...[
        const SizedBox(height: 17),
        const Text('Quick Actions', style: TextStyle(
          color: Color(0xFF0A1B48), fontSize: 19,
          fontWeight: FontWeight.w900)),
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.06,
          mainAxisSpacing: 8, crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (canCreateSale)
              _action(Icons.point_of_sale_outlined, 'New Sale',
                () => widget.navigate(1)),
            if (canViewProducts)
              _action(Icons.inventory_2_outlined, 'Products',
                () => widget.navigate(2)),
            if (canViewSales) ...[
              _action(Icons.receipt_long_outlined, 'Invoices', _sales),
            ],
          ],
        ),
        ],
        if (canViewSales && recent.isNotEmpty) const SizedBox(height: 17),
        if (canViewSales && recent.isNotEmpty) SectionHeading('Recent invoices',
          trailing: TextButton(onPressed: _sales,
            child: const Text('View all'))),
        if (canViewSales && !busy && error == null && recent.isNotEmpty)
          ...recent.take(5).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(padding: const EdgeInsets.symmetric(
              horizontal: 13, vertical: 12),
              child: Row(children: [
                CircleAvatar(backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.receipt_long_rounded,
                    color: scheme.primary, size: 20)),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(item['document_number'], 'Invoice'),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(field(item['sale_date']),
                      style: TextStyle(fontSize: 11,
                        color: scheme.onSurfaceVariant)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(item['grand_total'], app.currency),
                    style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 12)),
                  Text(field(item['status']),
                    style: TextStyle(fontSize: 10,
                      color: scheme.onSurfaceVariant)),
                ]),
              ]),
            )),
          ),
        const SizedBox(height: 16),
      ],
    )),
      const Positioned(left: 0, right: 0, bottom: 0,
        child: IgnorePointer(
          child: AuthReferenceWaves(height: 55))),
    ]);
  }
}
