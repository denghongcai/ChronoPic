import 'dart:io';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _UiLocale { en, zh }

final class _UiStrings {
  const _UiStrings({
    required this.appTitle,
    required this.exportBackup,
    required this.previewRestore,
    required this.restoreBackup,
    required this.allPhotos,
    required this.favorites,
    required this.memories,
    required this.language,
    required this.libraryFolderPath,
    required this.chooseFolder,
    required this.addLibrary,
    required this.scanLibrary,
    required this.searchAndFilters,
    required this.applyFilters,
    required this.clearFilters,
    required this.backupJsonPath,
    required this.chooseExportPath,
    required this.chooseRestoreFile,
    required this.exportBackupFile,
    required this.previewBackupFile,
    required this.restoreBackupFile,
    required this.memoryName,
    required this.createMemory,
    required this.addToMemory,
    required this.clearMemoryFilter,
    required this.grid,
    required this.map,
    required this.timeline,
  });

  final String appTitle;
  final String exportBackup;
  final String previewRestore;
  final String restoreBackup;
  final String allPhotos;
  final String favorites;
  final String memories;
  final String language;
  final String libraryFolderPath;
  final String chooseFolder;
  final String addLibrary;
  final String scanLibrary;
  final String searchAndFilters;
  final String applyFilters;
  final String clearFilters;
  final String backupJsonPath;
  final String chooseExportPath;
  final String chooseRestoreFile;
  final String exportBackupFile;
  final String previewBackupFile;
  final String restoreBackupFile;
  final String memoryName;
  final String createMemory;
  final String addToMemory;
  final String clearMemoryFilter;
  final String grid;
  final String map;
  final String timeline;
}

