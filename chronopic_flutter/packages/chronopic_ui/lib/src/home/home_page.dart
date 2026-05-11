part of '../chronopic_home.dart';

final class HomePage extends StatelessWidget {
  const HomePage({
    required this.activeFilterLabels,
    required this.aiStatus,
    required this.browseMode,
    required this.catalogPhotoCount,
    required this.captionController,
    required this.dateController,
    required this.detailFirst,
    required this.favoriteOnly,
    required this.filterPanelOpen,
    required this.filteredPhotoCount,
    required this.fromDateController,
    required this.gpsOnly,
    required this.hasMorePhotos,
    required this.labels,
    required this.libraryPathController,
    required this.entryMode,
    required this.memories,
    required this.onAddLibrary,
    required this.onAddToMemory,
    required this.onAllPhotos,
    required this.onAiStatusChanged,
    required this.onBrowseModeChanged,
    required this.onChooseLibraryFolder,
    required this.onChoosePhotos,
    required this.onCloseFocusedDetail,
    required this.onClearFilters,
    required this.onCreateFirstMemory,
    required this.onFilterApply,
    required this.onFilterPanelToggle,
    required this.onGpsOnlyChanged,
    required this.onLoadMorePhotos,
    required this.onOpenGallery,
    required this.onOpenDetailFor,
    required this.onOpenMemories,
    required this.onOpenSettings,
    required this.onFavorites,
    required this.onRollback,
    required this.onSaveCaption,
    required this.onSaveDatetime,
    required this.onSaveTags,
    required this.onScanLibrary,
    required this.onScrollNearEnd,
    required this.onSearchChanged,
    required this.onSelectMemory,
    required this.onSelectPhoto,
    required this.onSortByChanged,
    required this.onSortDirectionChanged,
    required this.onToggleFavorite,
    required this.photos,
    required this.query,
    required this.scanning,
    required this.scrollController,
    required this.selected,
    required this.sortBy,
    required this.sortDirection,
    required this.status,
    required this.tagController,
    required this.tagsController,
    required this.thumbnailLoader,
    required this.timeController,
    required this.toDateController,
  });

  final List<String> activeFilterLabels;
  final AiPipelineStatus? aiStatus;
  final BrowseMode browseMode;
  final int catalogPhotoCount;
  final TextEditingController captionController;
  final TextEditingController dateController;
  final bool detailFirst;
  final bool favoriteOnly;
  final bool filterPanelOpen;
  final int filteredPhotoCount;
  final TextEditingController fromDateController;
  final bool gpsOnly;
  final bool hasMorePhotos;
  final UiStrings labels;
  final TextEditingController libraryPathController;
  final ChronoPicEntryMode entryMode;
  final List<Memory> memories;
  final VoidCallback onAddLibrary;
  final VoidCallback onAddToMemory;
  final VoidCallback onAllPhotos;
  final ValueChanged<AiPipelineStatus?> onAiStatusChanged;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final VoidCallback onChooseLibraryFolder;
  final VoidCallback onChoosePhotos;
  final VoidCallback onCloseFocusedDetail;
  final VoidCallback onClearFilters;
  final VoidCallback onCreateFirstMemory;
  final VoidCallback onFilterApply;
  final VoidCallback onFilterPanelToggle;
  final ValueChanged<bool> onGpsOnlyChanged;
  final VoidCallback onLoadMorePhotos;
  final ValueChanged<BuildContext> onOpenGallery;
  final ValueChanged<PhotoRecord> onOpenDetailFor;
  final VoidCallback onOpenMemories;
  final VoidCallback onOpenSettings;
  final VoidCallback onFavorites;
  final VoidCallback onRollback;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveDatetime;
  final VoidCallback onSaveTags;
  final VoidCallback onScanLibrary;
  final VoidCallback onScrollNearEnd;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSelectMemory;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final ValueChanged<PhotoSortBy> onSortByChanged;
  final ValueChanged<SortDirection> onSortDirectionChanged;
  final VoidCallback onToggleFavorite;
  final List<PhotoRecord> photos;
  final String query;
  final bool scanning;
  final ScrollController scrollController;
  final PhotoRecord? selected;
  final PhotoSortBy sortBy;
  final SortDirection sortDirection;
  final String status;
  final TextEditingController tagController;
  final TextEditingController tagsController;
  final PhotoThumbnailLoader? thumbnailLoader;
  final TextEditingController timeController;
  final TextEditingController toDateController;

