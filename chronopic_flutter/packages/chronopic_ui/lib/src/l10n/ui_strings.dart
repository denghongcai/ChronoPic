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
    required this.languageDescription,
    required this.interfaceLanguage,
    required this.aiOutputLanguage,
    required this.followInterfaceLanguage,
    required this.saveLanguageSettings,
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
    required this.librarySection,
    required this.librarySubtitle,
    required this.discover,
    required this.highlights,
    required this.recentMemories,
    required this.newMemory,
    required this.newMemoryDescription,
    required this.photosUnit,
    required this.customCover,
    required this.noDescription,
    required this.itemsUnit,
    required this.matchesUnit,
    required this.tag,
    required this.gpsOnly,
    required this.aiAny,
    required this.aiDisabled,
    required this.aiPending,
    required this.aiProcessing,
    required this.aiCompleted,
    required this.aiFailed,
    required this.fromDate,
    required this.toDate,
    required this.sortDatetime,
    required this.sortPath,
    required this.sortUpdated,
    required this.desc,
    required this.asc,
    required this.activeFilters,
    required this.scanIdle,
  });

  final String appTitle;
  final String exportBackup;
  final String previewRestore;
  final String restoreBackup;
  final String allPhotos;
  final String favorites;
  final String memories;
  final String language;
  final String languageDescription;
  final String interfaceLanguage;
  final String aiOutputLanguage;
  final String followInterfaceLanguage;
  final String saveLanguageSettings;
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
  final String librarySection;
  final String librarySubtitle;
  final String discover;
  final String highlights;
  final String recentMemories;
  final String newMemory;
  final String newMemoryDescription;
  final String photosUnit;
  final String customCover;
  final String noDescription;
  final String itemsUnit;
  final String matchesUnit;
  final String tag;
  final String gpsOnly;
  final String aiAny;
  final String aiDisabled;
  final String aiPending;
  final String aiProcessing;
  final String aiCompleted;
  final String aiFailed;
  final String fromDate;
  final String toDate;
  final String sortDatetime;
  final String sortPath;
  final String sortUpdated;
  final String desc;
  final String asc;
  final String activeFilters;
  final String scanIdle;
}

const Map<UiLocale, UiStrings> uiStrings = <UiLocale, UiStrings>{
  UiLocale.en: UiStrings(
    appTitle: 'ChronoPic',
    exportBackup: 'Export Backup',
    previewRestore: 'Preview Restore',
    restoreBackup: 'Restore Backup',
    allPhotos: 'All Photos',
    favorites: 'Favorites',
    memories: 'Memories',
    language: 'Language',
    languageDescription:
        'Choose the interface language and the language used by future AI suggestions.',
    interfaceLanguage: 'Interface Language',
    aiOutputLanguage: 'AI Output Language',
    followInterfaceLanguage: 'Follow interface language',
    saveLanguageSettings: 'Save Language Settings',
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
    grid: 'Waterfall',
    map: 'Map',
    timeline: 'Timeline',
    librarySection: 'Library',
    librarySubtitle: 'Photo workspace',
    discover: 'Discover',
    highlights: 'Highlights',
    recentMemories: 'Recent Memories',
    newMemory: 'New Memory',
    newMemoryDescription: 'Create a new memory from your library.',
    photosUnit: 'photos',
    customCover: 'Custom cover',
    noDescription: 'No description',
    itemsUnit: 'items',
    matchesUnit: 'matches',
    tag: 'Tag',
    gpsOnly: 'GPS only',
    aiAny: 'AI: any',
    aiDisabled: 'AI: disabled',
    aiPending: 'AI: pending',
    aiProcessing: 'AI: processing',
    aiCompleted: 'AI: completed',
    aiFailed: 'AI: failed',
    fromDate: 'From date',
    toDate: 'To date',
    sortDatetime: 'Sort: datetime',
    sortPath: 'Sort: path',
    sortUpdated: 'Sort: updated',
    desc: 'Desc',
    asc: 'Asc',
    activeFilters: 'Active filters:',
    scanIdle: 'Scan progress: idle',
  ),
  UiLocale.zh: UiStrings(
    appTitle: 'ChronoPic',
    exportBackup: '导出备份',
    previewRestore: '预览恢复',
    restoreBackup: '恢复备份',
    allPhotos: '全部照片',
    favorites: '收藏',
    memories: '回忆',
    language: '语言',
    languageDescription: '选择界面语言，以及未来 AI 建议使用的输出语言。',
    interfaceLanguage: '界面语言',
    aiOutputLanguage: 'AI 输出语言',
    followInterfaceLanguage: '跟随界面语言',
    saveLanguageSettings: '保存语言设置',
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
    grid: '瀑布流',
    map: '地图',
    timeline: '时间线',
    librarySection: '资料库',
    librarySubtitle: '照片工作区',
    discover: '发现',
    highlights: '精选',
    recentMemories: '最近记忆',
    newMemory: '新建记忆',
    newMemoryDescription: '从资料库创建新的记忆。',
    photosUnit: '张照片',
    customCover: '自定义封面',
    noDescription: '暂无描述',
    itemsUnit: '项',
    matchesUnit: '个匹配',
    tag: '标签',
    gpsOnly: '仅 GPS',
    aiAny: 'AI：全部',
    aiDisabled: 'AI：已停用',
    aiPending: 'AI：待处理',
    aiProcessing: 'AI：处理中',
    aiCompleted: 'AI：已完成',
    aiFailed: 'AI：失败',
    fromDate: '开始日期',
    toDate: '结束日期',
    sortDatetime: '排序：时间',
    sortPath: '排序：路径',
    sortUpdated: '排序：更新',
    desc: '降序',
    asc: '升序',
    activeFilters: '当前筛选：',
    scanIdle: '扫描进度：空闲',
  ),
};
