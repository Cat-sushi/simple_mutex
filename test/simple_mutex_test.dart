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

Future<void> mySleep() async {
  sleep(Duration(seconds: 1));
}
