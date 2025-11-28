import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:pos_final/api_end_points.dart';
import 'package:async/async.dart';
import '../models/contact_model.dart';
import '../models/system.dart';
import 'api.dart';
import 'package:synchronized/synchronized.dart';

class CustomerApi extends Api {
  void insert(var data) {
    Contact().insertContact(data);
  }

  Future<dynamic> add(Map customer) async {
    try {
      String url = ApiEndPoints.addContact;
      var body = json.encode(customer);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: getHeader(token), body: body);
      var result = await jsonDecode(response.body);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<void> get() async {
    String? url = ApiEndPoints.getContact;
    var token = await System().getToken();
    print('Using Token for initial request: $token'); // Added: Logging the token for debugging

    var response;
    int retries = 0;
    while (retries < 3) { // Added: Retry loop for the initial request, similar to pages
      try {
        response = await http.get(Uri.parse(url!), headers: getHeader(token));
        if (response.statusCode == 200) {
          break; // Success, exit retry
        } else {
          print('Initial request failed with status: ${response.statusCode}'); // Added: Log status
          print('Error response body: ${response.body}'); // Added: Log response body for details (e.g., "Invalid token")
          if (response.statusCode == 401) {
            // Added: Specific handling for 401 - Attempt to refresh token or log
            print('401 Unauthorized - Token may be invalid or expired. Consider refreshing token.');
            // TODO: If you have a refresh token mechanism, call it here, e.g., await refreshToken();
          }
          throw HttpException('Failed to fetch initial contact data: ${response.statusCode}');
        }
      } catch (e) {
        print('Retry $retries failed: $e'); // Added: Log retry failure
        retries++;
        if (retries >= 3) {
          rethrow; // Rethrow after max retries
        }
        await Future.delayed(Duration(seconds: 2)); // Delay before retry
      }
    }

    final int totalPages = jsonDecode(response.body)['meta']['last_page'];

    // Use fewer isolates to prevent overwhelming the system
    int cores = min(Platform.numberOfProcessors - 1, min(4, totalPages));

    int numberOfPagesPerIsolate = totalPages < cores ? 0 : totalPages ~/ cores;
    int remainingPages = totalPages < cores ? totalPages : totalPages % cores;

    final completer = Completer<void>();
    var processedCount = 0;
    final totalExpectedBatches = min(cores, totalPages) + (remainingPages > 0 ? 1 : 0);

    final insertQueue = Queue<dynamic>();
    final insertLock = Lock();

    List<ReceivePort> ports = List.generate(cores + 1, (_) => ReceivePort());
    StreamGroup<dynamic> group = StreamGroup();

    for (var port in ports) {
      group.add(port.asBroadcastStream().handleError((error) {
        if (!completer.isCompleted) completer.completeError(error);
      }));
    }

    group.stream.listen(
          (data) async {
        await insertLock.synchronized(() async {
          insertQueue.add(data);
          await _processQueueInOrder(insertQueue);

          processedCount++;
          if (processedCount == totalExpectedBatches) {
            await System().insertCustomersLastSyncDateTimeNow(); // أضفت: تحديث last_sync بعد الجلب الناجح
            completer.complete();
          }
        });
      },
      onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
    );

    // Calculate requests per isolate to maintain 40 requests/minute across all isolates
    const requests = 40;
    final requestsPerIsolatePerMinute = requests ~/ cores;
    final millisecondsBetweenRequests = (60 * 1000) ~/ requestsPerIsolatePerMinute;

    try {
      for (int i = 0; i < cores; i++) {
        int start = (i * numberOfPagesPerIsolate) + 1;
        await Isolate.spawn(
          isolateWork,
          [start, numberOfPagesPerIsolate, token, ports[i].sendPort, millisecondsBetweenRequests],
          onError: ports[i].sendPort,
        );
      }

      if (remainingPages > 0) {
        int start = cores * numberOfPagesPerIsolate + 1;
        await Isolate.spawn(
          isolateWork,
          [start, remainingPages, token, ports[cores].sendPort, millisecondsBetweenRequests],
          onError: ports[cores].sendPort,
        );
      }

      await completer.future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _processQueueInOrder(Queue<dynamic> queue) async {
    while (queue.isNotEmpty) {
      var data = queue.first;
      try {
        insert(data);
        queue.removeFirst();
      } catch (e) {
        break;
      }
    }
  }

  void isolateWork(List<dynamic> params) async {
    final int startPage = params[0];
    final int pagesToProcess = params[1];
    final String token = params[2];
    final SendPort sendPort = params[3];
    final int millisecondsBetweenRequests = params[4];

    try {
      for (int page = startPage; page < startPage + pagesToProcess; page++) {
        int retries = 0;
        while (retries < 3) { // أضفت: retry لكل صفحة حتى 3 محاولات
          try {
            String url = '${ApiEndPoints.getContact}&page=$page';
            var response = await http.get(Uri.parse(url), headers: getHeader(token));

            if (response.statusCode == 200) {
              var body = jsonDecode(response.body);
              List<Map<String, dynamic>> data = (body['data'] as List).cast<Map<String, dynamic>>();
              sendPort.send(data);
              break; // نجاح، اخرج من retry
            } else {
              print('Page $page failed with status: ${response.statusCode}'); // Added: Log page failure
              print('Error response body for page $page: ${response.body}'); // Added: Log body
              if (response.statusCode == 401) {
                print('401 Unauthorized on page $page - Token may be invalid.'); // Added: Specific log
              }
              throw HttpException('Failed to fetch page $page: ${response.statusCode}');
            }
          } catch (e) {
            retries++;
            if (retries >= 3) {
              sendPort.send(['ERROR', e.toString(), 'Failed after 3 retries']);
            }
            await Future.delayed(Duration(seconds: 2)); // تأخير قبل إعادة المحاولة
          }
        }
        await Future.delayed(Duration(milliseconds: millisecondsBetweenRequests));
      }
    } catch (e, stackTrace) {
      sendPort.send(['ERROR', e.toString(), stackTrace.toString()]);
    }
  }
}