const Map<_UiLocale, _UiStrings> _uiStrings = <_UiLocale, _UiStrings>{
  _UiLocale.en: _UiStrings(
    appTitle: 'ChronoPic Flutter',
    exportBackup: 'Export Backup',
    previewRestore: 'Preview Restore',
    restoreBackup: 'Restore Backup',
    allPhotos: 'All Photos',
    favorites: 'Favorites',
    memories: 'Memories',
    language: 'Language',
    libraryFolderPath: 'Library folder path',
    chooseFolder: 'Choose Folder',
    addLibrary: 'Add Library',
    scanLibrary: 'Scan Library',
    searchAndFilters: 'Search and filters',
    applyFilters: 'Apply Filters',
    clearFilters: 'Clear Filters',
    backupJsonPath: 'Backup JSON path',
    chooseExportPath: 'Choose Export Path',
    chooseRestoreFile: 'Choose Restore File',
    exportBackupFile: 'Export Backup File',
    previewBackupFile: 'Preview Backup File',
    restoreBackupFile: 'Restore Backup File',
    memoryName: 'Memory name',
    createMemory: 'Create Memory',
    addToMemory: 'Add to Memory',
    clearMemoryFilter: 'Clear Memory Filter',
    grid: 'Grid',
    map: 'Map',
    timeline: 'Timeline',
  ),
  _UiLocale.zh: _UiStrings(
    appTitle: 'ChronoPic Flutter',
    exportBackup: '导出备份',
    previewRestore: '预览恢复',
    restoreBackup: '恢复备份',
    allPhotos: '全部照片',
    favorites: '收藏',
    memories: '回忆',
    language: '语言',
    libraryFolderPath: '图库文件夹路径',
    chooseFolder: '选择文件夹',
    addLibrary: '添加图库',
    scanLibrary: '扫描图库',
    searchAndFilters: '搜索和筛选',
    applyFilters: '应用筛选',
    clearFilters: '清除筛选',
    backupJsonPath: '备份 JSON 路径',
    chooseExportPath: '选择导出路径',
    chooseRestoreFile: '选择恢复文件',
    exportBackupFile: '导出备份文件',
    previewBackupFile: '预览备份文件',
    restoreBackupFile: '恢复备份文件',
    memoryName: '回忆名称',
    createMemory: '创建回忆',
    addToMemory: '加入回忆',
    clearMemoryFilter: '清除回忆筛选',
    grid: '网格',
    map: '地图',
    timeline: '时间线',
  ),
};

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
  String _query = '';
  String? _tagFilter;
  AiPipelineStatus? _aiStatusFilter;
  int? _fromDatetimeFilter;
  int? _toDatetimeFilter;
  bool _favoriteOnly = false;
  bool _gpsOnly = false;
  bool _scanning = false;
  _BrowseMode _browseMode = _BrowseMode.grid;
  _UiLocale _locale = _UiLocale.en;
  PhotoSortBy _sortBy = PhotoSortBy.datetime;
  SortDirection _sortDirection = SortDirection.desc;
  String? _selectedMemoryId;
  String _status = 'Scan progress: idle';
  PhotoRecord? _selected;
  ChronoPicBackup? _lastBackup;
  BackupRestorePreview? _restorePreview;
  bool _aiSettingsLoaded = false;

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
    final photos = _visiblePhotos();
    final memories = _service.listMemories();
    final aiReadiness = _service.getAiSetupReadiness();
    final aiStatusCounts = _service.getAiStatusCounts();
    final memoryCandidates = _service.listMemoryCandidates();
    _loadAiSettingsOnce();
    final selectedMemory = _selectedMemoryId == null
        ? null
        : _service.getMemory(_selectedMemoryId!);
    return MaterialApp(
      title: _l10n.appTitle,
      home: Builder(
        builder: (context) => Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleShellKey(context, event),
          child: Scaffold(
            appBar: AppBar(
              title: Text(_l10n.appTitle, key: const Key('app-title')),
              actions: <Widget>[
                TextButton(
                  key: const Key('export-backup'),
                  onPressed: _exportBackup,
                  child: Text(_l10n.exportBackup),
                ),
                TextButton(
                  key: const Key('preview-restore'),
                  onPressed: _previewRestore,
                  child: Text(_l10n.previewRestore),
                ),
                TextButton(
                  key: const Key('restore-backup'),
                  onPressed: _restoreBackup,
                  child: Text(_l10n.restoreBackup),
                ),
              ],
            ),
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _selectedMemoryId != null
                      ? 2
                      : (_favoriteOnly ? 1 : 0),
                  onDestinationSelected: (index) {
                    setState(() {
                      _favoriteOnly = index == 1;
                      if (index != 2) _selectedMemoryId = null;
                    });
                  },
                  destinations: <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        key: Key('all-photos-nav'),
                      ),
                      label: Text(_l10n.allPhotos),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(
                        Icons.star_border,
                        key: Key('favorites-nav'),
                      ),
                      label: Text(_l10n.favorites),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(
                        Icons.auto_stories_outlined,
                        key: Key('memories-nav'),
                      ),
                      label: Text(_l10n.memories),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _LibraryToolbar(
                            labels: _l10n,
                            libraryPathController: _libraryPathController,
                            scanning: _scanning,
                            onChooseLibraryFolder: _chooseLibraryFolder,
                            onAddLibrary: _addLibrary,
                            onScanLibrary: _scanLibrary,
                            onSearchChanged: (value) =>
                                setState(() => _query = value),
                          ),
                          const SizedBox(height: 12),
                          _LocaleSelector(
                            locale: _locale,
                            labels: _l10n,
                            onChanged: (locale) =>
                                setState(() => _locale = locale),
                          ),
                          const SizedBox(height: 12),
                          _FilterToolbar(
                            labels: _l10n,
                            tagController: _tagFilterController,
                            fromDateController: _fromDateFilterController,
                            toDateController: _toDateFilterController,
                            gpsOnly: _gpsOnly,
                            aiStatus: _aiStatusFilter,
                            sortBy: _sortBy,
                            sortDirection: _sortDirection,
                            onGpsOnlyChanged: (value) =>
                                setState(() => _gpsOnly = value),
                            onAiStatusChanged: (value) =>
                                setState(() => _aiStatusFilter = value),
                            onSortByChanged: (value) =>
                                setState(() => _sortBy = value),
                            onSortDirectionChanged: (value) =>
                                setState(() => _sortDirection = value),
                            onApply: _applyFilters,
                            onClear: _clearFilters,
                          ),
                          const SizedBox(height: 8),
                          _ActiveFilterSummary(labels: _activeFilterLabels()),
                          const SizedBox(height: 12),
                          Text(_status, key: const Key('scan-status')),
                          if (_restorePreview != null)
                            Text(
                              'Restore preview: ${_restorePreview!.photoCount} photos, ${_restorePreview!.memoryCount} memories',
                            ),
                          const SizedBox(height: 12),
                          _AiStatusPanel(
                            labels: _l10n,
                            readiness: aiReadiness,
                            statusCounts: aiStatusCounts,
                            candidates: memoryCandidates,
                            providerController: _aiProviderController,
                            baseUrlController: _aiBaseUrlController,
                            modelController: _aiModelController,
                            apiKeyController: _aiApiKeyController,
                            onSaveSettings: _saveAiSettings,
                            onRetryQueue: _retryAiQueue,
                            onAcceptCandidate: _acceptMemoryCandidate,
                            onRejectCandidate: _rejectMemoryCandidate,
                          ),
                          const SizedBox(height: 12),
                          _BackupToolbar(
                            labels: _l10n,
                            backupPathController: _backupPathController,
                            onChooseExportPath: _chooseBackupExportPath,
                            onChooseRestorePath: _chooseBackupRestorePath,
                            onExport: _exportBackup,
                            onPreview: _previewRestore,
                            onRestore: _restoreBackup,
                          ),
                          const SizedBox(height: 12),
                          _MemoryBar(
                            labels: _l10n,
                            memories: memories,
                            selectedMemoryId: _selectedMemoryId,
                            memoryNameController: _memoryNameController,
                            onClearMemory: () => setState(() {
                              _selectedMemoryId = null;
                              _memoryTitleController.clear();
                              _memoryDescriptionController.clear();
                            }),
                            onSelectMemory: _selectMemory,
                            onCreateMemory: _createMemory,
                            onAddSelectedToMemory: _addSelectedToMemory,
                          ),
                          if (selectedMemory != null) ...[
                            const SizedBox(height: 12),
                            _MemoryDetailPanel(
                              memory: selectedMemory,
                              selectedPhoto: _selected,
                              titleController: _memoryTitleController,
                              descriptionController:
                                  _memoryDescriptionController,
                              onSave: _saveSelectedMemory,
                              onSetCover: _setSelectedAsMemoryCover,
                              onRemoveSelectedPhoto: _removeSelectedFromMemory,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _BrowseModeSelector(
                            labels: _l10n,
                            mode: _browseMode,
                            onChanged: (mode) =>
                                setState(() => _browseMode = mode),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 360,
                            child: _BrowseSurface(
                              mode: _browseMode,
                              photos: photos,
                              onSelectPhoto: _selectPhoto,
                              photoCardBuilder: _photoCard,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailSurface(
                            record: _selected,
                            captionController: _captionController,
                            tagsController: _tagsController,
                            dateController: _dateController,
                            timeController: _timeController,
                            onSaveCaption: _saveCaption,
                            onSaveTags: _saveTags,
                            onSaveDatetime: _saveDatetime,
                            onToggleFavorite: _toggleSelectedFavorite,
                            onOpenGallery: _openGallery,
                            onRollback: _rollbackLatestEdit,
                          ),
                        ],
                      ),
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

  _UiStrings get _l10n => _uiStrings[_locale]!;

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

  Widget _photoCard(PhotoRecord record) {
    return Card(
      child: InkWell(
        key: Key('photo-card-${record.photo.id}'),
        onTap: () => _selectPhoto(record),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _MediaPreview(record: record)),
              Text(
                record.semantic.caption ?? _basename(record.photo.path),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(record.photo.favorite ? 'Favorite' : 'Not favorite'),
              TextButton.icon(
                key: Key('favorite-${record.photo.id}'),
                onPressed: () => _toggleFavorite(record),
                icon: Icon(
                  record.photo.favorite ? Icons.star : Icons.star_border,
                ),
                label: Text(record.photo.favorite ? 'Unfavorite' : 'Favorite'),
              ),
            ],
          ),
        ),
      ),
    );
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
      _browseMode = _BrowseMode.grid;
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
    final records = _visiblePhotos();
    final selectedIndex = records.indexWhere(
      (record) => record.photo.id == selected.photo.id,
    );
    final galleryRecords = selectedIndex < 0
        ? <PhotoRecord>[selected, ...records]
        : records;
    final result = await showDialog<PhotoRecord>(
      context: dialogContext,
      builder: (context) => _GalleryDialog(
        records: galleryRecords,
        initialIndex: selectedIndex < 0 ? 0 : selectedIndex,
      ),
    );
    if (result != null && mounted) {
      _selectPhoto(result);
    }
  }

  void _createMemory() {
    final name = _memoryNameController.text.trim();
    if (name.isEmpty) return;
    final memory = _service.createMemory(name);
    setState(() {
      _selectedMemoryId = memory.id;
      _favoriteOnly = false;
      _memoryTitleController.text = memory.name;
      _memoryDescriptionController.text = memory.description ?? '';
      _status = 'Created memory: ${memory.name}';
    });
  }

  void _selectMemory(String memoryId) {
    final memory = _service.getMemory(memoryId);
    if (memory == null) return;
    setState(() {
      _selectedMemoryId = memoryId;
      _favoriteOnly = false;
      _memoryTitleController.text = memory.name;
      _memoryDescriptionController.text = memory.description ?? '';
      _status = 'Selected memory: ${memory.name}';
    });
  }

  void _addSelectedToMemory() {
    final selected = _selected;
    final memoryId = _selectedMemoryId;
    if (selected == null || memoryId == null) {
      setState(() => _status = 'Select a photo and memory first');
      return;
    }
    _service.addPhotoToMemory(memoryId, selected.photo.id);
    setState(() => _status = 'Added photo to memory');
  }

  void _saveSelectedMemory() {
    final memoryId = _selectedMemoryId;
    if (memoryId == null) return;
    final name = _memoryTitleController.text.trim();
    if (name.isEmpty) {
      setState(() => _status = 'Memory title is required');
      return;
    }
    final description = _memoryDescriptionController.text.trim();
    final memory = _service.updateMemory(
      memoryId,
      name: name,
      description: description.isEmpty ? null : description,
    );
    setState(() => _status = 'Saved memory: ${memory.name}');
  }

  void _setSelectedAsMemoryCover() {
    final selected = _selected;
    final memoryId = _selectedMemoryId;
    if (selected == null || memoryId == null) {
      setState(() => _status = 'Select a photo and memory first');
      return;
    }
    _service.setMemoryCover(memoryId, selected.photo.id);
    setState(() => _status = 'Set memory cover');
  }

  void _removeSelectedFromMemory() {
    final selected = _selected;
    final memoryId = _selectedMemoryId;
    if (selected == null || memoryId == null) {
      setState(() => _status = 'Select a photo and memory first');
      return;
    }
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
      if (location == null) return;
      setState(() {
        _backupPathController.text = location.path;
        _status = 'Selected backup export path: ${location.path}';
      });
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
      if (file == null) return;
      setState(() {
        _backupPathController.text = file.path;
        _status = 'Selected backup restore file: ${file.path}';
      });
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
    setState(() => _status = 'Queued $count failed AI items for retry');
  }

  void _acceptMemoryCandidate(String candidateId) {
    final memory = _service.acceptMemoryCandidate(candidateId);
    setState(() {
      _selectedMemoryId = memory.id;
      _memoryTitleController.text = memory.name;
      _memoryDescriptionController.text = memory.description ?? '';
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
      final preview = path.isEmpty
          ? _service.previewBackupRestore(
              _lastBackup ?? _service.createBackup(),
            )
          : _service.previewBackupFile(path);
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
        _selected = null;
        _status =
            'Restored backup: ${result.restoredPhotoCount} photos, ${result.restoredMemoryCount} memories';
      });
    } on Object catch (error) {
      setState(() => _status = 'Restore failed: $error');
    }
  }
}

