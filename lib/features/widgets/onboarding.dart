import 'package:flutter/material.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({
    super.key,
    required this.usernameController,
    required this.onContinue,
  });

  final TextEditingController usernameController;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido a CírculoDiario',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Crea círculos de hábitos con tus amigos, haz check-in diario '
                'y mantén tu racha viva junto a los demás miembros del grupo.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tu apodo de usuario',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onContinue(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Continuar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
