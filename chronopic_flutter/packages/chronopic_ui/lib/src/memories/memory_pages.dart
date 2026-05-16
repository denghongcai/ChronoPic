part of '../chronopic_home.dart';

final class MemoryListPage extends StatelessWidget {
  const MemoryListPage({
    required this.candidates,
    required this.labels,
    required this.memories,
    required this.memoryNameController,
    required this.onAcceptCandidate,
    required this.onCreateMemory,
    required this.onCreateMobileMemory,
    required this.onGenerateCandidates,
    required this.onRejectCandidate,
    required this.onSelectMemory,
  });

  final List<MemoryCandidate> candidates;
  final UiStrings labels;
  final List<Memory> memories;
  final TextEditingController memoryNameController;
  final ValueChanged<String> onAcceptCandidate;
  final VoidCallback onCreateMemory;
  final ValueChanged<BuildContext> onCreateMobileMemory;
  final VoidCallback onGenerateCandidates;
  final ValueChanged<String> onRejectCandidate;
  final ValueChanged<String> onSelectMemory;

  @override
  Widget build(BuildContext context) {
    final mobileLayout = MediaQuery.sizeOf(context).width < 720;
    final candidatePanel = _MemoryCandidatePanel(
      candidates: candidates,
      labels: labels,
      onAcceptCandidate: onAcceptCandidate,
      onGenerateCandidates: onGenerateCandidates,
      onRejectCandidate: onRejectCandidate,
    );
    final collectionPanel = _MemoryCollectionPanel(
      labels: labels,
      memories: memories,
      memoryNameController: memoryNameController,
      onCreateMemory: onCreateMemory,
      onCreateMobileMemory: onCreateMobileMemory,
      onSelectMemory: onSelectMemory,
    );
    return Column(
      key: const Key('memories-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mobileLayout
          ? [collectionPanel, const SizedBox(height: 18), candidatePanel]
          : [candidatePanel, const SizedBox(height: 18), collectionPanel],
    );
  }
}

final class _MemoryCandidatePanel extends StatelessWidget {
  const _MemoryCandidatePanel({
    required this.candidates,
    required this.labels,
    required this.onAcceptCandidate,
    required this.onGenerateCandidates,
    required this.onRejectCandidate,
  });

  final List<MemoryCandidate> candidates;
  final UiStrings labels;
  final ValueChanged<String> onAcceptCandidate;
  final VoidCallback onGenerateCandidates;
  final ValueChanged<String> onRejectCandidate;

