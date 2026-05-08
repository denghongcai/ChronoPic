part of '../chronopic_home.dart';

enum UiLocale { en, zh }

final class UiStrings {
  const UiStrings({
    required this.appTitle,
    required this.exportBackup,
    required this.previewRestore,
    required this.restoreBackup,
    required this.allPhotos,
    required this.favorites,
    required this.memories,
    required this.language,
    required this.notifications,
    required this.settings,
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
  final String notifications;
  final String settings;
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

const Map<UiLocale, UiStrings> uiStrings = <UiLocale, UiStrings>{
  UiLocale.en: UiStrings(
    appTitle: 'ChronoPic Flutter',
    exportBackup: 'Export Backup',
    previewRestore: 'Preview Restore',
    restoreBackup: 'Restore Backup',
    allPhotos: 'All Photos',
    favorites: 'Favorites',
    memories: 'Memories',
    language: 'Language',
    notifications: 'Notifications',
    settings: 'Settings',
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
  UiLocale.zh: UiStrings(
    appTitle: 'ChronoPic Flutter',
    exportBackup: '导出备份',
    previewRestore: '预览恢复',
    restoreBackup: '恢复备份',
    allPhotos: '全部照片',
    favorites: '收藏',
    memories: '回忆',
    language: '语言',
    notifications: '通知',
    settings: '设置',
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
