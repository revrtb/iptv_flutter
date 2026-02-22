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
        autoPlay: true,
        looping: false,
        aspectRatio: controller.value.aspectRatio,
        allowFullScreen: false,
        allowMuting: true,
        showControls: true,
        fullScreenByDefault: false,
      );
      setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
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
              child: Chewie(controller: _chewieController!),
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
