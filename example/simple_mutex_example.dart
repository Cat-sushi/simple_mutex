import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:simple_mutex/simple_mutex.dart';

final mutex = Mutex();
final rand = Random();
final t = 1000;
var a = t;
var b = 0;

Future<void> mySleep(int ms) => Future.delayed(Duration(milliseconds: ms));

Future<void> move() async {
  while (a > 0) {
    await mutex.critical(() async {
      var a2 = a;
      var r = min(rand.nextInt(10) + 1, a2);
      await mySleep(rand.nextInt(10));
      a = a2 - r;
      await mySleep(rand.nextInt(10));
      var b2 = b;
      await mySleep(rand.nextInt(10));
      b = b2 + r;
    });
    await mySleep(rand.nextInt(10));
  }
}

Future<void> observe() async {
  while (a > 0) {
    await mutex.criticalShared(() async {
      if (a + b == t) {
        stdout.write('.');
      } else {
        print('\nerror: $a + $b = ${a + b} != $t');
      }
      await mySleep(rand.nextInt(10));
    });
  }
}

Future<void> main() async {
  print('$a + $b = ${a + b}');
  var futures = <Future<void>>[];
  for (var i = 0; i < 5; i++) {
    futures.add(move());
    futures.add(observe());
  }
  await Future.wait(futures);
  print('\n$a + $b = ${a + b}');
}
