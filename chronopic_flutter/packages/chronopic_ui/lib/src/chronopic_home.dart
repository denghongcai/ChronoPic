import 'dart:io';
import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:chronopic_media/chronopic_media_flutter.dart'
    show PhotoManagerGateway;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'browse/browse_surface.dart';
part 'detail/detail_surface.dart';
part 'filters/filter_toolbar.dart';
part 'gallery/gallery_dialog.dart';
part 'home/home_page.dart';
part 'l10n/ui_strings.dart';
part 'memories/memory_pages.dart';
part 'settings/settings_pages.dart';
part 'shell/desktop_shell.dart';
part 'theme/chronopic_theme.dart';

enum _DesktopPage { home, memories, memoryDetail, settings, notifications }

enum ChronoPicEntryMode { desktopFolder, mobilePhotoLibrary }

typedef MobileMediaSourceFactory = MediaSourceAdapter Function();
typedef PhotoThumbnailLoader = Future<Uint8List?> Function(PhotoRecord record);

const int _photoPageSize = 20;

final class _VisiblePhotoPage {
  const _VisiblePhotoPage({required this.photos, required this.hasMore});

  final List<PhotoRecord> photos;
  final bool hasMore;
}

final class _PhotoThumbnailLoaderScope extends InheritedWidget {
  const _PhotoThumbnailLoaderScope({
    required this.loader,
    required super.child,
  });

  final PhotoThumbnailLoader? loader;

  static PhotoThumbnailLoader? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PhotoThumbnailLoaderScope>()
        ?.loader;
  }

  @override
  bool updateShouldNotify(_PhotoThumbnailLoaderScope oldWidget) =>
      loader != oldWidget.loader;
}

final class ChronoPicHome extends StatefulWidget {
  const ChronoPicHome({
    super.key,
    this.service,
    this.entryModeOverride,
    this.mobileMediaSourceFactory,
  });

  final ChronoPicAppService? service;
  final ChronoPicEntryMode? entryModeOverride;
  final MobileMediaSourceFactory? mobileMediaSourceFactory;

  @override
  State<ChronoPicHome> createState() => _ChronoPicHomeState();
}

final class _ChronoPicHomeState extends State<ChronoPicHome> {
  late final ChronoPicAppService _service =
      widget.service ?? ChronoPicAppService.persistent();

  final TextEditingController _libraryPathController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _tagFilterController = TextEditingController();
  final TextEditingController _fromDateFilterController =
      TextEditingController();
  final TextEditingController _toDateFilterController = TextEditingController();
  final TextEditingController _backupPathController = TextEditingController();
  final TextEditingController _memoryNameController = TextEditingController(
    text: 'Desktop Memory',
  );
  final TextEditingController _memoryTitleController = TextEditingController();
  final TextEditingController _memoryDescriptionController =
      TextEditingController();
  final TextEditingController _aiProviderController = TextEditingController();
  final TextEditingController _aiBaseUrlController = TextEditingController();
  final TextEditingController _aiModelController = TextEditingController();
  final TextEditingController _aiApiKeyController = TextEditingController();
  final TextEditingController _mapApiKeyController = TextEditingController();
  final TextEditingController _mapSecurityJsCodeController =
      TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final PhotoManagerGateway _photoManagerGateway = PhotoManagerGateway();
  final Map<String, Future<Uint8List?>> _thumbnailFutures =
      <String, Future<Uint8List?>>{};

  _DesktopPage _page = _DesktopPage.home;
  BrowseMode _browseMode = BrowseMode.waterfall;
  UiLocale _locale = UiLocale.en;
  AiOutputLocale _aiOutputLocale = AiOutputLocale.followUi;
  PhotoRecord? _selected;
  ChronoPicBackup? _lastBackup;
  BackupRestorePreview? _restorePreview;
  bool _persistedSettingsLoaded = false;
  bool _localeSurfaceOverride = false;
  bool _favoriteOnly = false;
  bool _gpsOnly = false;
  bool _detailCaptureFirst = false;
  bool _filterPanelOpen = false;
  bool _scanning = false;
  String _query = '';
  String? _tagFilter;
  AiPipelineStatus? _aiStatusFilter;
  int? _fromDatetimeFilter;
  int? _toDatetimeFilter;
  PhotoSortBy _sortBy = PhotoSortBy.datetime;
  SortDirection _sortDirection = SortDirection.desc;
  String? _selectedMemoryId;
  String _status = uiStrings[UiLocale.en]!.scanIdle;
  int _photoResultLimit = _photoPageSize;
  bool _hasMoreVisiblePhotos = false;
  MediaSourceAdapter? _activeMobileMediaSource;

  @override
  void initState() {
    super.initState();
    _applyCaptureSurfaceFromEnvironment();
  }

