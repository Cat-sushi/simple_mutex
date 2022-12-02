import 'dart:async';
import 'dart:io';
import 'dart:math';

import "package:simple_mutex/simple_mutex.dart";

final t = 1000;
var a = t;
var b = 0;
var rand = Random();
var mutex = Mutex();

Future<void> mySleep(int ms) => Future.delayed(Duration(milliseconds: ms));

Future<void> move() async {
  while (a > 0) {
    await mutex.critical(() async {
      var a2 = a;
      var r = min(rand.nextInt(10), a2);
      await mySleep(rand.nextInt(10));
      a = a2 - r;
      await mySleep(rand.nextInt(10));
      b += r;
    });
    await mySleep(rand.nextInt(10));
  }
}

Future<void> check() async {
  while (a > 0) {
    mutex.criticalShared(() {
      if (a + b == t) {
        stdout.write('.');
      } else {
        print('\nerror: $a + $b != $t');
      }
    });
    await mySleep(rand.nextInt(10));
  }
}

Future<void> main() async {
  print('$a + $b = ${a + b}');
  var futures = <Future<void>>[];
  for (var i = 0; i < 5; i++) {
    futures.add(move());
    unawaited(check());
  }
  await Future.wait(futures);
  print('\n$a + $b = ${a + b}');
}
