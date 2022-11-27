// Copyright (c) 2022, Yako. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';

/// Simple Mutex providing a exclusive write lock and shared read-only locks.
class Mutex {
  var _exclusive = Completer<void>()..complete();
  var _shared = Completer<void>()..complete();
  int _sharedCount = 0;

  /// Aquires the exclusive lock.
  ///
  /// This is literally mutually exclusive with other users aqurering
  /// exclusive/ shared locks.
  ///
  /// 1. waits for the other existing users having requested for
  /// aquiring the exclusive lock at the call time to release it.
  /// 2. makes the other users wait for newly aquiring exclusive/ shared
  /// locks with some exception. See [unlock].
  /// 3. waits for all the existing users having aquired shared locks
  /// to release them.
  ///
  /// This is useful for a read/ write user of resouces which should not
  /// run with other users at the same time.
  ///
  /// When the code between [unlock] and [lock] is synchronous,
  /// and you don't want to get lock in succession, use [lock(true)]
  /// instead of [lock()] or [lock(false)].
  Future<void> lock([bool deliver = false]) async {
    if (deliver) {
      await _exclusive.future;
    }
    while (!_exclusive.isCompleted) {
      await _exclusive.future;
    }
    _exclusive = Completer<void>();
    while (!_shared.isCompleted) {
      await _shared.future;
    }
  }

  /// Releases the exclusive lock.
  ///
  /// This will resume the first user having requested for aquiring the exclusive lock,
  /// or will resume some users having requested for aquiring shared locks,
  /// dipending on calling order.
  ///
  /// Having said that, if the code between [unlock] and next [lock] on the same
  /// [Mutex] object is synchronous, the next [lock()] will succeed synchronously.
  /// It means, ajacent critical sections glued with synchronous code will be
  /// concatanated to single critical section.
  /// In other words, this doesn't introduce another unintended asynchronous behaviour,
  /// so don't hesitate [unlock] just fater each critical section.
  ///
  /// If you don't like this behavior, use [lock(true)] instead of [lock()] or [lock(false)].
  void unlock() {
    _exclusive.complete();
  }

  /// Critical section with [lock] and [unlock].
  ///
  /// When the code between [critical] and another [critical] is synchronous,
  /// and you don't want to get lock in succession, pass [deliver] `true`.
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
  /// var ret2 = await mutex.critical(deliver: true, () async {
  ///   ret1 = await someAsyncCriticalFunc3();
  ///   return await someAsyncCriticalFunc4();
  /// });
  /// ```
  Future<T> critical<T>(FutureOr<T> Function() func,
      {bool deliver = false}) async {
    await lock(deliver);
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

  /// Aquires a shared lock.
  ///
  /// This is mutually exclusive with other users aquiring the exclusive lock.
  ///
  /// But, this can be shared with all the other users aquiring shared locks.
  ///
  /// This is useful for read-only users of resources running asynchronously
  /// at the same time.
  Future<void> lockShared() async {
    while (!_exclusive.isCompleted) {
      await _exclusive.future;
    }
    if (_sharedCount == 0) {
      _shared = Completer<void>();
    }
    _sharedCount++;
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
    }
  }

  /// Critical section with [lockShared] and [unlockShared].
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
  Future<T> criticalShared<T>(FutureOr<T> Function() func) async {
    await lockShared();
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
}
