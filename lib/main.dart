import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'bloc_observer.dart';
import 'config.dart';
import 'helpers/app_theme.dart';
import 'helpers/routes.dart';
import 'locale/my_localizations.dart';
import 'pages/notifications/view_model_manger/notifications_cubit.dart';

Future<void> main() async {
  // Flutter Version that is used in the project: 3.27.2
  Bloc.observer = Observer();

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  /// 🧹 امسح قاعدة البيانات عند بدء التشغيل (اختياري أثناء التطوير)
  await deletePosDatabase(Config.userId);

  AppLanguage appLanguage = AppLanguage();
  await appLanguage.fetchLocale();

  runApp(MyApp(
    appLanguage: appLanguage,
  ));
}

/// 🔧 دالة لحذف قاعدة بيانات SQLite حسب userId
Future<void> deletePosDatabase(int? userId) async {
  if (userId == null) return;

  try {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'PosDemo$userId.db');
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      await dbFile.delete();
      print('✅ Database deleted at: $dbPath');
    } else {
      print('ℹ️ Database not found at: $dbPath');
    }
  } catch (e) {
    print('❌ Failed to delete database: $e');
  }
}

class MyApp extends StatelessWidget {
  final AppLanguage? appLanguage;

  const MyApp({super.key, this.appLanguage});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsCubit()..getNotification(),
      child: ChangeNotifierProvider<AppLanguage>(
        create: (_) => appLanguage!,
        child: Consumer<AppLanguage>(builder: (context, model, child) {
          return MaterialApp(
            routes: Routes.generateRoute(),
            initialRoute: '/splash',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getThemeFromThemeMode(1),
            locale: model.appLocal,
            supportedLocales: Config().supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
          );
        }),
      ),
    );
  }
}
