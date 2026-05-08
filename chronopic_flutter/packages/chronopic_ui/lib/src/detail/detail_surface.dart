part of '../chronopic_home.dart';

final class DetailSurface extends StatelessWidget {
  const DetailSurface({
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
  final ValueChanged<BuildContext> onOpenGallery;
  final VoidCallback onRollback;
  final VoidCallback onSaveCaption;
  final VoidCallback onSaveDatetime;
  final VoidCallback onSaveTags;
  final VoidCallback onToggleFavorite;
  final PhotoRecord? record;
  final TextEditingController tagsController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Detail view and gallery view',
            description: 'Inspect, edit, and open the focused desktop viewer.',
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1.2,
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
          ),
          const SizedBox(height: 10),
          Text(
            selected == null ? 'No photo selected' : selected.photo.path,
            overflow: TextOverflow.ellipsis,
          ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            MetadataGrid(record: selected),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('open-gallery-button'),
                onPressed: selected == null
                    ? null
                    : () => onOpenGallery(context),
                icon: const Icon(Icons.fullscreen),
                label: const Text('Open Gallery'),
              ),
              OutlinedButton.icon(
                key: const Key('detail-favorite-button'),
                onPressed: selected == null ? null : onToggleFavorite,
                icon: Icon(
                  selected?.photo.favorite == true
                      ? Icons.star
                      : Icons.star_border,
                ),
                label: Text(
                  selected?.photo.favorite == true ? 'Unfavorite' : 'Favorite',
                ),
              ),
              OutlinedButton.icon(
                key: const Key('rollback-button'),
                onPressed: selected == null ? null : onRollback,
                icon: const Icon(Icons.undo),
                label: const Text('Rollback Latest Edit'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('caption-field'),
            controller: captionController,
            decoration: const InputDecoration(labelText: 'Edit caption'),
            enabled: selected != null,
          ),
          const SizedBox(height: 10),
          FilledButton(
            key: const Key('save-caption-button'),
            onPressed: selected == null ? null : onSaveCaption,
            child: const Text('Save Caption'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tags-field'),
            controller: tagsController,
            decoration: const InputDecoration(labelText: 'Edit tags'),
            enabled: selected != null,
          ),
          const SizedBox(height: 10),
          FilledButton(
            key: const Key('save-tags-button'),
            onPressed: selected == null ? null : onSaveTags,
            child: const Text('Save Tags'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('date-field'),
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    hintText: 'YYYY-MM-DD',
                  ),
                  enabled: selected != null,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextField(
                  key: const Key('time-field'),
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
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
            onPressed: selected == null ? null : onSaveDatetime,
            child: const Text('Save Datetime'),
          ),
        ],
      ),
    );
  }
}

final class MetadataGrid extends StatelessWidget {
  const MetadataGrid({required this.record});

  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    final captured = record.metadata.datetime == null
        ? 'Captured: unknown'
        : 'Captured: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(record.metadata.datetime!).toLocal())} ${_formatTime(DateTime.fromMillisecondsSinceEpoch(record.metadata.datetime!).toLocal())}';
    final offset = DateTime.now().timeZoneOffset;
    final offsetHours = offset.inHours.toString().padLeft(2, '0');
    return Wrap(
      key: const Key('metadata-grid'),
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(captured),
        _MetaChip('Time zone: UTC$offsetHours'),
        _MetaChip('MIME: ${record.photo.mime}'),
        _MetaChip('Size: ${record.photo.size}'),
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
