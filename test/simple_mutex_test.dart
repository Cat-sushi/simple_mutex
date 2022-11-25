import 'dart:io';

import 'package:simple_mutex/simple_mutex.dart';
import 'package:test/test.dart';

import 'dart:async';

void main() {
  group('Exclusive lock tests', () {
    test('test1', () async {
      var results = [];

      var mutex = Mutex();
      await mutex.lock();

      var mutex1 = Mutex();
      await mutex1.lock();

      var mutex2 = Mutex();
      await mutex2.lock();

      var future1 = asyncFuncExclusive(1, mutex1, mutex, results);
      var future2 = asyncFuncExclusive(2, mutex2, mutex, results);

      await mySleep();

      results.add('restarting 1');
      mutex1.unlock();
      results.add('restarting 2');
      mutex2.unlock();
      mutex.unlock();

      results.add(await Future.wait<int>([future1, future2]));

      expect(results, [
        '1 locking',
        '2 locking',
        'restarting 1',
        'restarting 2',
        '1 locked.',
        '1 restarted.',
        '1 unlocked.',
        '2 locked.',
        '2 restarted.',
        '2 unlocked.',
        [1, 2]
      ]);
    });
    test('test2', () async {
      var results = [];

      var mutex = Mutex();
      await mutex.lock();

      var mutex1 = Mutex();
      await mutex1.lock();

      var mutex2 = Mutex();
      await mutex2.lock();

      var future1 = asyncFuncExclusive(1, mutex1, mutex, results);
      var future2 = asyncFuncExclusive(2, mutex2, mutex, results);

      await mySleep();

      results.add('restarting 2');
      mutex2.unlock();
      results.add('restarting 1');
      mutex1.unlock();
      mutex.unlock();

      results.add(await Future.wait<int>([future1, future2]));

      expect(results, [
        '1 locking',
        '2 locking',
        'restarting 2',
        'restarting 1',
        '1 locked.',
        '1 restarted.',
        '1 unlocked.',
        '2 locked.',
        '2 restarted.',
        '2 unlocked.',
        [1, 2]
      ]);
    });
  });
  group('Shared lock tests', () {
    test('test1', () async {
      var results = [];

      var mutex = Mutex();

      var mutex1 = Mutex();
      await mutex1.lock();

      var mutex2 = Mutex();
      await mutex2.lock();

      var mutex3 = Mutex();
      await mutex3.lock();

      var future1 = asyncFuncShared(1, mutex1, mutex, results);
      var future2 = asyncFuncShared(2, mutex2, mutex, results);
      var future3 = asyncFuncExclusive(3, mutex3, mutex, results);

      await mySleep();

      results.add('restarting 3');
      mutex3.unlock();
      results.add('restarting 1');
      mutex1.unlock();
      results.add('restarting 2');
      mutex2.unlock();

      results.add(await Future.wait<int>([future1, future2, future3]));

      expect(results, [
        '1 locking shared',
        '2 locking shared',
        '3 locking',
        '1 locked shared',
        '2 locked shared',
        'restarting 3',
        'restarting 1',
        'restarting 2',
        '1 restarted.',
        '1 unlocked shared',
        '2 restarted.',
        '2 unlocked shared',
        '3 locked.',
        '3 restarted.',
        '3 unlocked.',
        [1, 2, 3]
      ]);
    });
    test('test2', () async {
      var results = [];

      var mutex = Mutex();

      var mutex1 = Mutex();
      await mutex1.lock();

      var mutex2 = Mutex();
      await mutex2.lock();

      var mutex3 = Mutex();
      await mutex3.lock();

      var future1 = asyncFuncShared(1, mutex1, mutex, results);
      var future2 = asyncFuncShared(2, mutex2, mutex, results);
      var future3 = asyncFuncExclusive(3, mutex3, mutex, results);

      await mySleep();

      results.add('restarting 3');
      mutex3.unlock();
      results.add('restarting 2');
      mutex2.unlock();
      results.add('restarting 1');
      mutex1.unlock();

      results.add(await Future.wait<int>([future1, future2, future3]));

      expect(results, [
        '1 locking shared',
        '2 locking shared',
        '3 locking',
        '1 locked shared',
        '2 locked shared',
        'restarting 3',
        'restarting 2',
        'restarting 1',
        '2 restarted.',
        '2 unlocked shared',
        '1 restarted.',
        '1 unlocked shared',
        '3 locked.',
        '3 restarted.',
        '3 unlocked.',
        [1, 2, 3]
      ]);
    });
  });
  group('Critical section tests', () {
    test('test1', () async {
      var results = [];

      var mutex = Mutex();

      var mutex1 = Mutex();
      await mutex1.lock();

      var mutex2 = Mutex();
      await mutex2.lock();

      var mutex3 = Mutex();
      await mutex3.lock();

      var future1 = mutex.criticalShared(
          () async => results.add(await asyncFuncShared1(1, mutex1, results)));
      var future2 = mutex.criticalShared(
          () async => results.add(await asyncFuncShared1(2, mutex2, results)));
      var future3 = mutex.critical(() async =>
          results.add(await asyncFuncExclusive1(3, mutex3, results)));

      await mySleep();

      results.add('restarting 3');
      mutex3.unlock();
      results.add('restarting 2');
      mutex2.unlock();
      results.add('restarting 1');
      mutex1.unlock();

      await Future.wait<void>([future1, future2, future3]);

      expect(results, [
        'restarting 3',
        'restarting 2',
        'restarting 1',
        '2 restarted.',
        '2 unlocked shared',
        2,
        '1 restarted.',
        '1 unlocked shared',
        1,
        '3 locked.',
        '3 restarted.',
        3
      ]);
    });
    test('test2', () async {
      var results = [];

      var mutex = Mutex();

      var future1 = mutex.criticalShared(
          () async => results.add(await asyncFuncShared2(1, 4, results)));
      var future2 = mutex.criticalShared(
          () async => results.add(await asyncFuncShared2(2, 2, results)));
      var future3 =
          mutex.critical(() => results.add(syncFuncExclusive(3, 1, results)));

      await Future.wait<void>([future1, future2, future3]);

      expect(results, [
        '1 sleeping 4',
        '2 sleeping 2',
        '2 awaik',
        2,
        '1 awaik',
        1,
        '3 sleeping 1',
        '3 awaik',
        3
      ]);
    });
  });
  group('loop', () {
    test('test1', () async {
      var mutex = Mutex();
      var results = [];
      var future1 = exclusiveLoop1(mutex, results);
      await mySleep(100);
      var future2 = sharedLoop(mutex, results);
      await Future.wait([future1, future2]);
      expect(results, [
        'Start exclusive: 0',
        'Ended exclusive: 0',
        'Start exclusive: 1',
        'Ended exclusive: 1',
        'Start exclusive: 2',
        'Ended exclusive: 2',
        'Start shared: 0',
        'Ended shared: 0',
        'Start shared: 1',
        'Ended shared: 1',
        'Start shared: 2',
        'Ended shared: 2',
      ]);
    });
    test('test2', () async {
      var mutex = Mutex();
      var results = [];
      var future1 = exclusiveLoop2(mutex, results);
      await mySleep(100);
      var future2 = sharedLoop(mutex, results);
      await Future.wait([future1, future2]);
      expect(results, [
        'Start exclusive: 0',
        'Ended exclusive: 0',
        'Start shared: 0',
        'Ended shared: 0',
        'Start exclusive: 1',
        'Ended exclusive: 1',
        'Start shared: 1',
        'Ended shared: 1',
        'Start exclusive: 2',
        'Ended exclusive: 2',
        'Start shared: 2',
        'Ended shared: 2',
      ]);
    });
    test('test3', () async {
      var mutex = Mutex();
      var results = [];
      var future1 = exclusiveLoop3(mutex, results);
      await mySleep(100);
      var future2 = sharedLoop(mutex, results);
      await Future.wait([future1, future2]);
      expect(results, [
        'Start exclusive: 0',
        'Ended exclusive: 0',
        'Start exclusive: 1',
        'Ended exclusive: 1',
        'Start exclusive: 2',
        'Ended exclusive: 2',
        'Start shared: 0',
        'Ended shared: 0',
        'Start shared: 1',
        'Ended shared: 1',
        'Start shared: 2',
        'Ended shared: 2',
      ]);
    });
    test('test4', () async {
      var mutex = Mutex();
      var results = [];
      var future1 = exclusiveLoop4(mutex, results);
      await mySleep(100);
      var future2 = sharedLoop(mutex, results);
      await Future.wait([future1, future2]);
      expect(results, [
        'Start exclusive: 0',
        'Ended exclusive: 0',
        'Start shared: 0',
        'Ended shared: 0',
        'Start exclusive: 1',
        'Ended exclusive: 1',
        'Start shared: 1',
        'Ended shared: 1',
        'Start exclusive: 2',
        'Ended exclusive: 2',
        'Start shared: 2',
        'Ended shared: 2',
      ]);
    });
    test('test5', () async {
      var mutex = Mutex();
      unawaited(sharedLoop1(mutex));
      await mySleep(10);
      unawaited(sharedLoop1(mutex));
      await mySleep(10);
      unawaited(sharedLoop1(mutex));
      await mySleep(10);
      unawaited(sharedLoop1(mutex));
      await mySleep(10);
      unawaited(sharedLoop1(mutex));
      await mySleep(1000);
      await mutex.lock();
      mutex.unlock();
      expect('a', 'a');
    });
  });
}

