import 'dart:io';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
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

final class ChronoPicHome extends StatefulWidget {
  const ChronoPicHome({super.key, this.service});

  final ChronoPicAppService? service;

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

  _DesktopPage _page = _DesktopPage.home;
  BrowseMode _browseMode = BrowseMode.waterfall;
  UiLocale _locale = UiLocale.en;
  PhotoRecord? _selected;
  ChronoPicBackup? _lastBackup;
  BackupRestorePreview? _restorePreview;
  bool _aiSettingsLoaded = false;
  bool _favoriteOnly = false;
  bool _gpsOnly = false;
  bool _scanning = false;
  String _query = '';
  String? _tagFilter;
  AiPipelineStatus? _aiStatusFilter;
  int? _fromDatetimeFilter;
  int? _toDatetimeFilter;
  PhotoSortBy _sortBy = PhotoSortBy.datetime;
  SortDirection _sortDirection = SortDirection.desc;
  String? _selectedMemoryId;
  String _status = 'Scan progress: idle';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _loadAiSettingsOnce();
    final labels = _l10n;
    final photos = _visiblePhotos();
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: labels.appTitle,
      theme: ChronoPicTheme.light(),
      home: Builder(
        builder: (context) => Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleShellKey(context, event),
          child: _DesktopShell(
            activePage: _page,
            favoriteOnly: _favoriteOnly,
            labels: labels,
            locale: _locale,
            memories: memories,
            notificationCount: notificationCount,
            onAllPhotos: _showAllPhotos,
            onFavorites: _showFavorites,
            onLocaleChanged: (locale) => setState(() => _locale = locale),
            onMemorySelected: _selectMemory,
            onMemories: () => setState(() => _page = _DesktopPage.memories),
            onNotifications: () =>
                setState(() => _page = _DesktopPage.notifications),
            onSettings: () => setState(() => _page = _DesktopPage.settings),
            selectedMemoryId: _selectedMemoryId,
            status: _status,
            child: _buildPage(
              labels: labels,
              photos: photos,
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

  Widget _buildPage({
    required UiStrings labels,
    required List<PhotoRecord> photos,
    required List<Memory> memories,
    required Memory? selectedMemory,
    required AiReadiness aiReadiness,
    required Map<AiPipelineStatus, int> aiStatusCounts,
    required List<MemoryCandidate> memoryCandidates,
  }) {
    switch (_page) {
      case _DesktopPage.memories:
        return MemoryListPage(
          labels: labels,
          memories: memories,
          memoryNameController: _memoryNameController,
          onCreateMemory: _createMemory,
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
          aiReadiness: aiReadiness,
          aiStatusCounts: aiStatusCounts,
          backupPathController: _backupPathController,
          labels: labels,
          libraryPathController: _libraryPathController,
          locale: _locale,
          memories: memories,
          onAddLibrary: _addLibrary,
          onChooseBackupExportPath: _chooseBackupExportPath,
          onChooseBackupRestorePath: _chooseBackupRestorePath,
          onChooseLibraryFolder: _chooseLibraryFolder,
          onExportBackup: _exportBackup,
          onLocaleChanged: (locale) => setState(() => _locale = locale),
          onPreviewRestore: _previewRestore,
          onRestoreBackup: _restoreBackup,
          onScanLibrary: _scanLibrary,
          photos: _service.listPhotos(const PhotoFilter(limit: 1000000)),
          restorePreview: _restorePreview,
          scanning: _scanning,
          sources: _service.listLibrarySources(),
        );
      case _DesktopPage.notifications:
        return NotificationPage(
          aiReadiness: aiReadiness,
          aiStatusCounts: aiStatusCounts,
          apiKeyController: _aiApiKeyController,
          baseUrlController: _aiBaseUrlController,
          candidates: memoryCandidates,
          labels: labels,
          modelController: _aiModelController,
          onAcceptCandidate: _acceptMemoryCandidate,
          onRejectCandidate: _rejectMemoryCandidate,
          onRetryQueue: _retryAiQueue,
          onSaveSettings: _saveAiSettings,
          onSettings: () => setState(() => _page = _DesktopPage.settings),
          providerController: _aiProviderController,
        );
      case _DesktopPage.home:
        return HomePage(
          activeFilterLabels: _activeFilterLabels(),
          aiStatus: _aiStatusFilter,
          browseMode: _browseMode,
          captionController: _captionController,
          dateController: _dateController,
          favoriteOnly: _favoriteOnly,
          fromDateController: _fromDateFilterController,
          gpsOnly: _gpsOnly,
          labels: labels,
          libraryPathController: _libraryPathController,
          memories: memories,
          onAddLibrary: _addLibrary,
          onBrowseModeChanged: (mode) => setState(() => _browseMode = mode),
          onChooseLibraryFolder: _chooseLibraryFolder,
          onClearFilters: _clearFilters,
          onFilterApply: _applyFilters,
          onGpsOnlyChanged: (value) => setState(() => _gpsOnly = value),
          onAiStatusChanged: (value) => setState(() => _aiStatusFilter = value),
          onOpenGallery: _openGallery,
          onSaveCaption: _saveCaption,
          onSaveDatetime: _saveDatetime,
          onSaveTags: _saveTags,
          onScanLibrary: _scanLibrary,
          onSearchChanged: (value) => setState(() => _query = value),
          onSelectPhoto: _selectPhoto,
          onSortByChanged: (value) => setState(() => _sortBy = value),
          onSortDirectionChanged: (value) =>
              setState(() => _sortDirection = value),
          onToggleFavorite: _toggleSelectedFavorite,
          onRollback: _rollbackLatestEdit,
          photos: photos,
          query: _query,
          scanning: _scanning,
          selected: _selected,
          sortBy: _sortBy,
          sortDirection: _sortDirection,
          tagController: _tagFilterController,
          tagsController: _tagsController,
          timeController: _timeController,
          toDateController: _toDateFilterController,
        );
    }
  }

  List<PhotoRecord> _visiblePhotos() {
    return _service.listPhotos(
      PhotoFilter(
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
        limit: 1000,
      ),
    );
  }

  List<String> _activeFilterLabels() {
    final labels = <String>[];
    if (_query.trim().isNotEmpty) labels.add('Search: ${_query.trim()}');
    if (_tagFilter != null) labels.add('Tag: $_tagFilter');
    if (_gpsOnly) labels.add('GPS only');
    if (_aiStatusFilter != null) labels.add('AI: ${_aiStatusFilter!.name}');
    if (_fromDatetimeFilter != null) {
      labels.add(
        'From: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(_fromDatetimeFilter!).toLocal())}',
      );
    }
    if (_toDatetimeFilter != null) {
      labels.add(
        'To: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(_toDatetimeFilter!).toLocal())}',
      );
    }
    if (_favoriteOnly) labels.add('Favorites');
    if (_selectedMemoryId != null) labels.add('Memory: $_selectedMemoryId');
    if (_sortBy != PhotoSortBy.datetime ||
        _sortDirection != SortDirection.desc) {
      labels.add('Sort: ${_sortBy.name} ${_sortDirection.name}');
    }
    return labels;
  }

  KeyEventResult _handleShellKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent || _selected == null) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.keyG) {
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

  void _loadAiSettingsOnce() {
    if (_aiSettingsLoaded) return;
    final settings = _service.createBackup().settings.ai;
    _aiProviderController.text = settings.providerName;
    _aiBaseUrlController.text = settings.baseURL;
    _aiModelController.text = settings.model;
    _aiApiKeyController.text = settings.apiKey;
    _aiSettingsLoaded = true;
  }

  void _showAllPhotos() {
    setState(() {
      _favoriteOnly = false;
      _selectedMemoryId = null;
      _page = _DesktopPage.home;
    });
  }

  void _showFavorites() {
    setState(() {
      _favoriteOnly = true;
      _selectedMemoryId = null;
      _page = _DesktopPage.home;
    });
  }

  void _selectPhoto(PhotoRecord record) {
    setState(() {
      _selected = record;
      _captionController.text = record.semantic.caption ?? '';
      _tagsController.text = record.semantic.labels.join(', ');
      _setDatetimeControllers(record.metadata.datetime);
    });
  }

  void _addLibrary() {
    final path = _libraryPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = 'Library path is required');
      return;
    }
    final source = _service.addLibrarySource(path);
    setState(() => _status = 'Added library: ${source.path}');
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
    setState(() => _status = 'Added library: ${source.path}');
  }

