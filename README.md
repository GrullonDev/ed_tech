# CírculoDiario — Racha Tribu

> Círculos de hábitos con accountability social — construido con Flutter. Inspirado en el diseño **Kinship Routine** (`assets/DESIGN.md`).

App de micro-hábitos donde creas círculos de 6–8 personas, haces check-in diario y mantienes la racha colectiva. Incluye gamificación con niveles, gotas de constancia, mapa de territorio isométrico y sistema social con QR. Toda la lógica vive en `HomeLogic` (`lib/features/logic/logic.dart:10`); las páginas solo leen estado y disparan métodos.

**Características principales:**
- 🎮 Sistema de gamificación con niveles y gotas de constancia
- 🗺️ Mapa isométrico de territorio con totems por círculo
- 📱 Escaneo y generación de códigos QR para invocar aliados
- 💾 Persistencia local con Hive (sin backend requerido)
- 🎨 Diseño "Kinship Routine" con tipografía Plus Jakarta Sans

## ✨ Características

### 🚀 Onboarding
- Pantalla de bienvenida con logo y copy
- TextField para ingresar apodo (username)
- Generación automática de `playerId` único por dispositivo
- Persistencia inmediata en Hive antes de avanzar
- Controlado por `HomeLogic.usernameController` / `completeOnboarding()`

### 📊 Dashboard Principal
- **TopBar** con logo, pill de racha global, nivel de usuario y gotas de constancia
- **TodayCard** con progreso diario, check-in de hábitos y barra de progreso animada
- Banner de celebración al completar 100% del día
- **TerritoryMap**: mapa isométrico con totems por círculo (CustomPainter)
- Gestión de círculos con bottom sheet

### 🎯 Círculos de Hábito
- Creación de círculos con nombre y categoría (Salud, Estudio, Fitness, etc.)
- Check-in diario con animaciones de pulso
- Cálculo de racha consecutiva y racha más larga (`longestStreak`)
- Estado "Círculo Perfecto" cuando todos los miembros completan
- Simulación de miembros locales (sin backend real)

### 🏆 Sistema de Rachas
- Racha global derivada del máximo de rachas de todos los círculos
- Racha record histórica
- **"El Libro de los Ritos"**: camino visual de hitos (7, 21, 30, 50, 100 días)
- Cuadrícula semanal de actividad (lunes a domingo)

### 🎮 Gamificación
- **Nivel de usuario**: cada 7 días de racha = +1 nivel
- **Gotas de Constancia**: 10 gotas por check-in + 50 por cada hito alcanzado
- **Totems coleccionables** en PageView 3D:
  - Semana Imbatible
  - Hábito Consolidado
  - Círculo Perfecto
  - Pacto de 30 Días
- Animaciones tipo juego: `GamePressable` (rebote de escala), `GamePageRoute` (tweening entre pantallas)

### 👥 Sistema Social (simulado localmente)
- **"Invocar por QR"**: genera QR único, escanea QR de otros dispositivos
- Formato del QR: `RACHATRIBU:<playerId>:<username>`
- Sistema de aliados: solicitudes pendientes, aceptar/rechazar
- **"El Gran Agora Tribal"**: mapa visual de hogueras por círculo, leaderboard

### 💾 Persistencia Local (Hive)
- Cajas: `settings_box`, `circles_box`, `today_habits_box`, `ally_requests_box`
- Reset diario automático de habits al cambiar de calendario
- Función `clearAll()` para pruebas o "cerrar sesión"

### 👤 Perfil
- Métricas: racha activa, record personal, cumplimiento mensual, círculos activos
- Mapa de presencia (10 semanas x 7 días) con gradiente de actividad
- Lista de solicitudes de aliados pendientes

### 📱 Navegación
- **AppBottomNav** — píldora flotante con:
  - Círculos (seleccionado)
  - Rachas
  - Botón `+` con gradiente
  - Perfil
- Navegación entre pantallas con animaciones suaves

