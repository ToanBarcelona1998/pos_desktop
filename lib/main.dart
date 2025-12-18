import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/app_config/di.dart';
import 'package:pos_final/app_config/env_config.dart';
import 'package:pos_final/src/application.dart';
import 'package:pos_final/src/core/services/print_service.dart';
import 'package:pos_final/src/core/utils/window_manager_utils.dart';
import 'package:pos_final/src/offline_customer_application.dart';
import 'package:pos_final/src/online_customer_application.dart';
import 'package:window_manager/window_manager.dart';

import 'bloc_observer.dart';

import 'package:pos_final/src/core/app_version_manager.dart';

Future<void> main() async {
  Bloc.observer = Observer();

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final windowController = await WindowController.fromCurrentEngine();

  await windowController.customMethods();

  await PrintService.init();
  // Check app version and clear cache/database if needed
  await AppVersionManager.checkAndHandleVersionUpdate();

  await initDependencies(env: EnvConfig.environment);

  WindowArguments windowArguments = WindowManagerUtils.parseWindowArguments(windowController.arguments);

  switch(windowArguments.type){
    case WindowType.none:
      runApp(const Application());
      break;
    case WindowType.onlineCustomer:
      runApp(const OnlineCustomerApplication());
      break;
    case WindowType.offlineCustomer:
      runApp(const OfflineCustomerApplication());
      break;
  }
}
