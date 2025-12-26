import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/settings/settings_section.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/wr_logo.dart';
import '../../config/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          WRLogo(size: 24, onTap: () => Navigator.pushNamed(context, AppRouter.home)),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.settings),
        ]),
      ),
      body: ListView(
        children: [
          const SettingsSection(),
        ],
      ),
    );
  }
}