  @override
  Widget build(BuildContext context) {
    final ready = candidates
        .where((candidate) => candidate.status == MemoryCandidateStatus.pending)
        .toList();
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _SectionHeader(
              eyebrow: _localized(labels, 'SUGGESTED MEMORIES', '建议记忆'),
              title: _localized(
                labels,
                'AI-assisted grouping candidates',
                'AI 辅助分组候选',
              ),
              description: _localized(
                labels,
                'Review suggested groups before they become editable memories. Accepting a candidate creates an editable Memory; rejecting it leaves your library untouched.',
                '先审核建议分组，再将其变成可编辑记忆。接受候选会创建可编辑记忆；拒绝候选不会修改资料库。',
              ),
              trailing: Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text(
                      _localized(
                        labels,
                        '${ready.length} READY',
                        '${ready.length} 条就绪',
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('generate-memory-candidates-button'),
                    onPressed: onGenerateCandidates,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_localized(labels, 'Generate', '生成')),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ready.isEmpty
                ? Text(
                    _localized(
                      labels,
                      'No memory candidates are ready.',
                      '当前没有就绪的记忆候选。',
                    ),
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final candidate in ready)
                        _CandidateCard(
                          candidate: candidate,
                          labels: labels,
                          onAcceptCandidate: onAcceptCandidate,
                          onRejectCandidate: onRejectCandidate,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

final class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.labels,
    required this.onAcceptCandidate,
    required this.onRejectCandidate,
  });

  final MemoryCandidate candidate;
  final UiStrings labels;
  final ValueChanged<String> onAcceptCandidate;
  final ValueChanged<String> onRejectCandidate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('memory-candidate-${candidate.id}'),
      width: 540,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 180,
              height: 250,
              child: _CandidateCover(candidate),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.black.withValues(alpha: 0.05),
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        candidate.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      candidate.reason,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _localized(
                              labels,
                              '${candidate.photoIds.length} photos',
                              '${candidate.photoIds.length} 张照片',
                            ),
                          ),
                        ),
                        for (final label in candidate.generatedLabels.take(2))
                          Chip(label: Text(label)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _localized(
                              labels,
                              '${candidate.photoIds.length} photos suggested from ${candidate.source.name} evidence at ${(candidate.confidence * 100).round()}% confidence.',
                              '基于 ${candidate.source.name} 证据建议 ${candidate.photoIds.length} 张照片，置信度 ${(candidate.confidence * 100).round()}%。',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune, size: 16),
                      label: Text(_localized(labels, 'Adjust photos', '调整照片')),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton.icon(
                          key: Key('reject-candidate-${candidate.id}'),
                          onPressed: () => onRejectCandidate(candidate.id),
                          icon: const Icon(Icons.close, size: 16),
                          label: Text(_localized(labels, 'Reject', '拒绝')),
                        ),
                        FilledButton.icon(
                          key: Key('accept-candidate-${candidate.id}'),
                          onPressed: () => onAcceptCandidate(candidate.id),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(
                            _localized(labels, 'Accept Memory', '接受记忆'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CandidateCover extends StatelessWidget {
  const _CandidateCover(this.candidate);

  final MemoryCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final path = candidate.coverThumbnailPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _MediaFallbackSurface(label: candidate.title),
        Positioned(
          left: 12,
          top: 12,
          child: Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(candidate.source.name.toUpperCase()),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text('${(candidate.confidence * 100).round()}%'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _MemoryCollectionPanel extends StatelessWidget {
  const _MemoryCollectionPanel({
    required this.labels,
    required this.memories,
    required this.memoryNameController,
    required this.onCreateMemory,
    required this.onCreateMobileMemory,
    required this.onSelectMemory,
  });

  final UiStrings labels;
  final List<Memory> memories;
  final TextEditingController memoryNameController;
  final VoidCallback onCreateMemory;
  final ValueChanged<BuildContext> onCreateMobileMemory;
  final ValueChanged<String> onSelectMemory;

  @override
  Widget build(BuildContext context) {
    final mobileLayout = MediaQuery.sizeOf(context).width < 720;
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _SectionHeader(
              title: _localized(labels, 'Browse memory collections', '浏览记忆集合'),
              description: _localized(
                labels,
                'Open a memory to review its story, edit metadata, and manage contained photos.',
                '打开记忆以查看故事、编辑元数据并管理其中的照片。',
              ),
              trailing: Chip(
                label: Text(
                  _localized(
                    labels,
                    '${memories.length} memories',
                    '${memories.length} 个记忆',
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    key: const Key('memory-name-field'),
                    controller: memoryNameController,
                    decoration: InputDecoration(labelText: labels.memoryName),
                  ),
                ),
                KeyedSubtree(
                  key: const ValueKey<String>('mobile-create-memory'),
                  child: FilledButton.icon(
                    key: const Key('create-memory-button'),
                    onPressed: mobileLayout
                        ? () => onCreateMobileMemory(context)
                        : onCreateMemory,
                    icon: const Icon(Icons.add),
                    label: Text(labels.createMemory),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: memories.isEmpty
                ? Text(
                    _localized(
                      labels,
                      'No memories yet. Create one, then add selected photos from the detail pane.',
                      '还没有记忆。创建一个记忆后，可从详情面板加入所选照片。',
                    ),
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final memory in memories)
                        _MemoryCard(
                          labels: labels,
                          memory: memory,
                          onSelectMemory: onSelectMemory,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

final class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.labels,
    required this.memory,
    required this.onSelectMemory,
  });

  final UiStrings labels;
  final Memory memory;
  final ValueChanged<String> onSelectMemory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 130,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('memory-card-${memory.id}'),
          borderRadius: BorderRadius.circular(24),
          onTap: () => onSelectMemory(memory.id),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: double.infinity,
                child: _MemoryCover(memory),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        memory.description ?? labels.noDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.event_outlined, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDate(
                                DateTime.fromMillisecondsSinceEpoch(
                                  memory.updatedAt,
                                ).toLocal(),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              memory.source.name,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class MemoryDetailPage extends StatelessWidget {
  const MemoryDetailPage({
    required this.labels,
    required this.memory,
    required this.memoryDescriptionController,
    required this.memoryTitleController,
    required this.onAddSelectedToMemory,
    required this.onBackToMemories,
    required this.onRemoveSelectedFromMemory,
    required this.onSaveMemory,
    required this.onSetCover,
    required this.selected,
  });

  final UiStrings labels;
  final Memory? memory;
  final TextEditingController memoryDescriptionController;
  final TextEditingController memoryTitleController;
  final VoidCallback onAddSelectedToMemory;
  final VoidCallback onBackToMemories;
  final VoidCallback onRemoveSelectedFromMemory;
  final VoidCallback onSaveMemory;
  final VoidCallback onSetCover;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    if (memory == null) {
      return MemoryListPage(
        candidates: const [],
        labels: labels,
        memories: const [],
        memoryNameController: TextEditingController(),
        onAcceptCandidate: (_) {},
        onCreateMemory: () {},
        onCreateMobileMemory: (_) {},
        onGenerateCandidates: () {},
        onRejectCandidate: (_) {},
        onSelectMemory: (_) {},
      );
    }
    return Column(
      key: const Key('memory-detail-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MemoryDetailHero(
          labels: labels,
          memory: memory!,
          onRemoveSelectedFromMemory: onRemoveSelectedFromMemory,
          onSetCover: onSetCover,
          selected: selected,
        ),
        const SizedBox(height: 18),
        _StoryOutlinePanel(labels: labels, memory: memory!),
        const SizedBox(height: 18),
        _MemoryManagementPanel(
          labels: labels,
          memoryDescriptionController: memoryDescriptionController,
          memoryTitleController: memoryTitleController,
          onAddSelectedToMemory: onAddSelectedToMemory,
          onBackToMemories: onBackToMemories,
          onRemoveSelectedFromMemory: onRemoveSelectedFromMemory,
          onSaveMemory: onSaveMemory,
          onSetCover: onSetCover,
          selected: selected,
        ),
      ],
    );
  }
}

final class _MemoryDetailHero extends StatelessWidget {
  const _MemoryDetailHero({
    required this.labels,
    required this.memory,
    required this.onRemoveSelectedFromMemory,
    required this.onSetCover,
    required this.selected,
  });

  final UiStrings labels;
  final Memory memory;
  final VoidCallback onRemoveSelectedFromMemory;
  final VoidCallback onSetCover;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      memory.updatedAt,
    ).toLocal();
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _localized(
                              labels,
                              '${memory.photoCount} photos',
                              '${memory.photoCount} 张照片',
                            ),
                          ),
                        ),
                        Chip(label: Text(memory.source.name.toUpperCase())),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('memory-hero-set-cover-button'),
                    onPressed: selected == null ? null : onSetCover,
                    tooltip: _localized(labels, 'Set Cover', '设为封面'),
                    icon: const Icon(Icons.auto_fix_high_outlined),
                  ),
                  IconButton(
                    key: const Key('memory-hero-remove-button'),
                    onPressed: selected == null
                        ? null
                        : onRemoveSelectedFromMemory,
                    tooltip: _localized(labels, 'Remove from Memory', '从记忆移除'),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _localized(labels, 'MEMORY DETAIL', '记忆详情'),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                memory.name,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 17,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Updated ${_formatLongDateTime(updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                memory.coverPhotoId == null
                    ? _localized(labels, 'No custom cover selected', '未选择自定义封面')
                    : _localized(labels, 'Custom cover selected', '已选择自定义封面'),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _localized(labels, 'Description', '描述'),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  memory.description ?? labels.noDescription,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          );
          final cover = ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _MemoryCover(memory),
          );
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(aspectRatio: 16 / 9, child: cover),
                const SizedBox(height: 16),
                content,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, height: 270, child: cover),
              const SizedBox(width: 24),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

final class _MemoryManagementPanel extends StatelessWidget {
  const _MemoryManagementPanel({
    required this.labels,
    required this.memoryDescriptionController,
    required this.memoryTitleController,
    required this.onAddSelectedToMemory,
    required this.onBackToMemories,
    required this.onRemoveSelectedFromMemory,
    required this.onSaveMemory,
    required this.onSetCover,
    required this.selected,
  });

  final UiStrings labels;
  final TextEditingController memoryDescriptionController;
  final TextEditingController memoryTitleController;
  final VoidCallback onAddSelectedToMemory;
  final VoidCallback onBackToMemories;
  final VoidCallback onRemoveSelectedFromMemory;
  final VoidCallback onSaveMemory;
  final VoidCallback onSetCover;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _localized(labels, 'Memory management', '记忆管理'),
            description: _localized(
              labels,
              'Edit metadata and manage selected-photo membership after reviewing the story.',
              '查看故事后，编辑元数据并管理所选照片的记忆关系。',
            ),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: const ValueKey<String>('mobile-memory-rename'),
            child: TextField(
              key: const Key('memory-title-field'),
              controller: memoryTitleController,
              decoration: InputDecoration(labelText: labels.memoryName),
            ),
          ),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: const ValueKey<String>('mobile-memory-description'),
            child: TextField(
              key: const Key('memory-description-field'),
              controller: memoryDescriptionController,
              decoration: InputDecoration(
                labelText: _localized(labels, 'Description', '描述'),
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('save-memory-button'),
                onPressed: onSaveMemory,
                icon: const Icon(Icons.save_outlined),
                label: Text(_localized(labels, 'Save Memory', '保存记忆')),
              ),
              KeyedSubtree(
                key: const ValueKey<String>('mobile-add-to-memory'),
                child: OutlinedButton.icon(
                  key: const Key('add-to-memory-button'),
                  onPressed: selected == null ? null : onAddSelectedToMemory,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(labels.addToMemory),
                ),
              ),
              KeyedSubtree(
                key: const ValueKey<String>('mobile-memory-cover'),
                child: OutlinedButton.icon(
                  key: const Key('set-memory-cover-button'),
                  onPressed: selected == null ? null : onSetCover,
                  icon: const Icon(Icons.wallpaper_outlined),
                  label: Text(_localized(labels, 'Set Cover', '设为封面')),
                ),
              ),
              KeyedSubtree(
                key: const ValueKey<String>('mobile-remove-from-memory'),
                child: OutlinedButton.icon(
                  key: const Key('remove-from-memory-button'),
                  onPressed: selected == null
                      ? null
                      : onRemoveSelectedFromMemory,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text(
                    _localized(labels, 'Remove from Memory', '从记忆移除'),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onBackToMemories,
                icon: const Icon(Icons.arrow_back),
                label: Text(labels.memories),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _StoryOutlinePanel extends StatelessWidget {
  const _StoryOutlinePanel({required this.labels, required this.memory});

  final UiStrings labels;
  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      memory.updatedAt,
    ).toLocal();
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _SectionHeader(
              eyebrow: _localized(labels, 'STORY OUTLINE', '故事大纲'),
              title: _localized(
                labels,
                'Chapters inside this memory',
                '这个记忆中的章节',
              ),
              trailing: Chip(
                label: Text(
                  _localized(
                    labels,
                    '${memory.photoCount} CHAPTERS',
                    '${memory.photoCount} 个章节',
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 350,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 260, child: _MemoryCover(memory)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  _localized(labels, 'CHAPTER 1', '章节 1'),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _localized(
                                  labels,
                                  '${memory.photoCount} photos',
                                  '${memory.photoCount} 张照片',
                                ),
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _monthYear(updatedAt),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _monthDay(updatedAt),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  _localized(
                                    labels,
                                    '${memory.photoCount} MAPPED',
                                    '${memory.photoCount} 张已定位',
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  _localized(
                                    labels,
                                    '${memory.photoCount} AI ${memory.aiStatus == AiPipelineStatus.completed ? 'READY' : memory.aiStatus.name.toUpperCase()}',
                                    '${memory.photoCount} 个 AI ${memory.aiStatus == AiPipelineStatus.completed ? '就绪' : memory.aiStatus.name}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
  }
}

final class _MemoryCover extends StatelessWidget {
  const _MemoryCover(this.memory);

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final path = memory.coverThumbnailPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        key: Key('memory-cover-${memory.id}'),
        fit: BoxFit.cover,
      );
    }
    return _MediaFallbackSurface(
      key: Key('memory-cover-${memory.id}'),
      label: memory.name,
    );
  }
}
