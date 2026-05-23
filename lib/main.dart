import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_translations.dart';
import 'core/storage/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/offline_service.dart';
import 'core/utils/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('CHPA: Initialising SQLite database...');

  try {
    // Open (and create if needed) the real SQLite database.
    await DatabaseHelper.init();

    // Parallel init tasks.
    await Future.wait([
      initTranslations(),
      OfflineService.init(),
    ]);

    debugPrint('CHPA: Database ready.');
  } catch (e) {
    debugPrint('CHPA: Database init error — $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CHPA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkGlassTheme,
      routerConfig: router,
    );
  }
}