final class _BackupToolbar extends StatelessWidget {
  const _BackupToolbar({
    required this.labels,
    required this.backupPathController,
    required this.onChooseExportPath,
    required this.onChooseRestorePath,
    required this.onExport,
    required this.onPreview,
    required this.onRestore,
  });

  final _UiStrings labels;
  final TextEditingController backupPathController;
  final VoidCallback onChooseExportPath;
  final VoidCallback onChooseRestorePath;
  final VoidCallback onExport;
  final VoidCallback onPreview;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 420,
          child: TextField(
            key: const Key('backup-path-field'),
            controller: backupPathController,
            decoration: InputDecoration(
              labelText: labels.backupJsonPath,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        OutlinedButton(
          key: const Key('choose-backup-export-path'),
          onPressed: onChooseExportPath,
          child: Text(labels.chooseExportPath),
        ),
        OutlinedButton(
          key: const Key('choose-backup-restore-path'),
          onPressed: onChooseRestorePath,
          child: Text(labels.chooseRestoreFile),
        ),
        OutlinedButton(
          key: const Key('export-backup-file'),
          onPressed: onExport,
          child: Text(labels.exportBackupFile),
        ),
        OutlinedButton(
          key: const Key('preview-backup-file'),
          onPressed: onPreview,
          child: Text(labels.previewBackupFile),
        ),
        OutlinedButton(
          key: const Key('restore-backup-file'),
          onPressed: onRestore,
          child: Text(labels.restoreBackupFile),
        ),
      ],
    );
  }
}

