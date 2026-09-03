import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/project.dart';
import '../../../core/session/business_profile_store.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../home/screens/favorites_screen.dart';
import '../../listing/screens/listing_detail_screen.dart';
import '../../my_listings/screens/my_listings_screen.dart';
import '../../my_projects/screens/edit_project_screen.dart';
import '../../my_projects/screens/my_projects_screen.dart';
import '../../my_reels/screens/my_reels_screen.dart';
import '../../offers/screens/offers_list_screen.dart';
import '../../packages/screens/packages_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/screens/unit_detail_screen.dart';
import 'edit_business_profile_screen.dart';
import 'settings_screen.dart';

const _coverPhotoUrl = 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  File? _profileImage;
  File? _coverImage;
  int _tab = 0; // 0 posts, 1 reels, 2 manage

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _coverImage = File(picked.path));
  }

  /// The whole app is browsable as a guest — this only shows up when the
  /// visitor opens the profile tab specifically, and asks them to sign in
  /// or register (client accounts only; business accounts are admin-created).
  Widget _guestView(BuildContext context, AppPalette palette) {
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 40),
                ).animate().scale(duration: 420.ms, curve: Curves.easeOutBack).fadeIn(),
                const SizedBox(height: 22),
                Text('profile_page.guest_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)).animate(delay: 100.ms).fadeIn(duration: 320.ms),
                const SizedBox(height: 10),
                Text(
                  'profile_page.guest_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary, fontSize: 12.5, height: 1.6),
                ).animate(delay: 140.ms).fadeIn(duration: 320.ms),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: palette.onPrimary, padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: Text('auth.login'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ).animate(delay: 180.ms).fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: Text('profile_page.create_account_button'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700)),
                  ),
                ).animate(delay: 220.ms).fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final session = context.watch<UserSession>();
    if (!session.isLoggedIn) return _guestView(context, palette);
    final role = session.role;
    final isAgency = role == AccountRole.agency;
    final isCompany = role == AccountRole.company;
    final isComplex = role == AccountRole.complex;
    final isBusiness = isAgency || isCompany || isComplex;
    final myComplex = mockProjects.isNotEmpty ? mockProjects.first : null;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (isBusiness) _businessHeader(palette, role) else _clientHeader(palette),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isComplex ? (myComplex?.name ?? 'profile_page.complex_fallback_name'.tr()) : (isCompany || isAgency ? 'کۆمپانیای شکۆ' : 'ئارام حسێن'),
                  style: TextStyle(color: palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                if (isBusiness) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 17),
                ],
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 320.ms),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: isBusiness ? AppColors.goldGradient : null,
                  color: isBusiness ? null : palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isComplex ? 'profile_page.badge_complex_verified'.tr() : (isCompany ? 'profile_page.badge_developer'.tr() : (isAgency ? 'profile_page.badge_enterprise'.tr() : 'profile_page.badge_client'.tr())),
                  style: TextStyle(color: isBusiness ? AppColors.ink : palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ).animate(delay: 140.ms).fadeIn(duration: 320.ms),
            if (isComplex) ...[
              const SizedBox(height: 8),
              Consumer<BusinessProfileStore>(
                builder: (context, store, _) => Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(store.parentCompanyName != null ? Icons.business_rounded : Icons.check_circle_outline_rounded, size: 13, color: palette.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        store.parentCompanyName != null ? 'profile_page.created_by_company'.tr(args: [store.parentCompanyName!]) : 'profile_page.independent_complex'.tr(),
                        style: TextStyle(color: palette.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (isBusiness) ...[
              const SizedBox(height: 14),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditBusinessProfileScreen(isCompany: isCompany || isComplex))),
                  icon: Icon(Icons.edit_outlined, size: 16, color: palette.primary),
                  label: Text('profile_page.edit_profile_action'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: palette.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
              ).animate(delay: 160.ms).fadeIn(duration: 320.ms),
            ],
            const SizedBox(height: 18),
            if (isBusiness) ...[
              _statsRow(palette, isCompany: isCompany, isComplex: isComplex, myComplex: myComplex).animate(delay: 180.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 20),
              _tabsBar(palette),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: switch (_tab) {
                  0 => _postsGrid(context, palette, isCompany: isCompany, isComplex: isComplex, myComplex: myComplex),
                  1 => _reelsGrid(palette),
                  _ => _manageList(context, palette, isCompany: isCompany, isComplex: isComplex, myComplex: myComplex),
                },
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _becomeBusinessCard(
                      context,
                      palette,
                      role: AccountRole.agency,
                      icon: Icons.storefront_rounded,
                      title: 'profile_page.become_agency_title'.tr(),
                      subtitle: 'profile_page.become_agency_subtitle'.tr(),
                    ),
                    const SizedBox(height: 12),
                    _becomeBusinessCard(
                      context,
                      palette,
                      role: AccountRole.company,
                      icon: Icons.apartment_rounded,
                      title: 'profile_page.become_company_title'.tr(),
                      subtitle: 'profile_page.become_company_subtitle'.tr(),
                    ),
                    const SizedBox(height: 12),
                    _becomeBusinessCard(
                      context,
                      palette,
                      role: AccountRole.complex,
                      icon: Icons.location_city_rounded,
                      title: 'profile_page.become_complex_title'.tr(),
                      subtitle: 'auth.complex_benefit'.tr(),
                    ),
                    const SizedBox(height: 18),
                    _sectionCard(palette, delay: 100, children: [
                      _tile(palette, Icons.favorite_border_rounded, 'nav.favorites'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())), isLast: true),
                    ]),
                  ],
                ),
              ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  // ── Headers ────────────────────────────────────────────────────────────

  Widget _clientHeader(AppPalette palette) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
          child: Row(
            children: [
              const Spacer(),
              _settingsGearButton(context, palette),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _avatar(palette, size: 84, isBusiness: false),
      ],
    );
  }

  Widget _businessHeader(AppPalette palette, AccountRole role) {
    const coverHeight = 190.0;
    const avatarSize = 92.0;
    final avatarIcon = switch (role) {
      AccountRole.company => Icons.apartment_rounded,
      AccountRole.complex => Icons.location_city_rounded,
      _ => Icons.storefront_rounded,
    };
    return SizedBox(
      height: coverHeight + avatarSize / 2 + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: coverHeight,
            child: GestureDetector(
              onTap: _pickCoverImage,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _coverImage != null
                      ? Image.file(_coverImage!, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: _coverPhotoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: palette.surfaceElevated),
                        ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), Colors.transparent, Color(0x88000000)],
                        stops: [0, 0.5, 1],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 13),
                          const SizedBox(width: 6),
                          Text('profile_page.change_cover_label'.tr(), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(top: 10, end: 14, child: _settingsGearButton(context, palette)),
          Positioned(
            top: coverHeight - avatarSize / 2,
            left: 0,
            right: 0,
            child: Center(child: _avatar(palette, size: avatarSize, isBusiness: true, icon: avatarIcon)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 380.ms);
  }

  Widget _avatar(AppPalette palette, {required double size, required bool isBusiness, IconData icon = Icons.storefront_rounded}) {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isBusiness
                    ? [BoxShadow(color: AppColors.gold.withOpacity(0.3 + 0.15 * _glow.value), blurRadius: 20 + 8 * _glow.value, spreadRadius: 1 + _glow.value)]
                    : [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: child,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: _profileImage == null && isBusiness ? AppColors.goldGradient : null,
                color: _profileImage == null && !isBusiness ? palette.surfaceElevated : null,
                shape: BoxShape.circle,
                border: Border.all(color: palette.background, width: 4),
                image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null,
              ),
              child: _profileImage == null
                  ? Icon(isBusiness ? icon : Icons.person, color: isBusiness ? AppColors.ink : palette.textSecondary, size: size * 0.42)
                  : null,
            ),
          ),
          PositionedDirectional(
            bottom: -2,
            end: -2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: palette.textPrimary, shape: BoxShape.circle, border: Border.all(color: palette.background, width: 2.5)),
              child: Icon(Icons.camera_alt_rounded, color: palette.background, size: 13),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _settingsGearButton(BuildContext context, AppPalette palette) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.25))),
          child: const Icon(Icons.settings_outlined, color: Colors.white, size: 19),
        ),
      ),
    );
  }

  // ── Stats + tabs ───────────────────────────────────────────────────────

  Widget _statsRow(AppPalette palette, {required bool isCompany, required bool isComplex, required Project? myComplex}) {
    final firstStat = isComplex
        ? (Icons.door_front_door_outlined, '${myComplex?.unitTypes.length ?? 0}', 'profile_page.stat_unit'.tr())
        : (isCompany ? (Icons.apartment_rounded, '2', 'profile_page.stat_project'.tr()) : (Icons.home_work_outlined, '24', 'profile_page.stat_listing'.tr()));
    final stats = [
      firstStat,
      (Icons.star_rounded, '4.8', 'profile_page.stat_rating'.tr()),
      (Icons.handshake_rounded, '214', 'profile_page.stat_deal'.tr()),
      (Icons.schedule_rounded, '9', 'profile_page.stat_year'.tr()),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: stats
              .map((s) => Expanded(
                    child: Column(
                      children: [
                        Icon(s.$1, size: 17, color: AppColors.goldDark),
                        const SizedBox(height: 4),
                        _CountUp(target: s.$2, palette: palette),
                        const SizedBox(height: 2),
                        Text(s.$3, style: TextStyle(color: palette.textSecondary, fontSize: 9.5)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _tabsBar(AppPalette palette) {
    final labels = ['profile_page.tab_posts'.tr(), 'profile_page.tab_reels'.tr(), 'profile_page.tab_manage'.tr()];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = _tab == i;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: () => setState(() => _tab = i),
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: selected ? palette.textPrimary : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: Text(labels[i], style: TextStyle(color: selected ? palette.background : palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Tab content ────────────────────────────────────────────────────────

  Widget _postsGrid(BuildContext context, AppPalette palette, {required bool isCompany, required bool isComplex, required Project? myComplex}) {
    if (isComplex) {
      final units = myComplex?.unitTypes ?? const [];
      if (units.isEmpty) return _emptyTabState(palette, 'profile_page.empty_units'.tr());
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
        itemCount: units.length,
        itemBuilder: (_, i) {
          final u = units[i];
          return _postTile(
            palette: palette,
            imageUrl: u.images.isNotEmpty ? u.images.first : '',
            label: '\$${u.priceFrom.toStringAsFixed(0)}',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: u, project: myComplex!))),
          );
        },
      );
    }
    if (isCompany) {
      final projects = mockProjects.where((p) => p.agency.id == MockData.agencyShiko.id).toList();
      if (projects.isEmpty) return _emptyTabState(palette, 'profile_page.empty_projects'.tr());
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
        itemCount: projects.length,
        itemBuilder: (_, i) {
          final p = projects[i];
          return _postTile(
            palette: palette,
            imageUrl: p.images.isNotEmpty ? p.images.first : '',
            label: '\$${p.priceFrom.toStringAsFixed(0)}+',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p))),
          );
        },
      );
    }
    final listings = MockData.listings.where((l) => l.agency.id == MockData.agencyShiko.id).toList();
    if (listings.isEmpty) return _emptyTabState(palette, 'profile_page.empty_listings'.tr());
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
      itemCount: listings.length,
      itemBuilder: (_, i) {
        final l = listings[i];
        return _postTile(
          palette: palette,
          imageUrl: l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
          label: '\$${l.price.toStringAsFixed(0)}',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: l))),
        );
      },
    );
  }

  Widget _postTile({required AppPalette palette, required String imageUrl, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isNotEmpty
              ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, placeholder: (_, __) => Container(color: palette.surfaceElevated))
              : Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted)),
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reelsGrid(AppPalette palette) {
    final reels = MockData.reels.where((r) => r.listing.agency.id == MockData.agencyShiko.id).toList();
    if (reels.isEmpty) return _emptyTabState(palette, 'profile_page.empty_reels'.tr());
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3, childAspectRatio: 0.7),
      itemCount: reels.length,
      itemBuilder: (_, i) {
        final r = reels[i];
        return Stack(
          fit: StackFit.expand,
          children: [
            r.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: r.thumbnailUrl, fit: BoxFit.cover, placeholder: (_, __) => Container(color: palette.surfaceElevated))
                : Container(color: palette.surfaceElevated, child: Icon(Icons.videocam_outlined, color: palette.textMuted)),
            const Positioned(top: 5, right: 5, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 17)),
            Positioned(
              left: 5,
              bottom: 5,
              child: Text('${r.duration.inSeconds}s', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Widget _manageList(BuildContext context, AppPalette palette, {required bool isCompany, required bool isComplex, required Project? myComplex}) {
    final postsCount = isComplex
        ? (myComplex?.unitTypes.length ?? 0)
        : (isCompany ? mockProjects.where((p) => p.agency.id == MockData.agencyShiko.id).length : MockData.listings.where((l) => l.agency.id == MockData.agencyShiko.id).length);
    final reelsCount = MockData.reels.where((r) => r.listing.agency.id == MockData.agencyShiko.id).length;
    return Column(
      children: [
        _premiumPackageCard(context, palette, isCompany: isCompany || isComplex, postsCount: postsCount, reelsCount: reelsCount),
        const SizedBox(height: 16),
        _activeOfferCard(context, palette),
        const SizedBox(height: 16),
        _sectionCard(palette, children: [
          _tile(palette, Icons.dashboard_outlined, 'profile.dashboard'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DashboardScreen()))),
          if (isComplex && myComplex != null)
            _tile(palette, Icons.edit_road_outlined, 'profile_page.edit_my_complex_tile'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProjectScreen(project: myComplex))))
          else if (isCompany)
            _tile(palette, Icons.apartment_outlined, 'profile.my_projects'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProjectsScreen())))
          else
            _tile(palette, Icons.home_work_outlined, 'profile.my_listings'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyListingsScreen()))),
          _tile(palette, Icons.play_circle_outline, 'profile.my_reels'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReelsScreen()))),
          _tile(palette, Icons.local_offer_outlined, 'profile_page.offers_tile'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OffersListScreen())), isLast: true),
        ]),
      ],
    );
  }

  Widget _emptyTabState(AppPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.photo_library_outlined, color: palette.textMuted, size: 26),
          ),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Shared cards ───────────────────────────────────────────────────────

  Widget _premiumPackageCard(BuildContext context, AppPalette palette, {required bool isCompany, required int postsCount, required int reelsCount}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PackagesScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF2A2620)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.workspace_premium_rounded, color: AppColors.ink, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('profile_page.enterprise_package_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('profile_page.enterprise_package_expiry'.tr(), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gold, size: 22),
              ],
            ),
            const SizedBox(height: 16),
            _usageRow(isCompany ? 'profile_page.usage_projects_label'.tr() : 'profile_page.usage_listings_label'.tr(), 'profile_page.unlimited_count'.tr(args: ['$postsCount']), 1.0),
            const SizedBox(height: 12),
            _usageRow('profile_page.usage_reels_label'.tr(), 'profile_page.unlimited_count'.tr(args: ['$reelsCount']), 1.0),
          ],
        ),
      ),
    );
  }

  Widget _usageRow(String label, String valueLabel, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(valueLabel, style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
      ],
    );
  }

  /// Which promotional offer this account has joined, its expiry, and a
  /// quick link to browse more — surfaced right on the profile instead of
  /// buried only in the Offers list.
  Widget _activeOfferCard(BuildContext context, AppPalette palette) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OffersListScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.local_offer_rounded, size: 18, color: AppColors.goldDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('profile_page.active_offer_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('profile_page.active_offer_expiry'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  /// Shown only to client accounts — an invitation to become a business
  /// account. Agency/company/complex accounts are admin-created only (they
  /// never self-register), so this opens a contact sheet instead of a
  /// sign-up form.
  Widget _becomeBusinessCard(
    BuildContext context,
    AppPalette palette, {
    required AccountRole role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () => _showBusinessContactSheet(context, title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: AppColors.ink, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.goldDark, size: 22),
          ],
        ),
      ),
    ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  void _showBusinessContactSheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = sheetContext.palette;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.of(sheetContext).padding.bottom),
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
                Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'profile_page.business_contact_note'.tr(),
                  style: TextStyle(color: palette.textSecondary, fontSize: 12.5, height: 1.6),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('https://wa.me/9647700000000'), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.chat, size: 18),
                    label: Text('listing.contact_whatsapp'.tr()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:+9647700000000')),
                    icon: Icon(Icons.phone, size: 18, color: palette.primary),
                    label: Text('listing.contact_call'.tr(), style: TextStyle(color: palette.primary)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: palette.primary.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard(AppPalette palette, {required List<Widget> children, int delay = 0}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    ).animate(delay: delay.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _tile(AppPalette palette, IconData icon, String label, VoidCallback onTap, {Color? color, bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color ?? palette.textSecondary),
          title: Text(label, style: TextStyle(color: color ?? palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right, color: palette.textMuted, size: 18),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 1, indent: 56, color: palette.divider),
      ],
    );
  }
}

/// Small count-up stat number — animates from 0 the first time it appears.
class _CountUp extends StatelessWidget {
  final String target;
  final AppPalette palette;
  const _CountUp({required this.target, required this.palette});

  @override
  Widget build(BuildContext context) {
    final numeric = double.tryParse(target);
    if (numeric == null) {
      return Text(target, style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800));
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: numeric),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final display = numeric == numeric.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
        return Text(display, style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800));
      },
    );
  }
}
