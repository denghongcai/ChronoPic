part of '../chronopic_home.dart';

final class DetailSurface extends StatelessWidget {
  const DetailSurface({
    required this.captionController,
    required this.dateController,
    required this.photos,
    required this.labels,
    required this.onAddToMemory,
    required this.onCloseFocused,
    required this.onOpenGallery,
    required this.onRollback,
    required this.onSaveCaption,
    required this.onSaveDatetime,
    required this.onSaveTags,
    required this.onSelectPhoto,
    required this.onToggleFavorite,
    required this.record,
    required this.tagsController,
    required this.timeController,
    this.focusedMode = false,
  });

  final TextEditingController captionController;
  final TextEditingController dateController;
  final bool focusedMode;
  final UiStrings labels;
  final VoidCallback onAddToMemory;
  final VoidCallback onCloseFocused;
  final ValueChanged<BuildContext> onOpenGallery;
  final VoidCallback onRollback;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveDatetime;
  final VoidCallback onSaveTags;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final VoidCallback onToggleFavorite;
  final List<PhotoRecord> photos;
  final PhotoRecord? record;
  final TextEditingController tagsController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    if (focusedMode && selected != null) {
      return _FocusedDetailSurface(
        captionController: captionController,
        dateController: dateController,
        labels: labels,
        onAddToMemory: onAddToMemory,
        onCloseFocused: onCloseFocused,
        onOpenGallery: onOpenGallery,
        onRollback: onRollback,
        onSaveCaption: onSaveCaption,
        onSaveDatetime: onSaveDatetime,
        onSaveTags: onSaveTags,
        onSelectPhoto: onSelectPhoto,
        onToggleFavorite: onToggleFavorite,
        photos: photos,
        record: selected,
        tagsController: tagsController,
        timeController: timeController,
      );
    }
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final preview = _DetailPreview(record: selected);
          final inspector = _DetailInspector(
            captionController: captionController,
            dateController: dateController,
            labels: labels,
            onOpenGallery: selected == null
                ? null
                : () => onOpenGallery(context),
            onRollback: selected == null ? null : onRollback,
            onSaveCaption: selected == null ? null : onSaveCaption,
            onSaveDatetime: selected == null ? null : onSaveDatetime,
            onSaveTags: selected == null ? null : onSaveTags,
            onToggleFavorite: selected == null ? null : onToggleFavorite,
            record: selected,
            tagsController: tagsController,
            timeController: timeController,
          );
          if (constraints.maxWidth >= 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: _localized(
                    labels,
                    'Detail view and gallery view',
                    '详情视图和图库视图',
                  ),
                  description: _localized(
                    labels,
                    'Inspect, edit, and open the focused desktop viewer.',
                    '检查、编辑，并打开聚焦的桌面查看器。',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: preview),
                    const SizedBox(width: 18),
                    SizedBox(width: 330, child: inspector),
                  ],
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: _localized(
                  labels,
                  'Detail view and gallery view',
                  '详情视图和图库视图',
                ),
                description: _localized(
                  labels,
                  'Inspect, edit, and open the focused desktop viewer.',
                  '检查、编辑，并打开聚焦的桌面查看器。',
                ),
              ),
              const SizedBox(height: 14),
              preview,
              const SizedBox(height: 14),
              inspector,
            ],
          );
        },
      ),
    );
  }
}

final class _FocusedDetailSurface extends StatelessWidget {
  const _FocusedDetailSurface({
    required this.captionController,
    required this.dateController,
    required this.labels,
    required this.onAddToMemory,
    required this.onCloseFocused,
    required this.onOpenGallery,
    required this.onRollback,
    required this.onSaveCaption,
    required this.onSaveDatetime,
    required this.onSaveTags,
    required this.onSelectPhoto,
    required this.onToggleFavorite,
    required this.photos,
    required this.record,
    required this.tagsController,
    required this.timeController,
  });