final class _LocaleSelector extends StatelessWidget {
  const _LocaleSelector({
    required this.locale,
    required this.labels,
    required this.onChanged,
  });

  final _UiLocale locale;
  final _UiStrings labels;
  final ValueChanged<_UiLocale> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('locale-switcher'),
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(labels.language, key: const Key('locale-label')),
        SegmentedButton<_UiLocale>(
          segments: const <ButtonSegment<_UiLocale>>[
            ButtonSegment<_UiLocale>(
              value: _UiLocale.en,
              label: Text('English'),
            ),
            ButtonSegment<_UiLocale>(value: _UiLocale.zh, label: Text('中文')),
          ],
          selected: <_UiLocale>{locale},
          onSelectionChanged: (selection) => onChanged(selection.single),
        ),
      ],
    );
  }
}

final class _AiStatusPanel extends StatelessWidget {
  const _AiStatusPanel({
    required this.labels,
    required this.readiness,
    required this.statusCounts,
    required this.candidates,
    required this.providerController,
    required this.baseUrlController,
    required this.modelController,
    required this.apiKeyController,
    required this.onSaveSettings,
    required this.onRetryQueue,
    required this.onAcceptCandidate,
    required this.onRejectCandidate,
  });

  final _UiStrings labels;
  final AiReadiness readiness;
  final Map<AiPipelineStatus, int> statusCounts;
  final List<MemoryCandidate> candidates;
  final TextEditingController providerController;
  final TextEditingController baseUrlController;
  final TextEditingController modelController;
  final TextEditingController apiKeyController;
  final VoidCallback onSaveSettings;
  final VoidCallback onRetryQueue;
  final ValueChanged<String> onAcceptCandidate;
  final ValueChanged<String> onRejectCandidate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  readiness.configured
                      ? 'AI readiness: configured'
                      : 'AI readiness: incomplete',
                  key: const Key('ai-readiness-status'),
                ),
                Text(
                  'Missing: ${readiness.missingFields.join(', ')}',
                  key: const Key('ai-readiness-missing-fields'),
                ),
                for (final status in AiPipelineStatus.values)
                  Chip(
                    key: Key('ai-status-count-${status.name}'),
                    label: Text(
                      'AI ${status.name}: ${statusCounts[status] ?? 0}',
                    ),
                  ),
                Chip(
                  key: const Key('memory-candidate-count'),
                  label: Text('Memory candidates: ${candidates.length}'),
                ),
                OutlinedButton.icon(
                  key: const Key('retry-ai-queue-button'),
                  onPressed: onRetryQueue,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Failed AI'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                SizedBox(
                  width: 180,
                  child: TextField(
                    key: const Key('ai-provider-field'),
                    controller: providerController,
                    decoration: const InputDecoration(
                      labelText: 'AI provider',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const Key('ai-base-url-field'),
                    controller: baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'AI base URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    key: const Key('ai-model-field'),
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'AI model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    key: const Key('ai-api-key-field'),
                    controller: apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'AI API key',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ),
                FilledButton.icon(
                  key: const Key('save-ai-settings-button'),
                  onPressed: onSaveSettings,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save AI Settings'),
                ),
              ],
            ),
            if (candidates.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final candidate in candidates)
                ListTile(
                  key: Key('memory-candidate-${candidate.id}'),
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(candidate.title),
                  subtitle: Text(
                    '${candidate.reason} (${candidate.photoIds.length} photos)',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      TextButton(
                        key: Key('accept-candidate-${candidate.id}'),
                        onPressed: () => onAcceptCandidate(candidate.id),
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        key: Key('reject-candidate-${candidate.id}'),
                        onPressed: () => onRejectCandidate(candidate.id),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({required this.labels});

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
      children: <Widget>[
        const Text('Active filters:'),
        for (final label in labels)
          Chip(key: Key('active-filter-$label'), label: Text(label)),
      ],
    );
  }
}

