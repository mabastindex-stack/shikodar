import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/soft_card.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The app's one live ApiClient — whatever it's currently pointed at
    // (from a previous save, or the built-in default) is what's actually
    // in effect right now, so that's what this field should show.
    _urlController.text = context.read<ApiClient>().baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.server_settings'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'auth.server_url_hint'.tr(),
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                style: TextStyle(color: palette.textPrimary),
                decoration: const InputDecoration(hintText: 'http://127.0.0.1:8000/api'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  _presetChip(palette, 'Local AppServ', 'http://127.0.0.1/shikodar/public/api'),
                  _presetChip(palette, 'Hostinger', 'https://dublinclass.com/api'),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Updates the app's one live ApiClient directly — every
                  // repository already holds a reference to it, so this
                  // takes effect immediately, with no app restart needed.
                  await context.read<ApiClient>().updateBaseUrl(_urlController.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('auth.server_settings_saved'.tr())),
                    );
                  }
                },
                child: Text('common.save'.tr()),
              ),
            ],
          ),
        ).entrance(),
      ),
    );
  }

  Widget _presetChip(AppPalette palette, String label, String url) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: palette.surfaceElevated,
      labelStyle: TextStyle(color: palette.textPrimary),
      side: BorderSide.none,
      onPressed: () => setState(() => _urlController.text = url),
    );
  }
}
