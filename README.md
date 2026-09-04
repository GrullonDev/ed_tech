# CírculoDiario — EdTech TikTok

> Círculos de hábitos con accountability social — construido con Flutter. Inspirado en el diseño **Kinship Routine** (`assets/DESIGN.md`).

App de micro-hábitos donde creas círculos de 6–8 personas, haces check-in diario y mantienes la racha colectiva. Onboarding con apodo, dashboard con progreso del día, tarjetas de círculo con estado de cada miembro y navegación flotante. Toda la lógica vive en `HomeLogic` (`lib/features/logic/logic.dart:10`); las páginas solo leen estado y disparan métodos.

## ✨ Características actuales

### Onboarding
- Pantalla de bienvenida con logo y copy (`lib/features/widgets/onboarding.dart:6`) + `TextField` de apodo y CTA `Continuar` (`lib/features/widgets/onboarding.dart:56`)
- Controlado por `HomeLogic.usernameController` / `completeOnboarding()` (`lib/features/logic/logic.dart:82`). Se muestra mientras `!hasUsername` (`lib/features/page/home.dart:32`)

### Dashboard (home real)
- `SafeArea(bottom:false)` + `Scaffold.extendBody:true` para que el feed pase por debajo de la barra flotante (`lib/features/widgets/dashboard.dart:49`)
- Envuelto en `AppMaxWidth(maxWidth: 480)` para responsive en móviles grandes/tablets (`lib/core/theme/app_theme.dart:62`, `lib/features/widgets/dashboard.dart:56`)
- **TopBar** — logo `CírculoDiario` + pill de racha global (`overallStreakDays`) + avatar (`lib/features/widgets/dashboard.dart:144`)
- **Streak pill** con `warningContainer` (`lib/core/theme/app_theme.dart:36`) y animación de pulso al completar (`lib/features/widgets/dashboard.dart:218` `TweenAnimationBuilder` `1.5→1.0` `elasticOut` 450ms, `ValueKey(pulseTick)` `lib/features/widgets/dashboard.dart:200`)
- **Saludo** `¡Buen día, $username! 👋` y subtítulo tribal (`lib/features/widgets/dashboard.dart:67`)
- **TodayCard** — check-in del día con contador `$completed de $total`, `LinearProgressIndicator` y `Wrap` de hábitos tappables (`lib/features/widgets/dashboard.dart:261`, `lib/features/widgets/dashboard.dart:329`). Usa `TodayHabit.label/done` (`lib/core/model/today_habit.dart:1`)
- Métricas derivadas en `HomeLogic`: `todayCompletedCount`, `todayProgress`, `nextPendingHabit`, `overallStreakDays` (max streak de círculos) (`lib/features/logic/logic.dart:67`)
- **CTA pendiente** `Registrar hábito pendiente` si existe `nextPendingHabit` (`lib/features/widgets/dashboard.dart:90`)
- **Header de círculos** `Tus Círculos Activos` + pill de conteo + `Gestionar` (`lib/features/widgets/dashboard.dart:103`)
- **Lista de CircleCards** + banner `Círculo con cupo libre` / `Invitar` (`lib/features/widgets/dashboard.dart:127`)

### CircleCard
- Estado normal: categoría uppercase, nombre, `StreakBadge` (12% `secondary` + `AppShadows.streak`), barra de progreso, `_PendingBanner` si `pendingMemberName`, avatares apilados y botón `Listo / Ver círculo` (`lib/features/widgets/circle_card.dart:29`)
- Estado perfecto (`isPerfect` `lib/core/model/habit_circle.dart:22`): gradiente `celebrationStart→celebrationEnd` (`lib/features/widgets/circle_card.dart:154`), badge `¡CÍRCULO PERFECTO! 🎉`, botón `Celebrar`
- `_StackedAvatars` — hasta 4 visibles + `+extra` (`lib/features/widgets/circle_card.dart:324`), primer avatar usa `avatar_sample.png` (`lib/core/theme/app_assets.dart:4`)
- Tap en la card → `CircleDetailPage`; botón → `toggleCheckIn` (`lib/features/page/home.dart:58`)

### Detalle / Creación / Perfil
- **CircleDetailPage** — hero de racha y progreso + lista de miembros con estado `Pendiente`/check + botón check-in (`lib/features/page/circle_detail.dart:10`). Envuelta en `AppMaxWidth` + `AppBar` con `ellipsis`
- **CreateHabitPage** — `StatelessWidget` sin estado propio, delega a `HomeLogic.habitNameController` / `habitCategoryController` / `submitNewCircle()` (`lib/features/page/create_habit.dart:9`, `lib/features/logic/logic.dart:134`). Validación `name.isEmpty → false`
- **ProfilePage** — avatar grande, 3 `_StatCard` (racha máxima / círculos activos / perfectos) y lista de círculos resumidos (`lib/features/page/profile.dart:7`)

