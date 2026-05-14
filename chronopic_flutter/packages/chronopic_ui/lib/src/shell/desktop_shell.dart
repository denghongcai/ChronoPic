part of '../chronopic_home.dart';

final class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.activePage,
    required this.browseMode,
    required this.child,
    required this.favoriteOnly,
    required this.immersive,
    required this.labels,
    required this.memories,
    required this.notificationCount,
    required this.onAllPhotos,
    required this.onBrowseModeChanged,
    required this.onFavorites,
    required this.onMemories,
    required this.onMemorySelected,
    required this.onNotifications,
    required this.onSettings,
    required this.selectedMemoryId,
    required this.status,
  });

  final _DesktopPage activePage;
  final BrowseMode browseMode;
  final Widget child;
  final bool favoriteOnly;
  final bool immersive;
  final UiStrings labels;
  final List<Memory> memories;
  final int notificationCount;
  final VoidCallback onAllPhotos;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final VoidCallback onFavorites;
  final VoidCallback onMemories;
  final ValueChanged<String> onMemorySelected;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final String? selectedMemoryId;
  final String status;

  @override
  Widget build(BuildContext context) {
    if (immersive) {
      return Scaffold(
        backgroundColor: Colors.grey.shade700,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: child),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return _MobileShell(
            activePage: activePage,
            browseMode: browseMode,
            child: child,
            favoriteOnly: favoriteOnly,
            labels: labels,
            notificationCount: notificationCount,
            onBrowseModeChanged: onBrowseModeChanged,
            onNotifications: onNotifications,
            onSettings: onSettings,
            status: status,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _DesktopSidebar(
                activePage: activePage,
                favoriteOnly: favoriteOnly,
                labels: labels,
                memories: memories,
                notificationCount: notificationCount,
                onAllPhotos: onAllPhotos,
                onFavorites: onFavorites,
                onMemories: onMemories,
                onMemorySelected: onMemorySelected,
                onNotifications: onNotifications,
                onSettings: onSettings,
                selectedMemoryId: selectedMemoryId,
              ),
              Expanded(
                child: Column(
                  children: [
                    if (_showStatusBanner(labels, status))
                      _StatusBanner(labels: labels, status: status),
                    Expanded(
                      child: _ContentViewport(
                        child: child,
                        horizontalPadding: constraints.maxWidth >= 1440
                            ? 28
                            : 18,
                        maxWidth: 1920,
                        ownsScroll: child is HomePage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.activePage,
    required this.browseMode,
    required this.child,
    required this.favoriteOnly,
    required this.labels,
    required this.notificationCount,
    required this.onBrowseModeChanged,
    required this.onNotifications,
    required this.onSettings,
    required this.status,
  });

  final _DesktopPage activePage;
  final BrowseMode browseMode;
  final Widget child;
  final bool favoriteOnly;
  final UiStrings labels;
  final int notificationCount;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChronoPicTheme.mobileBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels.appTitle,
                          key: const Key('app-title'),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          labels.librarySubtitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SidebarNotificationButton(
                    active: activePage == _DesktopPage.notifications,
                    badge: notificationCount,
                    onPressed: onNotifications,
                  ),
                ],
              ),
            ),
            if (_showStatusBanner(labels, status))
              _StatusBanner(labels: labels, status: status),
            Expanded(
              child: _ContentViewport(
                child: child,
                bottomPadding: 18,
                horizontalPadding: 14,
                maxWidth: 620,
                ownsScroll: child is HomePage,
                verticalPadding: 8,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _MobileBottomNavigation(
          activePage: activePage,
          browseMode: browseMode,
          labels: labels,
          onBrowseModeChanged: onBrowseModeChanged,
          onSettings: onSettings,
        ),
      ),
    );
  }
}

final class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.activePage,
    required this.browseMode,
    required this.labels,
    required this.onBrowseModeChanged,
    required this.onSettings,
  });

  final _DesktopPage activePage;
  final BrowseMode browseMode;
  final UiStrings labels;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final homeActive = activePage == _DesktopPage.home;
    return DecoratedBox(
      key: const Key('mobile-bottom-navigation'),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            Expanded(
              child: _MobileBottomNavItem(
                active: homeActive && browseMode == BrowseMode.waterfall,
                icon: Icons.grid_view_outlined,
                keyName: 'mobile-bottom-waterfall',
                label: _localized(labels, 'Waterfall', '瀑布流'),
                onPressed: () => onBrowseModeChanged(BrowseMode.waterfall),
              ),
            ),
            Expanded(
              child: _MobileBottomNavItem(
                active: homeActive && browseMode == BrowseMode.map,
                icon: Icons.map_outlined,
                keyName: 'mobile-bottom-map',
                label: labels.map,
                onPressed: () => onBrowseModeChanged(BrowseMode.map),
              ),
            ),
            Expanded(
              child: _MobileBottomNavItem(
                active: homeActive && browseMode == BrowseMode.timeline,
                icon: Icons.calendar_month_outlined,
                keyName: 'mobile-bottom-timeline',
                label: labels.timeline,
                onPressed: () => onBrowseModeChanged(BrowseMode.timeline),
              ),
            ),
            Expanded(
              child: _MobileBottomNavItem(
                active: activePage == _DesktopPage.settings,
                icon: Icons.settings_outlined,
                keyName: 'mobile-bottom-settings',
                label: labels.settings,
                onPressed: onSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MobileBottomNavItem extends StatelessWidget {
  const _MobileBottomNavItem({
    required this.active,
    required this.icon,
    required this.keyName,
    required this.label,
    required this.onPressed,
  });

  final bool active;
  final IconData icon;
  final String keyName;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.black : Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: active ? ChronoPicTheme.mobileAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key(keyName),
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 21),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ContentViewport extends StatelessWidget {
  const _ContentViewport({
    required this.child,
    required this.horizontalPadding,
    required this.maxWidth,
    required this.ownsScroll,
    this.bottomPadding,
    this.verticalPadding = 24,
  });

  final double? bottomPadding;
  final Widget child;
  final double horizontalPadding;
  final double maxWidth;
  final bool ownsScroll;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final framedChild = Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(width: double.infinity, child: child),
          ),
        );
        final content = ownsScroll
            ? framedChild
            : SingleChildScrollView(child: framedChild);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            bottomPadding ?? (ownsScroll ? 0 : verticalPadding),
          ),
          child: content,
        );
      },
    );
  }
}

