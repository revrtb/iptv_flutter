import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../widgets/player_controls_overlay.dart';
import '../widgets/streaming/streaming_app_bar.dart';

class PlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String channelName;
  final String? fallbackStreamUrl;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.channelName,
    this.fallbackStreamUrl,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;
  bool _isFullscreen = false;
  bool _triedFallback = false;
  bool _isBuffering = false;
  int? _prebufferSecondsLeft;
  Timer? _prebufferTimer;

  @override
  void initState() {
    super.initState();
    _setupPlayer(widget.streamUrl);
  }

  Future<void> _setupPlayer(String url) async {
    _prebufferTimer?.cancel();
    _prebufferTimer = null;
    _prebufferSecondsLeft = null;
    _chewieController?.dispose();
    _videoController?.removeListener(_onPlayerValueChanged);
    _videoController?.dispose();
    if (mounted) setState(() => _error = null);
    final uri = Uri.parse(url);
    final isHls = uri.path.toLowerCase().endsWith('.m3u8');
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      if (uri.origin.isNotEmpty) 'Referer': uri.origin,
    };
    final controller = VideoPlayerController.networkUrl(
      uri,
      formatHint: (isHls && defaultTargetPlatform != TargetPlatform.macOS)
          ? VideoFormat.hls
          : null,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      httpHeaders: headers,
    );
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false, // Start paused so we can pre-buffer
        looping: false,
        aspectRatio: controller.value.aspectRatio,
        allowFullScreen: false, // We handle fullscreen ourselves to avoid black screen on exit
        allowMuting: true,
        showControls: true,
        fullScreenByDefault: false,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
      controller.addListener(_onPlayerValueChanged);
      _onPlayerValueChanged();
      _startPrebufferCountdown(controller);
      setState(() {});
    } catch (e) {
      if (mounted) {
        final msg = _userFriendlyPlaybackError(e);
        setState(() => _error = msg);
        debugPrint('PlayerScreen playback error: $e');
      }
    }
  }

  void _onPlayerValueChanged() {
    final c = _videoController;
    if (c == null || !mounted) return;
    final buffering = c.value.isBuffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
  }

  static const int _prebufferSeconds = 5;

  void _startPrebufferCountdown(VideoPlayerController controller) {
    _prebufferSecondsLeft = _prebufferSeconds;
    _prebufferTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _videoController != controller) {
        _prebufferTimer?.cancel();
        return;
      }
      setState(() {
        if (_prebufferSecondsLeft == null || _prebufferSecondsLeft! <= 1) {
          _prebufferSecondsLeft = null;
          _prebufferTimer?.cancel();
          _prebufferTimer = null;
          controller.play();
        } else {
          _prebufferSecondsLeft = _prebufferSecondsLeft! - 1;
        }
      });
    });
  }

  void _skipPrebuffer() {
    if (_prebufferSecondsLeft == null || _videoController == null) return;
    _prebufferTimer?.cancel();
    _prebufferTimer = null;
    _prebufferSecondsLeft = null;
    _videoController!.play();
    setState(() {});
  }
  static String _userFriendlyPlaybackError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('required system resources') ||
        s.contains('codec') ||
        s.contains('mediacodec') ||
        s.contains('bad_index') ||
        s.contains('failed to query')) {
      return 'This video couldn\'t be played. Try another stream or a different device.';
    }
    if (s.contains('invalidresponsecode') || s.contains('response code: 400') || s.contains('response code: 403') ||
        s.contains('response code: 404') || s.contains('response code: 401')) {
      return 'Server rejected the stream (bad request or forbidden). Check your login and stream URL.';
    }
    if (s.contains('connection') || s.contains('network') || s.contains('socket')) {
      return 'Connection error. Check your network and try again.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  @override
  void dispose() {
    _prebufferTimer?.cancel();
    _prebufferTimer = null;
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _videoController?.removeListener(_onPlayerValueChanged);
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _retry() {
    final tryFallback = widget.fallbackStreamUrl != null && !_triedFallback;
    if (tryFallback) _triedFallback = true;
    _setupPlayer(tryFallback ? widget.fallbackStreamUrl! : widget.streamUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen
          ? null
          : StreamingAppBar(
              title: widget.channelName,
              showBackButton: true,
              actions: [
                if (_videoController != null)
                  PlayerControlsOverlay(
                    controller: _videoController!,
                    onFullscreen: _toggleFullscreen,
                    isFullscreen: false,
                    compact: true,
                  ),
              ],
            ),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        widget.fallbackStreamUrl != null && !_triedFallback
                            ? 'Try alternative format'
                            : 'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_chewieController == null)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Chewie(controller: _chewieController!),
                    if (_isBuffering)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 12),
                              Text('Buffering...', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    if (_prebufferSecondsLeft != null)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 12),
                              Text(
                                _prebufferSecondsLeft! > 0
                                    ? 'Preparing stream... Starting in ${_prebufferSecondsLeft} s'
                                    : 'Starting...',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _skipPrebuffer,
                                icon: const Icon(Icons.play_arrow, color: Colors.white),
                                label: const Text('Play now', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (_isFullscreen && _videoController != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: PlayerControlsOverlay(
                controller: _videoController!,
                onFullscreen: _toggleFullscreen,
                isFullscreen: true,
                compact: false,
              ),
            ),
        ],
      ),
    );
  }
}
