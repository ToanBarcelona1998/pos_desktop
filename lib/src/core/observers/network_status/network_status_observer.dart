import 'package:pos_final/src/core/observers/base_observer.dart';

abstract class NetworkStatusObserver implements BaseObserver<bool> {
  const NetworkStatusObserver();
}