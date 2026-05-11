part of '../chronopic_home.dart';

const _settingsPrimary = Color(0xffff9800);
const _settingsBorder = Color(0xffe7e5e4);
const _settingsText = Color(0xff44403c);

ButtonStyle _primaryActionStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _settingsPrimary,
    foregroundColor: Colors.black,
    iconColor: Colors.black,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.16),
  );
}

ButtonStyle _secondaryActionStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: _settingsText,
    iconColor: _settingsText,
    side: const BorderSide(color: _settingsBorder),
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.10),
    backgroundColor: Colors.white,
  );
}

final class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.aiOutputLocale,
    required this.aiReadiness,
    required this.aiStatusCounts,
    required this.apiKeyController,
    required this.backupPathController,
    required this.baseUrlController,
    required this.labels,
    required this.libraryPathController,
    required this.locale,
    required this.mapApiKeyController,
    required this.mapSecurityJsCodeController,
    required this.memories,
    required this.modelController,
    required this.onAddLibrary,
    required this.onChooseBackupExportPath,
    required this.onChooseBackupRestorePath,
    required this.onChooseLibraryFolder,
    required this.onExportBackup,
    required this.onAiOutputLocaleChanged,
    required this.onLocaleChanged,
    required this.onPreviewRestore,
    required this.onRestoreBackup,
    required this.onSaveAiSettings,
    required this.onSaveLocaleSettings,
    required this.onSaveMapSettings,
    required this.onScanLibrary,
    required this.favoritePhotoCount,
    required this.photoCount,
    required this.providerController,
    required this.restorePreview,
    required this.scanning,
    required this.sources,
  });

  final AiOutputLocale aiOutputLocale;
  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final TextEditingController apiKeyController;
  final TextEditingController backupPathController;
  final TextEditingController baseUrlController;
  final UiStrings labels;
  final TextEditingController libraryPathController;
  final UiLocale locale;
  final TextEditingController mapApiKeyController;
  final TextEditingController mapSecurityJsCodeController;
  final List<Memory> memories;
  final TextEditingController modelController;
  final VoidCallback onAddLibrary;
  final VoidCallback onChooseBackupExportPath;
  final VoidCallback onChooseBackupRestorePath;
  final VoidCallback onChooseLibraryFolder;
  final VoidCallback onExportBackup;
  final ValueChanged<AiOutputLocale> onAiOutputLocaleChanged;
  final ValueChanged<UiLocale> onLocaleChanged;
  final VoidCallback onPreviewRestore;
  final VoidCallback onRestoreBackup;
  final VoidCallback onSaveAiSettings;
  final VoidCallback onSaveLocaleSettings;
  final VoidCallback onSaveMapSettings;
  final VoidCallback onScanLibrary;
  final int favoritePhotoCount;
  final int photoCount;
  final TextEditingController providerController;
  final BackupRestorePreview? restorePreview;
  final bool scanning;
  final List<LibrarySource> sources;

  @override
  Widget build(BuildContext context) {
    final libraryPanel = SettingsLibraryPanel(
      labels: labels,
      onChooseLibraryFolder: onChooseLibraryFolder,
      onScanLibrary: onScanLibrary,
      scanning: scanning,
    );
    final localePanel = LocaleSettingsPanel(
      aiOutputLocale: aiOutputLocale,
      labels: labels,
      locale: locale,
      onAiOutputLocaleChanged: onAiOutputLocaleChanged,
      onLocaleChanged: onLocaleChanged,
      onSaveLocaleSettings: onSaveLocaleSettings,
    );
    final backupPanel = BackupPanel(
      labels: labels,
      onExportBackup: onExportBackup,
      onPreviewRestore: onPreviewRestore,
      onRestoreBackup: onRestoreBackup,
      restorePreview: restorePreview,
    );
    final aiPanel = AiSettingsPanel(
      aiReadiness: aiReadiness,
      aiStatusCounts: aiStatusCounts,
      apiKeyController: apiKeyController,
      baseUrlController: baseUrlController,
      labels: labels,
      modelController: modelController,
      onSaveSettings: onSaveAiSettings,
      providerController: providerController,
    );
    final backupPathPanel = BackupPathPanel(
      backupPathController: backupPathController,
      labels: labels,
      onChooseBackupExportPath: onChooseBackupExportPath,
      onChooseBackupRestorePath: onChooseBackupRestorePath,
    );
    final mapPanel = MapSettingsPanel(
      apiKeyController: mapApiKeyController,
      labels: labels,
      onSaveSettings: onSaveMapSettings,
      securityJsCodeController: mapSecurityJsCodeController,
    );
    final manualPathPanel = ManualLibraryPathPanel(
      labels: labels,
      libraryPathController: libraryPathController,
      onAddLibrary: onAddLibrary,
    );
    final sourcesPanel = SourcesPanel(labels: labels, sources: sources);
    final statsGrid = _StatsGrid(
      favoritePhotoCount: favoritePhotoCount,
      labels: labels,
      photoCount: photoCount,
      memories: memories,
      sources: sources,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return _MobileSettingsList(
            groups: [
              _MobileSettingsGroup(
                child: libraryPanel,
                icon: Icons.photo_library_outlined,
                keyName: 'mobile-settings-library',
                subtitle: _localized(
                  labels,
                  'Choose photos, rescan, and manage the mobile catalog.',
                  '选择照片、重新扫描并管理移动端目录。',
                ),
                title: _localized(labels, 'Library', '图库'),
              ),
              _MobileSettingsGroup(
                child: localePanel,
                icon: Icons.translate_outlined,
                keyName: 'mobile-settings-language',
                subtitle: labels.languageDescription,
                title: labels.language,
              ),
              _MobileSettingsGroup(
                child: localePanel,
                icon: Icons.record_voice_over_outlined,
                keyName: 'mobile-settings-ai-language',
                subtitle: labels.followInterfaceLanguage,
                title: labels.aiOutputLanguage,
              ),
              _MobileSettingsGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    backupPanel,
                    const SizedBox(height: 14),
                    backupPathPanel,
                  ],
                ),
                icon: Icons.backup_outlined,
                keyName: 'mobile-settings-backup',
                subtitle: _localized(
                  labels,
                  'Original media files are referenced by path, not copied.',
                  '原始媒体文件按路径引用，不会复制。',
                ),
                title: _localized(labels, 'Backup', '备份'),
              ),
              _MobileSettingsGroup(
                child: aiPanel,
                icon: Icons.auto_awesome_outlined,
                keyName: 'mobile-settings-ai',
                subtitle: _localized(
                  labels,
                  'Secret-safe readiness and enrichment settings.',
                  '密钥安全的就绪状态和增强设置。',
                ),
                title: _localized(labels, 'AI Enrichment', 'AI 增强'),
              ),
              _MobileSettingsGroup(
                child: mapPanel,
                icon: Icons.map_outlined,
                keyName: 'mobile-settings-map',
                subtitle: _localized(
                  labels,
                  'Configure map rendering for mobile discovery.',
                  '配置移动端发现视图的地图渲染。',
                ),
                title: labels.map,
              ),
              _MobileSettingsGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    manualPathPanel,
                    const SizedBox(height: 14),
                    sourcesPanel,
                    const SizedBox(height: 14),
                    statsGrid,
                  ],
                ),
                icon: Icons.settings_applications_outlined,
                keyName: 'mobile-settings-advanced',
                subtitle: _localized(
                  labels,
                  'Manual paths, source list, and local statistics.',
                  '手动路径、来源列表和本地统计。',
                ),
                title: _localized(labels, 'Advanced', '高级'),
              ),
            ],
            labels: labels,
          );
        }

        return Column(
          key: const Key('settings-page'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            libraryPanel,
            const SizedBox(height: 18),
            localePanel,
            const SizedBox(height: 18),
            backupPanel,
            const SizedBox(height: 18),
            aiPanel,
            const SizedBox(height: 18),
            backupPathPanel,
            const SizedBox(height: 18),
            mapPanel,
            const SizedBox(height: 18),
            manualPathPanel,
            const SizedBox(height: 18),
            sourcesPanel,
            const SizedBox(height: 18),
            statsGrid,
          ],
        );
      },
    );
  }
}

