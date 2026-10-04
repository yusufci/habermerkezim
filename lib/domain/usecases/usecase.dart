/// Base UseCase sınıfları - Clean Architecture Use Case Pattern
/// Tüm use case'ler bu soyut sınıflardan türetilir
library;

/// Parametresiz use case
abstract class UseCase<T> {
  Future<T> call();
}

/// Parametreli use case
abstract class UseCaseWithParams<T, Params> {
  Future<T> call(Params params);
}

/// Stream dönen use case (reactive)
abstract class StreamUseCase<T> {
  Stream<T> call();
}

/// Stream dönen parametreli use case
abstract class StreamUseCaseWithParams<T, Params> {
  Stream<T> call(Params params);
}

/// Void dönen parametreli use case
abstract class VoidUseCaseWithParams<Params> {
  Future<void> call(Params params);
}

/// Void dönen parametresiz use case
abstract class VoidUseCase {
  Future<void> call();
}
