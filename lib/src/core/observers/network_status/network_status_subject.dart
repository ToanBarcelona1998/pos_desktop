import 'dart:async';

import 'package:pos_final/src/core/observers/base_subject.dart';
import 'package:pos_final/src/core/utils/connection_utils.dart';

final class NetworkStatusSubject extends BaseSubject<bool>{
  NetworkStatusSubject();

  StreamSubscription ? _subscription;

  void listenNetworkChanged() async{
    final ConnectionUtils connectionUtils = ConnectionUtils();

    final status = await connectionUtils.checkConnectivity();

    notify(status);

    _subscription = connectionUtils.listenNetworkChanged().listen((event) async{
      final status = await connectionUtils.checkConnectivity();

      notify(status);
    });
  }

  void close(){
    _subscription?.cancel();
    _subscription = null;
  }
}