  @override
  void dispose() {
    _libraryPathController.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _tagFilterController.dispose();
    _fromDateFilterController.dispose();
    _toDateFilterController.dispose();
    _backupPathController.dispose();
    _memoryNameController.dispose();
    _memoryTitleController.dispose();
    _memoryDescriptionController.dispose();
    _aiProviderController.dispose();
    _aiBaseUrlController.dispose();
    _aiModelController.dispose();
    _aiApiKeyController.dispose();
    _mapApiKeyController.dispose();
    _mapSecurityJsCodeController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _loadPersistedSettingsOnce();
    final labels = _l10n;
    final photoPage = _visiblePhotoPage();
    final photos = photoPage.photos;
    _hasMoreVisiblePhotos = photoPage.hasMore;
    final catalogPhotoCount = _service.countPhotos();
    final filteredPhotoCount = _service.countPhotos(_currentPhotoFilter());
    final viewerPhotos = _currentResultPhotos(filteredPhotoCount);
    final memories = _service.listMemories();
    final selectedMemory = _selectedMemoryId == null
        ? null
        : _service.getMemory(_selectedMemoryId!);
    final aiReadiness = _service.getAiSetupReadiness();
    final aiStatusCounts = _service.getAiStatusCounts();
    final memoryCandidates = _service.listMemoryCandidates();
    final notificationCount =
        memoryCandidates.length +
        (aiStatusCounts[AiPipelineStatus.failed] ?? 0) +
        (aiStatusCounts[AiPipelineStatus.pending] ?? 0) +
        (aiStatusCounts[AiPipelineStatus.processing] ?? 0);
    final immersiveDetail = _detailCaptureFirst && _selected != null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      title: labels.appTitle,
      theme: ChronoPicTheme.light(),
      home: Builder(
        builder: (context) => Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleShellKey(context, event),
          child: _DesktopShell(
            activePage: _page,
            browseMode: _browseMode,
            favoriteOnly: _favoriteOnly,
            immersive: immersiveDetail,
            labels: labels,
            memories: memories,
            notificationCount: notificationCount,
            onAllPhotos: _showAllPhotos,
            onFavorites: _showFavorites,
            onMemorySelected: _selectMemory,
            onMemories: () => setState(() => _page = _DesktopPage.memories),
            onBrowseModeChanged: _showBrowseMode,
            onNotifications: () =>
                setState(() => _page = _DesktopPage.notifications),
            onSettings: () => setState(() => _page = _DesktopPage.settings),
            selectedMemoryId: _selectedMemoryId,
            status: _status,
            child: _buildPage(
              labels: labels,
              photos: photos,
              viewerPhotos: viewerPhotos,
              catalogPhotoCount: catalogPhotoCount,
              filteredPhotoCount: filteredPhotoCount,
              hasMorePhotos: photoPage.hasMore,
              memories: memories,
              selectedMemory: selectedMemory,
              aiReadiness: aiReadiness,
              aiStatusCounts: aiStatusCounts,
              memoryCandidates: memoryCandidates,
            ),
          ),
        ),
      ),
    );
  }

  UiStrings get _l10n => uiStrings[_locale]!;

  ChronoPicEntryMode get _entryMode {
    final override = widget.entryModeOverride;
    if (override != null) return override;
    return Platform.isAndroid || Platform.isIOS
        ? ChronoPicEntryMode.mobilePhotoLibrary
        : ChronoPicEntryMode.desktopFolder;
  }

  Widget _buildPage({
    required UiStrings labels,
    required List<PhotoRecord> photos,
    required List<PhotoRecord> viewerPhotos,
    required int catalogPhotoCount,
    required int filteredPhotoCount,
    required bool hasMorePhotos,
    required List<Memory> memories,
    required Memory? selectedMemory,
    required AiReadiness aiReadiness,
    required Map<AiPipelineStatus, int> aiStatusCounts,
    required List<MemoryCandidate> memoryCandidates,
  }) {
    switch (_page) {
      case _DesktopPage.memories:
        return MemoryListPage(
          candidates: memoryCandidates,
          labels: labels,
          memories: memories,
          memoryNameController: _memoryNameController,
          onAcceptCandidate: _acceptMemoryCandidate,
          onCreateMemory: _createMemory,
          onGenerateCandidates: _refreshMemoryCandidates,
          onRejectCandidate: _rejectMemoryCandidate,
          onSelectMemory: _selectMemory,
        );
      case _DesktopPage.memoryDetail:
        return MemoryDetailPage(
          labels: labels,
          memory: selectedMemory,
          memoryTitleController: _memoryTitleController,
          memoryDescriptionController: _memoryDescriptionController,
          onAddSelectedToMemory: _addSelectedToMemory,
          onBackToMemories: () => setState(() => _page = _DesktopPage.memories),
          onRemoveSelectedFromMemory: _removeSelectedFromMemory,
          onSaveMemory: _saveSelectedMemory,
          onSetCover: _setSelectedAsMemoryCover,
          selected: _selected,
        );
      case _DesktopPage.settings:
        return SettingsPage(
          aiOutputLocale: _aiOutputLocale,
          aiReadiness: aiReadiness,
          aiStatusCounts: aiStatusCounts,
          apiKeyController: _aiApiKeyController,
          backupPathController: _backupPathController,
          baseUrlController: _aiBaseUrlController,
          labels: labels,
          libraryPathController: _libraryPathController,
          locale: _locale,
          mapApiKeyController: _mapApiKeyController,
          mapSecurityJsCodeController: _mapSecurityJsCodeController,
          memories: memories,
          modelController: _aiModelController,
          onAddLibrary: _addLibrary,
          onChooseBackupExportPath: _chooseBackupExportPath,
          onChooseBackupRestorePath: _chooseBackupRestorePath,
          onChooseLibraryFolder: _chooseLibraryFolder,
          onExportBackup: _exportBackup,
          onAiOutputLocaleChanged: _saveAiOutputLocale,
          onLocaleChanged: _saveUiLocale,
          onPreviewRestore: _previewRestore,
          onRestoreBackup: _restoreBackup,
          onSaveAiSettings: _saveAiSettings,
          onSaveLocaleSettings: _saveCurrentLocaleSettings,
          onSaveMapSettings: _saveMapSettings,
          onScanLibrary: _scanLibrary,
          favoritePhotoCount: _service.countPhotos(
            const PhotoFilter(favorite: true),
          ),
          photoCount: catalogPhotoCount,
          providerController: _aiProviderController,
          restorePreview: _restorePreview,
          scanning: _scanning,
          sources: _service.listLibrarySources(),
        );
      case _DesktopPage.notifications:
        return NotificationPage(
          aiReadiness: aiReadiness,
          aiStatusCounts: aiStatusCounts,
          candidates: memoryCandidates,
          labels: labels,
          onRetryQueue: _retryAiQueue,
          onSettings: () => setState(() => _page = _DesktopPage.settings),
          onViewMemories: () => setState(() => _page = _DesktopPage.memories),
        );
      case _DesktopPage.home:
        return HomePage(
          activeFilterLabels: _activeFilterLabels(),
          aiStatus: _aiStatusFilter,
          browseMode: _browseMode,
          catalogPhotoCount: catalogPhotoCount,
          captionController: _captionController,
          dateController: _dateController,
          favoriteOnly: _favoriteOnly,
          filterPanelOpen: _filterPanelOpen,
          filteredPhotoCount: filteredPhotoCount,
          fromDateController: _fromDateFilterController,
          gpsOnly: _gpsOnly,
          labels: labels,
          libraryPathController: _libraryPathController,
          entryMode: _entryMode,
          detailFirst: _detailCaptureFirst,
          memories: memories,
          onAddLibrary: _addLibrary,
          onAddToMemory: _openMemoryActionForSelectedPhoto,
          onAllPhotos: _showAllPhotos,
          onBrowseModeChanged: (mode) => setState(() => _browseMode = mode),
          onChooseLibraryFolder: _chooseLibraryFolder,
          onChoosePhotos: _scanPhotoLibrary,
          onCloseFocusedDetail: _closeFocusedDetail,
          onClearFilters: _clearFilters,
          onCreateFirstMemory: () =>
              setState(() => _page = _DesktopPage.memories),
          onFilterApply: _applyFilters,
          onFilterPanelToggle: () =>
              setState(() => _filterPanelOpen = !_filterPanelOpen),
          onGpsOnlyChanged: (value) => setState(() {
            _gpsOnly = value;
            _resetPhotoPagination();
          }),
          onAiStatusChanged: (value) => setState(() {
            _aiStatusFilter = value;
            _resetPhotoPagination();
          }),
          onOpenGallery: _openGallery,
          onOpenDetailFor: _openFocusedDetailFor,
          onOpenMemories: () => setState(() => _page = _DesktopPage.memories),
          onOpenSettings: () => setState(() => _page = _DesktopPage.settings),
          onFavorites: _showFavorites,
          onSaveCaption: _saveCaption,
          onSaveDatetime: _saveDatetime,
          onSaveTags: _saveTags,
          onScanLibrary: _scanLibrary,
          onSearchChanged: (value) => setState(() {
            _query = value;
            _resetPhotoPagination();
          }),
          onSelectMemory: _selectMemory,
          onSelectPhoto: _selectPhoto,
          onSortByChanged: (value) => setState(() {
            _sortBy = value;
            _resetPhotoPagination();
          }),
          onSortDirectionChanged: (value) => setState(() {
            _sortDirection = value;
            _resetPhotoPagination();
          }),
          onToggleFavorite: _toggleSelectedFavorite,
          onRollback: _rollbackLatestEdit,
          hasMorePhotos: hasMorePhotos,
          onLoadMorePhotos: _loadMorePhotos,
          onScrollNearEnd: _loadMorePhotos,
          photos: photos,
          viewerPhotos: viewerPhotos,
          query: _query,
          scanning: _scanning,
          selected: _selected,
          sortBy: _sortBy,
          sortDirection: _sortDirection,
          status: _status,
          tagController: _tagFilterController,
          tagsController: _tagsController,
          timeController: _timeController,
          toDateController: _toDateFilterController,
          scrollController: _homeScrollController,
          thumbnailLoader: _loadThumbnailBytes,
        );
    }
  }

  _VisiblePhotoPage _visiblePhotoPage() {
    final records = _service.listPhotos(
      _currentPhotoFilter(limit: _photoResultLimit + 1),
    );
    final hasMore = records.length > _photoResultLimit;
    return _VisiblePhotoPage(
      photos: hasMore ? records.sublist(0, _photoResultLimit) : records,
      hasMore: hasMore,
    );
  }

  PhotoFilter _currentPhotoFilter({int? limit}) {
    return PhotoFilter(
      query: _query.isEmpty ? null : _query,
      tag: _tagFilter,
      aiStatus: _aiStatusFilter,
      favorite: _favoriteOnly ? true : null,
      memoryId: _selectedMemoryId,
      hasGps: _gpsOnly ? true : null,
      fromDatetime: _fromDatetimeFilter,
      toDatetime: _toDatetimeFilter,
      sortBy: _sortBy,
      sortDirection: _sortDirection,
      limit: limit ?? 1000000000,
    );
  }

  List<PhotoRecord> _currentResultPhotos(int total) {
    if (total <= 0) return const [];
    return _service.listPhotos(_currentPhotoFilter(limit: total));
  }

  Future<Uint8List?> _loadThumbnailBytes(PhotoRecord record) {
    if (!record.photo.path.startsWith('asset://')) {
      return Future<Uint8List?>.value();
    }
    return _thumbnailFutures.putIfAbsent(record.photo.id, () async {
      final source = _activeMobileMediaSource;
      if (source != null) {
        try {
          final bytes = await source.readThumbnailBytes(record.photo.id);
          if (bytes != null && bytes.isNotEmpty) return bytes;
        } on Object {
          // Fall through to the platform gateway; UI previews should degrade.
        }
      }
      try {
        final bytes = await _photoManagerGateway.readThumbnailBytes(
          record.photo.id,
        );
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } on Object {
        return null;
      }
      return null;
    });
  }

  void _loadMorePhotos() {
    if (!_hasMoreVisiblePhotos) return;
    setState(() => _photoResultLimit += _photoPageSize);
  }

  void _resetPhotoPagination() {
    _photoResultLimit = _photoPageSize;
    if (!_homeScrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_homeScrollController.hasClients) return;
      _homeScrollController.jumpTo(0);
    });
  }

  List<String> _activeFilterLabels() {
    final labels = <String>[];
    if (_query.trim().isNotEmpty) {
      labels.add(_labelValue(_tr('Search', '搜索'), _query.trim()));
    }
    if (_tagFilter != null) {
      labels.add(_labelValue(_tr('Tag', '标签'), _tagFilter!));
    }
    if (_gpsOnly) labels.add(_l10n.gpsOnly);
    if (_aiStatusFilter != null) {
      labels.add(_aiStatusLabel(_aiStatusFilter!));
    }
    if (_fromDatetimeFilter != null) {
      labels.add(
        _labelValue(
          _tr('From', '开始'),
          _formatDate(
            DateTime.fromMillisecondsSinceEpoch(_fromDatetimeFilter!).toLocal(),
          ),
        ),
      );
    }
    if (_toDatetimeFilter != null) {
      labels.add(
        _labelValue(
          _tr('To', '结束'),
          _formatDate(
            DateTime.fromMillisecondsSinceEpoch(_toDatetimeFilter!).toLocal(),
          ),
        ),
      );
    }
    if (_favoriteOnly) labels.add(_l10n.favorites);
    if (_selectedMemoryId != null) {
      labels.add(_labelValue(_l10n.memories, _selectedMemoryId!));
    }
    if (_sortBy != PhotoSortBy.datetime ||
        _sortDirection != SortDirection.desc) {
      labels.add(
        '${_sortByLabel(_sortBy)} ${_sortDirectionLabel(_sortDirection)}',
      );
    }
    return labels;
  }

  String _tr(String en, String zh) => _localized(_l10n, en, zh);

  String _labelValue(String label, String value) {
    return identical(_l10n, uiStrings[UiLocale.zh])
        ? '$label：$value'
        : '$label: $value';
  }

  String _sortByLabel(PhotoSortBy value) {
    return switch (value) {
      PhotoSortBy.datetime => _l10n.sortDatetime,
      PhotoSortBy.path => _l10n.sortPath,
      PhotoSortBy.updatedAt => _l10n.sortUpdated,
    };
  }

  String _sortDirectionLabel(SortDirection value) {
    return switch (value) {
      SortDirection.desc => _l10n.desc,
      SortDirection.asc => _l10n.asc,
    };
  }

  String _aiStatusLabel(AiPipelineStatus value) {
    return switch (value) {
      AiPipelineStatus.disabled => _l10n.aiDisabled,
      AiPipelineStatus.pending => _l10n.aiPending,
      AiPipelineStatus.processing => _l10n.aiProcessing,
      AiPipelineStatus.completed => _l10n.aiCompleted,
      AiPipelineStatus.failed => _l10n.aiFailed,
    };
  }

  KeyEventResult _handleShellKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent || _selected == null) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && _detailCaptureFirst) {
      _closeFocusedDetail();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      setState(() => _detailCaptureFirst = true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyG) {
      _openGallery(context);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _toggleSelectedFavorite();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _rollbackLatestEdit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _loadPersistedSettingsOnce() {
    if (_persistedSettingsLoaded) return;
    final backupSettings = _service.createBackup().settings;
    final settings = backupSettings.ai;
    final mapSettings = backupSettings.map;
    final localeSettings = backupSettings.locale;
    _aiProviderController.text = settings.providerName;
    _aiBaseUrlController.text = settings.baseURL;
    _aiModelController.text = settings.model;
    _aiApiKeyController.text = settings.apiKey;
    _mapApiKeyController.text = mapSettings.apiKey;
    _mapSecurityJsCodeController.text = mapSettings.securityJsCode;
    if (!_localeSurfaceOverride) {
      _locale = _uiLocaleFromDomain(localeSettings.locale);
      _aiOutputLocale = localeSettings.aiOutputLocale;
      if (_status == uiStrings[UiLocale.en]!.scanIdle ||
          _status == uiStrings[UiLocale.zh]!.scanIdle) {
        _status = uiStrings[_locale]!.scanIdle;
      }
    }
    _persistedSettingsLoaded = true;
  }

  void _saveUiLocale(UiLocale locale) {
    _saveLocaleSettings(locale: locale, aiOutputLocale: _aiOutputLocale);
  }

  void _saveAiOutputLocale(AiOutputLocale aiOutputLocale) {
    _saveLocaleSettings(locale: _locale, aiOutputLocale: aiOutputLocale);
  }

  void _saveCurrentLocaleSettings() {
    _saveLocaleSettings(locale: _locale, aiOutputLocale: _aiOutputLocale);
  }

  void _saveLocaleSettings({
    required UiLocale locale,
    required AiOutputLocale aiOutputLocale,
  }) {
    final saved = _service.updateLocaleSettings(
      LocaleSettings(
        locale: _domainLocaleFromUi(locale),
        aiOutputLocale: aiOutputLocale,
      ),
    );
    setState(() {
      _locale = _uiLocaleFromDomain(saved.locale.locale);
      _aiOutputLocale = saved.locale.aiOutputLocale;
      _status = _localized(_l10n, 'Language settings saved', '语言设置已保存');
    });
  }

  void _showAllPhotos() {
    setState(() {
      _favoriteOnly = false;
      _selectedMemoryId = null;
      _page = _DesktopPage.home;
      _resetPhotoPagination();
    });
  }

  void _showFavorites() {
    setState(() {
      _favoriteOnly = true;
      _selectedMemoryId = null;
      _page = _DesktopPage.home;
      _resetPhotoPagination();
    });
  }

  void _showBrowseMode(BrowseMode mode) {
    setState(() {
      _browseMode = mode;
      _page = _DesktopPage.home;
      _detailCaptureFirst = false;
    });
  }

  void _selectPhoto(PhotoRecord record) {
    setState(() {
      _setSelectedPhoto(record);
    });
  }

  void _closeFocusedDetail() {
    setState(() => _detailCaptureFirst = false);
  }

  void _openFocusedDetailFor(PhotoRecord record) {
    setState(() {
      _page = _DesktopPage.home;
      _setSelectedPhoto(record);
      _detailCaptureFirst = true;
    });
  }

  void _openMemoryActionForSelectedPhoto() {
    if (_selected == null) return;
    if (_selectedMemoryId != null) {
      _addSelectedToMemory();
      return;
    }
    setState(() {
      _detailCaptureFirst = false;
      _page = _DesktopPage.memories;
      _status = _tr('Choose a memory for the selected photo', '为所选照片选择一个记忆');
    });
  }

  void _setSelectedPhoto(PhotoRecord record) {
    _selected = record;
    _captionController.text = record.semantic.caption ?? '';
    _tagsController.text = record.semantic.labels.join(', ');
    _setDatetimeControllers(record.metadata.datetime);
  }

  void _applyCaptureSurfaceFromEnvironment() {
    final surface = Platform.environment['CHRONOPIC_CAPTURE_SURFACE']?.trim();
    if (surface == null || surface.isEmpty) return;

    final photos = _service.listPhotos(
      const PhotoFilter(
        sortBy: PhotoSortBy.path,
        sortDirection: SortDirection.asc,
        limit: 1000,
      ),
    );
    final selected = photos.isEmpty ? null : photos.first;
    if (selected != null) _setSelectedPhoto(selected);

    final memories = _service.listMemories();
    final firstMemory = memories.isEmpty ? null : memories.first;

    switch (surface) {
      case 'empty-home':
      case 'populated-grid':
      case 'restart-persistence':
        _page = _DesktopPage.home;
        _browseMode = BrowseMode.waterfall;
      case 'map':
        _page = _DesktopPage.home;
        _browseMode = BrowseMode.map;
      case 'timeline':
        _page = _DesktopPage.home;
        _browseMode = BrowseMode.timeline;
      case 'detail':
        _page = _DesktopPage.home;
        _browseMode = BrowseMode.waterfall;
        _detailCaptureFirst = true;
      case 'gallery':
        _page = _DesktopPage.home;
        _browseMode = BrowseMode.waterfall;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigatorContext = _navigatorKey.currentContext;
          if (mounted && _selected != null && navigatorContext != null) {
            _openGallery(navigatorContext);
          }
        });
      case 'favorites':
        _page = _DesktopPage.home;
        _favoriteOnly = true;
        _browseMode = BrowseMode.waterfall;
      case 'memories-list':
        _page = _DesktopPage.memories;
      case 'memory-detail':
        _page = _DesktopPage.memoryDetail;
        _selectedMemoryId = firstMemory?.id;
        if (firstMemory != null) {
          _memoryTitleController.text = firstMemory.name;
          _memoryDescriptionController.text = firstMemory.description ?? '';
        }
      case 'settings':
        _page = _DesktopPage.settings;
      case 'notifications':
        _page = _DesktopPage.notifications;
      case 'zh-locale':
        _page = _DesktopPage.home;
        _locale = UiLocale.zh;
        _localeSurfaceOverride = true;
        _status = uiStrings[UiLocale.zh]!.scanIdle;
        _browseMode = BrowseMode.waterfall;
      default:
        _page = _DesktopPage.home;
        _browseMode = BrowseMode.waterfall;
    }
  }

  void _addLibrary() {
    final path = _libraryPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = _tr('Library path is required', '需要图库路径'));
      return;
    }
    final source = _service.addLibrarySource(path);
    setState(
      () => _status = _labelValue(_tr('Added library', '已添加图库'), source.path),
    );
  }

  Future<void> _chooseLibraryFolder() async {
    final selectedPath = await getDirectoryPath(
      initialDirectory: _libraryPathController.text.trim().isEmpty
          ? null
          : _libraryPathController.text.trim(),
      confirmButtonText: 'Choose Folder',
      canCreateDirectories: false,
    );
    if (selectedPath == null) return;
    _libraryPathController.text = selectedPath;
    final source = _service.addLibrarySource(selectedPath);
    setState(
      () => _status = _labelValue(_tr('Added library', '已添加图库'), source.path),
    );
  }

  Future<void> _scanLibrary() async {
    final path = _libraryPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = _tr('Library path is required', '需要图库路径'));
      return;
    }
    setState(() {
      _scanning = true;
      _status = _tr('Scan progress: scanning', '扫描进度：扫描中');
    });
    try {
      final stats = await _service.scanDesktopDirectory(path);
      setState(() {
        _status = _localized(
          _l10n,
          'Scan complete: ${stats.imported} imported, ${stats.updated} updated, ${stats.skipped} skipped, ${stats.errors} errors, ${stats.missing} missing',
          '扫描完成：${stats.imported} 个已导入，${stats.updated} 个已更新，${stats.skipped} 个已跳过，${stats.errors} 个错误，${stats.missing} 个缺失',
        );
        _selected = _selected == null
            ? null
            : _service.getPhoto(_selected!.photo.id);
      });
    } on Object catch (error) {
      setState(
        () => _status = _labelValue(_tr('Scan failed', '扫描失败'), '$error'),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _scanPhotoLibrary() async {
    setState(() {
      _scanning = true;
      _status = _tr(
        'Scan progress: requesting photo access',
        '扫描进度：正在请求照片访问权限',
      );
    });
    late final MediaSourceAdapter source;
    var sourcePath = 'photo-library';
    try {
      final factory = widget.mobileMediaSourceFactory;
      if (factory != null) {
        source = factory();
      } else {
        final gateway = PhotoManagerGateway();
        final scope = await _choosePhotoLibraryScope(gateway);
        if (scope == null) {
          if (!mounted) return;
          setState(
            () =>
                _status = _tr('Photo library selection cancelled', '已取消照片图库选择'),
          );
          return;
        }
        source = MobilePhotoLibraryMediaSource(gateway, scope: scope);
        sourcePath = 'photo-library/${scope.id}';
        if (mounted) {
          setState(
            () => _status = _labelValue(
              _tr('Scan progress: selected scope', '扫描进度：已选择范围'),
              '${scope.name} (${scope.assetCount})',
            ),
          );
        }
      }
      _activeMobileMediaSource = source;
      _thumbnailFutures.clear();
      final stats = await _service.scanMediaSource(
        sourcePath,
        source,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _status = _mobileScanProgressStatus(progress));
        },
      );
      if (!mounted) return;
      setState(() {
        _status = _mobileScanCompleteStatus(stats, source.permissionState);
        _selected = _selected == null
            ? null
            : _service.getPhoto(_selected!.photo.id);
      });
    } on MediaSourceException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = error.permissionState == MediaSourcePermissionState.denied
            ? _tr(
                'Photo library permission denied. Open settings to grant access.',
                '照片图库权限被拒绝。请到设置中授权。',
              )
            : _labelValue(
                _tr('Photo library scan failed', '照片图库扫描失败'),
                error.message,
              );
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _status = _labelValue(
          _tr('Photo library scan failed', '照片图库扫描失败'),
          '$error',
        ),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<PhotoLibraryScope?> _choosePhotoLibraryScope(
    PhotoLibraryGateway gateway,
  ) async {
    final permission = await gateway.requestPermission();
    if (permission.state == MediaSourcePermissionState.denied) {
      throw const MediaSourceException(
        'Photo library permission denied',
        permissionState: MediaSourcePermissionState.denied,
      );
    }
    final scopes = await gateway.listScopes();
    if (!mounted || scopes.isEmpty) return null;
    final sheetContext = _navigatorKey.currentContext;
    if (sheetContext == null) return null;
    return showModalBottomSheet<PhotoLibraryScope>(
      context: sheetContext,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Choose photo library', '选择照片图库'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tr(
                        'Select a folder or All Photos before scanning.',
                        '扫描前选择一个文件夹或全部照片。',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }
            final scope = scopes[index - 1];
            return ListTile(
              key: Key('photo-library-scope-${scope.id}'),
              leading: Icon(
                scope.isAll
                    ? Icons.photo_library_outlined
                    : Icons.folder_outlined,
              ),
              title: Text(scope.name),
              subtitle: Text(
                _localized(
                  _l10n,
                  '${scope.assetCount} items',
                  '${scope.assetCount} 项',
                ),
              ),
              onTap: () => Navigator.of(context).pop(scope),
            );
          },
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox(height: 8) : const Divider(height: 1),
          itemCount: scopes.length + 1,
        ),
      ),
    );
  }

  String _mobileScanProgressStatus(ScanProgress progress) {
    final state = switch (progress.state) {
      ScanRunState.running => _tr('Scan progress', '扫描进度'),
      ScanRunState.paused => _tr('Scan paused', '扫描已暂停'),
      ScanRunState.completed => _tr('Scan complete', '扫描完成'),
      ScanRunState.failed => _tr('Scan failed', '扫描失败'),
      ScanRunState.idle => _tr('Scan idle', '扫描空闲'),
    };
    return _localized(
      _l10n,
      '$state: ${progress.processed}/${progress.discovered} processed, ${progress.imported} imported${progress.message == null ? '' : ', ${progress.message}'}',
      '$state：已处理 ${progress.processed}/${progress.discovered}，已导入 ${progress.imported} 个${progress.message == null ? '' : '，${progress.message}'}',
    );
  }

  String _mobileScanCompleteStatus(
    IndexerStats stats,
    MediaSourcePermissionState permissionState,
  ) {
    final prefix = permissionState == MediaSourcePermissionState.limited
        ? _tr('Limited photo access', '有限照片访问')
        : _tr('Photo library scan complete', '照片图库扫描完成');
    return _localized(
      _l10n,
      '$prefix: ${stats.imported} imported, ${stats.updated} updated, ${stats.skipped} skipped, ${stats.errors} errors, ${stats.missing} missing${stats.lastError == null ? '' : ', ${stats.lastError}'}',
      '$prefix：${stats.imported} 个已导入，${stats.updated} 个已更新，${stats.skipped} 个已跳过，${stats.errors} 个错误，${stats.missing} 个缺失${stats.lastError == null ? '' : '，${stats.lastError}'}',
    );
  }

  void _toggleFavorite(PhotoRecord record) {
    final updated = _service.updatePhotoFavorite(
      record.photo.id,
      !record.photo.favorite,
    );
    setState(() {
      if (_selected?.photo.id == updated.photo.id) _selected = updated;
      _status = updated.photo.favorite
          ? _tr('Marked favorite', '已标记收藏')
          : _tr('Removed favorite', '已取消收藏');
    });
  }

  void _toggleSelectedFavorite() {
    final selected = _selected;
    if (selected == null) return;
    _toggleFavorite(selected);
  }

  void _saveCaption() {
    final selected = _selected;
    if (selected == null) return;
    final caption = _captionController.text.trim();
    if (caption.length > 160) {
      setState(
        () => _status = _tr(
          'Caption must be 160 characters or fewer',
          '标题必须不超过 160 个字符',
        ),
      );
      return;
    }
    final updated = _service.updatePhotoCaption(
      selected.photo.id,
      caption.isEmpty ? null : caption,
    );
    setState(() {
      _selected = updated;
      _status = caption.isEmpty
          ? _tr('Cleared caption', '已清除标题')
          : _tr('Saved caption', '已保存标题');
    });
  }

  void _saveTags() {
    final selected = _selected;
    if (selected == null) return;
    final labels = <String>[];
    final seen = <String>{};
    final rawLabels = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    for (final label in rawLabels) {
      if (label.length > 32) {
        setState(
          () => _status = _tr(
            'Tags must be 32 characters or fewer',
            '标签必须不超过 32 个字符',
          ),
        );
        return;
      }
      final normalized = label.toLowerCase();
      if (seen.add(normalized)) labels.add(label);
    }
    if (labels.length > 20) {
      setState(() => _status = _tr('Use 20 tags or fewer', '请使用不超过 20 个标签'));
      return;
    }
    final updated = _service.updatePhotoTags(selected.photo.id, labels);
    setState(() {
      _selected = updated;
      _tagsController.text = labels.join(', ');
      _status = labels.isEmpty
          ? _tr('Cleared tags', '已清除标签')
          : _localized(
              _l10n,
              'Saved tags: ${labels.length}',
              '已保存标签：${labels.length}',
            );
    });
  }

  void _saveDatetime() {
    final selected = _selected;
    if (selected == null) return;
    final parsed = _parseDateTimeInput();
    if (parsed == _DateTimeParseResult.invalid) {
      setState(
        () => _status = _tr(
          'Datetime must use YYYY-MM-DD and HH:mm',
          '日期时间必须使用 YYYY-MM-DD 和 HH:mm',
        ),
      );
      return;
    }
    final updated = _service.updatePhotoDatetime(
      selected.photo.id,
      parsed.millisecondsSinceEpoch,
    );
    setState(() {
      _selected = updated;
      _status = _tr('Saved datetime', '已保存日期时间');
    });
  }

  void _applyFilters() {
    final from = _parseDateFilter(_fromDateFilterController.text.trim());
    final to = _parseDateFilter(
      _toDateFilterController.text.trim(),
      endOfDay: true,
    );
    if (from == _DateFilterParseResult.invalid ||
        to == _DateFilterParseResult.invalid) {
      setState(
        () => _status = _tr(
          'Date filters must use YYYY-MM-DD',
          '日期筛选必须使用 YYYY-MM-DD',
        ),
      );
      return;
    }
    setState(() {
      _tagFilter = _tagFilterController.text.trim().isEmpty
          ? null
          : _tagFilterController.text.trim();
      _fromDatetimeFilter = from.millisecondsSinceEpoch;
      _toDatetimeFilter = to.millisecondsSinceEpoch;
      _selected = null;
      _resetPhotoPagination();
      _status = _tr('Applied filters', '已应用筛选');
    });
  }

  void _clearFilters() {
    setState(() {
      _tagFilterController.clear();
      _fromDateFilterController.clear();
      _toDateFilterController.clear();
      _tagFilter = null;
      _aiStatusFilter = null;
      _fromDatetimeFilter = null;
      _toDatetimeFilter = null;
      _gpsOnly = false;
      _sortBy = PhotoSortBy.datetime;
      _sortDirection = SortDirection.desc;
      _selected = null;
      _browseMode = BrowseMode.waterfall;
      _resetPhotoPagination();
      _status = _tr('Cleared filters', '已清除筛选');
    });
  }

  _DateFilterParseResult _parseDateFilter(String raw, {bool endOfDay = false}) {
    if (raw.isEmpty) return const _DateFilterParseResult.empty();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (match == null) return _DateFilterParseResult.invalid;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final dateTime = endOfDay
        ? DateTime(year, month, day, 23, 59, 59, 999)
        : DateTime(year, month, day);
    if (dateTime.year != year ||
        dateTime.month != month ||
        dateTime.day != day) {
      return _DateFilterParseResult.invalid;
    }
    return _DateFilterParseResult.value(dateTime.millisecondsSinceEpoch);
  }

  void _rollbackLatestEdit() {
    final selected = _selected;
    if (selected == null) return;
    final updated = _service.rollbackLatestEdit(selected.photo.id);
    setState(() {
      _selected = updated;
      _captionController.text = updated.semantic.caption ?? '';
      _tagsController.text = updated.semantic.labels.join(', ');
      _setDatetimeControllers(updated.metadata.datetime);
      _status = _tr('Rolled back latest edit', '已回滚最近编辑');
    });
  }

  void _setDatetimeControllers(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null) {
      _dateController.text = '';
      _timeController.text = '';
      return;
    }
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      millisecondsSinceEpoch,
    ).toLocal();
    _dateController.text = _formatDate(dateTime);
    _timeController.text = _formatTime(dateTime);
  }

  _DateTimeParseResult _parseDateTimeInput() {
    final rawDate = _dateController.text.trim();
    final rawTime = _timeController.text.trim();
    if (rawDate.isEmpty && rawTime.isEmpty) {
      return const _DateTimeParseResult.clear();
    }
    final dateMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(rawDate);
    if (dateMatch == null) return _DateTimeParseResult.invalid;
    final year = int.parse(dateMatch.group(1)!);
    final month = int.parse(dateMatch.group(2)!);
    final day = int.parse(dateMatch.group(3)!);

    var hour = 0;
    var minute = 0;
    if (rawTime.isNotEmpty) {
      final timeMatch = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(rawTime);
      if (timeMatch == null) return _DateTimeParseResult.invalid;
      hour = int.parse(timeMatch.group(1)!);
      minute = int.parse(timeMatch.group(2)!);
      if (hour > 23 || minute > 59) return _DateTimeParseResult.invalid;
    }

    final dateTime = DateTime(year, month, day, hour, minute);
    if (dateTime.year != year ||
        dateTime.month != month ||
        dateTime.day != day ||
        dateTime.hour != hour ||
        dateTime.minute != minute) {
      return _DateTimeParseResult.invalid;
    }
    return _DateTimeParseResult.value(dateTime.millisecondsSinceEpoch);
  }

  Future<void> _openGallery(BuildContext dialogContext) async {
    final selected = _selected;
    if (selected == null) return;
    await _openGalleryFor(dialogContext, selected);
  }

  Future<void> _openGalleryFor(
    BuildContext dialogContext,
    PhotoRecord record,
  ) async {
    setState(() {
      _setSelectedPhoto(record);
      _detailCaptureFirst = false;
    });
    final result = await showDialog<GalleryDialogResult>(
      context: dialogContext,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => _PhotoThumbnailLoaderScope(
        loader: _loadThumbnailBytes,
        child: GalleryDialog(
          initialPhotoId: record.photo.id,
          labels: _l10n,
          photos: _currentResultPhotos(
            _service.countPhotos(_currentPhotoFilter()),
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _setSelectedPhoto(result.record);
        _detailCaptureFirst = result.action == GalleryDialogResultAction.detail;
      });
    }
  }

  void _createMemory() {
    final name = _memoryNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _status = _tr('Memory name is required', '需要记忆名称'));
      return;
    }
    final memory = _service.createMemory(name);
    setState(() {
      _selectedMemoryId = memory.id;
      _memoryTitleController.text = memory.name;
      _memoryDescriptionController.text = memory.description ?? '';
      _page = _DesktopPage.memoryDetail;
      _status = _labelValue(_tr('Created memory', '已创建记忆'), memory.name);
    });
  }

  void _refreshMemoryCandidates() {
    final ready = _service.listMemoryCandidates().length;
    setState(
      () => _status = _localized(
        _l10n,
        'Memory suggestions refreshed: $ready ready',
        '记忆建议已刷新：$ready 条就绪',
      ),
    );
  }

  void _selectMemory(String memoryId) {
    final memory = _service.getMemory(memoryId);
    setState(() {
      _favoriteOnly = false;
      _selectedMemoryId = memoryId;
      _memoryTitleController.text = memory?.name ?? '';
      _memoryDescriptionController.text = memory?.description ?? '';
      _page = _DesktopPage.memoryDetail;
      _selected = null;
      _resetPhotoPagination();
    });
  }

  void _addSelectedToMemory() {
    final selected = _selected;
    final memoryId = _selectedMemoryId;
    if (selected == null || memoryId == null) return;
    _service.addPhotoToMemory(memoryId, selected.photo.id);
    setState(() => _status = _tr('Added photo to memory', '已将照片加入记忆'));
  }

  void _saveSelectedMemory() {
    final memoryId = _selectedMemoryId;
    if (memoryId == null) return;
    final updated = _service.updateMemory(
      memoryId,
      name: _memoryTitleController.text.trim().isEmpty
          ? 'Untitled Memory'
          : _memoryTitleController.text.trim(),
      description: _memoryDescriptionController.text.trim().isEmpty
          ? null
          : _memoryDescriptionController.text.trim(),
    );
    setState(() {
      _memoryTitleController.text = updated.name;
      _memoryDescriptionController.text = updated.description ?? '';
      _status = _tr('Saved memory', '已保存记忆');
    });
  }

  void _setSelectedAsMemoryCover() {
    final memoryId = _selectedMemoryId;
    final selected = _selected;
    if (memoryId == null || selected == null) return;
    _service.setMemoryCover(memoryId, selected.photo.id);
    setState(() => _status = _tr('Updated memory cover', '已更新记忆封面'));
  }

  void _removeSelectedFromMemory() {
    final memoryId = _selectedMemoryId;
    final selected = _selected;
    if (memoryId == null || selected == null) return;
    _service.removePhotoFromMemory(memoryId, selected.photo.id);
    setState(() {
      _selected = null;
      _status = _tr('Removed photo from memory', '已从记忆移除照片');
    });
  }

  void _exportBackup() {
    try {
      final path = _backupPathController.text.trim();
      final backup = _service.createBackup();
      if (path.isNotEmpty) {
        final file = _service.exportBackupToFile(path);
        setState(() {
          _lastBackup = backup;
          _status = _localized(
            _l10n,
            'Exported backup file: ${file.path} (${backup.photos.length} photos, ${backup.memories.length} memories)',
            '已导出备份文件：${file.path}（${backup.photos.length} 张照片，${backup.memories.length} 个记忆）',
          );
        });
      } else {
        setState(() {
          _lastBackup = backup;
          _status = _localized(
            _l10n,
            'Exported backup: ${backup.photos.length} photos, ${backup.memories.length} memories',
            '已导出备份：${backup.photos.length} 张照片，${backup.memories.length} 个记忆',
          );
        });
      }
    } on Object catch (error) {
      setState(
        () => _status = _labelValue(_tr('Export failed', '导出失败'), '$error'),
      );
    }
  }

  Future<void> _chooseBackupExportPath() async {
    try {
      final location = await getSaveLocation(
        suggestedName: 'chronopic-backup.json',
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(label: 'JSON backup', extensions: <String>['json']),
        ],
      );
      if (location != null) {
        _backupPathController.text = location.path;
        setState(
          () => _status = _labelValue(
            _tr('Selected backup export path', '已选择备份导出路径'),
            location.path,
          ),
        );
      }
    } on Object catch (error) {
      setState(
        () => _status = _labelValue(
          _tr('Choose export path failed', '选择导出路径失败'),
          '$error',
        ),
      );
    }
  }

  Future<void> _chooseBackupRestorePath() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(label: 'JSON backup', extensions: <String>['json']),
        ],
      );
      if (file != null) {
        _backupPathController.text = file.path;
        setState(
          () => _status = _labelValue(
            _tr('Selected backup restore file', '已选择备份恢复文件'),
            file.path,
          ),
        );
      }
    } on Object catch (error) {
      setState(
        () => _status = _labelValue(
          _tr('Choose restore file failed', '选择恢复文件失败'),
          '$error',
        ),
      );
    }
  }

  void _saveAiSettings() {
    _service.updateAiSettings(
      AiSettings(
        apiKey: _aiApiKeyController.text.trim(),
        baseURL: _aiBaseUrlController.text.trim(),
        model: _aiModelController.text.trim(),
        providerName: _aiProviderController.text.trim(),
      ),
    );
    setState(() => _status = _tr('Saved AI settings', '已保存 AI 设置'));
  }

  void _saveMapSettings() {
    _service.updateMapSettings(
      MapSettings(
        apiKey: _mapApiKeyController.text.trim(),
        securityJsCode: _mapSecurityJsCodeController.text.trim(),
      ),
    );
    setState(() => _status = _tr('Saved map settings', '已保存地图设置'));
  }

  void _retryAiQueue() {
    final count = _service.retryFailedAiQueue();
    setState(
      () => _status = _localized(
        _l10n,
        'Retried $count failed AI items',
        '已重试 $count 个失败的 AI 项目',
      ),
    );
  }

  void _acceptMemoryCandidate(String candidateId) {
    final memory = _service.acceptMemoryCandidate(candidateId);
    setState(() {
      _selectedMemoryId = memory.id;
      _memoryTitleController.text = memory.name;
      _memoryDescriptionController.text = memory.description ?? '';
      _page = _DesktopPage.memoryDetail;
      _status = _labelValue(
        _tr('Accepted memory candidate', '已接受记忆候选'),
        memory.name,
      );
    });
  }

  void _rejectMemoryCandidate(String candidateId) {
    _service.rejectMemoryCandidate(candidateId);
    setState(() => _status = _tr('Rejected memory candidate', '已拒绝记忆候选'));
  }

  void _previewRestore() {
    try {
      final path = _backupPathController.text.trim();
      final preview = path.isNotEmpty
          ? _service.previewBackupFile(path)
          : (_lastBackup == null
                ? null
                : _service.previewBackupRestore(_lastBackup!));
      if (preview == null) {
        setState(() => _status = _tr('No backup to preview', '没有可预览的备份'));
        return;
      }
      setState(() {
        _restorePreview = preview;
        _status = _localized(
          _l10n,
          'Preview restore: ${preview.photoCount} photos, ${preview.memoryCount} memories',
          '恢复预览：${preview.photoCount} 张照片，${preview.memoryCount} 个记忆',
        );
      });
    } on Object catch (error) {
      setState(
        () => _status = _labelValue(
          _tr('Preview restore failed', '恢复预览失败'),
          '$error',
        ),
      );
    }
  }

  void _restoreBackup() {
    try {
      final path = _backupPathController.text.trim();
      if (path.isNotEmpty) {
        final result = _service.restoreBackupFile(path);
        setState(() {
          _restorePreview = null;
          _selected = null;
          _status = _localized(
            _l10n,
            'Restored backup: ${result.restoredPhotoCount} photos, ${result.restoredMemoryCount} memories',
            '已恢复备份：${result.restoredPhotoCount} 张照片，${result.restoredMemoryCount} 个记忆',
          );
        });
        return;
      }
      final backup = _lastBackup;
      if (backup == null) {
        setState(
          () => _status = _tr('No exported backup to restore', '没有可恢复的已导出备份'),
        );
        return;
      }
      final result = _service.restoreBackup(backup);
      setState(() {
        _restorePreview = null;
        _selected = null;
        _status = _localized(
          _l10n,
          'Restored backup: ${result.restoredPhotoCount} photos, ${result.restoredMemoryCount} memories',
          '已恢复备份：${result.restoredPhotoCount} 张照片，${result.restoredMemoryCount} 个记忆',
        );
      });
    } on Object catch (error) {
      setState(
        () => _status = _labelValue(_tr('Restore failed', '恢复失败'), '$error'),
      );
    }
  }
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _monthYear(DateTime dateTime) {
  return '${_monthNames[dateTime.month - 1]} ${dateTime.year}';
}

