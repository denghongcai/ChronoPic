part of '../chronopic_home.dart';

final class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.aiReadiness,
    required this.aiStatusCounts,
    required this.backupPathController,
    required this.labels,
    required this.libraryPathController,
    required this.locale,
    required this.memories,
    required this.onAddLibrary,
    required this.onChooseBackupExportPath,
    required this.onChooseBackupRestorePath,
    required this.onChooseLibraryFolder,
    required this.onExportBackup,
    required this.onLocaleChanged,
    required this.onPreviewRestore,
    required this.onRestoreBackup,
    required this.onScanLibrary,
    required this.photos,
    required this.restorePreview,
    required this.scanning,
    required this.sources,
  });

  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final TextEditingController backupPathController;
  final UiStrings labels;
  final TextEditingController libraryPathController;
  final UiLocale locale;
  final List<Memory> memories;
  final VoidCallback onAddLibrary;
  final VoidCallback onChooseBackupExportPath;
  final VoidCallback onChooseBackupRestorePath;
  final VoidCallback onChooseLibraryFolder;
  final VoidCallback onExportBackup;
  final ValueChanged<UiLocale> onLocaleChanged;
  final VoidCallback onPreviewRestore;
  final VoidCallback onRestoreBackup;
  final VoidCallback onScanLibrary;
  final List<PhotoRecord> photos;
  final BackupRestorePreview? restorePreview;
  final bool scanning;
  final List<LibrarySource> sources;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('settings-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: labels.settings,
          description:
              'Manage local folders, language, backup files, and desktop runtime settings.',
        ),
        const SizedBox(height: 18),
        _StatsGrid(photos: photos, memories: memories, sources: sources),
        const SizedBox(height: 18),
        LibraryToolbar(
          labels: labels,
          libraryPathController: libraryPathController,
          onAddLibrary: onAddLibrary,
          onChooseLibraryFolder: onChooseLibraryFolder,
          onScanLibrary: onScanLibrary,
          onSearchChanged: (_) {},
          scanning: scanning,
        ),
        const SizedBox(height: 18),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: labels.language),
              const SizedBox(height: 12),
              LocaleSelector(
                labels: labels,
                locale: locale,
                onChanged: onLocaleChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        BackupPanel(
          backupPathController: backupPathController,
          labels: labels,
          onChooseBackupExportPath: onChooseBackupExportPath,
          onChooseBackupRestorePath: onChooseBackupRestorePath,
          onExportBackup: onExportBackup,
          onPreviewRestore: onPreviewRestore,
          onRestoreBackup: onRestoreBackup,
          restorePreview: restorePreview,
        ),
        const SizedBox(height: 18),
        SourcesPanel(labels: labels, sources: sources),
      ],
    );
  }
}

