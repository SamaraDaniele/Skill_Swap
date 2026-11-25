import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kReleaseMode;

const String _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

Future<void> activateAppCheck() async {
  final token = _debugToken.isEmpty ? null : _debugToken;
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : AndroidDebugProvider(debugToken: token),
      providerApple: kReleaseMode
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : AppleDebugProvider(debugToken: token),
    );
  } on Object catch (error) {
    if (kDebugMode) debugPrint('App Check not activated: $error');
  }
}