### 🎨 Responsive y Pulido Visual
- `AppMaxWidth` limita el ancho a 480px móvil, escala a 720px tablet
- `MediaQuery.textScaler.clamp(0.9, 1.2)` para evitar overflow por accesibilidad
- Anti-overflow: `Flexible` + `TextOverflow.ellipsis` en títulos
- `SingleChildScrollView` + `ConstrainedBox(minHeight)` en onboarding

## 🛠️ Stack Tecnológico

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | `^3.13.1` | Framework UI (probado con `3.47.1`) |
| Dart | `^3.13.1` | Lenguaje de programación |
| `hive` | `^2.2.3` | Base de datos local (persistencia) |
| `hive_flutter` | `^1.1.0` | Hive adaptado para Flutter |
| `google_fonts` | `^6.2.1` | Tipografía Plus Jakarta Sans |
| `cached_network_image` | `^4.0.0` | Imágenes en caché (preparado para avatares remotos) |
| `qr_flutter` | `^4.1.0` | Generación de códigos QR |
| `mobile_scanner` | `^7.1.3` | Escaneo de códigos QR con cámara |
| `cupertino_icons` | `^1.0.8` | Iconos iOS |
| `flutter_lints` | `^6.0.0` | Reglas de linting |
| `flutter_launcher_icons` | `^0.14.3` | Generador de iconos (solo Android) |

> **Nota:** El proyecto funciona 100% offline con Hive. No se requiere backend ni conexión a internet.

## 📁 Estructura del Proyecto

```
edtech_tiktok/
├── lib/
│   ├── main.dart                           # Punto de entrada: init Hive + runApp(MyApp)
│   ├── app.dart                            # MaterialApp + AppTheme + textScaler clamp
│   ├── core/
│   │   ├── model/
│   │   │   ├── app_user.dart               # AppUser (username, memberSince, playerId)
│   │   │   ├── habit_circle.dart           # HabitCircle (name, category, members, checkIns, streaks)
│   │   │   ├── today_habit.dart            # TodayHabit (label, done mutable)
│   │   │   ├── check_in.dart               # CheckIn (date normalizada a medianoche)
│   │   │   ├── milestone.dart              # Milestone (7, 21, 30, 50, 100 días)
│   │   │   └── ally_request.dart           # AllyRequest (fromUsername, sentAt)
│   │   ├── service/
│   │   │   └── local_storage_service.dart  # Servicio Hive (CRUD para user, circles, habits, allies)
│   │   └── theme/
│   │       ├── app_theme.dart              # AppColors, AppRadius, AppSpacing, AppShadows, AppMaxWidth
│   │       └── app_assets.dart             # Rutas de assets (logo.png, avatar_sample.png)
│   └── features/
│       ├── logic/
│       │   └── logic.dart                  # HomeLogic (ChangeNotifier) - toda la lógica de negocio
│       ├── page/
│       │   ├── home.dart                   # MyHomePage - orquestador principal con ListenableBuilder
│       │   ├── circle_detail.dart          # Detalle de círculo con progreso y miembros
│       │   ├── create_habit.dart           # Formulario para crear nuevo círculo
│       │   ├── profile.dart                # Perfil con métricas, mapa de presencia, totems
│       │   ├── rachas.dart                 # Pantalla de rachas con hitos y semana
│       │   ├── agora.dart                  # "El Gran Agora Tribal" - mapa social de hogueras
│       │   └── qr_summon.dart              # "Invocar por QR" - escaneo y generación de QR
│       └── widgets/
│           ├── dashboard.dart              # Dashboard principal con TodayCard, TopBar, CircleCards
│           ├── game_ui.dart                # GamePressable, Iso3DIcon, ConstancyDropsPill
│           ├── territory_map.dart          # Mapa isométrico con totems de círculos (CustomPainter)
│           ├── ritual_path.dart            # "El Libro de los Ritos" - camino de hitos (CustomPainter)
│           ├── onboarding.dart             # Pantalla de bienvenida con TextField de apodo
│           └── app_bottom_nav.dart         # Navegación inferior flotante tipo pill
├── assets/
│   ├── DESIGN.md                           # Documento de diseño "Kinship Routine"
│   └── images/
│       ├── logo.png
│       └── avatar_sample.png
├── analysis_options.yaml                   # flutter_lints + always_use_package_imports
├── pubspec.yaml
└── README.md
```

