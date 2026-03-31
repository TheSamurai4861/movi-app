import 'package:get_it/get_it.dart';

import 'package:movi/src/core/config/services/platform_selector.dart';
import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/application/usecases/get_current_subscription.dart';
import 'package:movi/src/core/subscription/application/usecases/load_available_subscription_offers.dart';
import 'package:movi/src/core/subscription/application/usecases/purchase_subscription.dart';
import 'package:movi/src/core/subscription/application/usecases/refresh_subscription.dart';
import 'package:movi/src/core/subscription/application/usecases/restore_subscription.dart';
import 'package:movi/src/core/subscription/data/adapters/subscription_store_adapter.dart';
import 'package:movi/src/core/subscription/data/catalog/subscription_product_catalog.dart';
import 'package:movi/src/core/subscription/data/datasources/subscription_local_cache_data_source.dart';
import 'package:movi/src/core/subscription/data/factories/subscription_store_adapter_factory.dart';
import 'package:movi/src/core/subscription/data/repositories/store_subscription_repository.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class SubscriptionModule {
  static void register(GetIt sl) {
    if (!sl.isRegistered<PlatformInfo>()) {
      sl.registerLazySingleton<PlatformInfo>(PlatformSelector.new);
    }

    if (!sl.isRegistered<SubscriptionProductCatalog>()) {
      sl.registerLazySingleton<SubscriptionProductCatalog>(
        SubscriptionProductCatalog.new,
      );
    }

    if (!sl.isRegistered<SubscriptionLocalCacheDataSource>()) {
      sl.registerLazySingleton<SubscriptionLocalCacheDataSource>(
        SubscriptionLocalCacheDataSource.new,
      );
    }

    if (!sl.isRegistered<SubscriptionStoreAdapter>()) {
      sl.registerLazySingleton<SubscriptionStoreAdapter>(
        () => SubscriptionStoreAdapterFactory(sl<PlatformInfo>()).create(),
      );
    }

    if (!sl.isRegistered<SubscriptionRepository>()) {
      sl.registerLazySingleton<SubscriptionRepository>(
        () => StoreSubscriptionRepository(
          localCache: sl<SubscriptionLocalCacheDataSource>(),
          storeAdapter: sl<SubscriptionStoreAdapter>(),
          productCatalog: sl<SubscriptionProductCatalog>(),
        ),
      );
    }

    if (!sl.isRegistered<GetCurrentSubscription>()) {
      sl.registerLazySingleton<GetCurrentSubscription>(
        () => GetCurrentSubscription(sl<SubscriptionRepository>()),
      );
    }

    if (!sl.isRegistered<LoadAvailableSubscriptionOffers>()) {
      sl.registerLazySingleton<LoadAvailableSubscriptionOffers>(
        () => LoadAvailableSubscriptionOffers(sl<SubscriptionRepository>()),
      );
    }

    if (!sl.isRegistered<PurchaseSubscription>()) {
      sl.registerLazySingleton<PurchaseSubscription>(
        () => PurchaseSubscription(sl<SubscriptionRepository>()),
      );
    }

    if (!sl.isRegistered<RestoreSubscription>()) {
      sl.registerLazySingleton<RestoreSubscription>(
        () => RestoreSubscription(sl<SubscriptionRepository>()),
      );
    }

    if (!sl.isRegistered<RefreshSubscription>()) {
      sl.registerLazySingleton<RefreshSubscription>(
        () => RefreshSubscription(sl<SubscriptionRepository>()),
      );
    }

    if (!sl.isRegistered<CanAccessPremiumFeature>()) {
      sl.registerLazySingleton<CanAccessPremiumFeature>(
        () => CanAccessPremiumFeature(sl<SubscriptionRepository>()),
      );
    }
  }
}