final class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.activePage,
    required this.favoriteOnly,
    required this.labels,
    required this.memories,
    required this.notificationCount,
    required this.onAllPhotos,
    required this.onFavorites,
    required this.onMemories,
    required this.onMemorySelected,
    required this.onNotifications,
    required this.onSettings,
    required this.selectedMemoryId,
  });

  final _DesktopPage activePage;
  final bool favoriteOnly;
  final UiStrings labels;
  final List<Memory> memories;
  final int notificationCount;
  final VoidCallback onAllPhotos;
  final VoidCallback onFavorites;
  final VoidCallback onMemories;
  final ValueChanged<String> onMemorySelected;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final String? selectedMemoryId;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('desktop-sidebar'),
      width: ChronoPicTheme.sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels.appTitle,
                          key: const Key('app-title'),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          labels.librarySubtitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SidebarNotificationButton(
                    active: activePage == _DesktopPage.notifications,
                    badge: notificationCount,
                    onPressed: onNotifications,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SidebarLabel(labels.librarySection),
              _SidebarItem(
                active: activePage == _DesktopPage.home && !favoriteOnly,
                icon: Icons.photo_library_outlined,
                keyName: 'all-photos-nav',
                label: labels.allPhotos,
                onPressed: onAllPhotos,
              ),
              _SidebarItem(
                active: favoriteOnly,
                icon: Icons.star_border,
                keyName: 'favorites-nav',
                label: labels.favorites,
                onPressed: onFavorites,
              ),
              _SidebarItem(
                active: false,
                icon: Icons.schedule_outlined,
                keyName: 'recent-nav',
                label: _localized(labels, 'Recent', '最近'),
                onPressed: onAllPhotos,
              ),
              _SidebarItem(
                active: activePage == _DesktopPage.settings,
                icon: Icons.settings_outlined,
                keyName: 'settings-nav',
                label: labels.settings,
                onPressed: onSettings,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _SidebarLabel(labels.memories)),
                  IconButton(
                    tooltip: labels.createMemory,
                    onPressed: onMemories,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              _SidebarItem(
                active: activePage == _DesktopPage.memories,
                icon: Icons.auto_stories_outlined,
                keyName: 'memories-nav',
                label: labels.memories,
                onPressed: onMemories,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 6),
                  children: [
                    for (final memory in memories)
                      _SidebarItem(
                        active: selectedMemoryId == memory.id,
                        icon: Icons.bookmark_border,
                        keyName: 'memory-nav-${memory.id}',
                        label: memory.name,
                        onPressed: () => onMemorySelected(memory.id),
                      ),
                  ],
                ),
              ),
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('create-memory-sidebar-button'),
                  onPressed: onMemories,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(labels.createMemory),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade200),
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SidebarNotificationButton extends StatelessWidget {
  const _SidebarNotificationButton({
    required this.active,
    required this.badge,
    required this.onPressed,
  });

  final bool active;
  final int badge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: active ? Colors.black : Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          child: InkWell(
            key: const Key('notifications-nav'),
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(
                Icons.notifications_none,
                color: active ? Colors.white : Colors.grey.shade700,
                size: 20,
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -3,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.pink.shade500,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge > 9 ? '9+' : '$badge',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

final class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.active,
    required this.icon,
    required this.keyName,
    required this.label,
    required this.onPressed,
  });

  final bool active;
  final IconData icon;
  final String keyName;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = active ? Colors.grey.shade900 : Colors.transparent;
    final foreground = active ? Colors.white : Colors.grey.shade800;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: Key(keyName),
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.labels, required this.status});

  final UiStrings labels;
  final String status;

  @override
  Widget build(BuildContext context) {
    final visibleStatus = status == uiStrings[UiLocale.en]!.scanIdle
        ? labels.scanIdle
        : status;
    return Container(
      key: const Key('scan-status'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: _statusColor(status)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              visibleStatus,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

bool _showStatusBanner(UiStrings labels, String status) {
  return status != labels.scanIdle &&
      status != uiStrings[UiLocale.en]!.scanIdle;
}
