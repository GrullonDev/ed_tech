/// Usuario actual de la app. Sin backend todavía, así que es un perfil
/// puramente local: solo existe el usuario del dispositivo.
class AppUser {
  AppUser({required this.username, required this.memberSince});

  final String username;
  final DateTime memberSince;

  Map<String, dynamic> toMap() => {
    'username': username,
    'memberSince': memberSince.toIso8601String(),
  };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
    username: map['username'] as String,
    memberSince: DateTime.parse(map['memberSince'] as String),
  );
}