## 🎨 Diseño — Kinship Routine

Tokens en `lib/core/theme/app_theme.dart` (`AppColors`, `AppRadius`, `AppSpacing`, `AppShadows`):

- **Primary** `#059669` / `primaryContainer #10B981` — crecimiento, progreso, acciones afirmativas
- **Secondary** `#F97316` / `secondaryContainer #F59E0B` — calor social, rachas
- **Neutrales** `onSurface #0F172A`, `background #F8FAFC`, `surface #FFFFFF`, `surfaceContainer #F1F5F9`
- **Estados** `lavenderContainer #EAECFB`, `warningContainer #FFF1E6`, `celebrationStart #E3F9EE → celebrationEnd #D3F3E4`
- **Tipografía** `GoogleFonts.plusJakartaSansTextTheme`
- **Spacing** base 8pt (`xs 4 → xl3 32`), **Radius** `pill 9999`, **Shadows** `card` y `streak`

Documento fuente: `assets/DESIGN.md` — paleta emocional, Warm Minimalist Tactile, grilla y elevaciones.

## 🔁 Flujo de Estado

```
Onboarding (usernameController) → completeOnboarding()
  → Dashboard (username, circles, todayHabits, todayProgress, overallStreakDays, userLevel, constancyDrops)
    → CircleCard.onCheckIn → toggleCheckIn(circle) → _streakPulseTick++ si !wasCheckedIn && done
    → _TodayCard.onToggle  → toggleTodayHabit(h)   → _streakPulseTick++ si !wasDone && done
    → FAB + → CreateHabitPage(logic) → submitNewCircle() → createCircle(name, category)
    → Tap card → CircleDetailPage(circle, onCheckIn)
    → Nav Rachas → RachasPage (hitos, semana, racha record)
    → Nav Agora → AgoraPage (mapa social de hogueras)
    → Nav QR → QrSummonPage (escanear/generar QR)
    → Nav Perfil → ProfilePage(username, overallStreakDays, circles, drops)
```

`MyHomePage` mantiene una única instancia de `HomeLogic` y la pasa con `ListenableBuilder` para reconstruir solo lo necesario.

**Persistencia:**
- Hive almacena: usuario, círculos, hábitos diarios, solicitudes de aliados
- Reset diario automático al cambiar de calendario
- Datos 100% locales (sin backend)

## 🚀 Inicio Rápido

### Requisitos

- Flutter `^3.13.1` (probado con `3.47.1`)
- Dart `^3.13.1`
- Android Studio / Xcode para emuladores
- Git

### Configuración del Proyecto

#### 1. Clonar el repositorio
```bash
git clone https://github.com/<tu-usuario>/edtech_tiktok.git
cd edtech_tiktok
```

#### 2. Instalar dependencias
```bash
flutter pub get
```

#### 3. Verificar configuración
```bash
flutter doctor
```
Esto verificará que tienes instalados:
- Flutter SDK
- Dart SDK
- Android Studio / Xcode
- Dispositivo o emulador configurado

#### 4. Configurar iconos de la app (opcional)
```bash
dart run flutter_launcher_icons
```
Esto generará los iconos de la app usando `assets/images/logo.png` como fuente.

#### 5. Ejecutar la app
```bash
# En dispositivo o emulador
flutter run

# En web (si está habilitado)
flutter run -d chrome

# En Windows (si está habilitado)
flutter run -d windows
```

### Primera Ejecución

Al abrir la app por primera vez:
1. Verás la pantalla de bienvenida con el logo de CírculoDiario
2. Ingresa tu apodo (username) en el campo de texto
3. Toca "Continuar" para acceder al dashboard
4. La app creará automáticamente tu perfil y almacenará los datos localmente