  final TextEditingController captionController;
  final TextEditingController dateController;
  final UiStrings labels;
  final VoidCallback onAddToMemory;
  final VoidCallback onCloseFocused;
  final ValueChanged<BuildContext> onOpenGallery;
  final VoidCallback onRollback;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveDatetime;
  final VoidCallback onSaveTags;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final VoidCallback onToggleFavorite;
  final List<PhotoRecord> photos;
  final PhotoRecord record;
  final TextEditingController tagsController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    final index = photos.indexWhere((item) => item.photo.id == record.photo.id);
    final displayIndex = index < 0 ? 1 : index + 1;
    final previous = index > 0 ? photos[index - 1] : null;
    final next = index >= 0 && index < photos.length - 1
        ? photos[index + 1]
        : null;
    return Card(
      key: const Key('focused-detail-view'),
      clipBehavior: Clip.antiAlias,
      color: Colors.black,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 780,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Chip(
                          label: Text('Detail View'),
                          side: BorderSide(color: Colors.white24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$displayIndex / ${photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        _FocusedViewerButton(
                          key: const Key('focused-detail-add-button'),
                          onPressed: onAddToMemory,
                          icon: const Icon(Icons.add),
                          highlighted: true,
                        ),
                        const SizedBox(width: 8),
                        _FocusedViewerButton(
                          key: const Key('focused-detail-close-button'),
                          onPressed: onCloseFocused,
                          icon: const Icon(Icons.close),
                        ),
                        const SizedBox(width: 8),
                        _FocusedViewerButton(
                          key: const Key('focused-detail-previous-button'),
                          onPressed: previous == null
                              ? null
                              : () => onSelectPhoto(previous),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        _FocusedViewerButton(
                          key: const Key('focused-detail-next-button'),
                          onPressed: next == null
                              ? null
                              : () => onSelectPhoto(next),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('focused-detail-gallery-button'),
                          onPressed: () => onOpenGallery(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.grey.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Gallery'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: MediaPreview(
                                record: record,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Esc close • Left/Right navigate • G gallery',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Chip(label: Text('${photos.length} items')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FocusedFilmstrip(photos: photos, selected: record),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 395,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _FocusedDetailInspector(
                    captionController: captionController,
                    dateController: dateController,
                    labels: labels,
                    onOpenGallery: () => onOpenGallery(context),
                    onRollback: onRollback,
                    onSaveCaption: onSaveCaption,
                    onSaveDatetime: onSaveDatetime,
                    onSaveTags: onSaveTags,
                    onToggleFavorite: onToggleFavorite,
                    record: record,
                    tagsController: tagsController,
                    timeController: timeController,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _FocusedViewerButton extends StatelessWidget {
  const _FocusedViewerButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.highlighted = false,
  });

  final bool highlighted;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      style: IconButton.styleFrom(
        backgroundColor: enabled ? Colors.grey.shade900 : Colors.black,
        disabledBackgroundColor: Colors.black,
        disabledForegroundColor: Colors.grey.shade800,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade800,
        fixedSize: const Size.square(38),
        side: highlighted
            ? BorderSide(color: Colors.amber.shade400, width: 2)
            : BorderSide.none,
      ),
    );
  }
}

final class _FocusedDetailInspector extends StatelessWidget {
  const _FocusedDetailInspector({
    required this.captionController,
    required this.dateController,
    required this.labels,
    required this.onOpenGallery,
    required this.onRollback,
    required this.onSaveCaption,
    required this.onSaveDatetime,
    required this.onSaveTags,
    required this.onToggleFavorite,
    required this.record,
    required this.tagsController,
    required this.timeController,
  });

  final TextEditingController captionController;
  final TextEditingController dateController;
  final UiStrings labels;
  final VoidCallback onOpenGallery;
  final VoidCallback onRollback;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveDatetime;
  final VoidCallback onSaveTags;
  final VoidCallback onToggleFavorite;
  final PhotoRecord record;
  final TextEditingController tagsController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    final semantic = record.semantic;
    return Column(
      key: const Key('focused-detail-inspector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'INSPECTOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Color(0xff6f645d),
              ),
            ),
            const Spacer(),
            _InspectorHealthPill(indexState: record.indexState),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _basename(record.photo.path),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        GridView.count(
          key: const Key('focused-detail-inspector-grid'),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          childAspectRatio: 1.2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _InspectorMetricCard(
              icon: Icons.folder_open,
              label: 'PATH',
              value: record.photo.path,
            ),
            _InspectorMetricCard(
              icon: Icons.image_outlined,
              label: 'MIME',
              value: record.photo.mime,
            ),
            _InspectorMetricCard(
              icon: Icons.schedule,
              label: 'DATETIME',
              value: record.metadata.datetime == null
                  ? 'Unavailable'
                  : '${_formatDate(DateTime.fromMillisecondsSinceEpoch(record.metadata.datetime!).toLocal()).replaceAll('-', '/')} ${_formatTime(DateTime.fromMillisecondsSinceEpoch(record.metadata.datetime!).toLocal())}',
            ),
            _InspectorMetricCard(
              icon: Icons.photo_camera_outlined,
              label: 'CAMERA',
              value: record.metadata.camera ?? 'Unavailable',
            ),
            _InspectorMetricCard(
              icon: Icons.location_on_outlined,
              label: 'GPS',
              value: record.metadata.lat == null || record.metadata.lng == null
                  ? 'Unavailable'
                  : '${record.metadata.lat}, ${record.metadata.lng}',
            ),
            _InspectorMetricCard(
              icon: Icons.auto_awesome,
              label: 'AI',
              value: semantic.aiModel == null
                  ? semantic.aiStatus.name
                  : '${semantic.aiStatus.name} · ${semantic.aiModel}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AiInsightCard(record: record),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const Key('open-gallery-button'),
              onPressed: onOpenGallery,
              icon: const Icon(Icons.fullscreen),
              label: Text(_localized(labels, 'Open Gallery', '打开图库')),
            ),
            OutlinedButton.icon(
              key: const Key('detail-favorite-button'),
              onPressed: onToggleFavorite,
              icon: Icon(
                record.photo.favorite ? Icons.star : Icons.star_border,
              ),
              label: Text(
                record.photo.favorite
                    ? _localized(labels, 'Unfavorite', '取消收藏')
                    : _localized(labels, 'Favorite', '收藏'),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('rollback-button'),
              onPressed: onRollback,
              icon: const Icon(Icons.undo),
              label: Text(_localized(labels, 'Rollback Latest Edit', '回滚最近编辑')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FocusedEditFields(
          captionController: captionController,
          dateController: dateController,
          labels: labels,
          onSaveCaption: onSaveCaption,
          onSaveDatetime: onSaveDatetime,
          onSaveTags: onSaveTags,
          tagsController: tagsController,
          timeController: timeController,
        ),
      ],
    );
  }
}

final class _InspectorHealthPill extends StatelessWidget {
  const _InspectorHealthPill({required this.indexState});

  final IndexState indexState;

  @override
  Widget build(BuildContext context) {
    final healthy =
        indexState.indexed &&
        indexState.error == null &&
        indexState.missingAt == null;
    return Chip(
      key: const Key('focused-detail-ai-health'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: healthy ? Colors.green.shade200 : Colors.red.shade200,
      ),
      backgroundColor: healthy ? Colors.green.shade50 : Colors.red.shade50,
      label: Text(
        healthy ? 'HEALTHY' : 'FAILED',
        style: TextStyle(
          color: healthy ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

final class _InspectorMetricCard extends StatelessWidget {
  const _InspectorMetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffeadfd6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff83766d),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

final class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.record});

  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    final semantic = record.semantic;
    return Container(
      key: const Key('focused-detail-ai-insights'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffeadfd6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 20),
          const SizedBox(height: 10),
          const Text(
            'AI INSIGHTS',
            style: TextStyle(
              color: Color(0xff83766d),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          _InsightText(
            label: 'GENERATED CAPTION',
            value: semantic.generatedCaption ?? 'Not generated yet',
          ),
          _InsightText(
            label: 'SUMMARY',
            value: semantic.summary ?? 'No generated summary.',
          ),
          if (semantic.generatedLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'GENERATED TAGS',
              style: TextStyle(
                color: Color(0xff83766d),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final label in semantic.generatedLabels)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(label.toUpperCase()),
                  ),
              ],
            ),
          ],
          if (semantic.aiError != null) ...[
            const SizedBox(height: 10),
            _InsightText(
              label: 'LAST AI ERROR',
              value: semantic.aiError!,
              accentColor: Colors.red.shade700,
            ),
          ],
        ],
      ),
    );
  }
}

final class _InsightText extends StatelessWidget {
  const _InsightText({
    required this.label,
    required this.value,
    this.accentColor,
  });

  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accentColor ?? const Color(0xff83766d),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor ?? Colors.black87,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

final class _FocusedEditFields extends StatelessWidget {
  const _FocusedEditFields({
    required this.captionController,
    required this.dateController,
    required this.labels,
    required this.onSaveCaption,
    required this.onSaveDatetime,
    required this.onSaveTags,
    required this.tagsController,
    required this.timeController,
  });

  final TextEditingController captionController;
  final TextEditingController dateController;
  final UiStrings labels;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveDatetime;
  final VoidCallback onSaveTags;
  final TextEditingController tagsController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('focused-detail-edit-fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('caption-field'),
          controller: captionController,
          decoration: InputDecoration(
            labelText: _localized(labels, 'Edit caption', '编辑标题'),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('save-caption-button'),
          onPressed: onSaveCaption,
          child: Text(_localized(labels, 'Save Caption', '保存标题')),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('tags-field'),
          controller: tagsController,
          decoration: InputDecoration(
            labelText: _localized(labels, 'Edit tags', '编辑标签'),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('save-tags-button'),
          onPressed: onSaveTags,
          child: Text(_localized(labels, 'Save Tags', '保存标签')),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('date-field'),
                controller: dateController,
                decoration: InputDecoration(
                  labelText: _localized(labels, 'Date', '日期'),
                  hintText: 'YYYY-MM-DD',
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: TextField(
                key: const Key('time-field'),
                controller: timeController,
                decoration: InputDecoration(
                  labelText: _localized(labels, 'Time', '时间'),
                  hintText: 'HH:mm',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('save-datetime-button'),
          onPressed: onSaveDatetime,
          child: Text(_localized(labels, 'Save Datetime', '保存日期时间')),
        ),
      ],
    );
  }
}

final class _FocusedFilmstrip extends StatelessWidget {
  const _FocusedFilmstrip({required this.photos, required this.selected});

  final List<PhotoRecord> photos;
  final PhotoRecord selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('focused-detail-filmstrip'),
      height: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GALLERY STRIP',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final record = photos[index];
                final active = record.photo.id == selected.photo.id;
                return Container(
                  key: Key('focused-detail-filmstrip-${record.photo.id}'),
                  width: 80,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? Colors.amber : Colors.white24,
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: MediaPreview(record: record, fit: BoxFit.cover),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemCount: photos.length,
            ),
          ),
        ],
      ),
    );
  }
}

final class _DetailPreview extends StatelessWidget {
  const _DetailPreview({required this.record});

