import 'package:fvp/fvp.dart' as fvp;

/// Register FVP for macOS so video uses FFmpeg-based backend (fixes OSStatus -12847/-12848).
void registerFvpIfNeeded() {
  fvp.registerWith(options: {
    'platforms': ['macos'],
    'lowLatency': 1,
  });
}
