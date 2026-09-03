import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../developer/screens/developer_profile_screen.dart';
import '../../home/screens/favorites_screen.dart';
import '../widgets/project_identity_carousel.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends StatelessWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(11), boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))]),
                    child: const Icon(Icons.home_work_rounded, size: 19, color: AppColors.ink),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      height: 44,
                      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))]),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: palette.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              textAlign: TextAlign.start,
                              style: TextStyle(color: palette.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'project_detail.search_hint'.tr(),
                                hintStyle: TextStyle(color: palette.textMuted, fontSize: 12.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: palette.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))]),
                    child: Icon(Icons.notifications_none_rounded, size: 20, color: palette.textPrimary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.apartment_rounded, size: 16, color: AppColors.goldDark),
                  const SizedBox(width: 8),
                  Text('project_detail.screen_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                itemCount: mockProjects.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _ProjectCard(project: mockProjects[i], index: i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final int index;
  const _ProjectCard({required this.project, required this.index});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDone = project.status == ProjectStatus.completed;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
        borderRadius: BorderRadius.circular(26),
        child: Container(
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(26), boxShadow: AppColors.floatingShadow),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProjectIdentityCarousel(images: project.images),
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
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.whatsapp : AppColors.gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isDone ? 'my_projects.badge_done'.tr() : 'my_projects.badge_building'.tr(),
                        style: TextStyle(color: isDone ? Colors.white : AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: FavoritesStore.ids,
                      builder: (_, ids, __) {
                        final fav = ids.contains(project.id);
                        return Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8)]),
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () => FavoritesStore.toggle(project.id),
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 17, color: fav ? palette.error : AppColors.ink),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(project.zone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => DeveloperProfileScreen(
                                agency: project.agency,
                                projects: mockProjects.where((p) => p.agency.id == project.agency.id).toList(),
                              ),
                            )),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_rounded, size: 12, color: AppColors.gold),
                                const SizedBox(width: 4),
                                Text('project_detail.by_agency'.tr(args: [project.agencyName]), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.gold),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('developer_profile.price_from_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 10.5)),
                      const SizedBox(height: 2),
                      Text(
                        '\$${project.priceFrom.toStringAsFixed(0)} – \$${project.priceTo.toStringAsFixed(0)}',
                        style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: palette.textPrimary, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('developer_profile.view_project_button'.tr(), style: TextStyle(color: palette.background, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: palette.background),
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
    ).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