  final PhotoRecord? record;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: selected == null
            ? Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 70),
                ),
              )
            : MediaPreview(record: selected, fit: BoxFit.contain),
      ),
    );
  }
}

final class _DetailInspector extends StatelessWidget {
  const _DetailInspector({
    required this.captionController,
    required this.dateController,
    required this.labels,
    required this.onOpenGallery,
    required this.onRollback,
    required this.onSaveCaption,
    required this.onSaveDatetime,
    required this.onSaveTags,
    required this.onToggleFavorite,
    required this.record,
    required this.tagsController,
    required this.timeController,
  });

  final TextEditingController captionController;
  final TextEditingController dateController;
  final UiStrings labels;
  final VoidCallback? onOpenGallery;
  final VoidCallback? onRollback;
  final VoidCallback? onSaveCaption;
  final VoidCallback? onSaveDatetime;
  final VoidCallback? onSaveTags;
  final VoidCallback? onToggleFavorite;
  final PhotoRecord? record;
  final TextEditingController tagsController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected == null
              ? _localized(labels, 'No photo selected', '未选择照片')
              : selected.photo.path,
          overflow: TextOverflow.ellipsis,
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          MetadataGrid(labels: labels, record: selected),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const Key('open-gallery-button'),
              onPressed: onOpenGallery,
              icon: const Icon(Icons.fullscreen),
              label: Text(_localized(labels, 'Open Gallery', '打开图库')),
            ),
            OutlinedButton.icon(
              key: const Key('detail-favorite-button'),
              onPressed: onToggleFavorite,
              icon: Icon(
                selected?.photo.favorite == true
                    ? Icons.star
                    : Icons.star_border,
              ),
              label: Text(
                selected?.photo.favorite == true
                    ? _localized(labels, 'Unfavorite', '取消收藏')
                    : _localized(labels, 'Favorite', '收藏'),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('rollback-button'),
              onPressed: onRollback,
              icon: const Icon(Icons.undo),
              label: Text(_localized(labels, 'Rollback Latest Edit', '回滚最近编辑')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('caption-field'),
          controller: captionController,
          decoration: InputDecoration(
            labelText: _localized(labels, 'Edit caption', '编辑标题'),
          ),
          enabled: selected != null,
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('save-caption-button'),
          onPressed: onSaveCaption,
          child: Text(_localized(labels, 'Save Caption', '保存标题')),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('tags-field'),
          controller: tagsController,
          decoration: InputDecoration(
            labelText: _localized(labels, 'Edit tags', '编辑标签'),
          ),
          enabled: selected != null,
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('save-tags-button'),
          onPressed: onSaveTags,
          child: Text(_localized(labels, 'Save Tags', '保存标签')),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('date-field'),
                controller: dateController,
                decoration: InputDecoration(
                  labelText: _localized(labels, 'Date', '日期'),
                  hintText: 'YYYY-MM-DD',
                ),
                enabled: selected != null,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: TextField(
                key: const Key('time-field'),
                controller: timeController,
                decoration: InputDecoration(
                  labelText: _localized(labels, 'Time', '时间'),
                  hintText: 'HH:mm',
                ),
                enabled: selected != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('save-datetime-button'),
          onPressed: onSaveDatetime,
          child: Text(_localized(labels, 'Save Datetime', '保存日期时间')),
        ),
      ],
    );
  }
}

