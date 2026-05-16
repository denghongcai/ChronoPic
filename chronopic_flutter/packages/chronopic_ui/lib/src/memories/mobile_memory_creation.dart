part of '../chronopic_home.dart';

final class MobileMemoryCreationSheet extends StatefulWidget {
  const MobileMemoryCreationSheet({
    required this.coverPhotoId,
    required this.descriptionController,
    required this.hasMorePhotos,
    required this.labels,
    required this.onCommit,
    required this.onLoadMorePhotos,
    required this.onSetCover,
    required this.onTogglePhoto,
    required this.photos,
    required this.selectedPhotoIds,
    required this.titleController,
    super.key,
  });

  final String? coverPhotoId;
  final TextEditingController descriptionController;
  final bool hasMorePhotos;
  final UiStrings labels;
  final VoidCallback onCommit;
  final VoidCallback onLoadMorePhotos;
  final ValueChanged<String> onSetCover;
  final ValueChanged<String> onTogglePhoto;
  final List<PhotoRecord> photos;
  final Set<String> selectedPhotoIds;
  final TextEditingController titleController;

  @override
  State<MobileMemoryCreationSheet> createState() =>
      _MobileMemoryCreationSheetState();
}

final class _MobileMemoryCreationSheetState
    extends State<MobileMemoryCreationSheet> {
  int _step = 0;

  bool get _hasSelection => widget.selectedPhotoIds.isNotEmpty;
  bool get _isLastStep => _step == 2;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Padding(
          key: const Key('mobile-memory-creation-sheet'),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MobileMemorySheetHeader(step: _step, labels: widget.labels),
              const SizedBox(height: 12),
              Expanded(child: _buildStep(context)),
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      0 => _MobileMemoryPhotoPicker(
        labels: widget.labels,
        photos: widget.photos,
        selectedPhotoIds: widget.selectedPhotoIds,
        onTogglePhoto: widget.onTogglePhoto,
        hasMorePhotos: widget.hasMorePhotos,
        onLoadMorePhotos: widget.onLoadMorePhotos,
      ),
      1 => _MobileMemoryDetailsStep(
        coverPhotoId: widget.coverPhotoId,
        descriptionController: widget.descriptionController,
        labels: widget.labels,
        onSetCover: widget.onSetCover,
        photos: widget.photos,
        selectedPhotoIds: widget.selectedPhotoIds,
        titleController: widget.titleController,
      ),
      _ => _MobileMemoryConfirmStep(
        coverPhotoId: widget.coverPhotoId,
        description: widget.descriptionController.text.trim(),
        labels: widget.labels,
        photos: widget.photos,
        selectedPhotoIds: widget.selectedPhotoIds,
        title: widget.titleController.text.trim(),
      ),
    };
  }

  Widget _buildActions(BuildContext context) {
    final nextEnabled = _step != 0 || _hasSelection;
    return Row(
      children: [
        TextButton(
          onPressed: () {
            if (_step == 0) {
              Navigator.of(context).pop();
              return;
            }
            setState(() => _step -= 1);
          },
          child: Text(
            _localized(
              widget.labels,
              _step == 0 ? 'Cancel' : 'Back',
              _step == 0 ? '取消' : '上一步',
            ),
          ),
        ),
        const Spacer(),
        FilledButton(
          key: Key(
            _isLastStep ? 'mobile-memory-create-confirm' : 'mobile-memory-next',
          ),
          onPressed: nextEnabled
              ? () {
                  if (_isLastStep) {
                    widget.onCommit();
                    return;
                  }
                  setState(() => _step += 1);
                }
              : null,
          child: Text(
            _isLastStep
                ? widget.labels.createMemory
                : _localized(widget.labels, 'Next', '下一步'),
          ),
        ),
      ],
    );
  }
}

final class _MobileMemorySheetHeader extends StatelessWidget {
  const _MobileMemorySheetHeader({required this.labels, required this.step});

  final UiStrings labels;
  final int step;

  @override
  Widget build(BuildContext context) {
    final title = switch (step) {
      0 => _localized(labels, 'Select photos', '选择照片'),
      1 => _localized(labels, 'Name and cover', '名称和封面'),
      _ => _localized(labels, 'Confirm memory', '确认记忆'),
    };
    final subtitle = switch (step) {
      0 => _localized(
        labels,
        'Choose the moments that belong together.',
        '选择属于同一段记忆的照片。',
      ),
      1 => _localized(
        labels,
        'Add a short title, optional description, and cover.',
        '添加简短标题、可选描述和封面。',
      ),
      _ => _localized(
        labels,
        'Review before creating an editable memory.',
        '创建可编辑记忆前先确认。',
      ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          foregroundColor: Colors.orange.shade900,
          child: Text('${step + 1}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }
}

final class _MobileMemoryPhotoPicker extends StatelessWidget {
  const _MobileMemoryPhotoPicker({
    required this.hasMorePhotos,
    required this.labels,
    required this.onLoadMorePhotos,
    required this.onTogglePhoto,
    required this.photos,
    required this.selectedPhotoIds,
  });

  final bool hasMorePhotos;
  final UiStrings labels;
  final VoidCallback onLoadMorePhotos;
  final ValueChanged<String> onTogglePhoto;
  final List<PhotoRecord> photos;
  final Set<String> selectedPhotoIds;

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedPhotoIds.length;
    return Column(
      key: const Key('mobile-memory-step-select'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedCount == 0
              ? _localized(labels, 'Select at least one photo', '请至少选择一张照片')
              : _localized(
                  labels,
                  '$selectedCount selected',
                  '已选择 $selectedCount 张',
                ),
          style: TextStyle(
            color: selectedCount == 0
                ? Colors.orange.shade900
                : Colors.green.shade800,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: photos.isEmpty
              ? Center(
                  child: Text(
                    _localized(labels, 'No photos available', '暂无可用照片'),
                  ),
                )
              : GridView.builder(
                  key: const Key('mobile-memory-photo-grid'),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final record = photos[index];
                    final selected = selectedPhotoIds.contains(record.photo.id);
                    return _MobileMemorySelectablePhotoTile(
                      key: Key('mobile-memory-select-${record.photo.id}'),
                      labels: labels,
                      onToggle: () => onTogglePhoto(record.photo.id),
                      record: record,
                      selected: selected,
                    );
                  },
                ),
        ),
        if (hasMorePhotos) ...[
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              key: const Key('mobile-memory-load-more'),
              onPressed: onLoadMorePhotos,
              icon: const Icon(Icons.expand_more),
              label: Text(_localized(labels, 'Load more', '加载更多')),
            ),
          ),
        ],
      ],
    );
  }
}

