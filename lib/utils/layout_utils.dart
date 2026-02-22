import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// True when running on Android or iOS in portrait (standard mode).
/// Used to show 30% player / 70% list split on mobile.
bool isMobilePortrait(BuildContext context) {
  if (kIsWeb) return false;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return false;
  }
  return MediaQuery.orientationOf(context) == Orientation.portrait;
}
