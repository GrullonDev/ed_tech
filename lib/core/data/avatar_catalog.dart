/// Un avatar-emoji desbloqueable con "Gotas de Constancia" (ver
/// `HomeLogic.unlockAvatar`) — personalización a largo plazo: la moneda del
/// juego pasa a tener algo tangible en qué gastarse más allá de apuestas
/// (Predicción de Tribu), y el perfil se vuelve distinto entre usuarios que
/// llevan tiempo jugando.
class AvatarOption {
  const AvatarOption({required this.id, required this.emoji, required this.cost});

  final String id;
  final String emoji;

  /// Costo en Gotas de Constancia. `0` = gratis, siempre desbloqueado desde
  /// el principio (ver [AvatarCatalog.defaultAvatarId]).
  final int cost;
}

/// Catálogo fijo de avatares. Ampliar esta lista es la única forma de
/// agregar más opciones — no hay "temporada" ni rotación todavía (ver nota
/// de variedad/sorpresa en el check-in, que sí es aleatoria).
class AvatarCatalog {
  AvatarCatalog._();

  static const String defaultAvatarId = 'ember';

  static const List<AvatarOption> all = [
    AvatarOption(id: defaultAvatarId, emoji: '🔥', cost: 0),
    AvatarOption(id: 'wolf', emoji: '🐺', cost: 100),
    AvatarOption(id: 'owl', emoji: '🦉', cost: 100),
    AvatarOption(id: 'lion', emoji: '🦁', cost: 200),
    AvatarOption(id: 'dragon', emoji: '🐉', cost: 300),
    AvatarOption(id: 'phoenix', emoji: '🔱', cost: 300),
    AvatarOption(id: 'crown', emoji: '👑', cost: 500),
    AvatarOption(id: 'star', emoji: '🌟', cost: 750),
    AvatarOption(id: 'diamond', emoji: '💎', cost: 1000),
  ];

  static AvatarOption byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
