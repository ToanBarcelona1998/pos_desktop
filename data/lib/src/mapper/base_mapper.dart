/// Base mapper interface for converting between models and entities
abstract class Mapper<M, E> {
  const Mapper();
  /// Converts model (DTO) to domain entity
  E toEntity(M model);

  /// Converts domain entity to model (DTO)
  M toModel(E entity);

  /// Converts list of models to list of entities
  List<E> toEntityList(List<M> models) {
    return models.map(toEntity).toList();
  }

  /// Converts list of entities to list of models
  List<M> toModelList(List<E> entities) {
    return entities.map(toModel).toList();
  }
}

/// Mapper that only maps from model to entity (for read-only data)
abstract class ReadOnlyMapper<M, E> {
  const ReadOnlyMapper();
  /// Converts model (DTO) to domain entity
  E toEntity(M model);

  /// Converts list of models to list of entities
  List<E> toEntityList(List<M> models) {
    return models.map(toEntity).toList();
  }
}














