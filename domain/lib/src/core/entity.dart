/// Base entity class for domain entities.
/// All domain entities should extend this class.
abstract class Entity {
  const Entity();

  /// Returns a list of properties to use for equality comparison.
  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final Entity otherEntity = other as Entity;
    return _listEquals(props, otherEntity.props);
  }

  @override
  int get hashCode => Object.hashAll(props);

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}






