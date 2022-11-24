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
  /// This is literally mutually exclusive with other users aqurering exclusive/ shared locks.
  ///
  /// 1. waits for the other existing users having requested for aquiring the exclusive lock at the call time to release it.
  /// 2. makes the other users wait for aquiring exclusive/ shared locks.
  /// 3. waits for all the existing users having aquired shared locks to release them.
  ///
  /// This is useful for a read/ write user of resouces which should not run with other users at the same time.
  Future<void> lock() async {
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
  /// or resume some users having requested for aquiring shared locks,
  /// dipending on calling order.
  void unlock() {
    _exclusive.complete();
  }

  /// Critical section with the exclusive lock.
  /// 
  /// ## Usage
  /// ```dart
  /// await mutex.critical(() /* async */ {
  ///   // critical section.
  /// });
  /// ```
  Future<void> critical(FutureOr<void> Function() func) async {
    await lock();
    try {
      if (func is Future<void> Function()) {
        await func();
      } else {
        func();
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
  /// This is useful for read-only users of resources running asynchronously at the same time.
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
  /// this will resume the first existing user having requested for aquireing the exclusive lock.
  void unlockShared() {
    _sharedCount--;
    if (_sharedCount == 0) {
      _shared.complete();
    }
  }

  /// Critical section with a shared lock.
  /// 
  /// ## Usage
  /// ```dart
  /// await mutex.criticalShared(() /* async */ {
  ///   // critical section.
  /// });
  /// ```
  Future<void> criticalShared(FutureOr<void> Function() func) async {
    await lockShared();
    try {
      if (func is Future<void> Function()) {
        await func();
      } else {
        func();
      }
    } finally {
      unlockShared();
    }
  }
}
