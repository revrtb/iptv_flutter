import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../widgets/player_controls_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    _setupPlayer(widget.streamUrl);
  }

  Future<void> _setupPlayer(String url) async {
    _chewieController?.dispose();
    _videoController?.dispose();
    if (mounted) setState(() => _error = null);
    final uri = Uri.parse(url);
    final isHls = uri.path.toLowerCase().endsWith('.m3u8');
    final controller = VideoPlayerController.networkUrl(
      uri,
      formatHint: (isHls && defaultTargetPlatform != TargetPlatform.macOS)
          ? VideoFormat.hls
          : null,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      },
    );
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true, // Video autoplay enabled
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
      setState(() {});
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _error = msg);
      }
    }
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
          : AppBar(
              title: Text(
                widget.channelName,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
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
                child: Chewie(controller: _chewieController!),
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
