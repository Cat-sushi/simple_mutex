# Simple Mutex

This provids a exclusive write lock and shared read-only locks.

Request for exclusive lock can politely interrupt multiple parallel loops acquiring shared locks.

## Features

- Aquiring the literally mutually exclusive lock, for read/ write user of resources.
- Releasing the mutually exclusive lock.
- Aquiring a shared locks, for read-only users.
- Releasing a shared lock.
- Criticaal sections.

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

To avoid leaking lock in exceptional cases or missing `await`,
`critical` and `criticalShared` are recommended.

## Additional information

This mekes use of the event loop as the waiting queue, without additional chain of `Completer`s
