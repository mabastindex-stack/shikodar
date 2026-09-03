import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/project.dart';
import '../../../core/session/business_profile_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/widgets/project_identity_carousel.dart';

const _cityTourVideoUrl = 'https://assets.mixkit.co/videos/preview/mixkit-modern-house-with-a-swimming-pool-4835-large.mp4';

/// A dramatically more elaborate profile — dedicated to residential-complex
/// developers (مجمع سکنی), distinct from the standard broker profile:
/// video header, milestone timeline, and their live projects grid.
class DeveloperProfileScreen extends StatefulWidget {
  final Agency agency;
  final List<Project> projects;
  const DeveloperProfileScreen({super.key, required this.agency, required this.projects});

  @override
  State<DeveloperProfileScreen> createState() => _DeveloperProfileScreenState();
}

class _DeveloperProfileScreenState extends State<DeveloperProfileScreen> with TickerProviderStateMixin {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;
  late final AnimationController _glow;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(_cityTourVideoUrl));
    _video = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    _glow.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final a = widget.agency;
    final foundedYear = DateTime.now().year - a.yearsActive;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.ink,
                expandedHeight: 300,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                ),
                flexibleSpace: FlexibleSpaceBar(background: _videoHeader()),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    children: [
                      _identityBlock(palette, a, foundedYear),
                      const SizedBox(height: 24),
                      _statsGrid(palette, a),
                      const SizedBox(height: 34),
                      _sectionHeader(palette, 'developer_profile.section_experience'.tr(), Icons.timeline_rounded, 260),
                      const SizedBox(height: 18),
                      _timeline(palette),
                      const SizedBox(height: 34),
                      _sectionHeader(palette, 'developer_profile.section_projects'.tr(), Icons.apartment_rounded, 500),
                      const SizedBox(height: 14),
                      _projectsRow(palette),
                      const SizedBox(height: 30),
                      _sectionHeader(palette, 'developer_profile.section_zones'.tr(), Icons.map_rounded, 560),
                      const SizedBox(height: 14),
                      _zonesWrap(palette),
                      const SizedBox(height: 140),
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

  Widget _videoHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_videoReady && _video != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: _video!.value.size.width, height: _video!.value.size.height, child: VideoPlayer(_video!)),
          )
        else if (!_videoFailed)
          Container(color: AppColors.ink, child: const Center(child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.4)))
        else
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, Color(0xFF3A2F17)]))),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x88000000), Colors.transparent, Color(0xCC000000)],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _shimmer,
          builder: (context, child) {
            final t = _shimmer.value;
            return Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + 2 * t, -1),
                    end: Alignment(0 + 2 * t, 1),
                    colors: [Colors.transparent, AppColors.gold.withOpacity(0.14), Colors.transparent],
                    stops: const [0.35, 0.5, 0.65],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 5),
                Text('developer_profile.video_tour_label'.tr(), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _identityBlock(AppPalette palette, Agency a, int foundedYear) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glow,
          builder: (context, child) => Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35 + 0.18 * _glow.value), blurRadius: 26 + 10 * _glow.value, spreadRadius: 1 + _glow.value)],
            ),
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle, border: Border.all(color: palette.background, width: 4)),
            child: const Icon(Icons.apartment_rounded, color: AppColors.ink, size: 40),
          ),
        ).animate().scale(duration: 480.ms, curve: Curves.easeOutBack).fadeIn(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(a.name, style: TextStyle(color: palette.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            if (a.verified) ...[const SizedBox(width: 7), const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 20)],
          ],
        ).animate(delay: 100.ms).fadeIn(duration: 320.ms),
        const SizedBox(height: 6),
        Text('developer_profile.subtitle'.tr(args: ['$foundedYear']), style: TextStyle(color: palette.textSecondary, fontSize: 12.5)).animate(delay: 140.ms).fadeIn(duration: 320.ms),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: const BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Text('developer_profile.badge'.tr(), style: const TextStyle(color: AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
        ).animate(delay: 180.ms).fadeIn(duration: 320.ms),
      ],
    );
  }

  Widget _statsGrid(AppPalette palette, Agency a) {
    final stats = [
      (Icons.apartment_rounded, '${widget.projects.length}', 'developer_profile.stat_projects'.tr()),
      (Icons.home_work_rounded, '${a.dealsCompleted}', 'developer_profile.stat_units_delivered'.tr()),
      (Icons.schedule_rounded, '${a.yearsActive}', 'developer_profile.stat_years_experience'.tr()),
      (Icons.sentiment_satisfied_alt_rounded, '%${a.responseRatePercent}', 'developer_profile.stat_client_satisfaction'.tr()),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(22), boxShadow: AppColors.floatingShadow),
        child: Row(
          children: stats
              .map((s) => Expanded(
                    child: Column(
                      children: [
                        Icon(s.$1, size: 19, color: AppColors.goldDark),
                        const SizedBox(height: 6),
                        _CountUp(target: s.$2, palette: palette),
                        const SizedBox(height: 3),
                        Text(s.$3, style: TextStyle(color: palette.textSecondary, fontSize: 9.5), textAlign: TextAlign.center),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    ).animate(delay: 220.ms).fadeIn(duration: 380.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _sectionHeader(AppPalette palette, String title, IconData icon, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 15, color: AppColors.goldDark),
          ),
          const SizedBox(width: 9),
          Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 300.ms);
  }

  Widget _timeline(AppPalette palette) {
    // "My own" company's timeline is owner-editable from the Profile tab
    // (EditBusinessProfileScreen) — reflect those edits live here.
    final isMine = widget.agency.id == MockData.agencyShiko.id;
    final milestones = isMine ? context.watch<BusinessProfileStore>().milestones : const <Milestone>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(milestones.length, (i) {
          final m = milestones[i];
          final isLast = i == milestones.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 10)]),
                      child: Icon(m.icon, size: 17, color: AppColors.ink),
                    ),
                    if (!isLast) Expanded(child: Container(width: 2, color: palette.divider)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.year, style: const TextStyle(color: AppColors.goldDark, fontSize: 12.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(m.title, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: (320 + 90 * i).ms).fadeIn(duration: 340.ms).slideX(begin: 0.08, end: 0);
        }),
      ),
    );
  }

  Widget _projectsRow(AppPalette palette) {
    if (widget.projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('developer_profile.no_projects'.tr(), style: TextStyle(color: palette.textSecondary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(widget.projects.length, (i) {
          final p = widget.projects[i];
          final isDone = p.status == ProjectStatus.completed;
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p))),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.floatingShadow),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 190,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProjectIdentityCarousel(images: p.images),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Color(0x99000000)], stops: [0.0, 0.55, 1.0]),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: isDone ? AppColors.whatsapp : AppColors.gold, borderRadius: BorderRadius.circular(20)),
                              child: Text(isDone ? 'my_projects.badge_done'.tr() : 'my_projects.badge_building'.tr(), style: TextStyle(color: isDone ? Colors.white : AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                                    const SizedBox(width: 3),
                                    Text(p.zone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('developer_profile.price_from_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 10.5)),
                              Text('\$${p.priceFrom.toStringAsFixed(0)} – \$${p.priceTo.toStringAsFixed(0)}', style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(color: palette.textPrimary, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('developer_profile.view_project_button'.tr(), style: TextStyle(color: palette.background, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 5),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: palette.background),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ).animate(delay: (540 + 120 * i).ms).fadeIn(duration: 360.ms).slideY(begin: 0.08, end: 0);
        }),
      ),
    );
  }

  Widget _zonesWrap(AppPalette palette) {
    final zones = widget.projects.map((p) => p.zone).toSet().toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: zones
            .map((z) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.goldDark),
                      const SizedBox(width: 5),
                      Text(z, style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      ),
    ).animate(delay: 600.ms).fadeIn(duration: 320.ms);
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 17, color: AppColors.ink)),
        ),
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

class _CountUp extends StatelessWidget {
  final String target;
  final AppPalette palette;
  const _CountUp({required this.target, required this.palette});

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'[\d.]+').firstMatch(target);
    final numeric = match != null ? double.tryParse(match.group(0)!) : null;
    if (numeric == null) {
      return Text(target, style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800));
    }
    final prefix = target.substring(0, match!.start);
    final suffix = target.substring(match.end);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: numeric),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final display = numeric == numeric.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
        return Text('$prefix$display$suffix', style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800));
      },
    );
  }
}