final class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
    required this.labels,
    required this.libraryPathController,
    required this.scanning,
    required this.onChooseLibraryFolder,
    required this.onAddLibrary,
    required this.onScanLibrary,
    required this.onSearchChanged,
  });

  final _UiStrings labels;
  final TextEditingController libraryPathController;
  final bool scanning;
  final VoidCallback onChooseLibraryFolder;
  final VoidCallback onAddLibrary;
  final VoidCallback onScanLibrary;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 320,
          child: TextField(
            key: const Key('library-path-field'),
            controller: libraryPathController,
            decoration: InputDecoration(
              labelText: labels.libraryFolderPath,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        FilledButton.icon(
          key: const Key('choose-library-folder-button'),
          onPressed: onChooseLibraryFolder,
          icon: const Icon(Icons.folder_open),
          label: Text(labels.chooseFolder),
        ),
        FilledButton.icon(
          key: const Key('add-library-button'),
          onPressed: onAddLibrary,
          icon: const Icon(Icons.create_new_folder_outlined),
          label: Text(labels.addLibrary),
        ),
        FilledButton.tonalIcon(
          key: const Key('scan-library-button'),
          onPressed: scanning ? null : onScanLibrary,
          icon: const Icon(Icons.sync),
          label: Text(labels.scanLibrary),
        ),
        SizedBox(
          width: 320,
          child: TextField(
            key: const Key('search-field'),
            decoration: InputDecoration(
              labelText: labels.searchAndFilters,
              border: const OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
        ),
      ],
    );
  }
}

final class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.labels,
    required this.tagController,
    required this.fromDateController,
    required this.toDateController,
    required this.gpsOnly,
    required this.aiStatus,
    required this.sortBy,
    required this.sortDirection,
    required this.onGpsOnlyChanged,
    required this.onAiStatusChanged,
    required this.onSortByChanged,
    required this.onSortDirectionChanged,
    required this.onApply,
    required this.onClear,
  });

  final _UiStrings labels;
  final TextEditingController tagController;
  final TextEditingController fromDateController;
  final TextEditingController toDateController;
  final bool gpsOnly;
  final AiPipelineStatus? aiStatus;
  final PhotoSortBy sortBy;
  final SortDirection sortDirection;
  final ValueChanged<bool> onGpsOnlyChanged;
  final ValueChanged<AiPipelineStatus?> onAiStatusChanged;
  final ValueChanged<PhotoSortBy> onSortByChanged;
  final ValueChanged<SortDirection> onSortDirectionChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 180,
          child: TextField(
            key: const Key('tag-filter-field'),
            controller: tagController,
            decoration: const InputDecoration(
              labelText: 'Tag',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        FilterChip(
          key: const Key('gps-filter-chip'),
          selected: gpsOnly,
          label: const Text('GPS only'),
          onSelected: onGpsOnlyChanged,
        ),
        DropdownButton<AiPipelineStatus?>(
          key: const Key('ai-status-filter-control'),
          value: aiStatus,
          onChanged: onAiStatusChanged,
          items: const <DropdownMenuItem<AiPipelineStatus?>>[
            DropdownMenuItem<AiPipelineStatus?>(
              value: null,
              child: Text('AI: any'),
            ),
            DropdownMenuItem<AiPipelineStatus?>(
              value: AiPipelineStatus.disabled,
              child: Text('AI: disabled'),
            ),
            DropdownMenuItem<AiPipelineStatus?>(
              value: AiPipelineStatus.pending,
              child: Text('AI: pending'),
            ),
            DropdownMenuItem<AiPipelineStatus?>(
              value: AiPipelineStatus.processing,
              child: Text('AI: processing'),
            ),
            DropdownMenuItem<AiPipelineStatus?>(
              value: AiPipelineStatus.completed,
              child: Text('AI: completed'),
            ),
            DropdownMenuItem<AiPipelineStatus?>(
              value: AiPipelineStatus.failed,
              child: Text('AI: failed'),
            ),
          ],
        ),
        SizedBox(
          width: 150,
          child: TextField(
            key: const Key('from-date-filter-field'),
            controller: fromDateController,
            decoration: const InputDecoration(
              labelText: 'From date',
              hintText: 'YYYY-MM-DD',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          width: 150,
          child: TextField(
            key: const Key('to-date-filter-field'),
            controller: toDateController,
            decoration: const InputDecoration(
              labelText: 'To date',
              hintText: 'YYYY-MM-DD',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        DropdownButton<PhotoSortBy>(
          key: const Key('sort-by-control'),
          value: sortBy,
          onChanged: (value) {
            if (value != null) onSortByChanged(value);
          },
          items: const <DropdownMenuItem<PhotoSortBy>>[
            DropdownMenuItem(
              value: PhotoSortBy.datetime,
              child: Text('Sort: datetime'),
            ),
            DropdownMenuItem(
              value: PhotoSortBy.path,
              child: Text('Sort: path'),
            ),
            DropdownMenuItem(
              value: PhotoSortBy.updatedAt,
              child: Text('Sort: updated'),
            ),
          ],
        ),
        DropdownButton<SortDirection>(
          key: const Key('sort-direction-control'),
          value: sortDirection,
          onChanged: (value) {
            if (value != null) onSortDirectionChanged(value);
          },
          items: const <DropdownMenuItem<SortDirection>>[
            DropdownMenuItem(value: SortDirection.desc, child: Text('Desc')),
            DropdownMenuItem(value: SortDirection.asc, child: Text('Asc')),
          ],
        ),
        FilledButton(
          key: const Key('apply-filter-button'),
          onPressed: onApply,
          child: Text(labels.applyFilters),
        ),
        OutlinedButton(
          key: const Key('clear-filter-button'),
          onPressed: onClear,
          child: Text(labels.clearFilters),
        ),
      ],
    );
  }
}

final class _MemoryBar extends StatelessWidget {
  const _MemoryBar({
    required this.labels,
    required this.memories,
    required this.selectedMemoryId,
    required this.memoryNameController,
    required this.onClearMemory,
    required this.onSelectMemory,
    required this.onCreateMemory,
    required this.onAddSelectedToMemory,
  });

  final _UiStrings labels;
  final List<Memory> memories;
  final String? selectedMemoryId;
  final TextEditingController memoryNameController;
  final VoidCallback onClearMemory;
  final ValueChanged<String> onSelectMemory;
  final VoidCallback onCreateMemory;
  final VoidCallback onAddSelectedToMemory;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 220,
          child: TextField(
            key: const Key('memory-name-field'),
            controller: memoryNameController,
            decoration: InputDecoration(
              labelText: labels.memoryName,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        OutlinedButton(
          key: const Key('create-memory-button'),
          onPressed: onCreateMemory,
          child: Text(labels.createMemory),
        ),
        OutlinedButton(
          key: const Key('add-to-memory-button'),
          onPressed: onAddSelectedToMemory,
          child: Text(labels.addToMemory),
        ),
        if (selectedMemoryId != null)
          InputChip(
            label: Text(labels.clearMemoryFilter),
            onPressed: onClearMemory,
          ),
        for (final memory in memories)
          ChoiceChip(
            key: Key('memory-chip-${memory.id}'),
            selected: selectedMemoryId == memory.id,
            label: Text('${memory.name} (${memory.photoCount})'),
            onSelected: (_) => onSelectMemory(memory.id),
          ),
      ],
    );
  }
}

enum _BrowseMode { grid, map, timeline }

final class _BrowseModeSelector extends StatelessWidget {
  const _BrowseModeSelector({
    required this.labels,
    required this.mode,
    required this.onChanged,
  });

  final _UiStrings labels;
  final _BrowseMode mode;
  final ValueChanged<_BrowseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_BrowseMode>(
      key: const Key('browse-mode-control'),
      segments: <ButtonSegment<_BrowseMode>>[
        ButtonSegment<_BrowseMode>(
          value: _BrowseMode.grid,
          icon: const Icon(Icons.grid_view),
          label: Text(labels.grid),
        ),
        ButtonSegment<_BrowseMode>(
          value: _BrowseMode.map,
          icon: const Icon(Icons.map_outlined),
          label: Text(labels.map),
        ),
        ButtonSegment<_BrowseMode>(
          value: _BrowseMode.timeline,
          icon: const Icon(Icons.timeline),
          label: Text(labels.timeline),
        ),
      ],
      selected: <_BrowseMode>{mode},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

final class _BrowseSurface extends StatelessWidget {
  const _BrowseSurface({
    required this.mode,
    required this.photos,
    required this.onSelectPhoto,
    required this.photoCardBuilder,
  });

  final _BrowseMode mode;
  final List<PhotoRecord> photos;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final Widget Function(PhotoRecord) photoCardBuilder;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const _EmptyLibrary();
    return switch (mode) {
      _BrowseMode.grid => LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            key: const Key('photo-grid'),
            crossAxisCount: _gridColumnCount(constraints.maxWidth),
            childAspectRatio: 0.72,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: photos.map(photoCardBuilder).toList(),
          );
        },
      ),
      _BrowseMode.map => _MapBrowseView(
        photos: photos,
        onSelectPhoto: onSelectPhoto,
      ),
      _BrowseMode.timeline => _TimelineBrowseView(
        photos: photos,
        onSelectPhoto: onSelectPhoto,
      ),
    };
  }
}

