/// Perfil local del dispositivo. Define el responsable por defecto que se
/// guarda en cada movimiento de inventario.
class LocalProfile {
  const LocalProfile({
    this.responsibleName = '',
    this.storeName = '',
    this.initialized = false,
  });

  final String responsibleName;
  final String storeName;

  /// Indica si el usuario ya completo el nombre del responsable.
  final bool initialized;

  LocalProfile copyWith({
    String? responsibleName,
    String? storeName,
    bool? initialized,
  }) {
    return LocalProfile(
      responsibleName: responsibleName ?? this.responsibleName,
      storeName: storeName ?? this.storeName,
      initialized: initialized ?? this.initialized,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LocalProfile &&
      other.responsibleName == responsibleName &&
      other.storeName == storeName &&
      other.initialized == initialized;

  @override
  int get hashCode => Object.hash(responsibleName, storeName, initialized);
}
