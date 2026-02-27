// lib/features/cart/cart_page.dart
import 'dart:ui' show ImageFilter;
import 'package:doora_app/features/checkout/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:doora_app/features/cart/cart_service.dart';
import 'package:doora_app/core/auth/auth_guard.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService cart = CartService.instance;

  bool _isHindi = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final surface = cs.surface;
    final onSurface = cs.onSurface;
    final primary = cs.primary;
    final card = theme.cardColor;
    final outline = cs.outline;
    final muted = onSurface.withValues(alpha: 0.60);
    final shadowColor = cs.shadow.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        top: true,
        child: AnimatedBuilder(
          animation: cart,
          builder: (context, _) {
            if (cart.items.isEmpty) return _EmptyCart(muted: muted);

            return Column(
              children: [
                // 🔹 TOP BLUE HEADER
                _CartHeader(
                  primary: primary,
                  onSurface: onSurface,
                  muted: muted,
                  itemCount: cart.items.length,
                  subtotal: cart.subtotal,
                  isHindi: _isHindi,
                  onLanguageChanged: (val) {
                    setState(() {
                      _isHindi = val;
                    });
                  },
                ),

                const SizedBox(height: 6),

                // ---------------- LIST + GLOBAL HOW SECTION ----------------
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      // 👇 items + 1 (last me HOW section)
                      itemCount: cart.items.length + 1,
                      separatorBuilder: (context, index) {
                        if (index == cart.items.length - 1) {
                          // last card -> how section
                          return const SizedBox(height: 18);
                        }
                        if (index >= cart.items.length) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (context, index) {
                        // 👉 0..(n-1): cards, n: HOW section
                        if (index < cart.items.length) {
                          final it = cart.items[index];
                          return Dismissible(
                            key: ValueKey('${it.title}-$index-${it.qty}'),
                            background: Container(
                              decoration: BoxDecoration(
                                color: cs.error.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: cs.error),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => cart.removeAt(index),
                            child: _CartTile(
                              card: card,
                              outline: outline,
                              shadowColor: shadowColor,
                              onSurface: onSurface,
                              muted: muted,
                              title: it.title,
                              subtitle: it.subtitle,
                              price: it.price,
                              qty: it.qty,
                              image: it.image, // 👈 actual service image
                              isHindi: _isHindi,
                              onInc: () => cart.increment(index),
                              onDec: () => cart.decrement(index),
                              onDelete: () => cart.removeAt(index),
                            ),
                          );
                        }

                        // 👇 Last item: single HOW section for all services
                        return _HowServiceInfo(
                          isHindi: _isHindi,
                          muted: muted,
                          outline: outline,
                          onSurface: onSurface,
                        );
                      },
                    ),
                  ),
                ),

                // 🔹 BOTTOM BLUE FOOTER
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                            color: shadowColor,
                          )
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isHindi ? 'Subtotal' : 'Subtotal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${cart.subtotal}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isHindi
                                        ? 'Verified Doorabag technician ~₹199 visit/diagnosis par (jabki local visit aam taur par ~₹500 hoti hai).'
                                        : 'Verified Doorabag technician at ~₹199 visit/diagnosis (vs ~₹500 typical local visit).',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 46,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: cart.items.isEmpty
                                    ? null
                                    : () async {
                                        await requireLoginThen(context, () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CheckoutPage(),
                                            ),
                                          );
                                        });
                                      },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isHindi ? 'आगे बढ़ें' : 'Proceed',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* -------------------- BLUE TOP HEADER -------------------- */

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.primary,
    required this.onSurface,
    required this.muted,
    required this.itemCount,
    required this.subtotal,
    required this.isHindi,
    required this.onLanguageChanged,
  });

  final Color primary;
  final Color onSurface;
  final Color muted;
  final int itemCount;
  final int subtotal;
  final bool isHindi;
  final ValueChanged<bool> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // My Cart center + toggle right
          Stack(
            children: [
              SizedBox(
                height: 32,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'My Cart',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _LanguageToggle(
                    isHindi: isHindi,
                    onChanged: onLanguageChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'} in your cart',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
              Text(
                '₹$subtotal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* -------------------- CART TILE (WITH IMAGE) -------------------- */

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.card,
    required this.outline,
    required this.shadowColor,
    required this.onSurface,
    required this.muted,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.qty,
    required this.image,
    required this.isHindi,
    required this.onInc,
    required this.onDec,
    required this.onDelete,
  });

  final Color card, outline, shadowColor, onSurface, muted;
  final String title, subtitle;
  final int price, qty;
  final String image; // 👈 new
  final bool isHindi;
  final VoidCallback onInc, onDec, onDelete;

  Widget _buildImageThumb() {
    if (image.isEmpty) {
      return Icon(
        Icons.home_repair_service_outlined,
        color: onSurface.withValues(alpha: 0.85),
        size: 26,
      );
    }

    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.image_not_supported_outlined,
          color: onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    return Image.asset(
      image,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported_outlined,
        color: onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final int lineTotal = price * qty;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outline.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: shadowColor,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: image + title + qty
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: onSurface.withValues(alpha: 0.05),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildImageThumb(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: muted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Remove',
                    ),
                    const SizedBox(height: 4),
                    _QtyPill(
                      qty: qty,
                      onInc: onInc,
                      onDec: onDec,
                      outline: outline,
                      onSurface: onSurface,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Price row
            Row(
              children: [
                Text(
                  isHindi
                      ? 'Visit / booking charge:'
                      : 'Visit / booking charge:',
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '₹$price',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  isHindi ? 'Item total:' : 'Item total:',
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '₹$lineTotal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- GLOBAL HOW SECTION (ONLY ONCE) -------------------- */

class _HowServiceInfo extends StatelessWidget {
  const _HowServiceInfo({
    required this.isHindi,
    required this.muted,
    required this.outline,
    required this.onSurface,
  });

  final bool isHindi;
  final Color muted, outline, onSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stepsEn = <String>[
      'You are paying only a booking / visit charge right now, not the full repair amount.',
      'A verified Doorabag technician is assigned to your booking shortly after confirmation.',
      'The technician visits your home and diagnoses the exact issue.',
      'If repair is needed, a clear estimate is shared on your mobile.',
      'If you accept, your booking amount is adjusted / discounted in the final bill.',
      'If you reject, you only pay this booking / visit charge.',
    ];

    final stepsHi = <String>[
      'Abhi aap sirf booking / visit charge pay kar rahe hain, full repair amount nahi.',
      'Booking confirm hone ke baad ek verified Doorabag technician aapko assign hota hai.',
      'Technician aapke ghar aakar problem ko properly diagnose karta hai.',
      'Problem hone par clear estimate aapke mobile par share kiya jata hai.',
      'Agar aap accept karte hain to ye booking amount final bill se adjust ho jata hai.',
      'Agar aap reject karte hain to sirf ye booking / visit charge hi dena hota hai.',
    ];

    final steps = isHindi ? stepsHi : stepsEn;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: onSurface.withValues(alpha: 0.02),
        border: Border.all(color: outline.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: onSurface.withValues(alpha: 0.06),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 13,
                  color: onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHindi
                      ? 'Doorabag par har service is tarah complete hoti hai:'
                      : 'Your Doorabag service will work like this:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: const Color(0xFF374151), // 🔹 dark grey (readable)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...steps.map(
            (t) => _BulletRow(
              text: t,
              muted: muted,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- QTY CONTROLS -------------------- */

class _QtyPill extends StatelessWidget {
  const _QtyPill({
    required this.qty,
    required this.onInc,
    required this.onDec,
    required this.outline,
    required this.onSurface,
  });

  final int qty;
  final VoidCallback onInc, onDec;
  final Color outline, onSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: outline.withValues(alpha: 0.40)),
        color: onSurface.withValues(alpha: 0.02),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtnCircle(icon: Icons.remove, onTap: onDec),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$qty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
            ),
          ),
          _QtyBtnCircle(icon: Icons.add, onTap: onInc),
        ],
      ),
    );
  }
}

class _QtyBtnCircle extends StatelessWidget {
  const _QtyBtnCircle({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Icon(
            icon,
            size: 16,
          ),
        ),
      ),
    );
  }
}

/* -------------------- BULLET ROW -------------------- */

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.text,
    required this.muted,
  });

  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Center(
              child: Container(
                width: 4.2,
                height: 4.2,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: muted,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- LANGUAGE TOGGLE -------------------- */

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.isHindi,
    required this.onChanged,
  });

  final bool isHindi;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final bg = onSurface.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'English',
            selected: !isHindi,
            onTap: () => onChanged(false),
          ),
          _LangChip(
            label: 'हिंदी',
            selected: isHindi,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color:
                selected ? Colors.white : cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

/* -------------------- EMPTY CART -------------------- */

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.muted});
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted.withValues(alpha: 0.06),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 42,
                color: muted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a service to get started.\nWe’ll keep everything ready here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
