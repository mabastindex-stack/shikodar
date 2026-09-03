import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/project.dart';
import '../../../core/session/admin_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class _TierOption {
  final String name;
  final PackageTier tier;
  final int price;
  const _TierOption(this.name, this.tier, this.price);
}

const _tiers = [
  _TierOption('Starter', PackageTier.starter, 50),
  _TierOption('Basic', PackageTier.basic, 100),
  _TierOption('Business', PackageTier.business, 175),
  _TierOption('Premium', PackageTier.premium, 250),
  _TierOption('Enterprise', PackageTier.enterprise, 400),
];

enum _BusinessKind { agency, company, complex }

// A function (not a `const` list) so each label re-evaluates `.tr()` against
// the current locale at call time, instead of being frozen at compile time.
List<(_BusinessKind, String, IconData)> _kinds() => [
      (_BusinessKind.agency, 'admin.contract_kind_agency'.tr(), Icons.storefront_rounded),
      (_BusinessKind.company, 'admin.contract_kind_company'.tr(), Icons.apartment_rounded),
      (_BusinessKind.complex, 'profile_page.complex_fallback_name'.tr(), Icons.location_city_rounded),
    ];

/// One form that does two (or three) jobs at once, by design: creates the
/// business's account, its contract terms (package, price, duration), and —
/// for a company/complex — a starter project record, in a single admin
/// action. Agencies/companies/complexes never self-register; this is the
/// only door in.
class CreateAgencyContractScreen extends StatefulWidget {
  const CreateAgencyContractScreen({super.key});

  @override
  State<CreateAgencyContractScreen> createState() => _CreateAgencyContractScreenState();
}

class _CreateAgencyContractScreenState extends State<CreateAgencyContractScreen> {
  _BusinessKind _kind = _BusinessKind.agency;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _zoneController = TextEditingController();
  final _priceController = TextEditingController();
  int _selectedTier = 2; // Business, sensible default
  int _durationMonths = 12;
  DateTime _startDate = DateTime.now();
  Agency? _createdAgency;

  DateTime get _endDate => DateTime(_startDate.year, _startDate.month + _durationMonths, _startDate.day);