final class _MapBrowseView extends StatelessWidget {
  const _MapBrowseView({required this.photos, required this.onSelectPhoto});

  final List<PhotoRecord> photos;
  final ValueChanged<PhotoRecord> onSelectPhoto;

  @override
  Widget build(BuildContext context) {
    final mapped = photos
        .where(
          (record) =>
              record.metadata.lat != null && record.metadata.lng != null,
        )
        .toList();
    if (mapped.isEmpty) {
      return const Center(
        key: Key('map-view'),
        child: Text('No mapped photos'),
      );
    }
    return ListView.separated(
      key: const Key('map-view'),
      itemCount: mapped.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = mapped[index];
        return ListTile(
          key: Key('map-photo-${record.photo.id}'),
          leading: const Icon(Icons.place_outlined),
          title: Text(record.semantic.caption ?? _basename(record.photo.path)),
          subtitle: Text('${record.metadata.lat}, ${record.metadata.lng}'),
          onTap: () => onSelectPhoto(record),
        );
      },
    );
  }
}

final class _TimelineBrowseView extends StatelessWidget {
  const _TimelineBrowseView({
    required this.photos,
    required this.onSelectPhoto,
  });

  final List<PhotoRecord> photos;
  final ValueChanged<PhotoRecord> onSelectPhoto;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PhotoRecord>>{};
    for (final record in photos) {
      final key = _timelineDateKey(record.metadata.datetime);
      groups.putIfAbsent(key, () => <PhotoRecord>[]).add(record);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView(
      key: const Key('timeline-view'),
      children: <Widget>[
        for (final date in dates) ...[
          Padding(
            key: Key('timeline-group-$date'),
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: Text(date, style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final record in groups[date]!)
            ListTile(
              key: Key('timeline-photo-${record.photo.id}'),
              leading: const Icon(Icons.event_outlined),
              title: Text(
                record.semantic.caption ?? _basename(record.photo.path),
              ),
              subtitle: Text(_formatMetadataDatetime(record.metadata.datetime)),
              onTap: () => onSelectPhoto(record),
            ),
        ],
      ],
    );
  }
}

final class _MemoryDetailPanel extends StatelessWidget {
  const _MemoryDetailPanel({
    required this.memory,
    required this.selectedPhoto,
    required this.titleController,
    required this.descriptionController,
    required this.onSave,
    required this.onSetCover,
    required this.onRemoveSelectedPhoto,
  });

