import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/offer_ride_screen.dart';
import 'screens/ride_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const UniRideApp());
}

class UniRideApp extends StatelessWidget {
  const UniRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/offer-ride': (context) => const OfferRideScreen(),
        // ❌ Do NOT include FindRideScreen here (it requires a parameter)
        '/ride-details': (context) => const RideDetailsScreen(),
      },

      initialRoute: '/',
    );
  }
}