final class _MobileMemorySelectablePhotoTile extends StatelessWidget {
  const _MobileMemorySelectablePhotoTile({
    required this.labels,
    required this.onToggle,
    required this.record,
    required this.selected,
    super.key,
  });

  final UiStrings labels;
  final VoidCallback onToggle;
  final PhotoRecord record;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Semantics(
        button: true,
        selected: selected,
        onTap: onToggle,
        label: _localized(
          labels,
          'Select ${record.semantic.caption ?? _basename(record.photo.path)}',
          '选择 ${record.semantic.caption ?? _basename(record.photo.path)}',
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? Colors.orange.shade700 : Colors.grey.shade200,
              width: selected ? 3 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaPreview(record: record, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xaa000000)],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  record.semantic.caption ?? _basename(record.photo.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: selected ? Colors.orange : Colors.white,
                  child: Icon(
                    selected ? Icons.check : Icons.add,
                    size: 17,
                    color: selected ? Colors.white : Colors.grey.shade800,
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

final class _MobileMemoryDetailsStep extends StatelessWidget {
  const _MobileMemoryDetailsStep({
    required this.coverPhotoId,
    required this.descriptionController,
    required this.labels,
    required this.onSetCover,
    required this.photos,
    required this.selectedPhotoIds,
    required this.titleController,
  });

  final String? coverPhotoId;
  final TextEditingController descriptionController;
  final UiStrings labels;
  final ValueChanged<String> onSetCover;
  final List<PhotoRecord> photos;
  final Set<String> selectedPhotoIds;
  final TextEditingController titleController;

  @override
  Widget build(BuildContext context) {
    final selectedPhotos = photos
        .where((record) => selectedPhotoIds.contains(record.photo.id))
        .toList();
    return ListView(
      key: const Key('mobile-memory-step-edit'),
      children: [
        TextField(
          key: const Key('mobile-memory-title-field'),
          controller: titleController,
          decoration: InputDecoration(labelText: labels.memoryName),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('mobile-memory-description-field'),
          controller: descriptionController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: _localized(labels, 'Description', '描述'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _localized(labels, 'Choose cover', '选择封面'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selectedPhotos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final record = selectedPhotos[index];
              final selected = coverPhotoId == record.photo.id;
              return _MobileMemoryCoverChoice(
                key: Key('mobile-memory-cover-${record.photo.id}'),
                onTap: () => onSetCover(record.photo.id),
                record: record,
                selected: selected,
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _MobileMemoryCoverChoice extends StatelessWidget {
  const _MobileMemoryCoverChoice({
    required this.onTap,
    required this.record,
    required this.selected,
    super.key,
  });

  final VoidCallback onTap;
  final PhotoRecord record;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? Colors.orange.shade700 : Colors.grey.shade200,
              width: selected ? 3 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaPreview(record: record, fit: BoxFit.cover),
              if (selected)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.orange.shade700,
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
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

final class _MobileMemoryConfirmStep extends StatelessWidget {
  const _MobileMemoryConfirmStep({
    required this.coverPhotoId,
    required this.description,
    required this.labels,
    required this.photos,
    required this.selectedPhotoIds,
    required this.title,
  });

  final String? coverPhotoId;
  final String description;
  final UiStrings labels;
  final List<PhotoRecord> photos;
  final Set<String> selectedPhotoIds;
  final String title;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.isEmpty
        ? _localized(labels, 'New Memory', '新记忆')
        : title;
    final selectedCount = selectedPhotoIds.length;
    final cover = coverPhotoId == null
        ? null
        : photos
              .where((record) => record.photo.id == coverPhotoId)
              .cast<PhotoRecord?>()
              .firstOrNull;
    return ListView(
      key: const Key('mobile-memory-step-confirm'),
      children: [
        if (cover != null)
          SizedBox(
            height: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: MediaPreview(record: cover, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          displayTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            _localized(labels, '$selectedCount photos', '$selectedCount 张照片'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description.isEmpty ? labels.noDescription : description,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