final class _MobileSettingsGroup {
  const _MobileSettingsGroup({
    required this.child,
    required this.icon,
    required this.keyName,
    required this.subtitle,
    required this.title,
  });

  final Widget child;
  final IconData icon;
  final String keyName;
  final String subtitle;
  final String title;
}

final class _MobileSettingsList extends StatelessWidget {
  const _MobileSettingsList({required this.groups, required this.labels});

  final List<_MobileSettingsGroup> groups;
  final UiStrings labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('settings-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.settings,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          key: const Key('mobile-settings-list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final group = groups[index];
            return _MobileSettingsRow(group: group);
          },
        ),
      ],
    );
  }
}

final class _MobileSettingsRow extends StatelessWidget {
  const _MobileSettingsRow({required this.group});

  final _MobileSettingsGroup group;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(ChronoPicTheme.mobileCardRadius),
      child: InkWell(
        key: Key(group.keyName),
        borderRadius: BorderRadius.circular(ChronoPicTheme.mobileCardRadius),
        onTap: () => _openGroup(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(group.icon, color: Colors.orange.shade900),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      group.subtitle,
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
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _openGroup(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              0,
              14,
              14 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: SingleChildScrollView(child: group.child),
          ),
        );
      },
    );
  }
}

final class SettingsLibraryPanel extends StatelessWidget {
  const SettingsLibraryPanel({
    required this.labels,
    required this.onChooseLibraryFolder,
    required this.onScanLibrary,
    required this.scanning,
  });

