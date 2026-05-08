part of '../chronopic_home.dart';

final class BrowseModeSelector extends StatelessWidget {
  const BrowseModeSelector({
    required this.labels,
    required this.mode,
    required this.onChanged,
  });

  final UiStrings labels;
  final BrowseMode mode;
  final ValueChanged<BrowseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<BrowseMode>(
      key: const Key('browse-mode-control'),
      segments: [
        ButtonSegment(
          value: BrowseMode.waterfall,
          icon: const Icon(Icons.grid_view),
          label: Text(labels.grid),
        ),
        ButtonSegment(
          value: BrowseMode.map,
          icon: const Icon(Icons.map_outlined),
          label: Text(labels.map),
        ),
        ButtonSegment(
          value: BrowseMode.timeline,
          icon: const Icon(Icons.timeline),
          label: Text(labels.timeline),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

final class BrowseSurface extends StatelessWidget {
  const BrowseSurface({
    required this.mode,
    required this.onSelectPhoto,
    required this.photos,
    required this.selected,
  });

  final BrowseMode mode;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final List<PhotoRecord> photos;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      BrowseMode.waterfall => PhotoGrid(
        onSelectPhoto: onSelectPhoto,
        photos: photos,
        selected: selected,
      ),
      BrowseMode.map => MapBrowseView(
        onSelectPhoto: onSelectPhoto,
        photos: photos,
      ),
      BrowseMode.timeline => TimelineBrowseView(
        onSelectPhoto: onSelectPhoto,
        photos: photos,
      ),
    };
  }
}

final class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    required this.onSelectPhoto,
    required this.photos,
    required this.selected,
  });

  final ValueChanged<PhotoRecord> onSelectPhoto;
  final List<PhotoRecord> photos;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const _EmptyLibrary();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 5
            : width >= 820
            ? 4
            : width >= 620
            ? 3
            : 2;
        return GridView.builder(
          key: const Key('photo-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final record = photos[index];
            return PhotoCardTile(
              onSelect: () => onSelectPhoto(record),
              record: record,
              selected: selected?.photo.id == record.photo.id,
            );
          },
        );
      },
    );
  }
}

final class PhotoCardTile extends StatelessWidget {
  const PhotoCardTile({
    required this.onSelect,
    required this.record,
    required this.selected,
  });

  final VoidCallback onSelect;
  final PhotoRecord record;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('photo-card-${record.photo.id}'),
      clipBehavior: Clip.antiAlias,
      color: selected ? Colors.amber.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Colors.amber.shade700 : Colors.grey.shade200,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: MediaPreview(record: record, fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.semantic.caption ?? _basename(record.photo.path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        record.photo.favorite ? Icons.star : Icons.star_border,
                        color: record.photo.favorite
                            ? Colors.amber.shade700
                            : Colors.grey.shade500,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.metadata.datetime == null
                              ? 'No date'
                              : _formatDate(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    record.metadata.datetime!,
                                  ).toLocal(),
                                ),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
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
    );
  }
}

final class MapBrowseView extends StatelessWidget {
  const MapBrowseView({required this.onSelectPhoto, required this.photos});

  final ValueChanged<PhotoRecord> onSelectPhoto;
  final List<PhotoRecord> photos;

  @override
  Widget build(BuildContext context) {
    final mapped = photos
        .where(
          (record) =>
              record.metadata.lat != null && record.metadata.lng != null,
        )
        .toList();
    return _Panel(
      child: Column(
        key: const Key('map-view'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Map',
            description: 'Photos with GPS metadata in the current result set.',
          ),
          const SizedBox(height: 12),
          if (mapped.isEmpty)
            const Text('No geotagged photos in this view.')
          else
            for (final record in mapped)
              ListTile(
                key: Key('map-photo-${record.photo.id}'),
                leading: const Icon(Icons.place_outlined),
                title: Text(
                  record.semantic.caption ?? _basename(record.photo.path),
                ),
                subtitle: Text(
                  '${record.metadata.lat}, ${record.metadata.lng}',
                ),
                onTap: () => onSelectPhoto(record),
              ),
        ],
      ),
    );
  }
}

final class TimelineBrowseView extends StatelessWidget {
  const TimelineBrowseView({required this.onSelectPhoto, required this.photos});

  final ValueChanged<PhotoRecord> onSelectPhoto;
  final List<PhotoRecord> photos;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PhotoRecord>>{};
    for (final record in photos) {
      final timestamp = record.metadata.datetime;
      final key = timestamp == null
          ? 'No date'
          : _formatDate(
              DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal(),
            );
      groups.putIfAbsent(key, () => <PhotoRecord>[]).add(record);
    }
    return _Panel(
      child: Column(
        key: const Key('timeline-view'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Timeline',
            description: 'Photos grouped by local capture date.',
          ),
          const SizedBox(height: 12),
          for (final entry in groups.entries) ...[
            Padding(
              key: Key('timeline-group-${entry.key}'),
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final record in entry.value)
              ListTile(
                key: Key('timeline-photo-${record.photo.id}'),
                leading: const Icon(Icons.photo_outlined),
                title: Text(
                  record.semantic.caption ?? _basename(record.photo.path),
                ),
                subtitle: Text(record.photo.path),
                onTap: () => onSelectPhoto(record),
              ),
          ],
        ],
      ),
    );
  }
}

final class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 52,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text('Add a folder, scan, then browse photos here.'),
            ],
          ),
        ),
      ),
    );
  }
}

final class MediaPreview extends StatelessWidget {
  const MediaPreview({required this.record, this.fit = BoxFit.cover});

  final BoxFit fit;
  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    final mime = record.photo.mime;
    if (mime.startsWith('video/')) {
      return Container(
        key: Key('video-preview-${record.photo.id}'),
        color: Colors.grey.shade900,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.movie_outlined, color: Colors.white70, size: 40),
              SizedBox(height: 8),
              Text('Video', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }
    final thumbnailPath = record.photo.thumbnailPath;
    final previewPath = thumbnailPath != null && thumbnailPath.isNotEmpty
        ? thumbnailPath
        : record.photo.path;
    final file = File(previewPath);
    if (!file.existsSync()) {
      return Container(
        key: Key('missing-preview-${record.photo.id}'),
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return Image.file(
      file,
      key: Key('media-preview-${record.photo.id}'),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
