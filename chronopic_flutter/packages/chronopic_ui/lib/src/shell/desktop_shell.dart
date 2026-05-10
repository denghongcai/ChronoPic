part of '../chronopic_home.dart';

final class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.activePage,
    required this.child,
    required this.favoriteOnly,
    required this.immersive,
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
    required this.status,
  });

  final _DesktopPage activePage;
  final Widget child;
  final bool favoriteOnly;
  final bool immersive;
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
            child: child,
            favoriteOnly: favoriteOnly,
            labels: labels,
            notificationCount: notificationCount,
            onAllPhotos: onAllPhotos,
            onFavorites: onFavorites,
            onMemories: onMemories,
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
    required this.child,
    required this.favoriteOnly,
    required this.labels,
    required this.notificationCount,
    required this.onAllPhotos,
    required this.onFavorites,
    required this.onMemories,
    required this.onNotifications,
    required this.onSettings,
    required this.status,
  });

  final _DesktopPage activePage;
  final Widget child;
  final bool favoriteOnly;
  final UiStrings labels;
  final int notificationCount;
  final VoidCallback onAllPhotos;
  final VoidCallback onFavorites;
  final VoidCallback onMemories;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _MobileNavItem(
                    active: activePage == _DesktopPage.home && !favoriteOnly,
                    icon: Icons.photo_library_outlined,
                    keyName: 'all-photos-nav',
                    label: labels.allPhotos,
                    onPressed: onAllPhotos,
                  ),
                  _MobileNavItem(
                    active: favoriteOnly,
                    icon: Icons.star_border,
                    keyName: 'favorites-nav',
                    label: labels.favorites,
                    onPressed: onFavorites,
                  ),
                  _MobileNavItem(
                    active: activePage == _DesktopPage.memories,
                    icon: Icons.auto_stories_outlined,
                    keyName: 'memories-nav',
                    label: labels.memories,
                    onPressed: onMemories,
                  ),
                  _MobileNavItem(
                    active: activePage == _DesktopPage.settings,
                    icon: Icons.settings_outlined,
                    keyName: 'settings-nav',
                    label: labels.settings,
                    onPressed: onSettings,
                  ),
                ],
              ),
            ),
            if (_showStatusBanner(labels, status))
              _StatusBanner(labels: labels, status: status),
            Expanded(
              child: _ContentViewport(
                child: child,
                horizontalPadding: 16,
                maxWidth: 620,
                ownsScroll: child is HomePage,
                verticalPadding: 16,
              ),
            ),
          ],
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
    this.verticalPadding = 24,
  });

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
            ownsScroll ? 0 : verticalPadding,
          ),
          child: content,
        );
      },
    );
  }
}

final class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
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
    final foreground = active ? Colors.white : Colors.grey.shade800;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextButton.icon(
        key: Key(keyName),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: active ? Colors.grey.shade900 : Colors.grey.shade100,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
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
