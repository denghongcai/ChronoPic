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
    required this.photos,
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
  final List<PhotoRecord> photos;
  final TextEditingController providerController;
  final BackupRestorePreview? restorePreview;
  final bool scanning;
  final List<LibrarySource> sources;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('settings-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsLibraryPanel(
          labels: labels,
          onChooseLibraryFolder: onChooseLibraryFolder,
          onScanLibrary: onScanLibrary,
          scanning: scanning,
        ),
        const SizedBox(height: 18),
        LocaleSettingsPanel(
          aiOutputLocale: aiOutputLocale,
          labels: labels,
          locale: locale,
          onAiOutputLocaleChanged: onAiOutputLocaleChanged,
          onLocaleChanged: onLocaleChanged,
          onSaveLocaleSettings: onSaveLocaleSettings,
        ),
        const SizedBox(height: 18),
        BackupPanel(
          labels: labels,
          onExportBackup: onExportBackup,
          onPreviewRestore: onPreviewRestore,
          onRestoreBackup: onRestoreBackup,
          restorePreview: restorePreview,
        ),
        const SizedBox(height: 18),
        AiSettingsPanel(
          aiReadiness: aiReadiness,
          aiStatusCounts: aiStatusCounts,
          apiKeyController: apiKeyController,
          baseUrlController: baseUrlController,
          modelController: modelController,
          onSaveSettings: onSaveAiSettings,
          providerController: providerController,
        ),
        const SizedBox(height: 18),
        BackupPathPanel(
          backupPathController: backupPathController,
          labels: labels,
          onChooseBackupExportPath: onChooseBackupExportPath,
          onChooseBackupRestorePath: onChooseBackupRestorePath,
        ),
        const SizedBox(height: 18),
        MapSettingsPanel(
          apiKeyController: mapApiKeyController,
          onSaveSettings: onSaveMapSettings,
          securityJsCodeController: mapSecurityJsCodeController,
        ),
        const SizedBox(height: 18),
        ManualLibraryPathPanel(
          labels: labels,
          libraryPathController: libraryPathController,
          onAddLibrary: onAddLibrary,
        ),
        const SizedBox(height: 18),
        SourcesPanel(labels: labels, sources: sources),
        const SizedBox(height: 18),
        _StatsGrid(photos: photos, memories: memories, sources: sources),
      ],
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
          const _SectionHeader(
            title: 'Library Settings',
            description:
                'Manage your library sources and indexing preferences.',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: labels.language,
            description: labels.languageDescription,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: DropdownButtonFormField<UiLocale>(
                  key: const Key('interface-locale-control'),
                  decoration: InputDecoration(
                    labelText: labels.interfaceLanguage,
                  ),
                  isExpanded: true,
                  initialValue: locale,
                  items: const [
                    DropdownMenuItem(
                      value: UiLocale.en,
                      child: Text('English'),
                    ),
                    DropdownMenuItem(value: UiLocale.zh, child: Text('中文')),
                  ],
                  onChanged: (value) {
                    if (value != null) onLocaleChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<AiOutputLocale>(
                  key: const Key('ai-output-locale-control'),
                  decoration: InputDecoration(
                    labelText: labels.aiOutputLanguage,
                  ),
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
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton.icon(
                key: const Key('save-locale-settings-button'),
                onPressed: onSaveLocaleSettings,
                style: _secondaryActionStyle(),
                icon: const Icon(Icons.save_outlined),
                label: Text(labels.saveLanguageSettings),
              ),
            ],
          ),
        ],
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
          const _SectionHeader(
            title: 'Export, Backup, and Restore',
            description:
                'Export the local ChronoPic projection and restore it into another desktop data directory.',
            trailing: _SettingsStatusChip(
              label: 'LOCAL JSON',
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
            'Backups include ChronoPic metadata, memories, favorites, generated fields, and settings. Original media files are referenced by path, not copied.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          if (restorePreview != null) ...[
            const SizedBox(height: 12),
            Text(
              'Restore preview: ${restorePreview!.photoCount} photos, ${restorePreview!.memoryCount} memories',
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
            title: 'Library sources',
            trailing: Chip(label: Text('${sources.length} active')),
          ),
          const SizedBox(height: 12),
          if (sources.isEmpty)
            Text(
              'No folders registered yet.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            for (final source in sources)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(source.path),
                subtitle: Text('Last scan: ${source.lastScanAt ?? 'never'}'),
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
    required this.modelController,
    required this.onSaveSettings,
    required this.providerController,
  });

  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
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
            title: 'AI Enrichment',
            description:
                'Configure the OpenAI-compatible endpoint used for photo and memory semantic enrichment.',
            trailing: _SettingsStatusChip(
              label: aiReadiness.configured ? 'CONFIGURED' : 'INCOMPLETE',
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
                  title:
                      'AI readiness: ${aiReadiness.configured ? 'configured' : 'incomplete'}',
                  description:
                      'AI enrichment can run for photo metadata, memory summaries, and reviewable memory suggestions.',
                  trailing: _SettingsStatusChip(
                    label: aiReadiness.configured ? 'CONFIGURED' : 'INCOMPLETE',
                    tone: aiReadiness.configured ? _Tone.success : _Tone.danger,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ReadinessPill(
                      label: 'API Key',
                      present: apiKeyController.text.isNotEmpty,
                    ),
                    _ReadinessPill(
                      label: 'Base URL',
                      present: baseUrlController.text.isNotEmpty,
                    ),
                    _ReadinessPill(
                      label: 'Model',
                      present: modelController.text.isNotEmpty,
                    ),
                    _ReadinessPill(
                      label: 'Provider',
                      present: providerController.text.isNotEmpty,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (aiReadiness.missingFields.isNotEmpty)
            Text(
              'Missing: ${aiReadiness.missingFields.join(', ')}',
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
                    'AI ${status.name}: ${aiStatusCounts[status] ?? 0}',
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
                  decoration: const InputDecoration(labelText: 'Provider'),
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
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('ai-api-key-field'),
                  controller: apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'API key'),
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
        ],
      ),
    );
  }
}

