import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/offer_ride_screen.dart';
import 'screens/find_ride_screen.dart';
import 'screens/ride_details_screen.dart';
import 'screens/profile_screen.dart';

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
        '/find-ride': (context) => const FindRideScreen(),
        '/offer-ride': (context) => const OfferRideScreen(),
        '/ride-details': (context) => const RideDetailsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },

      initialRoute: '/',
    );
  }
}
