import 'package:firebase_auth/firebase_auth.dart';

sealed class Failure implements Exception {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure();
}

final class EmailInUseFailure extends Failure {
  const EmailInUseFailure();
}

final class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure();
}

final class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure();
}

final class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure();
}

final class InvalidImageFailure extends Failure {
  const InvalidImageFailure();
}

final class InvalidVideoFailure extends Failure {
  const InvalidVideoFailure();
}

final class InvalidPostFailure extends Failure {
  const InvalidPostFailure();
}

final class PermissionFailure extends Failure {
  const PermissionFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure();
}

Failure mapToFailure(Object error) => switch (error) {
  Failure() => error,
  FirebaseAuthException(:final code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => const InvalidCredentialsFailure(),
    'invalid-email' => const InvalidEmailFailure(),
    'too-many-requests' => const TooManyRequestsFailure(),
    'email-already-in-use' => const EmailInUseFailure(),
    'weak-password' ||
    'password-does-not-meet-requirements' => const WeakPasswordFailure(),
    'network-request-failed' => const NetworkFailure(),
    _ => const UnknownFailure(),
  },
  FirebaseException(:final code) => switch (code) {
    'permission-denied' || 'unauthenticated' => const PermissionFailure(),
    'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
    _ => const UnknownFailure(),
  },
  _ => const UnknownFailure(),
};

Future<T> guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } catch (error) {
    throw mapToFailure(error);
  }
}

extension FailureStream<T> on Stream<T> {
  Stream<T> mapFailures() =>
      handleError((Object error) => throw mapToFailure(error));
}
