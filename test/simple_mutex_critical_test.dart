import 'package:simple_mutex/simple_mutex.dart';
import 'package:test/test.dart';

import 'dart:async';

void main() {
  group('Critical section', () {
    test('syncFunc1', () async {
      var mutex = Mutex();
      var ret = await mutex.critical(syncFunc1);
      expect(ret, 1);
    });
    test('asyncFunc1', () async {
      var mutex = Mutex();
      var ret = await mutex.critical(asyncFunc1);
      expect(ret, 1);
    });
    test('syncFunc2', () async {
      var mutex = Mutex();
      var ret = await mutex.critical(() => syncFunc2(2));
      expect(ret, 2);
    });
    test('asyncFunc2', () async {
      var mutex = Mutex();
      var ret = await mutex.critical(() => asyncFunc2(2));
      expect(ret, 2);
    });
    test('asyncFunc3', () async {
      var mutex = Mutex();
      var retFuture = mutex.critical(asyncFunc3);
      await mutex.criticalShared(() {
        results.add(2);
      });
      await retFuture;
      expect(results, [1,2]);
    });
  });
}

int syncFunc1() {
  return 1;
}

Future<int> asyncFunc1() async {
  await mySleep(100);
  return 1;
}

int syncFunc2(int i) {
  return i;
}

Future<int> asyncFunc2(i) async {
  await mySleep(100);
  return i;
}

var results = [];
Future<void> asyncFunc3() async {
  await mySleep(1000);
  results.add(1);
}

Future<void> mySleep([int ms = 1000]) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
}