## 📱 Uso de la App

### Navegación Principal

La app utiliza una barra de navegación inferior flotante con 4 secciones:

1. **Círculos** (🏠): Dashboard principal con tus círculos y hábitos del día
2. **Rachas** (🔥): Estadísticas de rachas, hitos y semana de actividad
3. **Agora** (🌐): Mapa social de hogueras por círculo
4. **Perfil** (👤): Tu perfil, métricas y configuración

### Crear un Círculo

1. Toca el botón **"+"** en la barra de navegación
2. Ingresa el nombre del círculo (ej: "Estudiar Español")
3. Selecciona una categoría (Salud, Estudio, Fitness, etc.)
4. Toca "Crear Círculo"
5. El círculo aparecerá en tu dashboard

### Check-in Diario

1. En el dashboard, verás tu **TodayCard** con los hábitos del día
2. Toca en un hábito para marcarlo como completado
3. La barra de progreso se actualizará automáticamente
4. Al completar todos los hábitos, verás un banner de celebración

### Sistema de Rachas

- **Racha Actual**: Días consecutivos completando al menos un hábito
- **Racha Record**: Tu racha más larga histórica
- **Hitos**: Alcanza 7, 21, 30, 50 o 100 días para desbloquear logros
- **Gotas de Constancia**: Moneda virtual que ganas por check-ins y hitos

### Gamificación

- **Nivel**: Cada 7 días de racha = +1 nivel
- **Gotas de Constancia**: 
  - 10 gotas por cada check-in completado
  - 50 gotas por cada hito alcanzado
- **Totems**: Colecciona totems especiales al alcanzar logros específicos

### Sistema Social (QR)

1. Ve a la sección **QR** (ícono de código QR)
2. **Generar QR**: Muestra tu código QR único
3. **Escanear QR**: Escanea el QR de otros dispositivos para agregar aliados
4. **Formato del QR**: `RACHATRIBU:<playerId>:<username>`

### Mapa de Territorio

- En el dashboard, desplázate hacia abajo para ver el **TerritoryMap**
- Mapa isométrico con totems que representan tus círculos
- Cada totem muestra el estado del círculo (activo, racha, etc.)

### Perfil y Estadísticas

1. Ve a la sección **Perfil**
2. **Métricas principales**:
   - Racha activa actual
   - Record personal de racha
   - Cumplimiento mensual porcentaje
   - Círculos activos
3. **Mapa de presencia**: Cuadrícula de 10 semanas mostrando actividad
4. **Solicitudes de aliados**: Gestiona tus solicitudes pendientes

### Guardado Automático

- Todos los datos se guardan automáticamente en Hive
- No necesitas botón de "guardar"
- Los datos persisten entre sesiones
- Reset diario automático de hábitos al cambiar de calendario

### Estructura de Datos (Hive)

La app utiliza Hive para persistencia local con las siguientes cajas:
- `settings_box`: Configuración del usuario (username, playerId, memberSince)
- `circles_box`: Círculos de hábitos creados
- `today_habits_box`: Hábitos del día actual
- `ally_requests_box`: Solicitudes de aliados pendientes

> **Nota:** Los datos se almacenan localmente en el dispositivo. No hay sincronización con servidor.

## 🧪 Testing

> ⚠️ `test/widget_test.dart` aún contiene el test de contador por defecto de `flutter create`. Reescribir para `MyHomePage` (verificar `Onboarding` → `Dashboard` tras `completeOnboarding`, `HomeLogic` toggles, `CircleCard` perfect vs normal).

```bash
flutter test
```

## 📄 Configuración

### Análisis de Código
- **Lints:** `analysis_options.yaml` incluye `package:flutter_lints/flutter.yaml`
- **Reglas adicionales:**
  - `always_use_package_imports: true`
  - `prefer_single_quotes: true`
  - `prefer_const_constructors: true`
  - `avoid_print: false` (permitido para debug)

