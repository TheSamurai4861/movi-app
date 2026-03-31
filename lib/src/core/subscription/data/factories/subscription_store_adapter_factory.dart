import 'package:movi/src/core/config/services/platform_selector.dart';
import 'package:movi/src/core/subscription/data/adapters/in_app_purchase_subscription_store_adapter.dart';
import 'package:movi/src/core/subscription/data/adapters/subscription_store_adapter.dart';
import 'package:movi/src/core/subscription/data/adapters/unsupported_subscription_store_adapter.dart';

class SubscriptionStoreAdapterFactory {
  const SubscriptionStoreAdapterFactory(this._platformInfo);

  final PlatformInfo _platformInfo;

  SubscriptionStoreAdapter create() {
    switch (_platformInfo.currentPlatform) {
      case AppPlatform.android:
      case AppPlatform.ios:
      case AppPlatform.macos:
        return InAppPurchaseSubscriptionStoreAdapter();
      case AppPlatform.windows:
      case AppPlatform.linux:
      case AppPlatform.web:
      case AppPlatform.fuchsia:
      case AppPlatform.unknown:
        return const UnsupportedSubscriptionStoreAdapter();
    }
  }
}
