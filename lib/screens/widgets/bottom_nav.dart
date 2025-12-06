import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../passenger_find_ride_screen.dart';
import '../driver_offer_ride_screen.dart';
import '../profile_screen.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 8,

      onTap: (index) {
        if (index == currentIndex) return;

        Widget? targetScreen;
        switch (index) {
          case 0:
            targetScreen = _getScreen('/home');
            break;
          case 1:
            targetScreen = _getScreen('/find-ride');
            break;
          case 2:
            targetScreen = _getScreen('/offer-ride');
            break;
          case 3:
            targetScreen = _getScreen('/profile');
            break;
        }

        if (targetScreen != null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => targetScreen!,
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      },

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Find"),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: "Offer",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }

  Widget? _getScreen(String route) {
    switch (route) {
      case '/home':
        return const HomeScreen();
      case '/find-ride':
        return const PassengerFindRideScreen();
      case '/offer-ride':
        return const DriverOfferRideScreen();
      case '/profile':
        return const ProfileScreen();
      default:
        return null;
    }
  }
}