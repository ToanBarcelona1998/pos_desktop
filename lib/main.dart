import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_final/app_config/di.dart';
import 'package:pos_final/app_config/env_config.dart';
import 'package:pos_final/src/application.dart';
import 'package:pos_final/src/core/localization/app_localization.dart';
import 'package:pos_final/src/core/services/print_service.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'bloc_observer.dart';
import 'config.dart';
import 'helpers/app_theme.dart';
import 'helpers/routes.dart';
import 'locale/my_localizations.dart';
import 'pages/notifications/view_model_manger/notifications_cubit.dart';

import 'package:pos_final/src/core/app_version_manager.dart';

Future<void> main() async {
  Bloc.observer = Observer();

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  await PrintService.init();
  // Check app version and clear cache/database if needed
  await AppVersionManager.checkAndHandleVersionUpdate();

  await initDependencies(env: EnvConfig.environment);

  runApp(const Application());
}