Future<void> exclusiveLoop1(Mutex mutex, List results) async {
  for (var i = 0; i < 3; i++) {
    await mutex.lock();
    results.add('Start exclusive: $i');
    print('Start exclusive: $i');
    await mySleep(200);
    results.add('Ended exclusive: $i');
    print('Ended exclusive: $i');
    mutex.unlock();
  }
}

Future<void> exclusiveLoop2(Mutex mutex, List results) async {
  for (var i = 0; i < 3; i++) {
    await mutex.lock(true);
    results.add('Start exclusive: $i');
    print('Start exclusive: $i');
    await mySleep(200);
    results.add('Ended exclusive: $i');
    print('Ended exclusive: $i');
    mutex.unlock();
  }
}

Future<void> exclusiveLoop3(Mutex mutex, List results) async {
  for (var i = 0; i < 3; i++) {
    await mutex.critical(() async {
      results.add('Start exclusive: $i');
      print('Start exclusive: $i');
      await mySleep(200);
      results.add('Ended exclusive: $i');
      print('Ended exclusive: $i');
    });
  }
}

Future<void> exclusiveLoop4(Mutex mutex, List results) async {
  for (var i = 0; i < 3; i++) {
    await mutex.critical(deliver: true, () async {
      results.add('Start exclusive: $i');
      print('Start exclusive: $i');
      await mySleep(200);
      results.add('Ended exclusive: $i');
      print('Ended exclusive: $i');
    });
  }
}

