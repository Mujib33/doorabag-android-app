import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

/// Local shadows (AppShadows से conflict न हो, इसलिए अलग नाम)
class UiShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

/* ───────── Search Bar ───────── */

class SearchBarCard extends StatelessWidget {
  final VoidCallback? onTap;
  const SearchBarCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
            boxShadow: UiShadows.card,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search services, e.g. AC Repair',
                    style: TextStyle(color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.mic_none_rounded, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────── Quick Actions ───────── */

class QuickAction extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback? onTap;
  const QuickAction({
    super.key,
    required this.iconAsset,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
              boxShadow: UiShadows.card,
            ),
            child: _buildIcon(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 84,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    final isSvg = iconAsset.toLowerCase().endsWith('.svg');
    return isSvg
        ? SvgPicture.asset(iconAsset, width: 24, height: 24)
        : Image.asset(iconAsset, width: 24, height: 24, fit: BoxFit.contain);
  }
}

/* ───────── Service Tile (Grid Item) ───────── */

class ServiceTile extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const ServiceTile({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
          boxShadow: UiShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final isSvg = iconAsset.toLowerCase().endsWith('.svg');
    return isSvg
        ? SvgPicture.asset(iconAsset, width: 28, height: 28)
        : Image.asset(iconAsset, width: 28, height: 28, fit: BoxFit.contain);
  }
}

/* ───────── (Optional) Gradient Banner Card ───────── */

class BannerCard extends StatelessWidget {
  final String title;
  final String caption;
  final String? badge;
  final VoidCallback? onTap;
  const BannerCard({
    super.key,
    required this.title,
    required this.caption,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F7AFF), Color(0xFF49A1FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: UiShadows.card,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            caption,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.local_offer_rounded,
                          size: 40, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────── HomeHeroCard: “Home Services At Your Doorstep” ───────── */

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1F7AFF), Color(0xFF49A1FF)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: UiShadows.card,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'UP TO 30% OFF',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Home Services At\nYour Doorstep',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We provide the best and certified professional home service at your doorstep.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {},
                    child: const Text('Go To Book Now'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _miniThumb('assets/images/hero1.jpg'),
                      const SizedBox(width: 8),
                      _miniThumb('assets/images/hero2.jpg'),
                      const SizedBox(width: 8),
                      _miniThumb('assets/images/hero3.jpg'),
                      const SizedBox(width: 8),
                      _miniThumb('assets/images/hero4.jpg'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.local_offer_rounded,
                  size: 40, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _miniThumb(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        path,
        width: 54,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            width: 54, height: 40, color: Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }
}
