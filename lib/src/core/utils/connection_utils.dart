import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

final class ConnectionUtils {
  Stream listenNetworkChanged() => Connectivity().onConnectivityChanged;

  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity()
          .checkConnectivity();

      return checkConnectivityStatus(connectivityResult);
    }catch(e){
      return false;
    }
  }

  Future<bool> checkConnectivityStatus(List<ConnectivityResult> connectivityResult) async{
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet)) {
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    }

    return false;
  }
}