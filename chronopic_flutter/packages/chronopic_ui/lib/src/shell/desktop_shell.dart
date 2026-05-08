part of '../chronopic_home.dart';

final class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.activePage,
    required this.child,
    required this.favoriteOnly,
    required this.labels,
    required this.locale,
    required this.memories,
    required this.notificationCount,
    required this.onAllPhotos,
    required this.onFavorites,
    required this.onLocaleChanged,
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
  final UiStrings labels;
  final UiLocale locale;
  final List<Memory> memories;
  final int notificationCount;
  final VoidCallback onAllPhotos;
  final VoidCallback onFavorites;
  final ValueChanged<UiLocale> onLocaleChanged;
  final VoidCallback onMemories;
  final ValueChanged<String> onMemorySelected;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final String? selectedMemoryId;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            activePage: activePage,
            favoriteOnly: favoriteOnly,
            labels: labels,
            locale: locale,
            memories: memories,
            notificationCount: notificationCount,
            onAllPhotos: onAllPhotos,
            onFavorites: onFavorites,
            onLocaleChanged: onLocaleChanged,
            onMemories: onMemories,
            onMemorySelected: onMemorySelected,
            onNotifications: onNotifications,
            onSettings: onSettings,
            selectedMemoryId: selectedMemoryId,
          ),
          Expanded(
            child: Column(
              children: [
                _StatusBanner(status: status),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1560),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.activePage,
    required this.favoriteOnly,
    required this.labels,
    required this.locale,
    required this.memories,
    required this.notificationCount,
    required this.onAllPhotos,
    required this.onFavorites,
    required this.onLocaleChanged,
    required this.onMemories,
    required this.onMemorySelected,
    required this.onNotifications,
    required this.onSettings,
    required this.selectedMemoryId,
  });

  final _DesktopPage activePage;
  final bool favoriteOnly;
  final UiStrings labels;
  final UiLocale locale;
  final List<Memory> memories;
  final int notificationCount;
  final VoidCallback onAllPhotos;
  final VoidCallback onFavorites;
  final ValueChanged<UiLocale> onLocaleChanged;
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
                          'Local-first memory library',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SidebarLabel('Library'),
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
                active: activePage == _DesktopPage.notifications,
                badge: notificationCount,
                icon: Icons.notifications_none,
                keyName: 'notifications-nav',
                label: labels.notifications,
                onPressed: onNotifications,
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
              const Divider(),
              LocaleSelector(
                labels: labels,
                locale: locale,
                onChanged: onLocaleChanged,
              ),
            ],
          ),
        ),
      ),
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
    this.badge = 0,
  });

  final bool active;
  final int badge;
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
                if (badge > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
  const _StatusBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
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
              status,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