Future<void> sharedLoop(Mutex mutex, List results) async {
  for (var i = 0; i < 3; i++) {
    await mutex.lockShared();
    results.add('Start shared: $i');
    print('Start shared: $i');
    await mySleep(50);
    results.add('Ended shared: $i');
    print('Ended shared: $i');
    mutex.unlockShared();
  }
}

Future<void> sharedLoop1(Mutex mutex) async {
  while (true) {
    await mutex.criticalShared(() async {
      await mySleep(50);
    });
  }
}

Future<int> asyncFuncExclusive(
    int me, Mutex myMutex, Mutex mutex, List results) async {
  results.add('$me locking');
  await mutex.lock();
  results.add('$me locked.');
  await myMutex.lock();
  results.add('$me restarted.');
  myMutex.unlock();
  mutex.unlock();
  results.add('$me unlocked.');
  return me;
}

Future<int> asyncFuncShared(
    int me, Mutex myMutex, Mutex mutex, List results) async {
  results.add('$me locking shared');
  await mutex.lockShared();
  results.add('$me locked shared');
  await myMutex.lock();
  results.add('$me restarted.');
  myMutex.unlock();
  mutex.unlockShared();
  results.add('$me unlocked shared');
  return me;
}

Future<int> asyncFuncExclusive1(int me, Mutex myMutex, List results) async {
  results.add('$me locked.');
  await myMutex.lock();
  results.add('$me restarted.');
  myMutex.unlock();
  return me;
}

Future<int> asyncFuncShared1(int me, Mutex myMutex, List results) async {
  await myMutex.lock();
  results.add('$me restarted.');
  myMutex.unlock();
  results.add('$me unlocked shared');
  return me;
}

int syncFuncExclusive(int me, int s, List results) {
  results.add('$me sleeping $s');
  sleep(Duration(seconds: s));
  results.add('$me awaik');
  return me;
}

Future<int> asyncFuncShared2(int me, int s, List results) async {
  results.add('$me sleeping $s');
  await Future<void>.delayed(Duration(seconds: s));
  results.add('$me awaik');
  return me;
}

Future<void> mySleep([int ms = 1000]) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
}
