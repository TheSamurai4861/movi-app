import 'dart:async';

import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:movi/src/core/subscription/data/adapters/store_product_offer.dart';
import 'package:movi/src/core/subscription/data/adapters/subscription_store_adapter.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';

class InAppPurchaseSubscriptionStoreAdapter
    implements SubscriptionStoreAdapter {
  InAppPurchaseSubscriptionStoreAdapter({
    InAppPurchase? inAppPurchase,
    Duration purchaseTimeout = const Duration(minutes: 2),
    Duration restoreTimeout = const Duration(seconds: 20),
    Duration restoreSettleDelay = const Duration(seconds: 2),
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
       _purchaseTimeout = purchaseTimeout,
       _restoreTimeout = restoreTimeout,
       _restoreSettleDelay = restoreSettleDelay;

  final InAppPurchase _inAppPurchase;
  final Duration _purchaseTimeout;
  final Duration _restoreTimeout;
  final Duration _restoreSettleDelay;

  @override
  Future<BillingAvailability> getBillingAvailability() async {
    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      return isAvailable
          ? BillingAvailability.available
          : BillingAvailability.unavailable;
    } on MissingPluginException {
      return BillingAvailability.unavailable;
    } catch (_) {
      return BillingAvailability.unavailable;
    }
  }

  @override
  Future<List<StoreProductOffer>> loadOffers(Set<String> productIds) async {
    await _ensureBillingAvailable();

    try {
      final response = await _inAppPurchase.queryProductDetails(productIds);
      if (response.error != null) {
        throw SubscriptionFailure.storeQueryFailed(response.error!.message);
      }

      return response.productDetails
          .map(
            (product) => StoreProductOffer(
              productId: product.id,
              title: product.title,
              description: product.description,
              priceLabel: product.price,
            ),
          )
          .toList(growable: false);
    } on SubscriptionFailure {
      rethrow;
    } catch (error) {
      throw SubscriptionFailure.storeQueryFailed(
        'Failed to load subscription offers: $error',
      );
    }
  }

  @override
  Future<Set<String>> purchase(String productId) async {
    await _ensureBillingAvailable();
    final product = await _loadSingleProduct(productId);

    late final StreamSubscription<List<PurchaseDetails>> subscription;
    final completer = Completer<Set<String>>();

    subscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) async {
        for (final purchase in purchaseDetailsList) {
          if (purchase.productID != productId) {
            continue;
          }

          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }

          if (purchase.status == PurchaseStatus.canceled) {
            if (!completer.isCompleted) {
              completer.completeError(SubscriptionFailure.purchaseCancelled());
            }
            continue;
          }

          if (purchase.status == PurchaseStatus.error) {
            if (!completer.isCompleted) {
              completer.completeError(
                SubscriptionFailure.purchaseFailed(
                  purchase.error?.message ??
                      'The store reported a purchase error.',
                ),
              );
            }
            continue;
          }

          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }

          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            if (!completer.isCompleted) {
              completer.complete(<String>{purchase.productID});
            }
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(
            SubscriptionFailure.purchaseFailed(
              'Purchase stream failed: $error',
            ),
            stackTrace,
          );
        }
      },
    );

    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

      if (!started) {
        throw SubscriptionFailure.purchaseFailed(
          'The store rejected the subscription purchase request.',
        );
      }

      return await completer.future.timeout(
        _purchaseTimeout,
        onTimeout: () => throw SubscriptionFailure.storeTimeout('purchase'),
      );
    } on SubscriptionFailure {
      rethrow;
    } catch (error) {
      throw SubscriptionFailure.purchaseFailed(
        'Failed to purchase subscription: $error',
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<Set<String>> restore() async {
    await _ensureBillingAvailable();

    late final StreamSubscription<List<PurchaseDetails>> subscription;
    final completer = Completer<Set<String>>();
    final restoredProductIds = <String>{};
    Timer? settleTimer;

    void scheduleCompletion() {
      settleTimer?.cancel();
      settleTimer = Timer(_restoreSettleDelay, () {
        if (!completer.isCompleted) {
          completer.complete(Set<String>.unmodifiable(restoredProductIds));
        }
      });
    }

    subscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) async {
        for (final purchase in purchaseDetailsList) {
          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }

          if (purchase.status == PurchaseStatus.error) {
            if (!completer.isCompleted) {
              completer.completeError(
                SubscriptionFailure.restoreFailed(
                  purchase.error?.message ??
                      'The store reported a restore error.',
                ),
              );
            }
            return;
          }

          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }

          if (purchase.status == PurchaseStatus.restored ||
              purchase.status == PurchaseStatus.purchased) {
            restoredProductIds.add(purchase.productID);
          }
        }

        scheduleCompletion();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(
            SubscriptionFailure.restoreFailed('Restore stream failed: $error'),
            stackTrace,
          );
        }
      },
    );

    try {
      await _inAppPurchase.restorePurchases();
      scheduleCompletion();

      return await completer.future.timeout(
        _restoreTimeout,
        onTimeout: () => Set<String>.unmodifiable(restoredProductIds),
      );
    } on SubscriptionFailure {
      rethrow;
    } catch (error) {
      throw SubscriptionFailure.restoreFailed(
        'Failed to restore subscriptions: $error',
      );
    } finally {
      settleTimer?.cancel();
      await subscription.cancel();
    }
  }

  Future<void> _ensureBillingAvailable() async {
    final availability = await getBillingAvailability();
    if (availability != BillingAvailability.available) {
      throw SubscriptionFailure.billingUnavailable();
    }
  }

  Future<ProductDetails> _loadSingleProduct(String productId) async {
    final response = await _inAppPurchase.queryProductDetails(<String>{
      productId,
    });

    if (response.error != null) {
      throw SubscriptionFailure.storeQueryFailed(response.error!.message);
    }

    for (final product in response.productDetails) {
      if (product.id == productId) {
        return product;
      }
    }

    throw SubscriptionFailure.offerNotFound(productId);
  }
}
