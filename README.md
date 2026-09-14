# EdTech TikTok

> Feed vertical inmersivo estilo TikTok para micro-lecciones educativas — construido con Flutter.

Proyecto Flutter que explora una experiencia de aprendizaje corto y adictivo: vídeos educativos en formato vertical con scroll infinito, panel de interacción y overlay informativo. Inspirado en la UX de TikTok pero enfocado en contenido EdTech.

## ✨ Características actuales

- **Feed vertical paginado** — `PageView.builder` con `scrollDirection: Axis.vertical` y `pageSnapping: true` (`lib/home.dart:10`)
- **Layout por capas con `Stack`** — 3 capas: fondo (placeholder de vídeo), panel lateral de interacción y bloque informativo inferior (`lib/home.dart:18`)
- **Panel de interacción** — avatar, likes (12.5K), comentarios (430) y bookmark (`lib/home.dart:33`)
- **Overlay informativo** — autor `@profesor_flutter` y caption con hashtags (`lib/home.dart:78`)
- **Tema Material 3** — `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` (`lib/app.dart:12`)
- **SafeArea optimizado** — `SafeArea(top: false, bottom: true)` para experiencia fullscreen inmersiva

## 🛠️ Stack Tecnológico

| Tecnología             | Versión    | Uso                                             |
| ---------------------- | ---------- | ----------------------------------------------- |
| Flutter                | `3.47.1`   | Framework UI                                    |
| Dart                   | `^3.13.1`  | Lenguaje                                        |
| `video_player`         | `^2.14.0`  | Reproducción de vídeo (preparado para integrar) |
| `cached_network_image` | `^4.0.0`   | Caché de imágenes de perfil/thumbnails          |
| `provider`             | `^6.1.5+1` | Gestión de estado                               |
| `scroll_spy`           | `^1.0.5`   | Detección de visibilidad en scroll              |
| `flutter_lints`        | `^6.0.0`   | Reglas de lint                                  |

> **Estado actual:** el feed usa `Container` con `Colors.primaries` como placeholder de vídeo (`lib/home.dart:23`). `video_player` y `cached_network_image` ya están en `pubspec.yaml:37` listos para reemplazar el placeholder.

## 📁 Estructura del Proyecto

```
edtech_tiktok/
├── lib/
│   ├── main.dart       # Entry point → runApp(MyApp)
│   ├── app.dart        # MyApp (MaterialApp + Theme + Home)
│   └── home.dart       # MyHomePage — PageView vertical con Stack de 3 capas
├── test/
│   └── widget_test.dart
├── android/            # Runner Android
├── ios/                # Runner iOS
├── analysis_options.yaml
└── pubspec.yaml
```

## 🚀 Inicio Rápido

### Requisitos

- Flutter `^3.13.1` (probado con `3.47.1`)
- Dart `^3.13.1`
- Android Studio / Xcode para emuladores

### Instalación

```bash
# 1. Clonar
git clone https://github.com/<tu-usuario>/edtech_tiktok.git
cd edtech_tiktok

# 2. Instalar dependencias
flutter pub get

# 3. Verificar entorno
flutter doctor

# 4. Ejecutar
flutter run              # dispositivo conectado / emulador por defecto
flutter run -d chrome    # web (si está habilitado)
```

### Comandos útiles

```bash
flutter analyze          # análisis estático (flutter_lints)
flutter test             # tests
flutter build apk        # APK release Android
flutter build ios        # build iOS (requiere macOS)
flutter pub outdated     # verificar dependencias desactualizadas
```

## 🧪 Testing

> ⚠️ `test/widget_test.dart:14` aún contiene el test de contador por defecto de `flutter create`. Debe reescribirse para `MyHomePage` (verificar que el `PageView` renderiza, que el `Stack` contiene las 3 capas, etc.).

```bash
flutter test
```

## 📄 Configuración

- **Lints:** `analysis_options.yaml` hereda `package:flutter_lints/flutter.yaml`
- **Versión:** `1.0.0+1` (`pubspec.yaml:19`)
- **Plataformas ignoradas en git:** `/web`, `/linux`, `/macos`, `/windows` según `.gitignore:54` — repo enfocado en mobile

## 🤝 Contribución

1. Haz fork del repo
2. Crea una rama `feat/nueva-funcionalidad`
3. Ejecuta `flutter analyze` y `flutter test` antes de commitear
4. Abre un PR

## 📚 Recursos

- [Documentación de Flutter](https://docs.flutter.dev/)
- [video_player](https://pub.dev/packages/video_player)
- [provider](https://pub.dev/packages/provider)
- [cached_network_image](https://pub.dev/packages/cached_network_image)

---

Hecho con Flutter 💜 — feed EdTech inspirado en TikTok.
