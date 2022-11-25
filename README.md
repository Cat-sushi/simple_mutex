# Simple Mutex

This provids a exclusive write lock and shared read-only locks.

## Features

- Aquiring the literally mutually exclusive lock, for read/ write user of resources.
- Releasing the mutually exclusive lock.
- Aquiring a shared locks, for read-only users.
- Releasing a shared lock.

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
// Some mutually exclusive asynchronous critical session.
// This prevent entering other mutually exclusive/ shared  critical sesssions.
// This wait for ending otehr mutually exclusive/ shared critical sesssions.
mutex.unlock();
```

Protect asynchronous critical section with shared lock.

```dart
await mutex.lockShared();
// Some shared asynchronous critical session.
// This can be run concurrently with other shared critical sessions.
// This wait for ending mutually exclusive critical sesssions.
mutex.unlockShared();
```

To avoid leaking lock in exceptional cases, [Mutex.critical] and [Mutex.criticalShared] are recommended.

## Additional information

This mekes use of the event loop as the waiting queue, without additional chain of `Completer`s.
