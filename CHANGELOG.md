# Change Log

## 2.0.1

- Breaqking Chage: Delete the `deliver` option that was not a good idea.
- Introduce handmade waiting queue as a substitute of the microtask queue,
for time poerformance and precise timeout behavior.

## 1.5.3

- Add message to `TimeoutException'.

## 1.5.2

- Suspend microtask more promised way.

## 1.5.1

- Fix typos in documents.

## 1.5.0

- Breaking change: make the `deliver` option from positional to named.
- Add `timeLimit` optional parameters.
- Relax the requierment of the dart SDK.

## 1.4.1

- Update the example.

## 1.4.0

- Add propeties `isLocked` and `sharedCount` for test.

## 1.3.2

- Fix bug of example.
- Recomend `unawaited_futures` lint in README.md.

## 1.3.1

- Add example.

## 1.3.0

- Add return to `critical` and `criticalShared`.

## 1.2.1

- Rerun the formatter correctly.
- Update doc comments.

## 1.2.0

- Add a optional behavior to `lock` and `critical`.
The new behavior yield execution right to existing users having
requested exclusive/ shared locks.

## 1.1.1

- Refine documents.

## 1.1.0

- Add critical section feature.

## 1.0.0

- Initial version.
