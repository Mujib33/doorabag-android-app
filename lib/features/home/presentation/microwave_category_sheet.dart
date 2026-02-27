import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class MicrowaveCategorySheet extends StatelessWidget {
  final String? city;
  const MicrowaveCategorySheet({super.key, this.city});

  static void open(BuildContext context, {String? city}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Microwave Category',
      barrierColor: Colors.transparent, // ❌ no black overlay
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (details) {
            if (details.delta.dy > 12) Navigator.of(ctx).maybePop();
          },
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              // ---- BACKGROUND BLUR + LIGHT DIM (no full black) ----
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // ---- SHEET ----
              Positioned(
                left: 0,
                right: 0,
                top: topGap,
                child: _SheetFrame(height: h, city: city),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 60),
          child: Opacity(
            // animation ke liye allowed
            opacity: anim.value,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SheetFrame extends StatelessWidget {
  final double height;
  final String? city;
  const _SheetFrame({required this.height, this.city});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        city == null ? 'Microwave Services' : 'Microwave Services • ${city!}';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),

            // header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // grid + content scrollable
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is OverscrollNotification && n.overscroll < 0) {
                    Navigator.of(context).maybePop();
                    return true;
                  }
                  if (n is ScrollUpdateNotification &&
                      n.metrics.pixels <= 0 &&
                      (n.scrollDelta ?? 0) < -10) {
                    Navigator.of(context).maybePop();
                    return true;
                  }
                  return false;
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 180,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _mwItems[index];
                            return _ServiceCard(
                              title: item.title,
                              subtitle: item.subtitle,
                              price: item.price,
                              icon: item.icon,
                              onTap: () => Navigator.of(context).maybePop(),
                            );
                          },
                          childCount: _mwItems.length,
                        ),
                      ),
                    ),

                    // Rate card teaser
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: _RateCardTile(
                          onTap: () {
                            // Eg: Navigator.pushNamed(context, '/rate-card', arguments: {'category':'Microwave', 'city': city});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: const [BoxShadow(blurRadius: 12, offset: Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              children: [
                Text('₹$price',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RateCardTile extends StatelessWidget {
  final VoidCallback onTap;
  const _RateCardTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'View Microwave Standard Rate Card',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.open_in_new),
          ],
        ),
      ),
    );
  }
}

class _MwItem {
  final String title;
  final String subtitle;
  final String price;
  final IconData icon;

  const _MwItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
  });
}

// 🔽 Items mapped from your PHP services list (price ₹99)
const _mwItems = <_MwItem>[
  _MwItem(
    title: 'Microwave Check-up',
    subtitle: 'Service charge / expert inspection',
    price: '99',
    icon: Icons.check_circle_outline,
  ),
  _MwItem(
    title: 'Buttons Not Working',
    subtitle: 'Fixing unresponsive buttons',
    price: '99',
    icon: Icons.touch_app_outlined,
  ),
  _MwItem(
    title: 'Microwave Not Working',
    subtitle: 'General diagnosis for no power/response',
    price: '99',
    icon: Icons.power_settings_new,
  ),
  _MwItem(
    title: 'Microwave Noise Issue',
    subtitle: 'Excessive noise inspection',
    price: '99',
    icon: Icons.volume_up_outlined,
  ),
  _MwItem(
    title: 'Microwave Not Heating',
    subtitle: 'Magnetron/diode/capacitor checks',
    price: '99',
    icon: Icons.local_fire_department_outlined,
  ),
  _MwItem(
    title: 'Microwave Unknown Issue',
    subtitle: 'Complete diagnosis & estimate',
    price: '99',
    icon: Icons.help_outline,
  ),
];
