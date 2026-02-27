// lib/features/home/presentation/video_carousel.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// 🔹 PRIVATE list of all active carousels (same file ke andar hi use hogi)
final List<_VideoCarouselState> _videoCarouselInstances = [];

// 🔹 State register/unregister helpers (private)
void _registerVideoCarousel(_VideoCarouselState state) {
  if (!_videoCarouselInstances.contains(state)) {
    _videoCarouselInstances.add(state);
  }
}

void _unregisterVideoCarousel(_VideoCarouselState state) {
  _videoCarouselInstances.remove(state);
}

// 🔹 PUBLIC helper — app me kahin se bhi call kar sakte ho
void pauseAllVideoCarousels() {
  for (final s in List<_VideoCarouselState>.from(_videoCarouselInstances)) {
    s._pauseAll(); // private method, same file → allowed
  }
}

class VideoCarousel extends StatefulWidget {
  final double height;
  final List<String> assetVideos;

  const VideoCarousel({
    super.key,
    required this.height,
    required this.assetVideos,
  });

  @override
  State<VideoCarousel> createState() => _VideoCarouselState();
}

class _VideoCarouselState extends State<VideoCarousel>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  final List<VideoPlayerController> _controllers = [];

  bool _isInitialized = false;
  bool _disposed = false;
  int _currentIndex = 0;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerVideoCarousel(this);
    _initControllers();
  }

  Future<void> _initControllers() async {
    if (widget.assetVideos.isEmpty) return;

    for (final path in widget.assetVideos) {
      final controller = VideoPlayerController.asset(path);
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(_muted ? 0 : 1);
      _controllers.add(controller);
    }

    if (!_disposed) {
      setState(() => _isInitialized = true);
    }
  }

  void _playIndex(int index) {
    if (!_isInitialized || _controllers.isEmpty) return;
    if (index < 0 || index >= _controllers.length) return;

    for (int i = 0; i < _controllers.length; i++) {
      if (i == index) {
        _controllers[i].play();
      } else {
        _controllers[i].pause();
      }
    }
  }

  void _pauseAll() {
    for (final c in _controllers) {
      c.pause();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    for (final c in _controllers) {
      c.setVolume(_muted ? 0 : 1);
    }
  }

  /// 🔍 Visibility ke basis pe auto play/pause
  void _handleVisibility(VisibilityInfo info) {
    final visible = info.visibleFraction;

    // Debug dekhna ho to:
    // debugPrint('VIDEO visible = ${visible.toStringAsFixed(2)}');

    if (visible <= 0.0) {
      _pauseAll();
    } else {
      _playIndex(_currentIndex);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pauseAll();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _unregisterVideoCarousel(this);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return VisibilityDetector(
      key: ValueKey(this),
      onVisibilityChanged: _handleVisibility,
      child: SizedBox(
        height: widget.height,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _controllers.length,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) {
            _currentIndex = i;
            _playIndex(i);
          },
          itemBuilder: (_, index) {
            final controller = _controllers[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // --- FULL VIDEO (Reels style) ---
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    ),

                    // --- TAP on video area → pause all ---
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          pauseAllVideoCarousels();
                        },
                      ),
                    ),

                    // --- MUTE / UNMUTE BUTTON (top-most) ---
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: Icon(
                            _muted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