  @override
  void initState() {
    super.initState();
    _priceController.text = _tiers[_selectedTier].price.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _zoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String get _nameLabel {
    switch (_kind) {
      case _BusinessKind.agency:
        return 'admin.contract_name_label_agency'.tr();
      case _BusinessKind.company:
        return 'admin.contract_name_label_company'.tr();
      case _BusinessKind.complex:
        return 'auth.complex_name'.tr();
    }
  }

  void _onTierChanged(int i) {
    setState(() {
      _selectedTier = i;
      _priceController.text = _tiers[i].price.toString();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.contract_validation_name_phone'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_kind != _BusinessKind.agency && _zoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.contract_validation_zone'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final store = context.read<AdminStore>();
    final zone = _zoneController.text.trim();
    final agency = Agency(
      id: store.nextAgencyId(),
      name: name,
      tier: _tiers[_selectedTier].tier,
      verified: true,
      serviceAreas: zone.isEmpty ? const [] : [zone],
      bio: '',
    );
    store.addAgency(agency);
    store.addContract(Contract(
      agencyId: agency.id,
      agencyName: name,
      tier: _tiers[_selectedTier].tier,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      price: int.tryParse(_priceController.text.trim()) ?? _tiers[_selectedTier].price,
      startDate: _startDate,
      endDate: _endDate,
    ));

    if (_kind != _BusinessKind.agency) {
      mockProjects.add(
        Project(
          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          zone: zone,
          images: const [
            'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=900&q=80',
            'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=900&q=80',
            'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=900&q=80',
          ],
          videoUrl: '',
          priceFrom: 0,
          priceTo: 0,
          status: ProjectStatus.underConstruction,
          description: '',
          highlights: const [],
          amenities: const [],
          unitTypes: const [],
          agencyName: name,
          agency: agency,
          paymentPlan: '',
          completionInfo: '',
          specs: const [],
        ),
      );
    }

    setState(() => _createdAgency = agency);
  }

  String _fmt(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('admin.contract_screen_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: _createdAgency != null ? _successView(palette) : _form(palette),
    );
  }

  Widget _form(AppPalette palette) {
    final kinds = _kinds();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _sectionLabel(palette, 'admin.contract_section_kind'.tr(), 0),
        Row(
          children: kinds.map((k) {
            final selected = _kind == k.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: k == kinds.last ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() => _kind = k.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.goldGradient : null,
                      color: selected ? null : palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: selected ? null : [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      children: [
                        Icon(k.$3, size: 20, color: selected ? AppColors.ink : palette.textSecondary),
                        const SizedBox(height: 6),
                        Text(k.$2, style: TextStyle(color: selected ? AppColors.ink : palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ).animate(delay: 20.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 26),
        _sectionLabel(palette, 'my_listings.step_basics_title'.tr(), 40),
        _field(palette, _nameController, Icons.badge_outlined, _nameLabel, 60),
        const SizedBox(height: 12),
        _field(palette, _phoneController, Icons.phone_outlined, 'auth.phone'.tr(), 90, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _field(palette, _emailController, Icons.email_outlined, 'auth.optional_email'.tr(), 120, keyboardType: TextInputType.emailAddress),
        if (_kind != _BusinessKind.agency) ...[
          const SizedBox(height: 12),
          _field(palette, _zoneController, Icons.location_on_outlined, 'admin.contract_zone_hint'.tr(), 140),
        ],

        const SizedBox(height: 26),
        _sectionLabel(palette, 'admin.contract_section_package'.tr(), 160),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_tiers.length, (i) {
            final selected = _selectedTier == i;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _onTierChanged(i),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.goldGradient : null,
                    color: selected ? null : palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: selected ? null : [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: Text('${_tiers[i].name} · \$${_tiers[i].price}', style: TextStyle(color: selected ? AppColors.ink : palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }),
        ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 20),
        _sectionLabel(palette, 'admin.contract_section_price'.tr(), 240),
        _field(palette, _priceController, Icons.attach_money_rounded, 'admin.contract_price_hint'.tr(), 260, keyboardType: TextInputType.number),

        const SizedBox(height: 26),
        _sectionLabel(palette, 'admin.contract_section_start_date'.tr(), 280),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _pickStartDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: palette.textSecondary),
                  const SizedBox(width: 10),
                  Text(_fmt(_startDate), style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.goldDark),
                ],
              ),
            ),
          ),
        ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 20),
        _sectionLabel(palette, 'admin.contract_section_duration'.tr(), 320),
        Row(
          children: [2, 6, 12, 24].map((m) {
            final selected = _durationMonths == m;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => _durationMonths = m),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: selected ? palette.textPrimary : palette.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                      child: Text('admin.contract_duration_months'.tr(args: ['$m']), style: TextStyle(color: selected ? palette.background : palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ).animate(delay: 340.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.event_available_outlined, size: 18, color: AppColors.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text('admin.contract_end_date_label'.tr(args: [_fmt(_endDate)]), style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ).animate(delay: 380.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 30),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _submit,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Text('admin.contract_submit_button'.tr(), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ).animate(delay: 420.ms).fadeIn(duration: 320.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _sectionLabel(AppPalette palette, String text, int delay) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)).animate(delay: delay.ms).fadeIn(duration: 280.ms),
      );

  Widget _field(AppPalette palette, TextEditingController c, IconData icon, String hint, int delay, {TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      style: TextStyle(color: palette.textPrimary),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: palette.textSecondary)),
    ).animate(delay: delay.ms).fadeIn(duration: 300.ms).slideX(begin: 0.06, end: 0);
  }

  Widget _successView(AppPalette palette) {
    final kind = _kinds().firstWhere((k) => k.$1 == _kind);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: AppColors.whatsapp.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.whatsapp, size: 44),
            ).animate().scale(duration: 450.ms, curve: Curves.elasticOut).fadeIn(),
            const SizedBox(height: 22),
            Text('admin.contract_success_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)).animate(delay: 150.ms).fadeIn(duration: 350.ms),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  _summaryRow(palette, 'admin.contract_summary_kind_label'.tr(), kind.$2),
                  _summaryRow(palette, 'admin.contract_summary_name_label'.tr(), _nameController.text),
                  _summaryRow(palette, 'admin.package_field_label'.tr(), '${_tiers[_selectedTier].name} · \$${_priceController.text}'),
                  _summaryRow(palette, 'admin.contract_summary_start_label'.tr(), _fmt(_startDate)),
                  _summaryRow(palette, 'admin.contract_summary_end_label'.tr(), _fmt(_endDate)),
                ],
              ),
            ).animate(delay: 220.ms).fadeIn(duration: 350.ms),
            const SizedBox(height: 22),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(color: palette.textPrimary, borderRadius: BorderRadius.circular(14)),
                  child: Text('admin.contract_ok_button'.tr(), style: TextStyle(color: palette.background, fontWeight: FontWeight.w700)),
                ),
              ),
            ).animate(delay: 280.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(AppPalette palette, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 12.5)),
            Text(value, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
