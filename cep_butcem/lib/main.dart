import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/state/profile_store.dart';
import 'core/services/notification_service.dart';
import 'core/services/subscription_auto_payment_service.dart';
import 'data/local/app_database.dart';
import 'data/repositories/profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite database'i başlat
  await AppDatabase.instance.database;

  // Bildirim sistemini başlat
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // Abonelik otomatik ödeme kontrolü
  await SubscriptionAutoPaymentService.instance.processDueSubscriptions();

  // Kayıtlı profili çek
  final profileRepository = ProfileRepository();
  final savedProfile = await profileRepository.getProfile();

  runApp(
    CepButcemApp(
      initialProfile:
          savedProfile ??
          const ProfileData(
            firstName: 'Asena',
            lastName: 'Türk',
            occupation: '',
          ),
    ),
  );
}

class CepButcemApp extends StatelessWidget {
  const CepButcemApp({super.key, required this.initialProfile});

  final ProfileData initialProfile;

  @override
  Widget build(BuildContext context) {
    final profileStore = ProfileStore(initialProfile);

    return ProfileScope(
      store: profileStore,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        title: 'Cep Bütçem',
        routerConfig: appRouter,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr')],
        locale: const Locale('tr'),
      ),
    );
  }
}
