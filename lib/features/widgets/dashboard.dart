import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';
import 'package:edtech_tiktok/features/widgets/circle_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.username,
    required this.circles,
    required this.onCreateCircle,
    required this.onCheckIn,
  });

  final String username;
  final List<HabitCircle> circles;
  final VoidCallback onCreateCircle;
  final ValueChanged<HabitCircle> onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $username 👋'),
        actions: [
          IconButton(
            onPressed: onCreateCircle,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Crear nuevo círculo',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Círculos de Hábitos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: circles.length,
                itemBuilder: (context, index) {
                  final circle = circles[index];
                  return CircleCard(
                    circle: circle,
                    onCheckIn: () => onCheckIn(circle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