final class NotificationPage extends StatelessWidget {
  const NotificationPage({
    required this.aiReadiness,
    required this.aiStatusCounts,
    required this.apiKeyController,
    required this.baseUrlController,
    required this.candidates,
    required this.labels,
    required this.modelController,
    required this.onAcceptCandidate,
    required this.onRejectCandidate,
    required this.onRetryQueue,
    required this.onSaveSettings,
    required this.onSettings,
    required this.providerController,
  });

  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
  final List<MemoryCandidate> candidates;
  final UiStrings labels;
  final TextEditingController modelController;
  final ValueChanged<String> onAcceptCandidate;
  final ValueChanged<String> onRejectCandidate;
  final VoidCallback onRetryQueue;
  final VoidCallback onSaveSettings;
  final VoidCallback onSettings;
  final TextEditingController providerController;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('notifications-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: labels.notifications,
          description:
              'Review AI readiness, failed queue recovery, and generated memory suggestions.',
          trailing: OutlinedButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            label: Text(labels.settings),
          ),
        ),
        const SizedBox(height: 18),
        AiStatusPanel(
          aiReadiness: aiReadiness,
          aiStatusCounts: aiStatusCounts,
          apiKeyController: apiKeyController,
          baseUrlController: baseUrlController,
          candidates: candidates,
          modelController: modelController,
          onAcceptCandidate: onAcceptCandidate,
          onRejectCandidate: onRejectCandidate,
          onRetryQueue: onRetryQueue,
          onSaveSettings: onSaveSettings,
          providerController: providerController,
        ),
      ],
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
    required this.backupPathController,
    required this.labels,
    required this.onChooseBackupExportPath,
    required this.onChooseBackupRestorePath,
    required this.onExportBackup,
    required this.onPreviewRestore,
    required this.onRestoreBackup,
    required this.restorePreview,
  });

  final TextEditingController backupPathController;
  final UiStrings labels;
  final VoidCallback onChooseBackupExportPath;
  final VoidCallback onChooseBackupRestorePath;
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
            title: 'Backup and restore',
            description:
                'Export local JSON backups, preview restore counts, and recover a catalog from disk.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
                icon: const Icon(Icons.save_alt),
                label: Text(labels.chooseExportPath),
              ),
              OutlinedButton.icon(
                key: const Key('choose-backup-restore-path'),
                onPressed: onChooseBackupRestorePath,
                icon: const Icon(Icons.file_open),
                label: Text(labels.chooseRestoreFile),
              ),
              FilledButton.icon(
                key: const Key('export-backup-file'),
                onPressed: onExportBackup,
                icon: const Icon(Icons.download),
                label: Text(labels.exportBackupFile),
              ),
              OutlinedButton.icon(
                key: const Key('preview-backup-file'),
                onPressed: onPreviewRestore,
                icon: const Icon(Icons.find_in_page_outlined),
                label: Text(labels.previewBackupFile),
              ),
              OutlinedButton.icon(
                key: const Key('restore-backup-file'),
                onPressed: onRestoreBackup,
                icon: const Icon(Icons.upload_file),
                label: Text(labels.restoreBackupFile),
              ),
            ],
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

final class AiStatusPanel extends StatelessWidget {
  const AiStatusPanel({
    required this.aiReadiness,
    required this.aiStatusCounts,
    required this.apiKeyController,
    required this.baseUrlController,
    required this.candidates,
    required this.modelController,
    required this.onAcceptCandidate,
    required this.onRejectCandidate,
    required this.onRetryQueue,
    required this.onSaveSettings,
    required this.providerController,
  });

  final AiReadiness aiReadiness;
  final Map<AiPipelineStatus, int> aiStatusCounts;
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
  final List<MemoryCandidate> candidates;
  final TextEditingController modelController;
  final ValueChanged<String> onAcceptCandidate;
  final ValueChanged<String> onRejectCandidate;
  final VoidCallback onRetryQueue;
  final VoidCallback onSaveSettings;
  final TextEditingController providerController;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title:
                'AI readiness: ${aiReadiness.configured ? 'configured' : 'incomplete'}',
            description:
                'Settings are secret-safe; the API key is never displayed outside the password field.',
          ),
          const SizedBox(height: 12),
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
              OutlinedButton.icon(
                key: const Key('retry-ai-queue-button'),
                onPressed: onRetryQueue,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Failed Queue'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Memory candidates: ${candidates.length}',
            key: const Key('memory-candidate-count'),
          ),
          const SizedBox(height: 8),
          for (final candidate in candidates)
            Card(
              key: Key('memory-candidate-${candidate.id}'),
              child: ListTile(
                title: Text(candidate.title),
                subtitle: Text(candidate.reason),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      key: Key('accept-candidate-${candidate.id}'),
                      onPressed: () => onAcceptCandidate(candidate.id),
                      child: const Text('Accept'),
                    ),
                    OutlinedButton(
                      key: Key('reject-candidate-${candidate.id}'),
                      onPressed: () => onRejectCandidate(candidate.id),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