  @override
  Widget build(BuildContext context) {
    final mobileLayout = MediaQuery.sizeOf(context).width < 720;
    final hasPhotos = photos.isNotEmpty;
    final hasExpandedFilterState =
        query.trim().isNotEmpty ||
        gpsOnly ||
        aiStatus != null ||
        tagController.text.trim().isNotEmpty ||
        fromDateController.text.trim().isNotEmpty ||
        toDateController.text.trim().isNotEmpty ||
        sortBy != PhotoSortBy.datetime ||
        sortDirection != SortDirection.desc;
    final hasBrowseContext =
        hasExpandedFilterState || favoriteOnly || activeFilterLabels.isNotEmpty;
    final showFirstRun = !hasPhotos && !hasBrowseContext;
    final showFilterControls = hasPhotos || hasExpandedFilterState;
    void openMobileFilterSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              key: const Key('mobile-filter-sheet'),
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels.searchAndFilters,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    FilterToolbar(
                      aiStatus: aiStatus,
                      fromDateController: fromDateController,
                      gpsOnly: gpsOnly,
                      labels: labels,
                      onAiStatusChanged: onAiStatusChanged,
                      onApply: () {
                        onFilterApply();
                        Navigator.of(sheetContext).pop();
                      },
                      onClear: () {
                        onClearFilters();
                        Navigator.of(sheetContext).pop();
                      },
                      onGpsOnlyChanged: onGpsOnlyChanged,
                      onSortByChanged: onSortByChanged,
                      onSortDirectionChanged: onSortDirectionChanged,
                      sortBy: sortBy,
                      sortDirection: sortDirection,
                      tagController: tagController,
                      toDateController: toDateController,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    Widget withThumbnailLoader(Widget child) {
      return _PhotoThumbnailLoaderScope(loader: thumbnailLoader, child: child);
    }

    if (detailFirst && selected != null) {
      return withThumbnailLoader(
        SizedBox(
          key: const Key('home-page'),
          width: double.infinity,
          child: DetailSurface(
            captionController: captionController,
            dateController: dateController,
            focusedMode: true,
            labels: labels,
            onAddToMemory: onAddToMemory,
            onCloseFocused: onCloseFocusedDetail,
            onOpenGallery: onOpenGallery,
            onRollback: onRollback,
            onSaveCaption: onSaveCaption,
            onSaveDatetime: onSaveDatetime,
            onSaveTags: onSaveTags,
            onSelectPhoto: onSelectPhoto,
            onToggleFavorite: onToggleFavorite,
            photos: photos,
            record: selected,
            status: status,
            tagsController: tagsController,
            timeController: timeController,
          ),
        ),
      );
    }
    return withThumbnailLoader(
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels > 0 &&
              notification.metrics.extentAfter < 5000) {
            onScrollNearEnd();
          }
          return false;
        },
        child: CustomScrollView(
          key: const Key('home-page'),
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mobileLayout && !showFirstRun) ...[
                    _MobileHomeDashboard(
                      catalogPhotoCount: catalogPhotoCount,
                      favoriteOnly: favoriteOnly,
                      labels: labels,
                      memories: memories,
                      onAllPhotos: onAllPhotos,
                      onFavorites: onFavorites,
                      onOpenMemories: onOpenMemories,
                      onOpenSettings: onOpenSettings,
                      onSearchChanged: onSearchChanged,
                      query: query,
                      scanning: scanning,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (showFirstRun) ...[
                    FirstRunPanel(
                      entryMode: entryMode,
                      labels: labels,
                      onAddFolder: onChooseLibraryFolder,
                      onChoosePhotos: onChoosePhotos,
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (mobileLayout && showFirstRun) ...[
                    _MobileHomeDashboard(
                      catalogPhotoCount: catalogPhotoCount,
                      favoriteOnly: favoriteOnly,
                      labels: labels,
                      memories: memories,
                      onAllPhotos: onAllPhotos,
                      onFavorites: onFavorites,
                      onOpenMemories: onOpenMemories,
                      onOpenSettings: onOpenSettings,
                      onSearchChanged: onSearchChanged,
                      query: query,
                      scanning: scanning,
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (!mobileLayout)
                    MemoryHighlightsPanel(
                      labels: labels,
                      memories: memories,
                      onCreateFirstMemory: onCreateFirstMemory,
                    ),
                  if (hasPhotos && memories.isEmpty)
                    GuidedNextStepPanel(labels: labels),
                  const SizedBox(height: 18),
                  if (hasPhotos && browseMode == BrowseMode.waterfall)
                    const SizedBox(
                      key: ValueKey<String>('mobile-browse-surface'),
                      height: 0,
                    ),
                  _BrowseToolbar(
                    browseMode: browseMode,
                    filterPanelOpen: filterPanelOpen,
                    labels: labels,
                    onBrowseModeChanged: onBrowseModeChanged,
                    onFilterPanelToggle: mobileLayout
                        ? openMobileFilterSheet
                        : onFilterPanelToggle,
                    onSearchChanged: onSearchChanged,
                    resultCount: filteredPhotoCount,
                    searchQuery: query,
                    visibleCount: photos.length,
                    compactMobile: mobileLayout,
                  ),
                  if (mobileLayout && hasExpandedFilterState)
                    ActiveFilterSummary(
                      filterLabels: activeFilterLabels,
                      labels: labels,
                    ),
                  if (hasPhotos) ...[
                    const SizedBox(height: 10),
                    _DiscoveryLensChips(
                      labels: labels,
                      memories: memories,
                      onBrowseModeChanged: onBrowseModeChanged,
                      onSelectMemory: onSelectMemory,
                      photos: photos,
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (showFilterControls &&
                      !mobileLayout &&
                      (filterPanelOpen || hasExpandedFilterState)) ...[
                    FilterToolbar(
                      aiStatus: aiStatus,
                      fromDateController: fromDateController,
                      gpsOnly: gpsOnly,
                      labels: labels,
                      onAiStatusChanged: onAiStatusChanged,
                      onApply: onFilterApply,
                      onClear: onClearFilters,
                      onGpsOnlyChanged: onGpsOnlyChanged,
                      onSortByChanged: onSortByChanged,
                      onSortDirectionChanged: onSortDirectionChanged,
                      sortBy: sortBy,
                      sortDirection: sortDirection,
                      tagController: tagController,
                      toDateController: toDateController,
                    ),
                    ActiveFilterSummary(
                      filterLabels: hasExpandedFilterState
                          ? activeFilterLabels
                          : const [],
                      labels: labels,
                    ),
                  ],
                  if (detailFirst && selected != null) ...[
                    const SizedBox(height: 14),
                    DetailSurface(
                      captionController: captionController,
                      dateController: dateController,
                      labels: labels,
                      onAddToMemory: onAddToMemory,
                      onCloseFocused: onCloseFocusedDetail,
                      onOpenGallery: onOpenGallery,
                      onRollback: onRollback,
                      onSaveCaption: onSaveCaption,
                      onSaveDatetime: onSaveDatetime,
                      onSaveTags: onSaveTags,
                      onSelectPhoto: onSelectPhoto,
                      onToggleFavorite: onToggleFavorite,
                      photos: photos,
                      record: selected,
                      tagsController: tagsController,
                      timeController: timeController,
                    ),
                  ],
                  if (!detailFirst &&
                      selected != null &&
                      browseMode == BrowseMode.waterfall) ...[
                    const SizedBox(height: 14),
                    _BrowseSelectedPhotoBanner(
                      labels: labels,
                      record: selected!,
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
              ),
            ),
            if (browseMode == BrowseMode.waterfall)
              PhotoGridSliver(
                labels: labels,
                onOpenDetail: onOpenDetailFor,
                onSelectPhoto: onSelectPhoto,
                photos: photos,
                selected: selected,
              )
            else
              SliverToBoxAdapter(
                child: BrowseSurface(
                  labels: labels,
                  mode: browseMode,
                  onOpenDetail: onOpenDetailFor,
                  onSelectPhoto: onSelectPhoto,
                  photos: photos,
                  selected: selected,
                ),
              ),
            if (hasMorePhotos && browseMode == BrowseMode.waterfall)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: OutlinedButton.icon(
                      key: const Key('load-more-photos-button'),
                      onPressed: onLoadMorePhotos,
                      icon: const Icon(Icons.expand_more),
                      label: Text(_localized(labels, 'Load more', '加载更多')),
                    ),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
          ],
        ),
      ),
    );
  }
}

final class _BrowseSelectedPhotoBanner extends StatelessWidget {
  const _BrowseSelectedPhotoBanner({
    required this.labels,
    required this.record,
  });

  final UiStrings labels;
  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('browse-selected-photo-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.lightBlue.shade200),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.lightBlue.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _localized(labels, 'SELECTED PHOTO', '已选照片'),
                style: TextStyle(
                  color: Colors.lightBlue.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          Text(
            _localized(
              labels,
              'This photo is not saved to any memory yet.',
              '这张照片还没有保存到任何记忆。',
            ),
            style: TextStyle(color: Colors.lightBlue.shade900),
          ),
        ],
      ),
    );
  }
}

final class _MobileHomeDashboard extends StatelessWidget {
  const _MobileHomeDashboard({
    required this.catalogPhotoCount,
    required this.favoriteOnly,
    required this.labels,
    required this.memories,
    required this.onAllPhotos,
    required this.onFavorites,
    required this.onOpenMemories,
    required this.onOpenSettings,
    required this.onSearchChanged,
    required this.query,
    required this.scanning,
  });

  final int catalogPhotoCount;
  final bool favoriteOnly;
  final UiStrings labels;
  final List<Memory> memories;
  final VoidCallback onAllPhotos;
  final VoidCallback onFavorites;
  final VoidCallback onOpenMemories;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onSearchChanged;
  final String query;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final latestMemory = memories.isEmpty ? null : memories.first;
    return Column(
      key: const Key('mobile-home-dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('mobile-dashboard-search'),
          initialValue: query,
          decoration: InputDecoration(
            hintText: labels.searchAndFilters,
            prefixIcon: const Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 92,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MobileDashboardShortcut(
                  active: !favoriteOnly,
                  icon: Icons.photo_library_outlined,
                  keyName: 'mobile-shortcut-all',
                  label: labels.allPhotos,
                  onPressed: onAllPhotos,
                  value: _localized(
                    labels,
                    '$catalogPhotoCount indexed',
                    '$catalogPhotoCount 个已索引',
                  ),
                ),
                const SizedBox(width: 10),
                _MobileDashboardShortcut(
                  active: favoriteOnly,
                  icon: Icons.star_border,
                  keyName: 'mobile-shortcut-favorites',
                  label: labels.favorites,
                  onPressed: onFavorites,
                  value: _localized(labels, 'Saved picks', '收藏精选'),
                ),
                const SizedBox(width: 10),
                _MobileDashboardShortcut(
                  active: false,
                  icon: Icons.auto_stories_outlined,
                  keyName: 'mobile-shortcut-memories',
                  label: labels.memories,
                  onPressed: onOpenMemories,
                  value:
                      latestMemory?.name ??
                      _localized(labels, 'Create story', '创建故事'),
                ),
                const SizedBox(width: 10),
                _MobileDashboardShortcut(
                  active: false,
                  icon: Icons.tune_outlined,
                  keyName: 'mobile-shortcut-settings',
                  label: labels.settings,
                  onPressed: onOpenSettings,
                  value: _localized(labels, 'Library tools', '资料库工具'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          key: const Key('mobile-scan-progress-card'),
          decoration: BoxDecoration(
            color: ChronoPicTheme.mobileSurface,
            borderRadius: BorderRadius.circular(
              ChronoPicTheme.mobileCardRadius,
            ),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scanning
                        ? Colors.orange.shade100
                        : Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    scanning ? Icons.sync : Icons.check_circle_outline,
                    color: scanning
                        ? Colors.orange.shade800
                        : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scanning
                            ? _localized(labels, 'Scanning library', '正在扫描图库')
                            : _localized(labels, 'Library ready', '图库就绪'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _localized(
                          labels,
                          '$catalogPhotoCount indexed locally',
                          '$catalogPhotoCount 个本地索引',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _MobileDashboardShortcut extends StatelessWidget {
  const _MobileDashboardShortcut({
    required this.active,
    required this.icon,
    required this.keyName,
    required this.label,
    required this.onPressed,
    required this.value,
  });

  final bool active;
  final IconData icon;
  final String keyName;
  final String label;
  final VoidCallback onPressed;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? ChronoPicTheme.mobileAccent : Colors.white,
      borderRadius: BorderRadius.circular(ChronoPicTheme.mobileCardRadius),
      child: InkWell(
        key: Key(keyName),
        borderRadius: BorderRadius.circular(ChronoPicTheme.mobileCardRadius),
        onTap: onPressed,
        child: SizedBox(
          width: 132,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: Colors.grey.shade900),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class FirstRunPanel extends StatelessWidget {
  const FirstRunPanel({
    required this.entryMode,
    required this.labels,
    required this.onAddFolder,
    required this.onChoosePhotos,
  });

  final ChronoPicEntryMode entryMode;
  final UiStrings labels;
  final VoidCallback onAddFolder;
  final VoidCallback onChoosePhotos;

  @override
  Widget build(BuildContext context) {
    final mobile = entryMode == ChronoPicEntryMode.mobilePhotoLibrary;
    return _Panel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChronoPicTheme.panelRadius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actions = KeyedSubtree(
              key: mobile
                  ? const Key('mobile-entry-actions')
                  : const Key('desktop-entry-actions'),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (mobile)
                    KeyedSubtree(
                      key: const ValueKey<String>('mobile-choose-photos'),
                      child: KeyedSubtree(
                        key: const Key('choose-photo-library-button'),
                        child: FilledButton.icon(
                          key: const Key('choose-photos-button'),
                          onPressed: onChoosePhotos,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _localized(labels, 'Choose Photos', '选择照片'),
                          ),
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      key: const Key('choose-library-folder-button'),
                      onPressed: onAddFolder,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: Text(_localized(labels, 'Add Folder', '添加文件夹')),
                    ),
                ],
              ),
            );
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(_localized(labels, 'First run', '首次使用')),
                  side: BorderSide(color: Colors.lightBlue.shade100),
                  backgroundColor: Colors.lightBlue.shade50,
                  labelStyle: TextStyle(
                    color: Colors.lightBlue.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  mobile
                      ? _localized(
                          labels,
                          'Start with your photo library',
                          '从你的照片图库开始',
                        )
                      : _localized(
                          labels,
                          'Start with a local folder',
                          '从本地文件夹开始',
                        ),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  mobile
                      ? _localized(
                          labels,
                          'ChronoPic indexes the photos you authorize, respects limited-library access, and keeps the catalog metadata on this device.',
                          'ChronoPic 会索引你授权的照片，尊重有限图库访问，并把目录元数据保存在这台设备上。',
                        )
                      : _localized(
                          labels,
                          'ChronoPic builds its library from folders you choose. Add one photo folder to index local media, generate thumbnails, and keep the catalog on this device.',
                          'ChronoPic 会从你选择的文件夹建立资料库。添加一个照片文件夹即可索引本地媒体、生成缩略图，并把目录保存在这台设备上。',
                        ),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                actions,
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (mobile) ...[
                      _SmallBadge(_localized(labels, 'Photo library', '照片图库')),
                      _SmallBadge(
                        _localized(labels, 'Limited access aware', '支持有限访问'),
                      ),
                      _SmallBadge(_localized(labels, 'Local catalog', '本地目录')),
                    ] else ...[
                      _SmallBadge(_localized(labels, 'Local library', '本地资料库')),
                      _SmallBadge(_localized(labels, 'Manual scan', '手动扫描')),
                      _SmallBadge(_localized(labels, 'Optional AI', '可选 AI')),
                    ],
                  ],
                ),
              ],
            );

            if (constraints.maxWidth < 680) {
              return Padding(padding: const EdgeInsets.all(20), child: copy);
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: copy,
                    ),
                  ),
                  SizedBox(
                    width: 340,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.grey.shade900),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(top: 34),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(top: 58),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

final class MemoryHighlightsPanel extends StatelessWidget {
  const MemoryHighlightsPanel({
    required this.labels,
    required this.memories,
    required this.onCreateFirstMemory,
  });

  final UiStrings labels;
  final List<Memory> memories;
  final VoidCallback onCreateFirstMemory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                labels.discover,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text('•', style: TextStyle(color: Colors.grey.shade400)),
              Text(
                labels.highlights,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                labels.recentMemories,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Chip(label: Text('${memories.length}')),
            ],
          ),
          const SizedBox(height: 18),
          if (memories.isEmpty)
            _Panel(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 210),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localized(labels, 'No recent memories yet', '还没有最近记忆'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _localized(
                          labels,
                          'Create a memory to pin a cover image, write a description, and keep a reusable story outside the gallery filter flow.',
                          '创建记忆后，可以固定封面、编写描述，并在图库筛选之外保存可复用的故事。',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton(
                        key: const Key('create-first-memory-button'),
                        onPressed: onCreateFirstMemory,
                        child: Text(
                          _localized(labels, 'Create First Memory', '创建第一个记忆'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final memory in memories.take(2))
                  SizedBox(
                    width: 360,
                    child: _MemoryHighlightCard(labels: labels, memory: memory),
                  ),
                SizedBox(
                  width: 300,
                  child: _Panel(
                    child: SizedBox(
                      height: 190,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              labels.newMemory,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              labels.newMemoryDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

final class _MemoryHighlightCard extends StatelessWidget {
  const _MemoryHighlightCard({required this.labels, required this.memory});

  final UiStrings labels;
  final Memory memory;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ChronoPicTheme.panelRadius),
                child: _MemoryCover(memory),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _SmallBadge(_photoCountLabel(labels, memory.photoCount)),
                      if (memory.coverPhotoId != null)
                        _SmallBadge(labels.customCover),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    memory.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    memory.description ?? labels.noDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label.toUpperCase()),
      labelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

final class GuidedNextStepPanel extends StatelessWidget {
  const GuidedNextStepPanel({required this.labels});

  final UiStrings labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: _Panel(
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _localized(
                  labels,
                  'Create a memory from selected photos, or use filters to shape a story before saving it.',
                  '从选中的照片创建记忆，或先用筛选塑造故事再保存。',
                ),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            Text(
              labels.memories,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

final class LibraryToolbar extends StatelessWidget {
  const LibraryToolbar({
    required this.labels,
    required this.libraryPathController,
    required this.onAddLibrary,
    required this.onChooseLibraryFolder,
    required this.onScanLibrary,
    required this.onSearchChanged,
    required this.scanning,
  });

  final UiStrings labels;
  final TextEditingController libraryPathController;
  final VoidCallback onAddLibrary;
  final VoidCallback onChooseLibraryFolder;
  final VoidCallback onScanLibrary;
  final ValueChanged<String> onSearchChanged;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              key: const Key('library-path-field'),
              controller: libraryPathController,
              decoration: InputDecoration(labelText: labels.libraryFolderPath),
            ),
          ),
          FilledButton.icon(
            key: const Key('choose-library-folder-button'),
            onPressed: onChooseLibraryFolder,
            icon: const Icon(Icons.folder_open),
            label: Text(_localized(labels, 'Add Folder', '添加文件夹')),
          ),
          OutlinedButton.icon(
            key: const Key('add-library-button'),
            onPressed: onAddLibrary,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: Text(labels.addLibrary),
          ),
          OutlinedButton.icon(
            key: const Key('scan-library-button'),
            onPressed: scanning ? null : onScanLibrary,
            icon: const Icon(Icons.sync),
            label: Text(labels.scanLibrary),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              key: const Key('search-field'),
              decoration: InputDecoration(labelText: labels.searchAndFilters),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }
}

final class _BrowseToolbar extends StatelessWidget {
  const _BrowseToolbar({
    required this.browseMode,
    required this.compactMobile,
    required this.filterPanelOpen,
    required this.labels,
    required this.onBrowseModeChanged,
    required this.onFilterPanelToggle,
    required this.onSearchChanged,
    required this.resultCount,
    required this.searchQuery,
    required this.visibleCount,
  });

  final BrowseMode browseMode;
  final bool compactMobile;
  final bool filterPanelOpen;
  final UiStrings labels;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final VoidCallback onFilterPanelToggle;
  final ValueChanged<String> onSearchChanged;
  final int resultCount;
  final String searchQuery;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth >= 340
            ? 320.0
            : constraints.maxWidth;
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!compactMobile)
              BrowseModeSelector(
                labels: labels,
                mode: browseMode,
                onChanged: onBrowseModeChanged,
              ),
            Chip(
              label: Text(
                compactMobile && visibleCount < resultCount
                    ? _localized(
                        labels,
                        '$visibleCount loaded / $resultCount total',
                        '已加载 $visibleCount / 共 $resultCount',
                      )
                    : searchQuery.isEmpty
                    ? '$resultCount ${labels.itemsUnit}'
                    : '$resultCount ${labels.matchesUnit}',
              ),
            ),
            if (!compactMobile)
              SizedBox(
                width: searchWidth,
                child: TextFormField(
                  key: const Key('search-field'),
                  initialValue: searchQuery,
                  decoration: InputDecoration(
                    labelText: labels.searchAndFilters,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
            KeyedSubtree(
              key: const ValueKey<String>('mobile-select-mode'),
              child: OutlinedButton.icon(
                key: const Key('select-mode-button'),
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(_localized(labels, 'Select', '选择')),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('filter-toggle-button'),
              onPressed: onFilterPanelToggle,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(_localized(labels, 'Filter', '筛选')),
              style: filterPanelOpen
                  ? OutlinedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.brown.shade800,
                      side: BorderSide(color: Colors.orange.shade200),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }
}

final class _DiscoveryLensChips extends StatelessWidget {
  const _DiscoveryLensChips({
    required this.labels,
    required this.memories,
    required this.onBrowseModeChanged,
    required this.onSelectMemory,
    required this.photos,
  });

  final UiStrings labels;
  final List<Memory> memories;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final ValueChanged<String> onSelectMemory;
  final List<PhotoRecord> photos;

  @override
  Widget build(BuildContext context) {
    final mappedCount = photos
        .where(
          (record) =>
              record.metadata.lat != null && record.metadata.lng != null,
        )
        .length;
    final datedCount = photos
        .where((record) => record.metadata.datetime != null)
        .length;
    final firstMemory = memories.isEmpty ? null : memories.first;
    return Wrap(
      key: const Key('discovery-lens-chips'),
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Chip(
          key: const Key('discover-chip'),
          label: Text(labels.discover.toUpperCase()),
        ),
        ActionChip(
          key: const Key('discover-map-chip'),
          avatar: const Icon(Icons.map_outlined, size: 18),
          label: Text(
            '${labels.map}  $mappedCount ${_localized(labels, 'places', '地点')}',
          ),
          onPressed: () => onBrowseModeChanged(BrowseMode.map),
        ),
        ActionChip(
          key: const Key('discover-timeline-chip'),
          avatar: const Icon(Icons.calendar_month, size: 18),
          label: Text(
            '${labels.timeline}  $datedCount ${_localized(labels, 'dated', '有日期')}',
          ),
          onPressed: () => onBrowseModeChanged(BrowseMode.timeline),
        ),
        if (firstMemory != null)
          ActionChip(
            key: const Key('discover-memory-chip'),
            avatar: const Icon(Icons.favorite_border, size: 18),
            label: Text(
              '${firstMemory.name}  ${_photoCountLabel(labels, firstMemory.photoCount)}',
            ),
            onPressed: () => onSelectMemory(firstMemory.id),
          ),
      ],
    );
  }
}

final class ActiveFilterSummary extends StatelessWidget {
  const ActiveFilterSummary({required this.filterLabels, required this.labels});

  final List<String> filterLabels;
  final UiStrings labels;

  @override
  Widget build(BuildContext context) {
    if (filterLabels.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        key: const Key('active-filter-summary'),
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(labels.activeFilters),
          for (final label in filterLabels)
            Chip(key: Key('active-filter-$label'), label: Text(label)),
        ],
      ),
    );
  }
}

String _localized(UiStrings labels, String en, String zh) {
  return identical(labels, uiStrings[UiLocale.zh]) ? zh : en;
}

String _photoCountLabel(UiStrings labels, int count) {
  return identical(labels, uiStrings[UiLocale.zh])
      ? '$count ${labels.photosUnit}'
      : '$count ${labels.photosUnit}';
}