String _monthDay(DateTime dateTime) {
  return '${_monthNames[dateTime.month - 1]} ${dateTime.day}';
}

String _formatLongDateTime(DateTime dateTime) {
  final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${_monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}, $hour12:$minute $period';
}

UiLocale _uiLocaleFromDomain(LocaleSetting locale) {
  return switch (locale) {
    LocaleSetting.zhCN => UiLocale.zh,
    LocaleSetting.enUS => UiLocale.en,
  };
}

LocaleSetting _domainLocaleFromUi(UiLocale locale) {
  return switch (locale) {
    UiLocale.zh => LocaleSetting.zhCN,
    UiLocale.en => LocaleSetting.enUS,
  };
}

String _basename(String path) => path.split(Platform.pathSeparator).last;

final class _DateTimeParseResult {
  const _DateTimeParseResult.value(this.millisecondsSinceEpoch);

  const _DateTimeParseResult.clear() : millisecondsSinceEpoch = null;

  static const invalid = _DateTimeParseResult.value(-1);

  final int? millisecondsSinceEpoch;
}

final class _DateFilterParseResult {
  const _DateFilterParseResult.value(this.millisecondsSinceEpoch);

  const _DateFilterParseResult.empty() : millisecondsSinceEpoch = null;

  static const invalid = _DateFilterParseResult.value(-1);

  final int? millisecondsSinceEpoch;
}
