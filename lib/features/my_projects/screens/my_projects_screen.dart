import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/boost_sheet.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/widgets/project_identity_carousel.dart';
import 'create_project_screen.dart';
import 'edit_project_screen.dart';

enum _StatusFilter { all, building, done }

/// A company/developer's own project-management list — the equivalent of
/// MyListingsScreen, but scoped to Projects (مجمع سکنی) instead of loose
/// Listings, since a company's "publishing" unit is a whole residential
/// complex, not a single house.
class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  _StatusFilter _filter = _StatusFilter.all;

  // Demo: treat the enterprise agency's projects as "my projects".
  List<Project> get _myProjects => mockProjects.where((p) {
        if (p.agency.id != MockData.agencyShiko.id) return false;
        if (_filter == _StatusFilter.building) return p.status == ProjectStatus.underConstruction;
        if (_filter == _StatusFilter.done) return p.status == ProjectStatus.completed;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final projects = _myProjects;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.my_projects'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
          if (created == true && mounted) setState(() {});
        },
        backgroundColor: palette.textPrimary,
        icon: Icon(Icons.add_rounded, color: palette.background),
        label: Text('my_projects.new_project_fab'.tr(), style: TextStyle(color: palette.background, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package usage strip.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF2A2620)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_rounded, color: AppColors.gold, size: 16),
                      const SizedBox(width: 8),
                      Text('my_projects.active_count'.tr(args: ['${projects.length}']), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                        child: Text('my_projects.enterprise_badge'.tr(), style: const TextStyle(color: AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 14),
                // Status filter tabs.
                Row(
                  children: [
                    Expanded(child: _statusTab(palette, 'filters.all'.tr(), _StatusFilter.all)),
                    const SizedBox(width: 8),
                    Expanded(child: _statusTab(palette, 'my_projects.status_building'.tr(), _StatusFilter.building)),
                    const SizedBox(width: 8),
                    Expanded(child: _statusTab(palette, 'my_projects.status_done'.tr(), _StatusFilter.done)),
                  ],
                ).animate(delay: 60.ms).fadeIn(duration: 300.ms),
              ],
            ),
          ),
          Expanded(
            child: projects.isEmpty
                ? Center(child: Text('my_projects.empty'.tr(), style: TextStyle(color: palette.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _projectRow(palette, projects[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusTab(AppPalette palette, String label, _StatusFilter value) {
    final selected = _filter == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.textPrimary : palette.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(color: selected ? palette.background : palette.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _projectRow(AppPalette palette, Project project, int index) {
    final isDone = project.status == ProjectStatus.completed;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
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
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProjectIdentityCarousel(images: project.images),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: isDone ? AppColors.whatsapp : AppColors.gold, borderRadius: BorderRadius.circular(20)),
                        child: Text(isDone ? 'my_projects.badge_done'.tr() : 'my_projects.badge_building'.tr(), style: TextStyle(color: isDone ? Colors.white : AppColors.ink, fontSize: 9.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: palette.textSecondary),
                        const SizedBox(width: 3),
                        Text(project.zone, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                        const Spacer(),
                        Text('my_projects.unit_count'.tr(args: ['${project.unitTypes.length}']), style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: palette.divider),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(palette, Icons.edit_outlined, 'my_projects.edit_action'.tr(), () async {
                            final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => EditProjectScreen(project: project)));
                            if (saved == true && mounted) setState(() {});
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _actionBtn(palette, Icons.trending_up_rounded, 'my_projects.boost_action'.tr(), () => showBoostSheet(context, itemName: project.name))),
                        const SizedBox(width: 8),
                        _actionIconBtn(Icons.delete_outline_rounded, palette.error, () => _confirmDelete(palette, project)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (80 * index).ms).fadeIn(duration: 340.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _actionBtn(AppPalette palette, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: palette.textPrimary),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: palette.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _confirmDelete(AppPalette palette, Project project) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('my_projects.confirm_delete_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('my_projects.confirm_delete_message'.tr(args: [project.name]), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              mockProjects.removeWhere((p) => p.id == project.id);
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('my_projects.delete_action'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
