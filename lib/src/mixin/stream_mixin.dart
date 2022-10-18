import 'dart:async';

import 'package:meta/meta.dart';

/// Implements [Stream] in terms of [stream].
mixin StreamMixin<T> implements Stream<T> {
  /// Target stream to which methods will be redirected.
  @protected
  Stream<T> get stream;

  @override
  Future<bool> any(bool Function(T element) test) => stream.any(test);

  @override
  Stream<T> asBroadcastStream({
    void Function(StreamSubscription<T> subscription)? onListen,
    void Function(StreamSubscription<T> subscription)? onCancel,
  }) =>
      stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) =>
      stream.asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      stream.asyncMap(convert);

  @override
  Stream<R> cast<R>() => stream.cast();

  @override
  Future<bool> contains(Object? needle) => stream.contains(needle);

  @override
  Stream<T> distinct([bool Function(T previous, T next)? equals]) =>
      stream.distinct(equals);

  @override
  Future<E> drain<E>([E? futureValue]) => stream.drain(futureValue);

  @override
  Future<T> elementAt(int index) => stream.elementAt(index);

  @override
  Future<bool> every(bool Function(T element) test) => stream.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) =>
      stream.expand(convert);

  @override
  Future<T> get first => stream.first;

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function()? orElse}) =>
      stream.firstWhere(test, orElse: orElse);

  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, T element) combine,
  ) =>
      stream.fold(initialValue, combine);

  @override
  Future<dynamic> forEach(void Function(T element) action) =>
      stream.forEach(action);

  @override
  Stream<T> handleError(
    Function onError, {
    bool Function(dynamic error)? test,
  }) =>
      stream.handleError(onError, test: test);

  @override
  bool get isBroadcast => stream.isBroadcast;

  @override
  Future<bool> get isEmpty => stream.isEmpty;

  @override
  Future<String> join([String separator = '']) => stream.join(separator);

  @override
  Future<T> get last => stream.last;

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function()? orElse}) =>
      stream.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => stream.length;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      stream.listen(onData, onDone: onDone, onError: onError);

  @override
  Stream<S> map<S>(S Function(T event) convert) => stream.map(convert);

  @override
  Future<dynamic> pipe(StreamConsumer<T> streamConsumer) =>
      stream.pipe(streamConsumer);

  @override
  Future<T> reduce(T Function(T previous, T element) combine) =>
      stream.reduce(combine);

  @override
  Future<T> get single => stream.single;

  @override
  Future<T> singleWhere(
    bool Function(T element) test, {
    T Function()? orElse,
  }) =>
      stream.singleWhere(test, orElse: orElse);

  @override
  Stream<T> skip(int count) => stream.skip(count);

  @override
  Stream<T> skipWhile(bool Function(T element) test) => stream.skipWhile(test);

  @override
  Stream<T> take(int count) => stream.take(count);

  @override
  Stream<T> takeWhile(bool Function(T element) test) => stream.takeWhile(test);

  @override
  Stream<T> timeout(
    Duration timeLimit, {
    void Function(EventSink<T> sink)? onTimeout,
  }) =>
      stream.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<T>> toList() => stream.toList();

  @override
  Future<Set<T>> toSet() => stream.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) =>
      stream.transform(streamTransformer);

  @override
  Stream<T> where(bool Function(T event) test) => stream.where(test);
}
