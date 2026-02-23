import 'package:video_player/video_player.dart';

/// PiP would require a player built with video_player_pip's own controller type.
/// Standard video_player controller is not compatible. Return false so the button
/// shows "not available" and the app builds without the plugin.
Future<bool> isPipSupported() async => false;

Future<bool> enterPipMode(VideoPlayerController controller) async => false;
