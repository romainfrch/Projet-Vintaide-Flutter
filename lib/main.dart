import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'home_shell.dart';

import 'theme/app_theme.dart';
import 'login_page.dart';
import 'buy_page.dart';
import 'clothing_detail_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'add_clothing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vintaide',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light(),

      initialRoute: '/login',

      routes: {
        '/login': (_) => const LoginPage(appName: 'Vintaide'),
        '/buy': (_) => const BuyPage(),
        '/detail': (_) => const ClothingDetailPage(),
        '/cart': (_) => const CartPage(),
        '/profile': (_) => const ProfilePage(),
        '/add': (_) => const AddClothingPage(),
        '/home': (_) => const HomeShell(),
      },
    );
  }
}
