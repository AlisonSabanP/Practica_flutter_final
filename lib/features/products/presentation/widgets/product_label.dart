import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/product.dart';

/// Representacion del codigo de barras Code 128 del producto. Se genera a
/// partir del codigo unico.
class ProductBarcode extends StatelessWidget {
  const ProductBarcode({
    super.key,
    required this.code,
    this.height = 70,
    this.showText = true,
    this.color = Colors.black,
  });

  final String code;
  final double height;
  final bool showText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BarcodeWidget(
      barcode: Barcode.code128(),
      data: code,
      height: height,
      drawText: showText,
      color: color,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1.5,
        fontFamily: 'monospace',
      ),
    );
  }
}

/// Representacion del codigo QR del producto. Contiene unicamente el codigo
/// unico: nunca cantidades ni existencias, porque cambian con cada movimiento.
class ProductQr extends StatelessWidget {
  const ProductQr({
    super.key,
    required this.code,
    this.size = 150,
    this.color = Colors.black,
  });

  final String code;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BarcodeWidget(
      barcode: Barcode.qrCode(errorCorrectLevel: BarcodeQRCorrectionLevel.medium),
      data: code,
      width: size,
      height: size,
      color: color,
    );
  }
}

/// Etiqueta imprimible con nombre, codigo, codigo de barras y QR.
class ProductLabel extends StatelessWidget {
  const ProductLabel({
    super.key,
    required this.product,
    this.showPrice = true,
  });

  final Product product;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('product-label'),
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.categoryName ?? 'Sin categoria',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ProductQr(code: product.code, size: 132),
                    const SizedBox(height: 6),
                    Text(
                      product.code,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProductBarcode(code: product.code, height: 64),
                    const SizedBox(height: 14),
                    if (showPrice)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          Formatters.currency(product.salePrice),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: scheme.outlineVariant, height: 1),
          const SizedBox(height: 6),
          const Text(
            'Inventario - etiqueta de producto',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
