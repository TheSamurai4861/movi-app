import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/config/config_module.dart';
import 'package:movi/src/core/config/env/dev_environment.dart';
import 'package:movi/src/core/config/env/environment.dart';
import 'package:movi/src/core/config/models/app_config.dart';
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/core/network/network_executor.dart';
import '../../helpers/database_initializer.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  test('registerConfig + initDependencies wires AppConfig and NetworkExecutor', () async {
    await initTestDatabase();
    final flavor = DevEnvironment();
    final config = await registerConfig(flavor: flavor);

    expect(GetIt.I<AppConfig>(), config);
    expect(GetIt.I<EnvironmentFlavor>(), flavor);

    await initDependencies(appConfig: config);

    expect(GetIt.I.isRegistered<NetworkExecutor>(), isTrue);
  });
}
