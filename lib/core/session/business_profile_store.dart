import 'package:flutter/material.dart';

/// One achievement on a company/developer's "experience" timeline — the
/// exact shape DeveloperProfileScreen renders under "ئەزموونی کۆمپانیا".
class Milestone {
  const Milestone({required this.year, required this.title, required this.icon});

  final String year;
  final String title;
  final IconData icon;
}

const _defaultMilestones = [
  Milestone(year: '٢٠١٧', title: 'دامەزراندنی کۆمپانیا لە کەرکوک', icon: Icons.flag_circle_rounded),
  Milestone(year: '٢٠١٩', title: 'یەکەم پڕۆژەی سکنی تەواو کرا', icon: Icons.apartment_rounded),
  Milestone(year: '٢٠٢١', title: 'گەیشتنە ژمارەی ٥٠٠ خانووی نیشتەجێکراو', icon: Icons.groups_rounded),
  Milestone(year: '٢٠٢٤', title: 'وەرگرتنی بادجی Verified لە شکۆدار', icon: Icons.verified_rounded),
];

/// The editable half of a business account's public profile — everything an
/// agency/company sets about themselves (bio, specialties, service areas,
/// and — for developers — their achievement timeline). Seeded from the demo
/// agency's mock data so the public profile screens look unchanged until the
/// owner actually edits something from their own Profile tab; from then on,
/// EditBusinessProfileScreen writes here and AgencyProfileScreen /
/// DeveloperProfileScreen read from here whenever they're showing "my own"
/// account, so an edit is immediately visible on the public-facing profile.
class BusinessProfileStore extends ChangeNotifier {
  String bio = 'کۆمپانیای شکۆ لە ساڵی ٢٠١٧ دامەزراوە و بووەتە یەکێک لە کارگێڕە پشتڕاستکراوەکانی بازاڕی خانووبەرەی کەرکوک، بە فۆکەسکردن لەسەر ڤیلا و پڕۆژە سکنیە گەورەکان.';
  Set<String> specialties = {'ڤیلا', 'مجمع سکنی', 'موڵکی بازرگانی'};
  Set<String> serviceAreas = {'شۆڕجە', 'ڕاپەرین', 'ناوەڕاست', 'ئیمام قاسم'};
  List<Milestone> milestones = List.of(_defaultMilestones);

  /// Set only for a `complex` (مجمع سکنی) account that said, at
  /// registration, it was created by a company. Null means independent —
  /// no parent company at all — which is just as valid a complex account.
  String? parentCompanyName;

  void setParentCompany(String? name) {
    parentCompanyName = (name == null || name.trim().isEmpty) ? null : name.trim();
    notifyListeners();
  }

  void updateAbout({required String bio, required Set<String> specialties, required Set<String> serviceAreas}) {
    this.bio = bio;
    this.specialties = specialties;
    this.serviceAreas = serviceAreas;
    notifyListeners();
  }

  void addMilestone(Milestone milestone) {
    milestones = [...milestones, milestone];
    notifyListeners();
  }

  void removeMilestoneAt(int index) {
    milestones = [...milestones]..removeAt(index);
    notifyListeners();
  }
}
