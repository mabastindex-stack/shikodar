import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../agency/screens/agency_profile_screen.dart';
import '../../listing/screens/listing_detail_screen.dart';

/// Premium reel info overlay: agency identity row, title, price pill, and
/// two clearly separated contact actions. No like/comment — by design.
class ReelOverlay extends StatelessWidget {
  final Listing listing;
  const ReelOverlay({super.key, required this.listing});

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/9647700000000');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call() async {
    final uri = Uri.parse('tel:+9647700000000');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        // Extra bottom clearance (~100) so this never sits behind the
        // floating glass bottom nav bar rendered on top of this tab.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Agency identity — tappable, opens the portfolio.
            _InkTap(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgencyProfileScreen(agency: listing.agency))),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.4),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.ink, size: 16),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(listing.agency.name, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  ),
                  if (listing.agency.verified) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.verified_rounded, color: AppColors.gold, size: 15),
                  ],
                ],
              ),
            ).entrance(index: 0),
            const SizedBox(height: 10),

            // Title.
            _InkTap(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing))),
              child: Text(
                listing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.35),
              ),
            ).entrance(index: 1),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                const SizedBox(width: 3),
                Text(listing.zone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ).entrance(index: 1),
            const SizedBox(height: 10),

            // Price pill + spec chips.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                  child: Text('\$${listing.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                if (listing.negotiable) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(20)),
                    child: Text('listing.negotiable'.tr(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ).entrance(index: 2),
            const SizedBox(height: 16),

            // Contact actions.
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ContactButton(icon: Icons.chat_bubble_rounded, label: 'listing.contact_whatsapp'.tr(), color: AppColors.whatsapp, onTap: _openWhatsApp),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _ContactButton(icon: Icons.phone_rounded, label: 'listing.contact_call'.tr(), color: Colors.white.withOpacity(0.16), textColor: Colors.white, onTap: _call),
                ),
              ],
            ).entrance(index: 3),
          ],
        ),
      ),
    );
  }
}

/// A tap target with real ink feedback but no visible container of its own —
/// for text/row elements that need to feel responsive without a background.
class _InkTap extends StatelessWidget {
  const _InkTap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: child),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.label, required this.color, this.textColor = Colors.white, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
