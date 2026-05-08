part of '../chronopic_home.dart';

final class HomePage extends StatelessWidget {
  const HomePage({
    required this.activeFilterLabels,
    required this.aiStatus,
    required this.browseMode,
    required this.captionController,
    required this.dateController,
    required this.favoriteOnly,
    required this.fromDateController,
    required this.gpsOnly,
    required this.labels,
    required this.libraryPathController,
    required this.memories,
    required this.onAddLibrary,
    required this.onAiStatusChanged,
    required this.onBrowseModeChanged,
    required this.onChooseLibraryFolder,
    required this.onClearFilters,
    required this.onFilterApply,
    required this.onGpsOnlyChanged,
    required this.onOpenGallery,
    required this.onRollback,
    required this.onSaveCaption,
    required this.onSaveDatetime,
    required this.onSaveTags,
    required this.onScanLibrary,
    required this.onSearchChanged,
    required this.onSelectPhoto,
    required this.onSortByChanged,
    required this.onSortDirectionChanged,
    required this.onToggleFavorite,
    required this.photos,
    required this.query,
    required this.scanning,
    required this.selected,
    required this.sortBy,
    required this.sortDirection,
    required this.tagController,
    required this.tagsController,
    required this.timeController,
    required this.toDateController,
  });

  final List<String> activeFilterLabels;
  final AiPipelineStatus? aiStatus;
  final BrowseMode browseMode;
  final TextEditingController captionController;
  final TextEditingController dateController;
  final bool favoriteOnly;
  final TextEditingController fromDateController;
  final bool gpsOnly;
  final UiStrings labels;
  final TextEditingController libraryPathController;
  final List<Memory> memories;
  final VoidCallback onAddLibrary;
  final ValueChanged<AiPipelineStatus?> onAiStatusChanged;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final VoidCallback onChooseLibraryFolder;
  final VoidCallback onClearFilters;
  final VoidCallback onFilterApply;
  final ValueChanged<bool> onGpsOnlyChanged;
  final ValueChanged<BuildContext> onOpenGallery;
  final VoidCallback onRollback;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveDatetime;
  final VoidCallback onSaveTags;
  final VoidCallback onScanLibrary;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final ValueChanged<PhotoSortBy> onSortByChanged;
  final ValueChanged<SortDirection> onSortDirectionChanged;
  final VoidCallback onToggleFavorite;
  final List<PhotoRecord> photos;
  final String query;
  final bool scanning;
  final PhotoRecord? selected;
  final PhotoSortBy sortBy;
  final SortDirection sortDirection;
  final TextEditingController tagController;
  final TextEditingController tagsController;
  final TextEditingController timeController;
  final TextEditingController toDateController;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = photos.isNotEmpty;
    return Column(
      key: const Key('home-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasPhotos)
          FirstRunPanel(
            labels: labels,
            onAddLibrary: onAddLibrary,
            onScanLibrary: onScanLibrary,
            scanning: scanning,
          )
        else if (memories.isEmpty)
          GuidedNextStepPanel(labels: labels),
        if (!hasPhotos) const SizedBox(height: 18),
        LibraryToolbar(
          labels: labels,
          libraryPathController: libraryPathController,
          onAddLibrary: onAddLibrary,
          onChooseLibraryFolder: onChooseLibraryFolder,
          onScanLibrary: onScanLibrary,
          onSearchChanged: onSearchChanged,
          scanning: scanning,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final browse = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrowseToolbar(
                  browseMode: browseMode,
                  labels: labels,
                  onBrowseModeChanged: onBrowseModeChanged,
                  resultCount: photos.length,
                  searchQuery: query,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 10),
                ActiveFilterSummary(labels: activeFilterLabels),
                const SizedBox(height: 18),
                BrowseSurface(
                  mode: browseMode,
                  onSelectPhoto: onSelectPhoto,
                  photos: photos,
                  selected: selected,
                ),
              ],
            );
            final detail = DetailSurface(
              captionController: captionController,
              dateController: dateController,
              labels: labels,
              onOpenGallery: onOpenGallery,
              onRollback: onRollback,
              onSaveCaption: onSaveCaption,
              onSaveDatetime: onSaveDatetime,
              onSaveTags: onSaveTags,
              onToggleFavorite: onToggleFavorite,
              record: selected,
              tagsController: tagsController,
              timeController: timeController,
            );
            if (!wide) {
              return Column(
                children: [browse, const SizedBox(height: 18), detail],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: browse),
                const SizedBox(width: 20),
                SizedBox(width: 430, child: detail),
              ],
            );
          },
        ),
      ],
    );
  }
}

final class FirstRunPanel extends StatelessWidget {
  const FirstRunPanel({
    required this.labels,
    required this.onAddLibrary,
    required this.onScanLibrary,
    required this.scanning,
  });

  final UiStrings labels;
  final VoidCallback onAddLibrary;
  final VoidCallback onScanLibrary;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onAddLibrary,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(labels.addLibrary),
              ),
              OutlinedButton.icon(
                onPressed: scanning ? null : onScanLibrary,
                icon: scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(labels.scanLibrary),
              ),
            ],
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'First run library setup',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Add a local folder, scan it, and start browsing photos without leaving the desktop app.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          );

          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
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
                'Create a memory from selected photos, or use filters to shape a story before saving it.',
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
            label: Text(labels.chooseFolder),
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
    required this.labels,
    required this.onBrowseModeChanged,
    required this.resultCount,
    required this.searchQuery,
  });

  final BrowseMode browseMode;
  final UiStrings labels;
  final ValueChanged<BrowseMode> onBrowseModeChanged;
  final int resultCount;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        BrowseModeSelector(
          labels: labels,
          mode: browseMode,
          onChanged: onBrowseModeChanged,
        ),
        Chip(
          label: Text(
            searchQuery.isEmpty ? '$resultCount items' : '$resultCount matches',
          ),
        ),
      ],
    );
  }
}

final class ActiveFilterSummary extends StatelessWidget {
  const ActiveFilterSummary({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const Text(
        'Active filters: none',
        key: Key('active-filter-summary'),
      );
    }
    return Wrap(
      key: const Key('active-filter-summary'),
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Active filters:'),
        for (final label in labels)
          Chip(key: Key('active-filter-$label'), label: Text(label)),
      ],
    );
  }
}
