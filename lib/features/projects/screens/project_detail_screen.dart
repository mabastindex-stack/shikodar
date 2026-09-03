import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';
import '../../developer/screens/developer_profile_screen.dart';
import '../../home/screens/favorites_screen.dart';
import 'unit_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _galleryController = PageController();
  int _photoIndex = 0;
  Timer? _autoTimer;
  ListingPurpose? _purposeFilter; // null = all
  String _typeFilter = 'all';
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _videoExpanded = false;

  Project get project => widget.project;

  List<UnitType> get _filteredUnits => project.unitTypes.where((u) {
        if (_purposeFilter != null && u.purpose != _purposeFilter) return false;
        if (_typeFilter != 'all' && u.type.name != _typeFilter) return false;
        return true;
      }).toList();

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_galleryController.hasClients) return;
      final next = (_photoIndex + 1) % project.images.length;
      _galleryController.animateToPage(next, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (project.videoUrl.isEmpty) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(project.videoUrl));
    _video = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _galleryController.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDone = project.status == ProjectStatus.completed;
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        controller: _galleryController,
                        itemCount: project.images.length,
                        onPageChanged: (i) => setState(() => _photoIndex = i),
                        itemBuilder: (_, i) => !isNetworkImage(project.images[i])
                            ? Image.file(File(project.images[i]), fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: project.images[i],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: palette.surfaceElevated),
                                errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                              ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 90,
                      child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x88000000)]))),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(project.images.length, (i) {
                          final active = i == _photoIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(color: active ? AppColors.gold : Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(3)),
                          );
                        }),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                          ValueListenableBuilder<Set<String>>(
                            valueListenable: FavoritesStore.ids,
                            builder: (_, ids, __) {
                              final fav = ids.contains(project.id);
                              return _circleBtn(fav ? Icons.favorite : Icons.favorite_border, () => FavoritesStore.toggle(project.id), color: fav ? palette.error : AppColors.ink);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(color: palette.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: isDone ? AppColors.whatsapp : AppColors.gold, borderRadius: BorderRadius.circular(20)),
                            child: Text(isDone ? 'my_projects.badge_done'.tr() : 'my_projects.badge_building'.tr(), style: TextStyle(color: isDone ? Colors.white : AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DeveloperProfileScreen(
                                  agency: project.agency,
                                  projects: mockProjects.where((p) => p.agency.id == project.agency.id).toList(),
                                ),
                              )),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                                      child: const Icon(Icons.storefront_rounded, size: 14, color: AppColors.ink),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(project.agencyName, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.gold),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().scale(delay: 80.ms, duration: 420.ms, curve: Curves.easeOutBack).fadeIn(),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),
                      Text(project.name, style: TextStyle(color: palette.textPrimary, fontSize: 24, fontWeight: FontWeight.w800))
                          .animate(delay: 60.ms)
                          .fadeIn(duration: 320.ms)
                          .slideX(begin: -0.04, end: 0),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: palette.textSecondary),
                          const SizedBox(width: 4),
                          Text(project.zone, style: TextStyle(color: palette.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _priceCol(palette, 'my_projects.edit_price_from_field'.tr(), project.priceFrom),
                            Container(width: 1, height: 34, color: palette.divider),
                            _priceCol(palette, 'my_projects.edit_price_to_field'.tr(), project.priceTo),
                          ],
                        ),
                      ).animate(delay: 100.ms).fadeIn(duration: 320.ms),

                      const SizedBox(height: 24),
                      _sectionTitle(palette, 'project_detail.video_tour_section_title'.tr(), 120),
                      const SizedBox(height: 12),
                      _videoShowcase(palette).animate(delay: 130.ms).fadeIn(duration: 340.ms).slideY(begin: 0.06, end: 0),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _infoCard(palette, Icons.payments_outlined, 'project_detail.payment_plan_label'.tr(), project.paymentPlan)),
                          const SizedBox(width: 12),
                          Expanded(child: _infoCard(palette, Icons.event_available_outlined, 'project_detail.completion_time_label'.tr(), project.completionInfo)),
                        ],
                      ).animate(delay: 140.ms).fadeIn(duration: 320.ms),

                      const SizedBox(height: 26),
                      _sectionTitle(palette, 'project_detail.about_project_title'.tr(), 140),
                      const SizedBox(height: 10),
                      Text(project.description, style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.7)).animate(delay: 160.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),
                      ...List.generate(project.highlights.length, (i) => _highlightRow(palette, project.highlights[i], i)),

                      const SizedBox(height: 22),
                      _sectionTitle(palette, 'project_detail.units_section_title'.tr(), 260),
                      const SizedBox(height: 12),
                      _unitFilterBar(palette),
                      const SizedBox(height: 14),
                      _filteredUnits.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Center(child: Text('project_detail.no_units_found'.tr(), style: TextStyle(color: palette.textSecondary))),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: _filteredUnits.length,
                              itemBuilder: (_, i) => _unitCard(palette, _filteredUnits[i], i),
                            ),

                      const SizedBox(height: 10),
                      _sectionTitle(palette, 'project_detail.amenities_section_title'.tr(), 280),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3.0,
                        children: project.amenities.map((a) => _amenityChip(palette, a)).toList(),
                      ).animate(delay: 320.ms).fadeIn(duration: 320.ms),

                      const SizedBox(height: 26),
                      _sectionTitle(palette, 'project_detail.specs_table_title'.tr(), 360),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: List.generate(project.specs.length, (i) {
                            final s = project.specs[i];
                            final isLast = i == project.specs.length - 1;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                  child: Row(
                                    children: [
                                      Icon(_specIcon(s.$1), size: 17, color: AppColors.goldDark),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(s.$1, style: TextStyle(color: palette.textSecondary, fontSize: 12.5))),
                                      Text(s.$2, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: palette.divider),
                              ],
                            );
                          }),
                        ),
                      ).animate(delay: 400.ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _contactBar()),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = AppColors.ink}) {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 17, color: color)),
        ),
      ),
    );
  }

  Widget _sectionTitle(AppPalette palette, String text, int delay) =>
      Text(text, style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: delay.ms).fadeIn(duration: 300.ms);

  Widget _priceCol(AppPalette palette, String label, double value) => Column(
        children: [
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text('\$${value.toStringAsFixed(0)}', style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _highlightRow(AppPalette palette, String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_rounded, size: 14, color: AppColors.goldDark),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5))),
        ],
      ),
    ).animate(delay: (200 + 50 * index).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _unitFilterBar(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _purposeChip(palette, 'filters.all'.tr(), null)),
            const SizedBox(width: 6),
            Expanded(child: _purposeChip(palette, 'filters.rent'.tr(), ListingPurpose.rent)),
            const SizedBox(width: 6),
            Expanded(child: _purposeChip(palette, 'filters.sale'.tr(), ListingPurpose.sale)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _typeChip(palette, 'all', 'filters.all'.tr(), Icons.apps_rounded),
              _typeChip(palette, 'house', 'filters.house'.tr(), Icons.house_outlined),
              _typeChip(palette, 'villa', 'filters.villa'.tr(), Icons.villa_outlined),
              _typeChip(palette, 'shop', 'filters.shop'.tr(), Icons.storefront_outlined),
            ],
          ),
        ),
      ],
    ).animate(delay: 240.ms).fadeIn(duration: 300.ms);
  }

  Widget _purposeChip(AppPalette palette, String label, ListingPurpose? value) {
    final selected = _purposeFilter == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () => setState(() => _purposeFilter = value),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.goldGradient : null,
            color: selected ? null : palette.surfaceElevated,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(label, style: TextStyle(color: selected ? AppColors.ink : palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _typeChip(AppPalette palette, String value, String label, IconData icon) {
    final selected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => setState(() => _typeFilter = value),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: selected ? palette.textPrimary : palette.surfaceElevated, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Icon(icon, size: 13, color: selected ? palette.background : palette.textSecondary),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(color: selected ? palette.background : palette.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _unitCard(AppPalette palette, UnitType u, int i) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: u, project: project))),
        borderRadius: BorderRadius.circular(20),
        child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  u.images.isEmpty
                      ? Container(color: palette.surfaceElevated, child: Icon(Icons.door_front_door_outlined, color: palette.textMuted))
                      : !isNetworkImage(u.images.first)
                          ? Image.file(File(u.images.first), fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: u.images.first,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: palette.surfaceElevated),
                              errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated, child: Icon(Icons.door_front_door_outlined, color: palette.textMuted)),
                            ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: u.purpose == ListingPurpose.rent ? AppColors.negotiable : palette.textPrimary, borderRadius: BorderRadius.circular(20)),
                      child: Text(u.purpose == ListingPurpose.rent ? 'filters.rent'.tr() : 'filters.sale'.tr(), style: TextStyle(color: palette.background, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.square_foot, size: 12, color: palette.textSecondary),
                      const SizedBox(width: 3),
                      Text(u.area, style: TextStyle(color: palette.textSecondary, fontSize: 10.5)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${'project_detail.price_from_prefix'.tr()} \$${u.priceFrom.toStringAsFixed(0)}', style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    ).animate(delay: (300 + 60 * i).ms).fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _videoShowcase(AppPalette palette) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
      onTap: () {
        if (_video == null) return;
        setState(() {
          _videoExpanded = !_videoExpanded;
          _videoExpanded ? _video!.play() : _video!.pause();
        });
      },
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_videoReady && _video != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(width: _video!.value.size.width, height: _video!.value.size.height, child: VideoPlayer(_video!)),
                )
              else if (!_videoFailed && !isNetworkImage(project.images.first))
                Image.file(File(project.images.first), fit: BoxFit.cover)
              else if (!_videoFailed)
                CachedNetworkImage(imageUrl: project.images.first, fit: BoxFit.cover, placeholder: (_, __) => Container(color: palette.surfaceElevated))
              else
                Container(color: palette.surfaceElevated, child: Icon(Icons.videocam_off_outlined, color: palette.textMuted)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x66000000)], stops: [0.5, 1.0]),
                ),
              ),
              if (!_videoExpanded)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 20)]),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.ink, size: 30),
                  ),
                ),
              Positioned(
                bottom: 12,
                right: 14,
                child: Row(
                  children: [
                    const Icon(Icons.hd_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('project_detail.video_tour_badge'.tr(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _infoCard(AppPalette palette, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.goldDark),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: palette.textSecondary, fontSize: 10.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w700, height: 1.4)),
        ],
      ),
    );
  }

  IconData _specIcon(String label) {
    if (label.contains('بلۆک')) return Icons.apartment_rounded;
    if (label.contains('نهۆم') || label.contains('تاوەر')) return Icons.stairs_rounded;
    if (label.contains('ڕووبەر')) return Icons.square_foot_rounded;
    if (label.contains('پارکینگ')) return Icons.local_parking_rounded;
    return Icons.info_outline_rounded;
  }

  Widget _amenityChip(AppPalette palette, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.goldDark),
          const SizedBox(width: 7),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _contactBar() {
    final palette = context.palette;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: palette.background.withOpacity(0.92), border: Border(top: BorderSide(color: palette.divider))),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://wa.me/9647700000000'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text('listing.contact_whatsapp'.tr()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:+9647700000000')),
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text('listing.contact_call'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
