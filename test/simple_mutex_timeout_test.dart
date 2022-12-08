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
      } catch (e) {
        ret = 'Timed out';
      }
      expect(ret, 'Timed out');
    });
    test('lock2', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lockShared();
      try {
        await mutex.lock(timeLimit: Duration(milliseconds: 100));
        ret = 'Ok';
      } catch (e) {
        ret = 'Timed out';
      }
      expect(ret, 'Timed out');
    });
    test('lock3', () async {
      var mutex = Mutex();
      var ret = '';
      unawaited(mutex.lock());
      await null;
      print('isLocked1: ${mutex.isLocked}');
      unawaited(mutex.lockShared());
      await null;
      Future.delayed(Duration(milliseconds: 100), () async {
        print('isLocked2: ${mutex.isLocked}');
        mutex.unlock();
        print('unlock');
        print('isLocked3: ${mutex.isLocked}');
        await null;
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
      } catch (e) {
        ret = 'Timed out';
        print('Timed out');
      }
      expect([mutex.isLocked, ret], [false, 'Timed out']);
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
      expect(ret, 'Timed out');
    });
    test('critical2', () async {
      var mutex = Mutex();
      var ret = '';
      unawaited(mutex.lock());
      await null;
      print('isLocked1: ${mutex.isLocked}');
      unawaited(mutex.lockShared());
      await null;
      Future.delayed(Duration(milliseconds: 100), () async {
        print('isLocked2: ${mutex.isLocked}');
        mutex.unlock();
        print('unlock');
        print('isLocked3: ${mutex.isLocked}');
        await null;
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
        print('Timed out');
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
      } catch (e) {
        ret = 'Timed out';
      }
      expect(ret, 'Timed out');
    });
    test('shared2', () async {
      var mutex = Mutex();
      var ret = '';
      await mutex.lockShared();
      try {
        await mutex.lockShared(timeLimit: Duration(milliseconds: 100));
        ret = 'Ok';
      } catch (e) {
        ret = 'Timed out';
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
        await mutex.critical(timeLimit: Duration(milliseconds: 100), () {
          ret = 'Ok';
        });
      } catch (e) {
        ret = 'Timed out';
      }
      expect(ret, 'Timed out');
    });
  });
}