  final Memory memory;
  final PhotoRecord? selectedPhoto;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onSave;
  final VoidCallback onSetCover;
  final VoidCallback onRemoveSelectedPhoto;

  @override
  Widget build(BuildContext context) {
    final selectedPhotoName = selectedPhoto == null
        ? 'No photo selected'
        : _basename(selectedPhoto!.photo.path);
    return Card(
      key: const Key('memory-detail-panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Memory detail',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(
                  key: const Key('memory-photo-count'),
                  label: Text('Photos: ${memory.photoCount}'),
                ),
                Chip(
                  key: const Key('memory-cover-photo'),
                  label: Text('Cover: ${memory.coverPhotoId ?? 'none'}'),
                ),
                Chip(label: Text('Selected: $selectedPhotoName')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('memory-title-field'),
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Memory title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('memory-description-field'),
              controller: descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Memory description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  key: const Key('save-memory-button'),
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Memory'),
                ),
                OutlinedButton.icon(
                  key: const Key('set-memory-cover-button'),
                  onPressed: selectedPhoto == null ? null : onSetCover,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Set Cover'),
                ),
                OutlinedButton.icon(
                  key: const Key('remove-from-memory-button'),
                  onPressed: selectedPhoto == null
                      ? null
                      : onRemoveSelectedPhoto,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Remove Photo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.photo_library_outlined, size: 64),
          Text('First run library setup'),
          Text('Add a folder, scan, then browse photos here.'),
        ],
      ),
    );
  }
}

final class _DetailSurface extends StatelessWidget {
  const _DetailSurface({
    required this.record,
    required this.captionController,
    required this.tagsController,
    required this.dateController,
    required this.timeController,
    required this.onSaveCaption,
    required this.onSaveTags,
    required this.onSaveDatetime,
    required this.onToggleFavorite,
    required this.onOpenGallery,
    required this.onRollback,
  });

  final PhotoRecord? record;
  final TextEditingController captionController;
  final TextEditingController tagsController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveTags;
  final VoidCallback onSaveDatetime;
  final VoidCallback onToggleFavorite;
  final ValueChanged<BuildContext> onOpenGallery;
  final VoidCallback onRollback;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Detail view and gallery view'),
            SizedBox(
              height: 220,
              child: selected == null
                  ? const Center(child: Icon(Icons.image_outlined, size: 72))
                  : _MediaPreview(record: selected, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(selected == null ? 'No photo selected' : selected.photo.path),
            if (selected != null) ...[
              const SizedBox(height: 8),
              _MetadataGrid(record: selected),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('open-gallery-button'),
              onPressed: selected == null ? null : () => onOpenGallery(context),
              icon: const Icon(Icons.fullscreen),
              label: const Text('Open Gallery'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const Key('caption-field'),
                    controller: captionController,
                    decoration: const InputDecoration(
                      labelText: 'Edit caption',
                      border: OutlineInputBorder(),
                    ),
                    enabled: selected != null,
                  ),
                ),
                FilledButton(
                  key: const Key('save-caption-button'),
                  onPressed: selected == null ? null : onSaveCaption,
                  child: const Text('Save Caption'),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const Key('tags-field'),
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Edit tags',
                      border: OutlineInputBorder(),
                    ),
                    enabled: selected != null,
                  ),
                ),
                FilledButton(
                  key: const Key('save-tags-button'),
                  onPressed: selected == null ? null : onSaveTags,
                  child: const Text('Save Tags'),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    key: const Key('date-field'),
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    enabled: selected != null,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    key: const Key('time-field'),
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      hintText: 'HH:mm',
                      border: OutlineInputBorder(),
                    ),
                    enabled: selected != null,
                  ),
                ),
                FilledButton(
                  key: const Key('save-datetime-button'),
                  onPressed: selected == null ? null : onSaveDatetime,
                  child: const Text('Save Datetime'),
                ),
                OutlinedButton(
                  key: const Key('detail-favorite-button'),
                  onPressed: selected == null ? null : onToggleFavorite,
                  child: Text(
                    selected?.photo.favorite == true
                        ? 'Unfavorite'
                        : 'Favorite',
                  ),
                ),
                OutlinedButton(
                  key: const Key('rollback-button'),
                  onPressed: selected == null ? null : onRollback,
                  child: const Text('Rollback Latest Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _MetadataGrid extends StatelessWidget {
  const _MetadataGrid({required this.record});

  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, Key)>[
      (
        'Captured',
        _formatMetadataDatetime(record.metadata.datetime),
        const Key('metadata-captured'),
      ),
      (
        'Time zone',
        _formatMetadataTimezone(record.metadata.datetime),
        const Key('metadata-timezone'),
      ),
      (
        'Original date text',
        record.metadata.originalDatetimeText ?? 'None',
        const Key('metadata-original-date'),
      ),
      (
        'Camera',
        record.metadata.camera ?? 'Unknown',
        const Key('metadata-camera'),
      ),
      (
        'GPS',
        record.metadata.lat == null || record.metadata.lng == null
            ? 'None'
            : '${record.metadata.lat}, ${record.metadata.lng}',
        const Key('metadata-gps'),
      ),
      ('MIME', record.photo.mime, const Key('metadata-mime')),
      ('Size', '${record.photo.size} bytes', const Key('metadata-size')),
    ];
    return Wrap(
      key: const Key('metadata-grid'),
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final row in rows)
          Chip(key: row.$3, label: Text('${row.$1}: ${row.$2}')),
      ],
    );
  }
}

