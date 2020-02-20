@JS()
library sample;

import 'dart:html';
import 'package:js/js.dart';



@anonymous
@JS()
abstract class MessageEvent {
  external dynamic get data;
}

@JS('postMessage')
external void PostMessage(obj);

@JS('onmessage')
external set onMessage(f);

@JS('self')
external DedicatedWorkerGlobalScope get self;

void main() {
  print('Worker created');

// self.onMessage.listen((e) {
//     print('Message received from main script');
//     var workerResult = 'Result: ${e.data[0] * e.data[1]}';
//     print('Posting message back to main script');
//     self.postMessage(workerResult, null);
//   });

  onMessage = allowInterop((event) {
    var e = event as MessageEvent;
    print('worker: got...' + e.data);

    PostMessage("OK");
  });
}