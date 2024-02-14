import 'package:simple_mutex/simple_mutex.dart';
import 'package:test/test.dart';

import 'dart:async';

void main() {
  group('lock', () {
    test('lock1', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lock();
      try {
        await mutex.lock(timeLimit: Duration(milliseconds: 100));
        ret = 'Ok';
      } on TimeoutException catch (e) {
        ret = e.message!;
      }
      expect([ret, mutex.isLocked],
          ['lock: Timed out during awating the exclusive lock released', true]);
    });
    test('lock2', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lockShared();
      try {
        await mutex.lock(timeLimit: Duration(milliseconds: 100));
        ret = 'Ok';
      } on TimeoutException catch (e) {
        ret = e.message!;
      }
      expect([ret, mutex.isLocked, mutex.sharedCount],
          ['lock: Timed out during awating shared locks released', false, 1]);
    });
    test('lock3', () async {
      var mutex = Mutex();
      var ret = '';
      unawaited(mutex.lock());
      await Future<void>.microtask(() {});
      print('isLocked: ${mutex.isLocked}');
      unawaited(mutex.lockShared());
      await Future<void>.microtask(() {});
      Future.delayed(Duration(milliseconds: 100), () async {
        mutex.unlock();
        print('unlock');
        await Future<void>.microtask(() {});
        print('shardCount1: ${mutex.sharedCount}');
      });
      Future.delayed(Duration(milliseconds: 400), () {
        mutex.unlockShared();
        print('unlockShared');
      });
      print('try lock');
      try {
        await mutex.lock(timeLimit: Duration(milliseconds: 200));
        ret = 'Ok';
        print('shardCount2: ${mutex.sharedCount}');
      } on TimeoutException catch (e) {
        ret = e.message!;
      }
      expect([mutex.isLocked, ret],
          [false, 'lock: Timed out during awating shared locks released']);
    });
  });
  group('critical', () {
    test('critical1', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lock();
      try {
        await mutex.critical(timeLimit: Duration(milliseconds: 100), () {
          ret = 'Ok';
        });
      } catch (e) {
        ret = 'Timed out';
      }
      expect([mutex.isLocked, ret], [true, 'Timed out']);
    });
    test('critical2', () async {
      var mutex = Mutex();
      var ret = '';
      unawaited(mutex.lock());
      await Future<void>.microtask(() {});
      print('isLocked: ${mutex.isLocked}');
      unawaited(mutex.lockShared());
      await Future<void>.microtask(() {});
      Future.delayed(Duration(milliseconds: 100), () async {
        mutex.unlock();
        print('unlock');
        await Future<void>.microtask(() {});
        print('shardCount1: ${mutex.sharedCount}');
      });
      Future.delayed(Duration(milliseconds: 400), () {
        mutex.unlockShared();
        print('unlockShared');
      });
      print('try lock');
      try {
        await mutex.critical(timeLimit: Duration(milliseconds: 200), () {
          ret = 'Ok';
          print('shardCount2: ${mutex.sharedCount}');
        });
      } catch (e) {
        ret = 'Timed out';
      }
      expect([mutex.isLocked, ret], [false, 'Timed out']);
    });
  });
  group('shared', () {
    test('shared1', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lock();
      try {
        await mutex.lockShared(timeLimit: Duration(milliseconds: 100));
        ret = 'Ok';
      } on TimeoutException catch (e) {
        ret = e.message!;
      }
      expect(ret,
          'lockShared: Timed out during awating the exclusive lock released');
    });
    test('shared2', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lockShared();
      try {
        await mutex.lockShared(timeLimit: Duration(milliseconds: 100));
        ret = 'Ok';
      } on TimeoutException catch (e) {
        ret = e.message!;
      }
      expect(ret, 'Ok');
    });
  });
  group('criticalShared', () {
    test('criticalShared1', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lock();
      try {
        await mutex.criticalShared(timeLimit: Duration(milliseconds: 100), () {
          ret = 'Ok';
        });
      } catch (e) {
        ret = 'Timed out';
      }
      expect(ret, 'Timed out');
    });
  });
}
