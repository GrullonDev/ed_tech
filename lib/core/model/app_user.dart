/// Usuario actual de la app. Sin backend todavía, así que es un perfil
/// puramente local: solo existe el usuario del dispositivo.
///
/// [playerId] es un identificador local corto y único (generado una sola vez
/// al completar el onboarding) que viaja dentro del código QR de "Invocar
/// por QR": es lo que permite que otro dispositivo lo reconozca como un
/// jugador distinto al escanearlo, sin necesidad de un servidor central.
class AppUser {
  AppUser({
    required this.username,
    required this.memberSince,
    required this.playerId,
  });

  final String username;
  final DateTime memberSince;
  final String playerId;

  Map<String, dynamic> toMap() => {
    'username': username,
    'memberSince': memberSince.toIso8601String(),
    'playerId': playerId,
  };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
    username: map['username'] as String,
    memberSince: DateTime.parse(map['memberSince'] as String),
    // Los perfiles guardados antes de que existiera "Invocar por QR" no
    // tienen playerId propio: se deriva uno estable a partir del username
    // para no romper el arranque de instalaciones existentes.
    playerId: (map['playerId'] as String?) ?? _fallbackPlayerId(map['username'] as String),
  );

  static String _fallbackPlayerId(String username) =>
      username.hashCode.toRadixString(36);
}
