import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UniRide Home"),
        backgroundColor: const Color(0xFF009DAE),
      ),
      body: const Center(
        child: Text("Welcome to UniRide! 🎉", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