  final UiStrings labels;
  final VoidCallback onChooseLibraryFolder;
  final VoidCallback onScanLibrary;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(labels, 'Library Settings', '资料库设置'),
            description: _localized(
              labels,
              'Manage your library sources and indexing preferences.',
              '管理资料库来源和索引偏好。',
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: const Key('choose-library-folder-button'),
                onPressed: onChooseLibraryFolder,
                style: _primaryActionStyle(),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(_localized(labels, 'Add Folder', '添加文件夹')),
              ),
              OutlinedButton.icon(
                key: const Key('scan-library-button'),
                onPressed: scanning ? null : onScanLibrary,
                style: _secondaryActionStyle(),
                icon: const Icon(Icons.folder_outlined),
                label: Text(labels.scanLibrary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ManualLibraryPathPanel extends StatelessWidget {
  const ManualLibraryPathPanel({
    required this.labels,
    required this.libraryPathController,
    required this.onAddLibrary,
  });

  final UiStrings labels;
  final TextEditingController libraryPathController;
  final VoidCallback onAddLibrary;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(labels, 'Manual library path', '手动图库路径'),
            description: _localized(
              labels,
              'Paste a folder path when the native folder picker is not available.',
              '当原生文件夹选择器不可用时，可粘贴文件夹路径。',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 520,
                child: TextField(
                  key: const Key('library-path-field'),
                  controller: libraryPathController,
                  decoration: InputDecoration(
                    labelText: labels.libraryFolderPath,
                    helperText: _localized(
                      labels,
                      'Optional: paste a folder path, then add it to the library.',
                      '可选：粘贴文件夹路径，然后添加到资料库。',
                    ),
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('add-library-button'),
                onPressed: onAddLibrary,
                style: _secondaryActionStyle(),
                icon: const Icon(Icons.add_box_outlined),
                label: Text(labels.addLibrary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class LocaleSettingsPanel extends StatelessWidget {
  const LocaleSettingsPanel({
    required this.aiOutputLocale,
    required this.labels,
    required this.locale,
    required this.onAiOutputLocaleChanged,
    required this.onLocaleChanged,
    required this.onSaveLocaleSettings,
  });

  final AiOutputLocale aiOutputLocale;
  final UiStrings labels;
  final UiLocale locale;
  final ValueChanged<AiOutputLocale> onAiOutputLocaleChanged;
  final ValueChanged<UiLocale> onLocaleChanged;
  final VoidCallback onSaveLocaleSettings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final interfaceControl = DropdownButtonFormField<UiLocale>(
            key: const Key('interface-locale-control'),
            decoration: InputDecoration(labelText: labels.interfaceLanguage),
            isExpanded: true,
            initialValue: locale,
            items: const [
              DropdownMenuItem(value: UiLocale.en, child: Text('English')),
              DropdownMenuItem(value: UiLocale.zh, child: Text('中文')),
            ],
            onChanged: (value) {
              if (value != null) onLocaleChanged(value);
            },
          );
          final aiControl = DropdownButtonFormField<AiOutputLocale>(
            key: const Key('ai-output-locale-control'),
            decoration: InputDecoration(labelText: labels.aiOutputLanguage),
            isExpanded: true,
            initialValue: aiOutputLocale,
            items: [
              DropdownMenuItem(
                value: AiOutputLocale.followUi,
                child: Text(labels.followInterfaceLanguage),
              ),
              const DropdownMenuItem(
                value: AiOutputLocale.enUS,
                child: Text('English'),
              ),
              const DropdownMenuItem(
                value: AiOutputLocale.zhCN,
                child: Text('中文'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onAiOutputLocaleChanged(value);
            },
          );
          final saveButton = OutlinedButton.icon(
            key: const Key('save-locale-settings-button'),
            onPressed: onSaveLocaleSettings,
            style: _secondaryActionStyle(),
            icon: const Icon(Icons.save_outlined),
            label: Text(labels.saveLanguageSettings),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: labels.language,
                description: labels.languageDescription,
              ),
              const SizedBox(height: 18),
              if (constraints.maxWidth < 620)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    interfaceControl,
                    const SizedBox(height: 12),
                    aiControl,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: saveButton),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: interfaceControl),
                    const SizedBox(width: 14),
                    Expanded(child: aiControl),
                    const SizedBox(width: 14),
                    saveButton,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

final class NotificationPage extends StatelessWidget {
  const NotificationPage({
    required this.aiReadiness,
    required this.aiStatusCounts,
    required this.candidates,
    required this.labels,
    required this.onRetryQueue,
    required this.onSettings,
    required this.onViewMemories,
  });

  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final List<MemoryCandidate> candidates;
  final UiStrings labels;
  final VoidCallback onRetryQueue;
  final VoidCallback onSettings;
  final VoidCallback onViewMemories;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('notifications-page'),
      child: NotificationCenterPanel(
        aiReadiness: aiReadiness,
        aiStatusCounts: aiStatusCounts,
        candidates: candidates,
        labels: labels,
        onRetryQueue: onRetryQueue,
        onViewMemories: onViewMemories,
      ),
    );
  }
}

final class LocaleSelector extends StatelessWidget {
  const LocaleSelector({
    required this.labels,
    required this.locale,
    required this.onChanged,
  });

  final UiStrings labels;
  final UiLocale locale;
  final ValueChanged<UiLocale> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UiLocale>(
      key: const Key('locale-switcher'),
      segments: const [
        ButtonSegment(value: UiLocale.en, label: Text('English')),
        ButtonSegment(value: UiLocale.zh, label: Text('中文')),
      ],
      selected: {locale},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

final class BackupPanel extends StatelessWidget {
  const BackupPanel({
    required this.labels,
    required this.onExportBackup,
    required this.onPreviewRestore,
    required this.onRestoreBackup,
    required this.restorePreview,
  });

  final UiStrings labels;
  final VoidCallback onExportBackup;
  final VoidCallback onPreviewRestore;
  final VoidCallback onRestoreBackup;
  final BackupRestorePreview? restorePreview;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(
              labels,
              'Export, Backup, and Restore',
              '导出、备份和恢复',
            ),
            description: _localized(
              labels,
              'Export the local ChronoPic projection and restore it into another desktop data directory.',
              '导出本地 ChronoPic 投影，并将其恢复到另一个桌面数据目录。',
            ),
            trailing: _SettingsStatusChip(
              label: _localized(labels, 'LOCAL JSON', '本地 JSON'),
              tone: _Tone.info,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('export-backup-file'),
                  onPressed: onExportBackup,
                  icon: const Icon(Icons.download),
                  label: Text(labels.exportBackupFile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('preview-backup-file'),
                  onPressed: onPreviewRestore,
                  icon: const Icon(Icons.find_in_page_outlined),
                  label: Text(labels.previewBackupFile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('restore-backup-file'),
                  onPressed: onRestoreBackup,
                  style: _primaryActionStyle(),
                  icon: const Icon(Icons.upload_file),
                  label: Text(labels.restoreBackupFile),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _localized(
              labels,
              'Backups include ChronoPic metadata, memories, favorites, generated fields, and settings. Original media files are referenced by path, not copied.',
              '备份包含 ChronoPic 元数据、记忆、收藏、生成字段和设置。原始媒体文件按路径引用，不会复制。',
            ),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          if (restorePreview != null) ...[
            const SizedBox(height: 12),
            Text(
              _localized(
                labels,
                'Restore preview: ${restorePreview!.photoCount} photos, ${restorePreview!.memoryCount} memories',
                '恢复预览：${restorePreview!.photoCount} 张照片，${restorePreview!.memoryCount} 个记忆',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class BackupPathPanel extends StatelessWidget {
  const BackupPathPanel({
    required this.backupPathController,
    required this.labels,
    required this.onChooseBackupExportPath,
    required this.onChooseBackupRestorePath,
  });

  final TextEditingController backupPathController;
  final UiStrings labels;
  final VoidCallback onChooseBackupExportPath;
  final VoidCallback onChooseBackupRestorePath;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(labels, 'Backup file path', '备份文件路径'),
            description: _localized(
              labels,
              'Choose or paste a JSON file path when exporting or restoring backups.',
              '导出或恢复备份时，可选择或粘贴 JSON 文件路径。',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  key: const Key('backup-path-field'),
                  controller: backupPathController,
                  decoration: InputDecoration(labelText: labels.backupJsonPath),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('choose-backup-export-path'),
                onPressed: onChooseBackupExportPath,
                style: _secondaryActionStyle(),
                icon: const Icon(Icons.save_alt),
                label: Text(labels.chooseExportPath),
              ),
              OutlinedButton.icon(
                key: const Key('choose-backup-restore-path'),
                onPressed: onChooseBackupRestorePath,
                style: _secondaryActionStyle(),
                icon: const Icon(Icons.file_open),
                label: Text(labels.chooseRestoreFile),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class SourcesPanel extends StatelessWidget {
  const SourcesPanel({required this.labels, required this.sources});

  final UiStrings labels;
  final List<LibrarySource> sources;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(labels, 'Library sources', '资料库来源'),
            trailing: Chip(
              label: Text(
                _localized(
                  labels,
                  '${sources.length} active',
                  '${sources.length} 个启用',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (sources.isEmpty)
            Text(
              _localized(labels, 'No folders registered yet.', '尚未注册文件夹。'),
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            for (final source in sources)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(source.path),
                subtitle: Text(
                  _localized(
                    labels,
                    'Last scan: ${source.lastScanAt ?? 'never'}',
                    '上次扫描：${source.lastScanAt ?? '从未'}',
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

final class AiSettingsPanel extends StatelessWidget {
  const AiSettingsPanel({
    required this.aiReadiness,
    required this.aiStatusCounts,
    required this.apiKeyController,
    required this.baseUrlController,
    required this.labels,
    required this.modelController,
    required this.onSaveSettings,
    required this.providerController,
  });

  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
  final UiStrings labels;
  final TextEditingController modelController;
  final VoidCallback onSaveSettings;
  final TextEditingController providerController;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(labels, 'AI Enrichment', 'AI 增强'),
            description: _localized(
              labels,
              'Configure the OpenAI-compatible endpoint used for photo and memory semantic enrichment.',
              '配置用于照片和记忆语义增强的 OpenAI 兼容端点。',
            ),
            trailing: _SettingsStatusChip(
              label: aiReadiness.configured
                  ? _localized(labels, 'CONFIGURED', '已配置')
                  : _localized(labels, 'INCOMPLETE', '不完整'),
              tone: aiReadiness.configured ? _Tone.success : _Tone.danger,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffeadfd6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: aiReadiness.configured
                      ? _localized(
                          labels,
                          'AI readiness: configured',
                          'AI 就绪状态：已配置',
                        )
                      : _localized(
                          labels,
                          'AI readiness: incomplete',
                          'AI 就绪状态：不完整',
                        ),
                  description: _localized(
                    labels,
                    'AI enrichment can run for photo metadata, memory summaries, and reviewable memory suggestions.',
                    'AI 增强可用于照片元数据、记忆摘要和可审核的记忆建议。',
                  ),
                  trailing: _SettingsStatusChip(
                    label: aiReadiness.configured
                        ? _localized(labels, 'CONFIGURED', '已配置')
                        : _localized(labels, 'INCOMPLETE', '不完整'),
                    tone: aiReadiness.configured ? _Tone.success : _Tone.danger,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ReadinessPill(
                      label: _localized(labels, 'API Key', 'API 密钥'),
                      missingLabel: _localized(labels, 'MISSING', '缺失'),
                      present: apiKeyController.text.isNotEmpty,
                      presentLabel: _localized(labels, 'PRESENT', '存在'),
                    ),
                    _ReadinessPill(
                      label: _localized(labels, 'Base URL', 'Base URL'),
                      missingLabel: _localized(labels, 'MISSING', '缺失'),
                      present: baseUrlController.text.isNotEmpty,
                      presentLabel: _localized(labels, 'PRESENT', '存在'),
                    ),
                    _ReadinessPill(
                      label: _localized(labels, 'Model', '模型'),
                      missingLabel: _localized(labels, 'MISSING', '缺失'),
                      present: modelController.text.isNotEmpty,
                      presentLabel: _localized(labels, 'PRESENT', '存在'),
                    ),
                    _ReadinessPill(
                      label: _localized(labels, 'Provider', '服务商'),
                      missingLabel: _localized(labels, 'MISSING', '缺失'),
                      present: providerController.text.isNotEmpty,
                      presentLabel: _localized(labels, 'PRESENT', '存在'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (aiReadiness.missingFields.isNotEmpty)
            Text(
              _localized(
                labels,
                'Missing: ${aiReadiness.missingFields.join(', ')}',
                '缺少：${aiReadiness.missingFields.join(', ')}',
              ),
              key: const Key('ai-readiness-missing-fields'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final status in AiPipelineStatus.values)
                Chip(
                  key: Key('ai-status-count-${status.name}'),
                  label: Text(
                    _localized(
                      labels,
                      'AI ${status.name}: ${aiStatusCounts[status] ?? 0}',
                      'AI ${status.name}：${aiStatusCounts[status] ?? 0}',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('ai-provider-field'),
                  controller: providerController,
                  decoration: InputDecoration(
                    labelText: _localized(labels, 'Provider', '服务商'),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  key: const Key('ai-base-url-field'),
                  controller: baseUrlController,
                  decoration: const InputDecoration(labelText: 'Base URL'),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('ai-model-field'),
                  controller: modelController,
                  decoration: InputDecoration(
                    labelText: _localized(labels, 'Model', '模型'),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('ai-api-key-field'),
                  controller: apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _localized(labels, 'API key', 'API 密钥'),
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('save-ai-settings-button'),
                onPressed: onSaveSettings,
                icon: const Icon(Icons.save_outlined),
                label: Text(_localized(labels, 'Save AI Settings', '保存 AI 设置')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class MapSettingsPanel extends StatelessWidget {
  const MapSettingsPanel({
    required this.apiKeyController,
    required this.labels,
    required this.onSaveSettings,
    required this.securityJsCodeController,
  });

  final TextEditingController apiKeyController;
  final UiStrings labels;
  final VoidCallback onSaveSettings;
  final TextEditingController securityJsCodeController;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(labels, 'Map settings', '地图设置'),
            description: _localized(
              labels,
              'Configure map credentials used by the desktop map surface when an online provider is enabled.',
              '配置启用在线地图服务时桌面地图界面使用的凭据。',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  key: const Key('map-api-key-field'),
                  controller: apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _localized(labels, 'Map API key', '地图 API 密钥'),
                  ),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  key: const Key('map-security-js-code-field'),
                  controller: securityJsCodeController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _localized(
                      labels,
                      'Map security JS code',
                      '地图安全 JS 代码',
                    ),
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('save-map-settings-button'),
                onPressed: onSaveSettings,
                icon: const Icon(Icons.save_outlined),
                label: Text(_localized(labels, 'Save Map Settings', '保存地图设置')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ReadinessPill extends StatelessWidget {
  const _ReadinessPill({
    required this.label,
    required this.missingLabel,
    required this.present,
    required this.presentLabel,
  });

  final String label;
  final String missingLabel;
  final bool present;
  final String presentLabel;

  @override
  Widget build(BuildContext context) {
    return Chip(
      side: BorderSide(
        color: present ? Colors.green.shade200 : Colors.red.shade200,
      ),
      backgroundColor: present ? Colors.green.shade50 : Colors.red.shade50,
      label: Text(
        '$label  ${present ? presentLabel : missingLabel}',
        style: TextStyle(
          color: present ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

final class _SettingsStatusChip extends StatelessWidget {
  const _SettingsStatusChip({required this.label, required this.tone});

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    return _TintedChip(label: label, tone: tone);
  }
}

final class NotificationCenterPanel extends StatelessWidget {
  const NotificationCenterPanel({
    required this.aiReadiness,
    required this.aiStatusCounts,
    required this.candidates,
    required this.labels,
    required this.onRetryQueue,
    required this.onViewMemories,
  });

  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final List<MemoryCandidate> candidates;
  final UiStrings labels;
  final VoidCallback onRetryQueue;
  final VoidCallback onViewMemories;

  @override
  Widget build(BuildContext context) {
    final pending =
        (aiStatusCounts[AiPipelineStatus.pending] ?? 0) +
        (aiStatusCounts[AiPipelineStatus.processing] ?? 0);
    final failed = aiStatusCounts[AiPipelineStatus.failed] ?? 0;
    final ready = candidates
        .where((candidate) => candidate.status == MemoryCandidateStatus.pending)
        .length;
    return KeyedSubtree(
      key: const Key('notification-center-panel'),
      child: _Panel(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labels.notifications,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              _localized(
                labels,
                'Review pending AI metadata and suggested memories.',
                '查看待处理 AI 元数据和建议记忆。',
              ),
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 26),
            _NotificationCard(
              title: _localized(labels, 'AI queue', 'AI 队列'),
              description: pending + failed == 0
                  ? _localized(
                      labels,
                      'No AI queue items need attention.',
                      '当前没有需要处理的 AI 队列项目。',
                    )
                  : _localized(
                      labels,
                      'Outstanding AI items are waiting in the library queue.',
                      '待处理 AI 项目正在资料库队列中等待。',
                    ),
              footnote: _localized(
                labels,
                'Generated captions, summaries, tags, and memory suggestions stay reviewable and separate from your edits.',
                '生成的标题、摘要、标签和记忆建议会保持可审核，并与用户编辑分开保存。',
              ),
              chips: [
                _NotificationChipData(
                  _localized(labels, 'AI QUEUE', 'AI 队列'),
                  _Tone.info,
                ),
                _NotificationChipData(
                  _localized(labels, '$failed FAILED', '$failed 个失败'),
                  _Tone.danger,
                ),
                _NotificationChipData(
                  _localized(labels, '$ready READY', '$ready 条就绪'),
                  _Tone.success,
                ),
              ],
              actionLabel: _localized(labels, 'Enrich Queue', '丰富队列'),
              actionKey: const Key('retry-ai-queue-button'),
              onAction: onRetryQueue,
            ),
            const SizedBox(height: 24),
            _NotificationCard(
              title: _localized(labels, 'Memory candidates', '记忆候选'),
              description: _localized(
                labels,
                '$ready suggested memories are waiting for review in Memories.',
                '$ready 条建议记忆正在记忆页等待审核。',
              ),
              chips: [
                _NotificationChipData(
                  _localized(labels, 'MEMORY CANDIDATES', '记忆候选'),
                  _Tone.info,
                ),
                _NotificationChipData(
                  _localized(labels, '$ready READY', '$ready 条就绪'),
                  _Tone.warning,
                ),
              ],
              actionLabel: _localized(labels, 'Refresh Suggestions', '刷新建议'),
              actionKey: const Key('view-memory-candidates-button'),
              onAction: onViewMemories,
            ),
            Text(
              _localized(labels, 'Memory candidates: $ready', '记忆候选：$ready'),
              key: const Key('memory-candidate-count'),
              style: const TextStyle(fontSize: 0),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.actionKey,
    required this.actionLabel,
    required this.chips,
    required this.description,
    required this.onAction,
    required this.title,
    this.footnote,
  });

  final Key actionKey;
  final String actionLabel;
  final List<_NotificationChipData> chips;
  final String description;
  final String? footnote;
  final VoidCallback onAction;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe7e5e4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final chip in chips) _NotificationChip(chip)],
                ),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(description),
                if (footnote != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    footnote!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            key: actionKey,
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

enum _Tone { info, danger, success, warning }

final class _NotificationChipData {
  const _NotificationChipData(this.label, this.tone);

  final String label;
  final _Tone tone;
}

final class _NotificationChip extends StatelessWidget {
  const _NotificationChip(this.data);

  final _NotificationChipData data;

  @override
  Widget build(BuildContext context) {
    return _TintedChip(label: data.label, tone: data.tone);
  }
}

final class _TintedChip extends StatelessWidget {
  const _TintedChip({required this.label, required this.tone});

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _Tone.info => (
        background: const Color(0xffeff9ff),
        border: const Color(0xffbae6fd),
        text: const Color(0xff0277bd),
      ),
      _Tone.danger => (
        background: const Color(0xfffff1f2),
        border: const Color(0xffffccd5),
        text: const Color(0xffe11d48),
      ),
      _Tone.success => (
        background: const Color(0xffecfdf5),
        border: const Color(0xffa7f3d0),
        text: const Color(0xff047857),
      ),
      _Tone.warning => (
        background: const Color(0xfffffbeb),
        border: const Color(0xfffde68a),
        text: const Color(0xffb45309),
      ),
    };
    return Chip(
      backgroundColor: colors.background,
      side: BorderSide(color: colors.border),
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: TextStyle(
          color: colors.text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

final class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.favoritePhotoCount,
    required this.labels,
    required this.memories,
    required this.photoCount,
    required this.sources,
  });

  final int favoritePhotoCount;
  final UiStrings labels;
  final List<Memory> memories;
  final int photoCount;
  final List<LibrarySource> sources;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        _localized(labels, 'Photos', '照片'),
        photoCount,
        Icons.photo_library_outlined,
      ),
      (
        _localized(labels, 'Memories', '记忆'),
        memories.length,
        Icons.auto_stories_outlined,
      ),
      (
        _localized(labels, 'Sources', '来源'),
        sources.length,
        Icons.folder_outlined,
      ),
      (
        _localized(labels, 'Favorites', '收藏'),
        favoritePhotoCount,
        Icons.star_border,
      ),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final stat in stats)
          SizedBox(
            width: 180,
            child: _Panel(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(stat.$3, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stat.$2}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          stat.$1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
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
