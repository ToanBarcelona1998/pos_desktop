import 'base_observer.dart';

abstract class BaseSubject<S> {
  final List<BaseObserver> _observers = [];

  void attach(BaseObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  void detach(BaseObserver observer) {
    _observers.remove(observer);
  }

  void notify(S newState) {
    for (var observer in _observers) {
      observer.update(newState);
    }
  }
}