### Configuración de la App
- **Versión:** `1.0.0+1`
- **Assets:** `assets/images/` (logo.png, avatar_sample.png)
- **Plataformas soportadas:** Android, iOS
- **Plataformas ignoradas:** `/web`, `/linux`, `/macos`, `/windows` (en `.gitignore`)

### Configuración de TextScaler
- Limitado a `0.9 - 1.2` en `app.dart` para evitar overflow por ajustes de accesibilidad
- Calculado dinámicamente: `(screenWidth * 0.9).clamp(320, 720)` para responsive

### Configuración de Hive
- **Cajas:**
  - `settings_box`: Configuración del usuario
  - `circles_box`: Círculos de hábitos
  - `today_habits_box`: Hábitos del día
  - `ally_requests_box`: Solicitudes de aliados
- **Inicialización:** En `main.dart` antes de `runApp()`
- **Reset diario:** Automático al detectar cambio de fecha

## 🗺️ Roadmap

### ✅ Completado
- [x] Persistencia local con Hive
- [x] Sistema de rachas con hitos (7, 21, 30, 50, 100 días)
- [x] Pantalla de rachas con semana de actividad
- [x] Sistema de gamificación (niveles, gotas de constancia, totems)
- [x] Mapa isométrico de territorio (TerritoryMap)
- [x] Sistema social con QR (invocar aliados)
- [x] El Gran Agora Tribal (mapa social)
- [x] Perfil con métricas y mapa de presencia
- [x] Onboarding con generación de playerId único

### 🔄 En Progreso
- [ ] Tests de `HomeLogic` y golden tests de `CircleCard`
- [ ] Notificaciones de racha

### 📋 Pendiente
- [ ] Autenticación real y sync remoto
- [ ] Notificaciones push para recordatorios de check-in
- [ ] Historias en vídeo para círculos
- [ ] Multiidioma (i18n)
- [ ] Tema oscuro
- [ ] Widget de iOS/Android para racha actual
- [ ] Integración con calendario del dispositivo
- [ ] Exportar datos de progreso
- [ ] Modo offline mejorado con sync cuando haya conexión

---

## 📝 Comandos Útiles

```bash
# Desarrollo
flutter run                          # Ejecutar en dispositivo/emulador
flutter run -d chrome                # Ejecutar en web
flutter run -d windows               # Ejecutar en Windows

# Análisis y tests
flutter analyze                      # Análisis estático del código
flutter test                         # Ejecutar tests
flutter test --coverage             # Tests con cobertura de código

# Construcción
flutter build apk                    # Construir APK para Android
flutter build ios                    # Construir para iOS (requiere macOS)
flutter build web                    # Construir para web

# Mantenimiento
flutter pub get                      # Instalar dependencias
flutter pub upgrade                  # Actualizar dependencias
flutter pub outdated                 # Ver dependencias desactualizadas
dart run flutter_launcher_icons      # Regenerar iconos de la app

# Limpieza
flutter clean                        # Limpiar archivos de build
flutter doctor                       # Verificar configuración del entorno
```

## 🐛 Solución de Problemas

### Errores comunes

1. **"Unable to find a suitable Flutter SDK"**
   - Verificar que Flutter está en el PATH
   - Ejecutar `flutter doctor`

2. **"Could not resolve the artifact"**
   - Ejecutar `flutter clean` y luego `flutter pub get`

3. **"Error: Cannot run with sound null safety"**
   - Verificar versión de Dart: `dart --version`
   - Actualizar a Dart 2.12.0 o superior

4. **"Font not found"**
   - Verificar que `google_fonts` está en `pubspec.yaml`
   - Ejecutar `flutter pub get`

### Logs y depuración

```bash
# Ver logs de Flutter
flutter run --verbose

# Ver logs de Android
adb logcat

# Ver logs de iOS
xcrun devicectl device info log show <device_id>
```

---

Hecho con Flutter 💚 — de feed TikTok EdTech a **CírculoDiario**.
