// Copyright (c) 2022, Yako. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';

/// Simple but the best Mutex providing a exclusive write lock and shared read-only locks.
class Mutex {
  final _waitingQueue = <Completer<void>>[];
  var _isLocked = false;
  var _shared = Completer<void>()..complete();
  var _sharedCount = 0;

  /// Aquires the exclusive lock.
  ///
  /// This is literally mutually exclusive with other users aqurering
  /// exclusive/ shared locks.
  ///
  /// 1. waits for the other existing users having requested for
  /// aquiring the exclusive lock at the call time to release it.
  /// 2. makes the other users wait for newly aquiring exclusive/ shared locks.
  /// 3. waits for all the existing users having aquired shared locks
  /// to release them.
  ///
  /// This is useful for a read/ write user of resouces which should not
  /// run with other users at the same time.
  ///
  /// If [timeLimit] is not `null` this might throw [TimeoutException]
  ///  after [timeLimit] * 2, at max.
  /// 1 [timeLimit] for waiting for the exclusive lock released,
  /// and 1 [timeLimit] for waiting for shared locks released.
  Future<void> lock({Duration? timeLimit}) async {
    if (_isLocked || _waitingQueue.isNotEmpty) {
      var myCompleter = Completer<void>.sync();
      _waitingQueue.add(myCompleter);
      if (timeLimit == null) {
        await myCompleter.future;
      } else {
        await myCompleter.future.timeout(timeLimit, onTimeout: () {
          _waitingQueue.remove(myCompleter);
          return Future.error(TimeoutException('Timed out in wating queue.'));
        });
      }
      _waitingQueue.removeAt(0);
    }
    _isLocked = true;
    if (_sharedCount > 0) {
      if (timeLimit == null) {
        await _shared.future;
        return;
      }
      await _shared.future.timeout(timeLimit, onTimeout: () {
        _isLocked = false;
        return Future.error(TimeoutException(
            'Timed out while wating for shared locks released.'));
      });
    }
  }

  /// Releases the exclusive lock.
  ///
  /// This will resume the first user having requested for aquiring the exclusive lock,
  /// or will resume some users having requested for aquiring shared locks,
  /// dipending on calling order.
  void unlock() {
    _isLocked = false;
    if (_waitingQueue.isNotEmpty) {
      _waitingQueue[0].complete();
    }
  }

  /// Critical section with [lock] and [unlock].
  ///
  /// If [timeLimit] is not `null`, this might throw [TimeoutException]
  /// when [lock()] is timed out. See [lock].
  /// ## Usage
  /// ```dart
  /// var ret = await mutex.critical(someSyncCriticalFunc1);
  /// ```
  /// ```dart
  /// var ret = await mutex.critical(someAsyncCriticalFunc1);
  /// ```
  /// ```dart
  /// var ret = await mutex.critical(() => someSyncCriticalFunc2(arg1, arg2));
  /// ```
  /// ```dart
  /// var ret = await mutex.critical(() => someAsyncCriticalFunc2(arg1, arg2));
  /// ```
  /// ```dart
  /// late RetType ret1;
  /// var ret2 = await mutex.critical(() {
  ///   ret1 = someSyncCriticalFunc3();
  ///   return someSyncCriticalFunc4();
  /// });
  /// ```
  /// ```dart
  /// late RetType ret1;
  /// var ret2 = await mutex.critical(() async {
  ///   ret1 = await someAsyncCriticalFunc3();
  ///   return await someAsyncCriticalFunc4();
  /// });
  /// ```
  Future<T> critical<T>(FutureOr<T> Function() func,
      {Duration? timeLimit}) async {
    await lock(timeLimit: timeLimit);
    try {
      if (func is Future<T> Function()) {
        return await func();
      } else {
        return func();
      }
    } finally {
      unlock();
    }
  }

  /// For test only.
  ///
  /// Exclusively Locked, including wating for shared locks unlocked.
  bool get isLocked => _isLocked;

  /// Aquires a shared lock.
  ///
  /// This is mutually exclusive with other users aquiring the exclusive lock.
  ///
  /// But, this can be shared with all the other users aquiring shared locks.
  ///
  /// This is useful for read-only users of resources running asynchronously
  /// at the same time.
  ///
  /// If [timeLimit] is not `null`, this might throw [TimeoutException]
  /// after [timeLimit].
  Future<void> lockShared({Duration? timeLimit}) async {
    if (_isLocked || _waitingQueue.isNotEmpty) {
      var myCompleter = Completer<void>.sync();
      _waitingQueue.add(myCompleter);
      if (timeLimit == null) {
        await myCompleter.future;
      } else {
        await myCompleter.future.timeout(timeLimit, onTimeout: () {
          _waitingQueue.remove(myCompleter);
          return Future.error(TimeoutException('Timed out in wating queue.'));
        });
      }
      _waitingQueue.removeAt(0);
    }
    if (_sharedCount == 0) {
      _shared = Completer<void>();
    }
    _sharedCount++;
    if (_waitingQueue.isNotEmpty) {
      _waitingQueue[0].complete();
    }
  }

  /// Releases a shared lock.
  ///
  /// If the caller is the last user having aquired a shared lock,
  /// this will resume the first existing user having requested for aquireing
  /// the exclusive lock.
  void unlockShared() {
    _sharedCount--;
    if (_sharedCount == 0) {
      _shared.complete();
      if (_waitingQueue.isNotEmpty && !_isLocked) {
        _waitingQueue[0].complete();
      }
    }
  }

  /// Critical section with [lockShared] and [unlockShared].
  ///
  /// If [timeLimit] is not `null`, this might throw [TimeoutException]
  /// when [lockShared()] is timed out.
  ///
  /// ## Usage
  /// ```dart
  /// var ret = await mutex.criticalShared(someSyncCriticalFunc1);
  /// ```
  /// ```dart
  /// var ret = await mutex.criticalShared(someAsyncCriticalFunc1);
  /// ```
  /// ```dart
  /// var ret = await mutex.criticalShared(() => someSyncCriticalFunc2(arg1, arg2));
  /// ```
  /// ```dart
  /// var ret = await mutex.criticalShared(() => someAsyncCriticalFunc2(arg1, arg2));
  /// ```
  /// ```dart
  /// late RetType ret1;
  /// var ret2 = await mutex.criticalShared(() {
  ///   ret1 = someSyncCriticalFunc3();
  ///   return someSyncCriticalFunc4();
  /// });
  /// ```
  /// ```dart
  /// late RetType ret1;
  /// var ret2 = await mutex.criticalShared(() async {
  ///   ret1 = await someAsyncCriticalFunc3();
  ///   return await someAsyncCriticalFunc4();
  /// });
  /// ```
  Future<T> criticalShared<T>(FutureOr<T> Function() func,
      {Duration? timeLimit}) async {
    await lockShared(timeLimit: timeLimit);
    try {
      if (func is Future<T> Function()) {
        return await func();
      } else {
        return func();
      }
    } finally {
      unlockShared();
    }
  }

  /// For test only.
  int get sharedCount => _sharedCount;
}
