import 'package:flutter/material.dart';

import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';

/// Home page app bar
class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final bool isSyncing;
  final VoidCallback? onSync;
  final VoidCallback? onNotifications;

  const HomeAppBarWidget({
    super.key,
    required this.userName,
    this.isSyncing = false,
    this.onSync,
    this.onNotifications,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final greeting = _getGreeting(l10n);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: AppTypography.bodySmall,
          ),
          Text(
            userName,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (isSyncing)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: onSync,
            tooltip: l10n?.translate(LocaleKeys.sync) ?? 'Sync',
          ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onNotifications,
          tooltip: l10n?.translate(LocaleKeys.notifications) ?? 'Notifications',
        ),
      ],
    );
  }

  String _getGreeting(AppLocalizations? l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n?.translate(LocaleKeys.goodMorning) ?? 'Good Morning';
    } else if (hour < 17) {
      return l10n?.translate(LocaleKeys.goodAfternoon) ?? 'Good Afternoon';
    } else {
      return l10n?.translate(LocaleKeys.goodEvening) ?? 'Good Evening';
    }
  }
}



