import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/providers/session_provider.dart';
import 'shared/routing/app_router.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Résolution de sessionProvider avant montage de MaterialApp — évite la race
  // condition auth (AD-12, AC-3)
  final container = ProviderContainer();
  await container.read(sessionStateProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GestBudApp(),
    ),
  );
}

class GestBudApp extends ConsumerWidget {
  const GestBudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'GestBud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
