# Simple Mutex

This provids a exclusive write lock and shared read-only locks.

Request for exclusive lock can gracefully interrupt multiple parallel
loops acquiring shared locks.

## Features

- Literally mutually exclusive lock, for read/ write user of resources.
- Shared locks, for read-only users.
- Eclusive critical section helper with retrun value.
- Shared critical section helper with return value.

## Getting started

```dart
import 'simple_mutex/simple_mutex.dart';
```

## Usage

Declaration.

```dart
final mutex = Mutex();
```

Protect asynchronous critical section with mutually exclusive lock.

```dart
await mutex.lock();
try {
  // Some mutually exclusive asynchronous critical section.
  // This prevent entering other mutually exclusive/ shared critical sections.
} finally {
  mutex.unlock();
}
```

Protect asynchronous critical section with shared lock.

```dart
await mutex.lockShared();
try {
  // Some shared asynchronous critical section.
  // This prevent entering other mutually exclusive critical sections.
  // On the other hand, this can be run in parallel with other shared 
  // critical sections.
} finally {
  mutex.unlockShared();
}
```

To avoid leaking lock in exceptional cases, `critical` and `criticalShared`
are recommended.

Lint `unawaited_futures` is also recommended, because if you miss `await`
for `critical` or `criticalShared`, memory will be exhausted.

## Additional information

This mekes use of the event queue as the waiting queue,
without additional chain of `Completer`s.
