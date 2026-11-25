import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/profile/profile.dart';

bool isStartupResolved({
  required AsyncValue<String?> auth,
  required AsyncValue<UserProfile?> profile,
  required AsyncValue<bool> consent,
}) {
  if (auth.hasError) return true;
  if (!auth.hasValue) return false;
  if (auth.value == null) return true;
  if (profile.hasError) return true;
  if (!profile.hasValue || profile.isLoading) return false;
  if (profile.value == null) return true;
  if (consent.hasError) return true;
  return consent.hasValue && !consent.isLoading;
}

final startupResolvedProvider = Provider<bool>(
  (ref) => isStartupResolved(
    auth: ref.watch(authStateProvider),
    profile: ref.watch(currentProfileProvider),
    consent: ref.watch(consentProvider),
  ),
);
