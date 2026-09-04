import 'package:flutter/material.dart';

import 'package:edtech_tiktok/core/model/habit_circle.dart';

class CircleCard extends StatelessWidget {
  const CircleCard({super.key, required this.circle, required this.onCheckIn});

  final HabitCircle circle;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  circle.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Racha de ${circle.streakDays} días 🔥',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: circle.members.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return Column(
                    children: [
                      CircleAvatar(radius: 16, child: Text(circle.members[i])),
                      Icon(
                        circle.checkedInToday
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: circle.checkedInToday
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: circle.checkedInToday ? Colors.green : null,
                ),
                icon: Icon(
                  circle.checkedInToday
                      ? Icons.check
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  circle.checkedInToday
                      ? 'Check-in completado'
                      : 'Hacer Check-in',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