final class MapSettingsPanel extends StatelessWidget {
  const MapSettingsPanel({
    required this.apiKeyController,
    required this.onSaveSettings,
    required this.securityJsCodeController,
  });

  final TextEditingController apiKeyController;
  final VoidCallback onSaveSettings;
  final TextEditingController securityJsCodeController;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Map settings',
            description:
                'Configure map credentials used by the desktop map surface when an online provider is enabled.',
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
                  decoration: const InputDecoration(labelText: 'Map API key'),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  key: const Key('map-security-js-code-field'),
                  controller: securityJsCodeController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Map security JS code',
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('save-map-settings-button'),
                onPressed: onSaveSettings,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Map Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ReadinessPill extends StatelessWidget {
  const _ReadinessPill({required this.label, required this.present});

  final String label;
  final bool present;

  @override
  Widget build(BuildContext context) {
    return Chip(
      side: BorderSide(
        color: present ? Colors.green.shade200 : Colors.red.shade200,
      ),
      backgroundColor: present ? Colors.green.shade50 : Colors.red.shade50,
      label: Text(
        '$label  ${present ? 'PRESENT' : 'MISSING'}',
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
              'Review pending AI metadata and suggested memories.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 26),
            _NotificationCard(
              title: 'AI queue',
              description: pending + failed == 0
                  ? 'No AI queue items need attention.'
                  : 'Outstanding AI items are waiting in the library queue.',
              footnote:
                  'Generated captions, summaries, tags, and memory suggestions stay reviewable and separate from your edits.',
              chips: [
                const _NotificationChipData('AI QUEUE', _Tone.info),
                _NotificationChipData('$failed FAILED', _Tone.danger),
                _NotificationChipData('$ready READY', _Tone.success),
              ],
              actionLabel: 'Enrich Queue',
              actionKey: const Key('retry-ai-queue-button'),
              onAction: onRetryQueue,
            ),
            const SizedBox(height: 24),
            _NotificationCard(
              title: 'Memory candidates',
              description:
                  '$ready suggested memories are waiting for review in Memories.',
              chips: [
                const _NotificationChipData('MEMORY CANDIDATES', _Tone.info),
                _NotificationChipData('$ready READY', _Tone.warning),
              ],
              actionLabel: 'Refresh Suggestions',
              actionKey: const Key('view-memory-candidates-button'),
              onAction: onViewMemories,
            ),
            Text(
              'Memory candidates: $ready',
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
    required this.memories,
    required this.photos,
    required this.sources,
  });

  final List<Memory> memories;
  final List<PhotoRecord> photos;
  final List<LibrarySource> sources;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Photos', photos.length, Icons.photo_library_outlined),
      ('Memories', memories.length, Icons.auto_stories_outlined),
      ('Sources', sources.length, Icons.folder_outlined),
      (
        'Favorites',
        photos.where((record) => record.photo.favorite).length,
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
