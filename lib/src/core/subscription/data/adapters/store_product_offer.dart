import 'package:flutter/foundation.dart';

@immutable
class StoreProductOffer {
  const StoreProductOffer({
    required this.productId,
    required this.title,
    required this.description,
    required this.priceLabel,
  });

  final String productId;
  final String title;
  final String description;
  final String priceLabel;
}