final class MetadataGrid extends StatelessWidget {
  const MetadataGrid({required this.labels, required this.record});

  final UiStrings labels;
  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    final capturedPrefix = _localized(labels, 'Captured', '拍摄');
    final captured = record.metadata.datetime == null
        ? '$capturedPrefix: ${_localized(labels, 'unknown', '未知')}'
        : '$capturedPrefix: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(record.metadata.datetime!).toLocal())} ${_formatTime(DateTime.fromMillisecondsSinceEpoch(record.metadata.datetime!).toLocal())}';
    final offset = DateTime.now().timeZoneOffset;
    final offsetHours = offset.inHours.toString().padLeft(2, '0');
    return Wrap(
      key: const Key('metadata-grid'),
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(captured),
        _MetaChip('${_localized(labels, 'Time zone', '时区')}: UTC$offsetHours'),
        _MetaChip('MIME: ${record.photo.mime}'),
        _MetaChip('${_localized(labels, 'Size', '大小')}: ${record.photo.size}'),
        if (record.metadata.camera != null)
          _MetaChip('Camera: ${record.metadata.camera}'),
        if (record.metadata.originalDatetimeText != null)
          _MetaChip('Original: ${record.metadata.originalDatetimeText}'),
        if (record.metadata.lat != null && record.metadata.lng != null)
          _MetaChip('GPS: ${record.metadata.lat}, ${record.metadata.lng}'),
      ],
    );
  }
}

final class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