### Navegación
- **AppBottomNav** — píldora flotante (`height:68`, `borderRadius:pill`, `BoxShadow.card`) con `Círculos` (selected) / `Rachas` (placeholder) / botón `+` con gradiente `primaryContainer→primary` / `Perfil` (`lib/features/widgets/app_bottom_nav.dart:10`)
- `Home` cablea con `Navigator.push` + `ListenableBuilder` para que `CircleDetailPage` y `ProfilePage` reaccionen a `HomeLogic` (`lib/features/page/home.dart:58`)
- `CreateHabitPage` recibe `logic` directo por constructor (`lib/features/page/home.dart:72`)

### Estado y animación
- `HomeLogic extends ChangeNotifier` con `ListenableBuilder` en `MyHomePage` (`lib/features/page/home.dart:29`)
- `streakPulseTick` — contador que solo incrementa al **completar** (no al desmarcar) en `toggleTodayHabit` / `toggleCheckIn` (`lib/features/logic/logic.dart:59`, `90`, `97`). Propagado como `ValueKey` para disparar `_StreakFirePulse`
- `createCircle({name, category})` parametrizable y `createNewCircle()` legacy (`lib/features/logic/logic.dart:116`)

### Responsive y pulido visual
- `AppMaxWidth` en `Dashboard`, `CircleDetailPage`, `CreateHabitPage`, `ProfilePage`, `Onboarding` (`lib/core/theme/app_theme.dart:62`)
- `MediaQuery.textScaler.clamp(0.9, 1.2)` en `MyApp.builder` para evitar overflow por accesibilidad descontrolada (`lib/app.dart:14`)
- Anti-overflow: `Flexible`+`TextOverflow.ellipsis` en títulos y `SingleChildScrollView`+`ConstrainedBox(minHeight)` en onboarding (`lib/features/widgets/onboarding.dart:23`)
- `_NavItem` pulido (icon 22px, gaps 3/2, `height:1.1`) (`lib/features/widgets/app_bottom_nav.dart:104`)

## 🛠️ Stack Tecnológico

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | `3.47.1` | Framework UI |
| Dart | `^3.13.1` | Lenguaje |
| `provider` | `^6.1.5+1` | Gestión de estado (declarada, lógica actual usa `ChangeNotifier` directo) |
| `google_fonts` | `^6.2.1` | `Plus Jakarta Sans` (`lib/core/theme/app_theme.dart:105`) |
| `cached_network_image` | `^4.0.0` | Preparado para avatares remotos |
| `video_player` | `^2.14.0` | Declarada (legado EdTech TikTok, no usada en CírculoDiario) |
| `scroll_spy` | `^1.0.5` | Declarada |
| `flutter_lints` | `^6.0.0` | Reglas (`analysis_options.yaml:1`) |

> Nota: `video_player` / `cached_network_image` / `scroll_spy` vienen del concepto inicial de feed vertical TikTok. El feed actual es dashboard de círculos; pueden retirarse o integrarse (p. ej. historias de hábitos en vídeo).

## 📁 Estructura del Proyecto

```
edtech_tiktok/
├── lib/
│   ├── main.dart                         # runApp(MyApp)
│   ├── app.dart                          # MyApp — MaterialApp + AppTheme.light() + textScaler clamp
│   ├── core/
│   │   ├── model/
│   │   │   ├── habit_circle.dart         # HabitCircle (progress, isPerfect, extraMembers)
│   │   │   └── today_habit.dart          # TodayHabit (label, done mutable)
│   │   └── theme/
│   │       ├── app_theme.dart            # AppColors / AppRadius / AppSpacing / AppShadows / AppMaxWidth / AppTheme
│   │       └── app_assets.dart           # AppAssets.logo / avatarSample
│   └── features/
│       ├── logic/
│       │   └── logic.dart                # HomeLogic (ChangeNotifier)
│       ├── page/
│       │   ├── home.dart                 # MyHomePage — ListenableBuilder + Navigator wiring
│       │   ├── circle_detail.dart        # CircleDetailPage
│       │   ├── create_habit.dart         # CreateHabitPage (Stateless + HomeLogic)
│       │   └── profile.dart              # ProfilePage
│       └── widgets/
│           ├── dashboard.dart            # Dashboard + _TopBar + _StreakPill + _StreakFirePulse + _TodayCard
│           ├── circle_card.dart          # CircleCard + _PerfectCircleCard + _PendingBanner + _StreakBadge
│           ├── onboarding.dart           # Onboarding
│           └── app_bottom_nav.dart       # AppBottomNav (píldora flotante)
├── assets/
│   ├── DESIGN.md                         # Kinship Routine — Warm Minimalist Tactile
│   └── images/
│       ├── logo.png
│       └── avatar_sample.png
├── test/
│   └── widget_test.dart                  # ⚠️ test de contador por defecto, pendiente reescribir
├── analysis_options.yaml
└── pubspec.yaml
```

