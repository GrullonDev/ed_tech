import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: .vertical,
        itemCount: 16,
        pageSnapping: true,
        allowImplicitScrolling: false,
        clipBehavior: .antiAliasWithSaveLayer,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Stack(
            fit: .expand,
            children: [
              // Capa 1: Fondo (simulando el reproductor de video por ahora)
              Container(
                color: Colors.primaries[index % Colors.primaries.length],
                child: Center(
                  child: Text(
                    'Video Educativo #$index',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),

              // Capa 2: Panel de interacción lateral derecho
              Positioned(
                right: 16,
                bottom: 80,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const Text('12.5K', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.comment,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const Text('430', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.bookmark,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              // Capa 3: Información de la lección (Inferior izquierda)
              const Positioned(
                left: 16,
                bottom: 40,
                right: 80,
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Text(
                      '@profesor_flutter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aprende a usar Stack y Positioned en 60 segundos 🚀 #flutter #dev',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
