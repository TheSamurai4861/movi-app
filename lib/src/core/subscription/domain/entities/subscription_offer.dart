import 'package:flutter/foundation.dart';

@immutable
class SubscriptionOffer {
  const SubscriptionOffer({
    required this.id,
    required this.storeProductId,
    required this.title,
    required this.description,
    required this.displayPrice,
  });

  final String id;
  final String storeProductId;
  final String title;
  final String description;
  final String displayPrice;

  SubscriptionOffer copyWith({
    String? id,
    String? storeProductId,
    String? title,
    String? description,
    String? displayPrice,
  }) {
    return SubscriptionOffer(
      id: id ?? this.id,
      storeProductId: storeProductId ?? this.storeProductId,
      title: title ?? this.title,
      description: description ?? this.description,
      displayPrice: displayPrice ?? this.displayPrice,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubscriptionOffer &&
            other.id == id &&
            other.storeProductId == storeProductId &&
            other.title == title &&
            other.description == description &&
            other.displayPrice == displayPrice;
  }

  @override
  int get hashCode =>
      Object.hash(id, storeProductId, title, description, displayPrice);
}
