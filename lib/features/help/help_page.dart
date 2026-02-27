import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Dark brand blue
const Color kBrandBlue = Color(0xFF1f3b73);
// Light header blue
const Color kHeaderBlue = Color(0xFF2E6FF2);

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final String _supportPhone = '917498979275'; // <- yahan apna number
  final String _supportWhatsApp = '917498979275'; // <- yahan apna number
  final String _supportEmail = 'doorabag@gmail.com';

  bool _isHindi = false; // false = English (default), true = Hindi

  // ---------------- CALL / WHATSAPP / EMAIL ----------------

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    final ok = await launchUrl(uri);
    if (!ok) {
      _showSnack('Dialer open nahi ho paaya');
    }
  }

  Future<void> _whatsappSupport() async {
    final text =
        Uri.encodeComponent('Hi Doorabag, I need help with my booking.');
    final url = 'https://wa.me/$_supportWhatsApp?text=$text';
    final uri = Uri.parse(url);

    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok) {
      _showSnack('WhatsApp open nahi ho paa raha');
    }
  }

  Future<void> _emailSupport() async {
    final subject = Uri.encodeComponent("Need help with my booking");
    final body = Uri.encodeComponent(
        "Hi Doorabag Team,\n\nI need help with my booking.\n\nDetails:\n- Booking ID:\n- Name:\n- Mobile:\n\nThanks,\n");

    final url = "mailto:$_supportEmail?subject=$subject&body=$body";
    final uri = Uri.parse(url);

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        _showSnack("Email app nahi mil raha (Gmail/Outlook install karo)");
      }
    } catch (e) {
      _showSnack("Email open nahi ho paaya");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HelpHeaderDelegate(height: 150),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildQuickActions(theme),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFaq(theme),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBottomSupportCard(theme),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ---------------- QUICK ACTIONS + LANGUAGE TOGGLE ----------------

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            "How can we help?",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _GlassButton(
                icon: Icons.call_rounded,
                label: "Call Support",
                subtitle: "Instant help",
                onTap: _callSupport,
                // yahan chaho to size override kar sakte ho:
                titleSize: 11,
                subtitleSize: 9,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassButton(
                icon: Icons.chat_bubble_rounded,
                label: "WhatsApp",
                subtitle: "Chat with us",
                onTap: _whatsappSupport,
                titleSize: 11,
                subtitleSize: 9,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _GlassButtonFull(
          icon: Icons.mail_rounded,
          label: "Email Support",
          subtitle: "Detailed assistance",
          onTap: _emailSupport,
        ),

        const SizedBox(height: 18),

        // 🔀 Language toggle – UNIQUE pill style
        _buildLanguageToggle(theme),
      ],
    );
  }

  Widget _buildLanguageToggle(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangChip(
              label: "English",
              selected: !_isHindi,
              onTap: () {
                if (_isHindi) {
                  setState(() => _isHindi = false);
                }
              },
            ),
            const SizedBox(width: 4),
            _LangChip(
              label: "हिंदी",
              selected: _isHindi,
              onTap: () {
                if (!_isHindi) {
                  setState(() => _isHindi = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FAQ ----------------

  Widget _buildFaq(ThemeData theme) {
    final faqEn = [
      {
        "q": "When will the technician arrive?",
        "a":
            "The technician will visit within your selected time slot. You can track the status from the My Bookings section."
      },
      {
        "q": "How is the service price decided?",
        "a":
            "After diagnosing the issue, the technician provides a clear estimate. Repair begins only after you approve the estimate."
      },
      {
        "q": "How does the warranty process work?",
        "a":
            "If the same issue reappears during the warranty period, you can raise a claim from My Bookings to get a free revisit."
      },
      {
        "q": "How can I reschedule or cancel my booking?",
        "a":
            "Go to the My Bookings page and open the booking card to find the Reschedule or Cancel option, based on slot availability."
      },
    ];

    final faqHi = [
      {
        "q": "टेक्नीशियन कब आएगा?",
        "a":
            "टेक्नीशियन आपके चुने हुए टाइम स्लॉट के अंदर विजिट करता है। आप My Bookings में जाकर स्टेटस देख सकते हैं।"
      },
      {
        "q": "सर्विस का प्राइस कैसे तय होता है?",
        "a":
            "पहले मशीन की जांच की जाती है, उसके बाद आपको पूरा estimate बताया जाता है। आपकी मंजूरी के बाद ही repair शुरू होता है।"
      },
      {
        "q": "वारंटी कैसे काम करती है?",
        "a":
            "अगर वही issue वारंटी पीरियड में दोबारा आता है, तो आप My Bookings से 'Claim Warranty' पर क्लिक करके free revisit बुक कर सकते हैं।"
      },
      {
        "q": "मैं बुकिंग reschedule या cancel कैसे करूं?",
        "a":
            "My Bookings पेज पर जाकर, जिस बुकिंग को बदलना है उस कार्ड पर Reschedule / Cancel का ऑप्शन मिलेगा (slot के हिसाब से)।"
      },
    ];

    final items = _isHindi ? faqHi : faqEn;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionPanelList.radio(
              elevation: 0,
              expandedHeaderPadding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < items.length; i++)
                  ExpansionPanelRadio(
                    value: i,
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        title: Text(
                          items[i]['q']!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        items[i]['a']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------- BOTTOM SUPPORT CARD ----------------

  Widget _buildBottomSupportCard(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [
                kBrandBlue,
                Color(0xFF12264e),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                size: 34,
                color: Colors.white,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Still need help?",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Send your booking ID, our team will call you back.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _whatsappSupport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kBrandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Chat Now",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- GLASS BUTTONS -----------------

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  // 🔹 Yahan font size options
  final double titleSize;
  final double subtitleSize;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.titleSize = 16,
    this.subtitleSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFd9e6ff),
                        Color(0xFFb6c8ff),
                      ],
                    ),
                  ),
                  child: Icon(icon, size: 22, color: kBrandBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: titleSize,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontSize: subtitleSize,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButtonFull extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _GlassButtonFull({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFd9e6ff),
                        Color(0xFFb6c8ff),
                      ],
                    ),
                  ),
                  child: Icon(icon, size: 22, color: kBrandBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------- LANGUAGE CHIP (UNIQUE STYLE) ----------------

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? kBrandBlue : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

class _HelpHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;

  _HelpHeaderDelegate({required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        color: kHeaderBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ICON + TITLE ROW (fixed size)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 22,
                  color: kBrandBlue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Help & Support",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // SUBTEXT – always visible, no fade
          Text(
            "We’re here 8 AM – 8 PM, 7 days",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_HelpHeaderDelegate oldDelegate) {
    return oldDelegate.height != height;
  }
}
