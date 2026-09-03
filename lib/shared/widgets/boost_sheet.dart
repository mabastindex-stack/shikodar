import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// "Boost" (بەرزکردنەوە) isn't a real paid feature yet — there's no backend
/// to charge or track a boost against. Rather than a dead button, this opens
/// the same contact-to-activate pattern already used for packages/offers,
/// pre-filled with which listing/project the owner wants boosted.
void showBoostSheet(BuildContext context, {required String itemName}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final palette = sheetContext.palette;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(22, 20, 22, 22 + MediaQuery.of(sheetContext).padding.bottom),
          decoration: BoxDecoration(color: palette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: palette.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.trending_up_rounded, color: AppColors.ink, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('boost_sheet.title'.tr(args: [itemName]), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'boost_sheet.description'.tr(),
                style: TextStyle(color: palette.textSecondary, fontSize: 12.5, height: 1.6),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://wa.me/9647700000000?text=${Uri.encodeComponent('boost_sheet.whatsapp_message'.tr(args: [itemName]))}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text('packages.contact_via_whatsapp'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsapp,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:+9647700000000')),
                  icon: Icon(Icons.phone, size: 18, color: palette.primary),
                  label: Text('packages.call_action'.tr(), style: TextStyle(color: palette.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: palette.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
