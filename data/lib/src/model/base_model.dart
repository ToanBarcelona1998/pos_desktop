/// Base model interface for DTOs
abstract class BaseModel {
  const BaseModel();

  /// Converts model to JSON map
  Map<String, dynamic> toJson();
}

/// Mixin for models that can be parsed from JSON
mixin JsonParseable<T> {
  /// Creates model from JSON map
  T fromJson(Map<String, dynamic> json);
}









