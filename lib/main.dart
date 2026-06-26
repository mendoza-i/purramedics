import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:purramedics/AI Assistant/data/claude_api_service.dart';
import 'package:purramedics/AI Assistant/presentation/chat_provider.dart';
import 'package:purramedics/pages/intro_page.dart';
import 'package:purramedics/pages/splash_screen.dart'; // Import Custom Splash Screen
import 'models/pet.dart';
import 'models/event.dart';
import 'models/appointment.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'config.dart'; // Import config

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  Hive.registerAdapter(PetAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(AppointmentAdapter()); // Register Appointment Adapter

  await Hive.openBox<Pet>('petsBox');
  await Hive.openBox<Event>('eventsBox');
  await Hive.openBox<Appointment>('appointmentsBox'); // Open Box

  // Check current auth status
  await AuthService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            apiService: ClaudeApiService(
              apiKey: kIsWeb ? '' : claudeApiKey,
              proxyUrl: kIsWeb
                  ? Uri.base.resolve('/api/chat').toString()
                  : null,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Purramedics',
        theme: AppTheme.light,
        home:
            const SplashScreen(), // Boot to new custom Animated Splash Screen instead of IntroPage
      ),
    );
  }
}
