import 'dart:io';
import 'dart:math';

import 'package:simple_mutex/simple_mutex.dart';
import 'package:test/test.dart';

import 'dart:async';

final mutex = Mutex();
final rand = Random();
final t = 1000;
var a = t;
var b = 0;
var sharedCount = 0;
var maxShareCount = 0;

Future<void> mySleep(int ms) => Future.delayed(Duration(milliseconds: ms));

Future<void> move(int i) async {
  while (a > 0) {
    await mutex.critical(deliver: true, () async {
      var a2 = a;
      var r = min(rand.nextInt(9) + 1, a2);
      await mySleep(rand.nextInt(10));
      a = a2 - r;
      await mySleep(rand.nextInt(10));
      var b2 = b;
      await mySleep(rand.nextInt(10));
      b = b2 + r;
      await mySleep(rand.nextInt(10));
      stdout.write('M$i:$r ');
    });
  }
}

Future<void> observe(int i) async {
  while (a > 0) {
    await mutex.criticalShared(() async {
      sharedCount++;
      stdout.write('O$i:${mutex.isLocked ? "l" : "u"}${mutex.sharedCount} ');
      maxShareCount = max(maxShareCount, mutex.sharedCount);
      if (a + b != t) {
        stdout.writeln('\nerror: $a + $b = ${a + b} != $t');
      }
      maxShareCount = max(maxShareCount, sharedCount);
      await mySleep(rand.nextInt(10));
      sharedCount--;
    });
  }
}

void main() {
  group('example', () {
    test('exampla', () async {
      stdout.writeln('$a + $b = ${a + b}');
      var futures = <Future<void>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(observe(i));
      }
      await null;
      for (var i = 0; i < 5; i++) {
        futures.add(move(i));
      }
      await Future.wait(futures);
      stdout.writeln('\n$a + $b = ${a + b}');
      expect([a, b, maxShareCount], [0, 1000, 5]);
    });
  }, timeout: Timeout(Duration(minutes: 30)));
}