## 🎨 Diseño — Kinship Routine

Tokens en `lib/core/theme/app_theme.dart:8` (`AppColors`, `AppRadius`, `AppSpacing`, `AppShadows`):

- **Primary** `#059669` / `primaryContainer #10B981` — crecimiento, progreso, acciones afirmativas
- **Secondary** `#F97316` / `secondaryContainer #F59E0B` — calor social, rachas
- **Neutrales** `onSurface #0F172A`, `background #F8FAFC`, `surface #FFFFFF`, `surfaceContainer #F1F5F9`
- **Estados** `lavenderContainer #EAECFB`, `warningContainer #FFF1E6`, `celebrationStart #E3F9EE → celebrationEnd #D3F3E4`
- **Tipografía** `GoogleFonts.plusJakartaSansTextTheme` (`lib/core/theme/app_theme.dart:105`)
- **Spacing** base 8pt (`xs 4 → xl3 32`), **Radius** `pill 9999`, **Shadows** `card` y `streak`

Documento fuente: `assets/DESIGN.md` — paleta emocional, Warm Minimalist Tactile, grilla y elevaciones.

## 🔁 Flujo de Estado

```
Onboarding (usernameController) → completeOnboarding()
  → Dashboard (username, circles, todayHabits, todayProgress, nextPendingHabit, overallStreakDays, streakPulseTick)
    → CircleCard.onCheckIn → toggleCheckIn(circle) → _streakPulseTick++ si !wasCheckedIn && done → notifyListeners()
    → _TodayCard.onToggle  → toggleTodayHabit(h)   → _streakPulseTick++ si !wasDone && done
    → FAB + → CreateHabitPage(logic) → submitNewCircle() → createCircle(name, category)
    → Tap card → CircleDetailPage(circle, onCheckIn)
    → Nav Perfil → ProfilePage(username, overallStreakDays, circles)
```

`MyHomePage` mantiene una única instancia de `HomeLogic` (`lib/features/page/home.dart:19`) y la pasa con `ListenableBuilder` para reconstruir solo lo necesario.

## 🚀 Inicio Rápido

### Requisitos

- Flutter `^3.13.1` (probado con `3.47.1`)
- Dart `^3.13.1`
- Android Studio / Xcode para emuladores

### Instalación

```bash
git clone https://github.com/<tu-usuario>/edtech_tiktok.git
cd edtech_tiktok
flutter pub get
flutter doctor
flutter run              # dispositivo / emulador
flutter run -d chrome    # web (si está habilitado)
```

### Comandos útiles

```bash
flutter analyze          # análisis estático (flutter_lints + always_use_package_imports, prefer_single_quotes)
flutter test             # tests
flutter build apk        # APK release
flutter build ios        # iOS (requiere macOS)
flutter pub outdated     # dependencias desactualizadas
```

## 🧪 Testing

> ⚠️ `test/widget_test.dart` aún contiene el test de contador por defecto de `flutter create`. Reescribir para `MyHomePage` (verificar `Onboarding` → `Dashboard` tras `completeOnboarding`, `HomeLogic` toggles, `CircleCard` perfect vs normal).

```bash
flutter test
```

## 📄 Configuración

- **Lints:** `analysis_options.yaml` incluye `package:flutter_lints/flutter.yaml` + `always_use_package_imports`, `prefer_single_quotes`, `prefer_const_constructors`
- **Versión:** `1.0.0+1` (`pubspec.yaml:19`)
- **Assets:** `assets/images/` (`pubspec.yaml:65`)
- **Plataformas ignoradas:** `/web`, `/linux`, `/macos`, `/windows` según `.gitignore` — repo enfocado en mobile

## 🗺️ Roadmap

- [ ] Persistencia local (SharedPreferences / Hive) para `circles` y `todayHabits`
- [ ] Autenticación real y sync remoto
- [ ] Pantalla `Rachas` (actual placeholder en `AppBottomNav:45`)
- [ ] Notificaciones de racha y `Dar aliento` funcional (`_PendingBanner:280`)
- [ ] Historias en vídeo para círculos (reaprovechar `video_player`)
- [ ] Tests de `HomeLogic` y golden tests de `CircleCard`

---

Hecho con Flutter 💜 — de feed TikTok EdTech a **CírculoDiario**.
