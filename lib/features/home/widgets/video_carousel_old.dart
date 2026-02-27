// lib/features/home/widgets/video_carousel.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initControllers();
  }

  Future<void> _initControllers() async {
    if (widget.assetVideos.isEmpty) return;

    for (final path in widget.assetVideos) {
      final controller = VideoPlayerController.asset(path);
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(0); // mute
      _controllers.add(controller);
    }

    if (_disposed) return;

    setState(() => _isInitialized = true);
  }

  void _playIndex(int index) {
    if (!_isInitialized || _controllers.isEmpty) return;

    for (int i = 0; i < _controllers.length; i++) {
      if (i == index) {
        _controllers[i].play();
      } else {
        _controllers[i].pause();
        _controllers[i].seekTo(Duration.zero);
      }
    }
  }

  void _pauseAll() {
    for (final c in _controllers) {
      c.pause();
    }
  }

  void _onPageChanged(int index) {
    _currentIndex = index;
    _playIndex(_currentIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      // resume pe visibility callback decide karega
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final fraction = info.visibleFraction;
    debugPrint('VIDEO visibleFraction = ${fraction.toStringAsFixed(2)}');

    if (fraction <= 0.0) {
      _pauseAll();
    } else {
      _playIndex(_currentIndex);
    }
  }

  @override
  void dispose() {
    _disposed = true;
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
      key: const Key('video-carousel'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: SizedBox(
        height: widget.height,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _controllers.length,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (_, index) {
            final controller = _controllers[index];
            final ar = controller.value.isInitialized
                ? controller.value.aspectRatio
                : 16 / 9;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.black,
                      child: AspectRatio(
                        aspectRatio: ar,
                        child: VideoPlayer(controller),
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