final class _GalleryDialog extends StatefulWidget {
  const _GalleryDialog({required this.records, required this.initialIndex});

  final List<PhotoRecord> records;
  final int initialIndex;

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

final class _GalleryDialogState extends State<_GalleryDialog> {
  late int _index = widget.initialIndex.clamp(0, widget.records.length - 1);

  PhotoRecord get _record => widget.records[_index];

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Dialog.fullscreen(
        child: Scaffold(
          key: const Key('gallery-dialog'),
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _basename(_record.photo.path),
                  key: Key('gallery-title-${_record.photo.id}'),
                ),
                Text(
                  '${_index + 1} / ${widget.records.length}',
                  key: const Key('gallery-counter'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                key: const Key('previous-gallery-button'),
                onPressed: _index == 0 ? null : () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                key: const Key('next-gallery-button'),
                onPressed: _index == widget.records.length - 1
                    ? null
                    : () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                key: const Key('close-gallery-button'),
                onPressed: () => Navigator.of(context).pop(_record),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Use arrow keys to browse, Esc to close',
                    key: Key('gallery-keyboard-hint'),
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _MediaPreview(record: _record, fit: BoxFit.contain),
                  ),
                ),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    key: const Key('gallery-filmstrip'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: widget.records.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final record = widget.records[index];
                      final selected = index == _index;
                      return OutlinedButton(
                        key: Key('gallery-filmstrip-${record.photo.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: selected
                              ? Colors.black
                              : Colors.white,
                          backgroundColor: selected
                              ? Colors.white
                              : Colors.transparent,
                          side: BorderSide(
                            color: selected ? Colors.white : Colors.white38,
                          ),
                        ),
                        onPressed: () => setState(() => _index = index),
                        child: Text(_basename(record.photo.path)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(_record);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _move(int delta) {
    final next = (_index + delta).clamp(0, widget.records.length - 1);
    if (next == _index) return;
    setState(() => _index = next);
  }
}

final class _DateTimeParseResult {
  const _DateTimeParseResult._(this.millisecondsSinceEpoch, this.isInvalid);

  const _DateTimeParseResult.clear() : this._(null, false);

  const _DateTimeParseResult.value(int millisecondsSinceEpoch)
    : this._(millisecondsSinceEpoch, false);

  static const invalid = _DateTimeParseResult._(null, true);

  final int? millisecondsSinceEpoch;
  final bool isInvalid;
}

final class _DateFilterParseResult {
  const _DateFilterParseResult._(this.millisecondsSinceEpoch, this.isInvalid);

  const _DateFilterParseResult.empty() : this._(null, false);

  const _DateFilterParseResult.value(int millisecondsSinceEpoch)
    : this._(millisecondsSinceEpoch, false);

  static const invalid = _DateFilterParseResult._(null, true);

  final int? millisecondsSinceEpoch;
  final bool isInvalid;
}

final class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.record, this.fit = BoxFit.cover});

  final PhotoRecord record;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final file = File(record.photo.thumbnailPath ?? record.photo.path);
    if (record.photo.mime.startsWith('video/')) {
      return Center(
        key: Key('video-preview-${record.photo.id}'),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.movie_outlined, size: 48),
            SizedBox(height: 4),
            Text('Video'),
          ],
        ),
      );
    }
    if (record.photo.mime.startsWith('image/') && file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          key: Key('media-preview-${record.photo.id}'),
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
        ),
      );
    }
    return const Center(child: Icon(Icons.image_outlined, size: 48));
  }
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final index = normalized.lastIndexOf('/');
  return index < 0 ? normalized : normalized.substring(index + 1);
}

int _gridColumnCount(double width) {
  if (width >= 1200) return 5;
  if (width >= 960) return 4;
  if (width >= 720) return 3;
  if (width >= 480) return 2;
  return 1;
}

String _formatDate(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatMetadataDatetime(int? millisecondsSinceEpoch) {
  if (millisecondsSinceEpoch == null) return 'Unknown';
  final dateTime = DateTime.fromMillisecondsSinceEpoch(
    millisecondsSinceEpoch,
  ).toLocal();
  return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
}

String _formatMetadataTimezone(int? millisecondsSinceEpoch) {
  if (millisecondsSinceEpoch == null) return 'Local';
  final dateTime = DateTime.fromMillisecondsSinceEpoch(
    millisecondsSinceEpoch,
  ).toLocal();
  final offset = dateTime.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absolute = offset.abs();
  final hours = absolute.inHours.toString().padLeft(2, '0');
  final minutes = absolute.inMinutes.remainder(60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}

String _timelineDateKey(int? millisecondsSinceEpoch) {
  if (millisecondsSinceEpoch == null) return 'Unknown';
  final dateTime = DateTime.fromMillisecondsSinceEpoch(
    millisecondsSinceEpoch,
  ).toLocal();
  return _formatDate(dateTime);
}