  Future<void> _scanLibrary() async {
    final path = _libraryPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = 'Library path is required');
      return;
    }
    setState(() {
      _scanning = true;
      _status = 'Scan progress: scanning';
    });
    try {
      final stats = await _service.scanDesktopDirectory(path);
      setState(() {
        _status =
            'Scan complete: ${stats.imported} imported, ${stats.updated} updated, ${stats.skipped} skipped, ${stats.errors} errors, ${stats.missing} missing';
        _selected = _selected == null
            ? null
            : _service.getPhoto(_selected!.photo.id);
      });
    } on Object catch (error) {
      setState(() => _status = 'Scan failed: $error');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _toggleFavorite(PhotoRecord record) {
    final updated = _service.updatePhotoFavorite(
      record.photo.id,
      !record.photo.favorite,
    );
    setState(() {
      if (_selected?.photo.id == updated.photo.id) _selected = updated;
      _status = updated.photo.favorite ? 'Marked favorite' : 'Removed favorite';
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
      setState(() => _status = 'Caption must be 160 characters or fewer');
      return;
    }
    final updated = _service.updatePhotoCaption(
      selected.photo.id,
      caption.isEmpty ? null : caption,
    );
    setState(() {
      _selected = updated;
      _status = caption.isEmpty ? 'Cleared caption' : 'Saved caption';
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
        setState(() => _status = 'Tags must be 32 characters or fewer');
        return;
      }
      final normalized = label.toLowerCase();
      if (seen.add(normalized)) labels.add(label);
    }
    if (labels.length > 20) {
      setState(() => _status = 'Use 20 tags or fewer');
      return;
    }
    final updated = _service.updatePhotoTags(selected.photo.id, labels);
    setState(() {
      _selected = updated;
      _tagsController.text = labels.join(', ');
      _status = labels.isEmpty
          ? 'Cleared tags'
          : 'Saved tags: ${labels.length}';
    });
  }

  void _saveDatetime() {
    final selected = _selected;
    if (selected == null) return;
    final parsed = _parseDateTimeInput();
    if (parsed == _DateTimeParseResult.invalid) {
      setState(() => _status = 'Datetime must use YYYY-MM-DD and HH:mm');
      return;
    }
    final updated = _service.updatePhotoDatetime(
      selected.photo.id,
      parsed.millisecondsSinceEpoch,
    );
    setState(() {
      _selected = updated;
      _status = 'Saved datetime';
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
      setState(() => _status = 'Date filters must use YYYY-MM-DD');
      return;
    }
    setState(() {
      _tagFilter = _tagFilterController.text.trim().isEmpty
          ? null
          : _tagFilterController.text.trim();
      _fromDatetimeFilter = from.millisecondsSinceEpoch;
      _toDatetimeFilter = to.millisecondsSinceEpoch;
      _selected = null;
      _status = 'Applied filters';
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
      _status = 'Cleared filters';
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
      _status = 'Rolled back latest edit';
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
    final result = await showDialog<PhotoRecord>(
      context: dialogContext,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => GalleryDialog(
        initialPhotoId: selected.photo.id,
        photos: _visiblePhotos(),
      ),
    );
    if (result != null) _selectPhoto(result);
  }

  void _createMemory() {
    final name = _memoryNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _status = 'Memory name is required');
      return;
    }
    final memory = _service.createMemory(name);
    setState(() {
      _selectedMemoryId = memory.id;
      _memoryTitleController.text = memory.name;
      _memoryDescriptionController.text = memory.description ?? '';
      _page = _DesktopPage.memoryDetail;
      _status = 'Created memory: ${memory.name}';
    });
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
    });
  }

  void _addSelectedToMemory() {
    final selected = _selected;
    final memoryId = _selectedMemoryId;
    if (selected == null || memoryId == null) return;
    _service.addPhotoToMemory(memoryId, selected.photo.id);
    setState(() => _status = 'Added photo to memory');
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
      _status = 'Saved memory';
    });
  }

  void _setSelectedAsMemoryCover() {
    final memoryId = _selectedMemoryId;
    final selected = _selected;
    if (memoryId == null || selected == null) return;
    _service.setMemoryCover(memoryId, selected.photo.id);
    setState(() => _status = 'Updated memory cover');
  }

  void _removeSelectedFromMemory() {
    final memoryId = _selectedMemoryId;
    final selected = _selected;
    if (memoryId == null || selected == null) return;
    _service.removePhotoFromMemory(memoryId, selected.photo.id);
    setState(() {
      _selected = null;
      _status = 'Removed photo from memory';
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
          _status =
              'Exported backup file: ${file.path} (${backup.photos.length} photos, ${backup.memories.length} memories)';
        });
      } else {
        setState(() {
          _lastBackup = backup;
          _status =
              'Exported backup: ${backup.photos.length} photos, ${backup.memories.length} memories';
        });
      }
    } on Object catch (error) {
      setState(() => _status = 'Export failed: $error');
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
          () => _status = 'Selected backup export path: ${location.path}',
        );
      }
    } on Object catch (error) {
      setState(() => _status = 'Choose export path failed: $error');
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
        setState(() => _status = 'Selected backup restore file: ${file.path}');
      }
    } on Object catch (error) {
      setState(() => _status = 'Choose restore file failed: $error');
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
    setState(() => _status = 'Saved AI settings');
  }

  void _retryAiQueue() {
    final count = _service.retryFailedAiQueue();
    setState(() => _status = 'Retried $count failed AI items');
  }

  void _acceptMemoryCandidate(String candidateId) {
    final memory = _service.acceptMemoryCandidate(candidateId);
    setState(() {
      _selectedMemoryId = memory.id;
      _memoryTitleController.text = memory.name;
      _memoryDescriptionController.text = memory.description ?? '';
      _page = _DesktopPage.memoryDetail;
      _status = 'Accepted memory candidate: ${memory.name}';
    });
  }

  void _rejectMemoryCandidate(String candidateId) {
    _service.rejectMemoryCandidate(candidateId);
    setState(() => _status = 'Rejected memory candidate');
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
        setState(() => _status = 'No backup to preview');
        return;
      }
      setState(() {
        _restorePreview = preview;
        _status =
            'Preview restore: ${preview.photoCount} photos, ${preview.memoryCount} memories';
      });
    } on Object catch (error) {
      setState(() => _status = 'Preview restore failed: $error');
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
          _status =
              'Restored backup: ${result.restoredPhotoCount} photos, ${result.restoredMemoryCount} memories';
        });
        return;
      }
      final backup = _lastBackup;
      if (backup == null) {
        setState(() => _status = 'No exported backup to restore');
        return;
      }
      final result = _service.restoreBackup(backup);
      setState(() {
        _restorePreview = null;
        _selected = null;
        _status =
            'Restored backup: ${result.restoredPhotoCount} photos, ${result.restoredMemoryCount} memories';
      });
    } on Object catch (error) {
      setState(() => _status = 'Restore failed: $error');
    }
  }
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
