import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

/// Overlay with volume, brightness, speed, seek ±10s, PiP (when supported).
class PlayerControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onFullscreen;
  final VoidCallback? onPiP;
  final bool isFullscreen;
  final bool compact;

  const PlayerControlsOverlay({
    super.key,
    required this.controller,
    this.onFullscreen,
    this.onPiP,
    this.isFullscreen = false,
    this.compact = false,
  });

  @override
  State<PlayerControlsOverlay> createState() => _PlayerControlsOverlayState();
}

class _PlayerControlsOverlayState extends State<PlayerControlsOverlay> {
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  double _volume = 1.0;
  double _brightness = 0.5;
  bool _brightnessLoaded = false;
  bool _pipSupported = false;

  @override
  void initState() {
    super.initState();
    _volume = widget.controller.value.volume;
    _checkBrightness();
    _checkPipSupport();
  }

  Future<void> _checkBrightness() async {
    try {
      final b = await ScreenBrightness().application;
      if (mounted) setState(() { _brightness = b; _brightnessLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _brightnessLoaded = true);
    }
  }

  Future<void> _checkPipSupport() async {
    if (kIsWeb) {
      setState(() => _pipSupported = false);
      return;
    }
    // PiP supported on Android 8+ / iOS 14+; button still shown for user to try device PiP
    setState(() => _pipSupported = true);
  }

  Future<void> _setBrightness(double value) async {
    setState(() => _brightness = value.clamp(0.0, 1.0));
    try {
      await ScreenBrightness().setApplicationScreenBrightness(_brightness);
    } catch (_) {}
  }

  void _seekRelative(Duration delta) {
    final pos = widget.controller.value.position + delta;
    final dur = widget.controller.value.duration;
    final clamped = Duration(
      milliseconds: (pos.inMilliseconds).clamp(0, dur.inMilliseconds),
    );
    widget.controller.seekTo(clamped);
  }

  void _setSpeed(double speed) {
    widget.controller.setPlaybackSpeed(speed);
    setState(() {});
  }

  void _setVolume(double value) {
    final v = value.clamp(0.0, 1.0);
    setState(() => _volume = v);
    widget.controller.setVolume(v);
  }

  void _showVolumeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.volume_up, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: _setVolume,
                      activeColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBrightnessSheet() {
    if (!_brightnessLoaded) _checkBrightness();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.brightness_6, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _brightness,
                          onChanged: (v) {
                            setModalState(() => _brightness = v);
                            _setBrightness(v);
                          },
                          activeColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSpeedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _speeds.map((s) {
              final current = widget.controller.value.playbackSpeed;
              final selected = (current - s).abs() < 0.01;
              return Material(
                color: selected ? Colors.white24 : Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    _setSpeed(s);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      '${s}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      IconButton(
        icon: const Icon(Icons.replay_10, color: Colors.white),
        onPressed: () => _seekRelative(const Duration(seconds: -10)),
        tooltip: 'Back 10s',
      ),
      IconButton(
        icon: const Icon(Icons.forward_10, color: Colors.white),
        onPressed: () => _seekRelative(const Duration(seconds: 10)),
        tooltip: 'Forward 10s',
      ),
      IconButton(
        icon: const Icon(Icons.speed, color: Colors.white),
        onPressed: _showSpeedSheet,
        tooltip: 'Playback speed',
      ),
      IconButton(
        icon: Icon(_volume == 0 ? Icons.volume_off : Icons.volume_up, color: Colors.white),
        onPressed: _showVolumeSheet,
        tooltip: 'Volume',
      ),
      IconButton(
        icon: const Icon(Icons.brightness_6, color: Colors.white),
        onPressed: _showBrightnessSheet,
        tooltip: 'Brightness',
      ),
      if (widget.onPiP != null || _pipSupported)
        IconButton(
          icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
          onPressed: widget.onPiP ?? () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PiP: use device PiP from recent apps (Android 8+ / iOS 14+)')),
          ),
          tooltip: 'Picture-in-Picture',
        ),
      if (widget.onFullscreen != null)
        IconButton(
          icon: Icon(
            widget.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
          ),
          onPressed: widget.onFullscreen,
          tooltip: widget.isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
        ),
    ];

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
