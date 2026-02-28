import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'player_controls_overlay.dart';
import '../screens/player_screen.dart';

/// Compact player for split layout (top 30% on mobile portrait).
/// Shows placeholder when [streamUrl] is null; otherwise plays and has a fullscreen button.
class InlinePlayerWidget extends StatefulWidget {
  final String? streamUrl;
  final String? fallbackStreamUrl;
  final String title;

  const InlinePlayerWidget({
    super.key,
    required this.streamUrl,
    this.fallbackStreamUrl,
    required this.title,
  });

  @override
  State<InlinePlayerWidget> createState() => _InlinePlayerWidgetState();
}

class _InlinePlayerWidgetState extends State<InlinePlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;
  String? _lastUrl;
  bool _isBuffering = false;
  int? _prebufferSecondsLeft;
  Timer? _prebufferTimer;

  @override
  void initState() {
    super.initState();
    if (widget.streamUrl != null && widget.streamUrl!.isNotEmpty) {
      _load(widget.streamUrl!);
    }
  }

  @override
  void didUpdateWidget(InlinePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final url = widget.streamUrl;
    if (url != _lastUrl && url != null && url.isNotEmpty) {
      _load(url);
    } else if (url == null || url.isEmpty) {
      _dispose();
      if (mounted) setState(() { _error = null; _lastUrl = null; });
    }
  }

  void _dispose() {
    _prebufferTimer?.cancel();
    _prebufferTimer = null;
    _prebufferSecondsLeft = null;
    _videoController?.removeListener(_onPlayerValueChanged);
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  Future<void> _load(String url) async {
    _dispose();
    _lastUrl = url;
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
        autoPlay: false,
        looping: false,
        aspectRatio: controller.value.aspectRatio,
        allowFullScreen: false,
        allowMuting: true,
        showControls: true,
        fullScreenByDefault: false,
      );
      controller.addListener(_onPlayerValueChanged);
      _onPlayerValueChanged();
      _startPrebufferCountdown(controller);
      setState(() {});
    } catch (e) {
      if (mounted) {
        final msg = _userFriendlyPlaybackError(e);
        setState(() => _error = msg);
        debugPrint('InlinePlayer playback error: $e');
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

  static const int _prebufferSeconds = 4;

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
      return 'Video couldn\'t be played. Try another stream or device.';
    }
    if (s.contains('invalidresponsecode') || s.contains('response code: 400') || s.contains('response code: 403') ||
        s.contains('response code: 404') || s.contains('response code: 401')) {
      return 'Server rejected the stream. Check login and stream URL.';
    }
    if (s.contains('connection') || s.contains('network') || s.contains('socket')) {
      return 'Connection error. Check network.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _openFullscreen() {
    if (widget.streamUrl == null || widget.streamUrl!.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PlayerScreen(
          streamUrl: widget.streamUrl!,
          channelName: widget.title,
          fallbackStreamUrl: widget.fallbackStreamUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streamUrl == null || widget.streamUrl!.isEmpty) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Text(
            'Tap an item to play',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }
    if (_error != null) {
      return Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              color: Colors.white70,
              onPressed: _openFullscreen,
              tooltip: 'Open fullscreen',
            ),
          ],
        ),
      );
    }
    if (_chewieController == null) {
      return Container(
        color: Colors.black87,
        child: const Center(child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
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
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(height: 6),
                            Text('Buffering...', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _prebufferSecondsLeft! > 0
                                  ? 'Preparing... ${_prebufferSecondsLeft}s'
                                  : 'Starting...',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            TextButton(
                              onPressed: _skipPrebuffer,
                              child: const Text('Play now', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: PlayerControlsOverlay(
            controller: _videoController!,
            onFullscreen: _openFullscreen,
            isFullscreen: false,
            compact: true,
          ),
        ),
      ],
    );
  }
}
