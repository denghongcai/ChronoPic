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
    required this.onOpenGallery,
    required this.onSelectPhoto,
    required this.photos,
    required this.selected,
  });

  final BrowseMode mode;
  final ValueChanged<PhotoRecord> onOpenGallery;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final List<PhotoRecord> photos;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      BrowseMode.waterfall => PhotoGrid(
        onOpenGallery: onOpenGallery,
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
        selected: selected,
      ),
    };
  }
}

final class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    required this.onOpenGallery,
    required this.onSelectPhoto,
    required this.photos,
    required this.selected,
  });

  final ValueChanged<PhotoRecord> onOpenGallery;
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
        final columns = width >= 950
            ? 3
            : width >= 620
            ? 2
            : 1;
        return GridView.builder(
          key: const Key('photo-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.92,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final record = photos[index];
            return PhotoCardTile(
              onOpenGallery: () => onOpenGallery(record),
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

final class PhotoCardTile extends StatefulWidget {
  const PhotoCardTile({
    required this.onOpenGallery,
    required this.onSelect,
    required this.record,
    required this.selected,
  });

  final VoidCallback onOpenGallery;
  final VoidCallback onSelect;
  final PhotoRecord record;
  final bool selected;

  @override
  State<PhotoCardTile> createState() => _PhotoCardTileState();
}

final class _PhotoCardTileState extends State<PhotoCardTile> {
  DateTime? _lastTapAt;

  void _handleTap() {
    final now = DateTime.now();
    final isDoubleTap =
        _lastTapAt != null &&
        now.difference(_lastTapAt!) <= const Duration(milliseconds: 320);
    _lastTapAt = isDoubleTap ? null : now;
    widget.onSelect();
    if (isDoubleTap) widget.onOpenGallery();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('photo-card-${widget.record.photo.id}'),
      clipBehavior: Clip.antiAlias,
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: widget.selected
              ? Colors.amber.shade700
              : Colors.grey.shade200,
          width: widget.selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _handleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaPreview(record: widget.record, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00ffffff),
                    Color(0x22f6f0e8),
                    Color(0xdd1d1a16),
                  ],
                  stops: [0.35, 0.62, 1],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.record.semantic.caption ??
                        _basename(widget.record.photo.path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        widget.record.photo.favorite
                            ? Icons.star
                            : Icons.star_border,
                        color: widget.record.photo.favorite
                            ? Colors.amber.shade700
                            : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.record.metadata.datetime == null
                              ? 'No date'
                              : _formatDate(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    widget.record.metadata.datetime!,
                                  ).toLocal(),
                                ),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
          Container(
            key: const Key('map-disabled-canvas'),
            height: 340,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFEFEFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _MapGridPainter()),
                ),
                Center(child: _MapStatusCard(mappedCount: mapped.length)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (mapped.isEmpty)
            _MapEmptyState(totalCount: photos.length)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Mappable Photos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${mapped.length} of ${photos.length} in current results',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final record in mapped)
                  _MapPhotoTile(
                    key: Key('map-photo-${record.photo.id}'),
                    onTap: () => onSelectPhoto(record),
                    record: record,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

final class _MapStatusCard extends StatelessWidget {
  const _MapStatusCard({required this.mappedCount});

  final int mappedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                'MAP ERROR',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Map view failed to initialize',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Text(
            'AMap loaded but window.AMap is unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 18),
          Semantics(
            label: '$mappedCount mapped photos remain selectable below',
            child: _SoftStat(label: 'Mapped', value: '$mappedCount'),
          ),
        ],
      ),
    );
  }
}

final class _MapPhotoTile extends StatelessWidget {
  const _MapPhotoTile({required this.onTap, required this.record, super.key});

  final VoidCallback onTap;
  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.grey.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.shade100,
          child: Icon(Icons.place_outlined, color: Colors.amber.shade800),
        ),
        title: Text(record.semantic.caption ?? _basename(record.photo.path)),
        subtitle: Text(
          '${_formatCoordinate(record.metadata.lat)}, ${_formatCoordinate(record.metadata.lng)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

final class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No geotagged photos in these $totalCount results. Use grid or timeline to continue browsing.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

final class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade200.withValues(alpha: 0.34)
      ..strokeWidth = 1;
    for (double x = 60; x < size.width; x += 92) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 58; y < size.height; y += 86) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final class _SoftStat extends StatelessWidget {
  const _SoftStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

final class TimelineBrowseView extends StatelessWidget {
  const TimelineBrowseView({
    required this.onSelectPhoto,
    required this.photos,
    required this.selected,
  });

  final ValueChanged<PhotoRecord> onSelectPhoto;
  final List<PhotoRecord> photos;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PhotoRecord>>{};
    for (final record in photos) {
      final timestamp = record.metadata.datetime;
      final key = timestamp == null
          ? 'No date'
          : _formatTimelineMonth(
              DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal(),
            );
      groups.putIfAbsent(key, () => <PhotoRecord>[]).add(record);
    }
    final dated = photos.where((record) => record.metadata.datetime != null);
    final timestamps = dated.map((record) => record.metadata.datetime!).toList()
      ..sort();
    final range = timestamps.isEmpty
        ? 'No dated media'
        : '${_formatDate(DateTime.fromMillisecondsSinceEpoch(timestamps.first).toLocal())} to ${_formatDate(DateTime.fromMillisecondsSinceEpoch(timestamps.last).toLocal())}';
    return _Panel(
      child: Column(
        key: const Key('timeline-view'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Timeline View',
            description:
                'Review the current library results by capture date without leaving the desktop browse shell.',
            trailing: Chip(
              avatar: const Icon(Icons.timeline, size: 16),
              label: Text('${groups.length} groups'),
            ),
          ),
          const SizedBox(height: 16),
          _TimelineHero(
            datedCount: timestamps.length,
            groupCount: groups.length,
            onSelectPhoto: onSelectPhoto,
            range: range,
            selected: selected,
            totalCount: photos.length,
          ),
          const SizedBox(height: 16),
          for (final entry in groups.entries) ...[
            _TimelineGroupCard(
              key: Key('timeline-group-${entry.key}'),
              dateLabel: entry.key,
              onSelectPhoto: onSelectPhoto,
              records: entry.value,
              selected: selected,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

final class _TimelineHero extends StatelessWidget {
  const _TimelineHero({
    required this.datedCount,
    required this.groupCount,
    required this.onSelectPhoto,
    required this.range,
    required this.selected,
    required this.totalCount,
  });

  final int datedCount;
  final int groupCount;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final String range;
  final PhotoRecord? selected;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _TimelineScopeChip(label: 'Year'),
              const _TimelineScopeChip(label: 'Month', selected: true),
              const _TimelineScopeChip(label: 'Day'),
              OutlinedButton(
                key: const Key('timeline-select-button'),
                onPressed: selected == null
                    ? null
                    : () => onSelectPhoto(selected),
                child: const Text('Select'),
              ),
              _TimelineMetricChip(label: '$groupCount groups'),
              _TimelineMetricChip(label: '$datedCount dated photos'),
            ],
          ),
          const SizedBox(height: 18),
          _TimelineInfoStrip(
            label: 'TIMELINE SCOPE',
            text:
                'Showing $datedCount dated photos across $groupCount Month groups in $totalCount current results.',
          ),
          if (selected != null) ...[
            const SizedBox(height: 14),
            _TimelineSelectedBanner(
              onSelectPhoto: onSelectPhoto,
              record: selected,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(range, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}

final class _TimelineScopeChip extends StatelessWidget {
  const _TimelineScopeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.grey.shade900 : Colors.grey.shade700,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

final class _TimelineMetricChip extends StatelessWidget {
  const _TimelineMetricChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? Colors.lightBlue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? Colors.lightBlue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.lightBlue.shade800 : Colors.grey.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

final class _TimelineInfoStrip extends StatelessWidget {
  const _TimelineInfoStrip({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _TimelineMetricChip(label: label, selected: true),
          Text(text, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

final class _TimelineSelectedBanner extends StatelessWidget {
  const _TimelineSelectedBanner({
    required this.onSelectPhoto,
    required this.record,
  });

  final ValueChanged<PhotoRecord> onSelectPhoto;
  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('timeline-selected-photo-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.lightBlue.shade200),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _TimelineMetricChip(label: 'SELECTED PHOTO', selected: true),
          Text(
            '${_basename(record.photo.path)} is the current timeline focus.',
            style: TextStyle(color: Colors.lightBlue.shade900),
          ),
          OutlinedButton(
            key: const Key('timeline-open-detail-button'),
            onPressed: () => onSelectPhoto(record),
            child: const Text('Open Detail'),
          ),
        ],
      ),
    );
  }
}

final class _TimelineGroupCard extends StatelessWidget {
  const _TimelineGroupCard({
    required this.dateLabel,
    required this.onSelectPhoto,
    required this.records,
    required this.selected,
    super.key,
  });

  final String dateLabel;
  final ValueChanged<PhotoRecord> onSelectPhoto;
  final List<PhotoRecord> records;
  final PhotoRecord? selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.lightBlue.shade50,
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.lightBlue.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${records.length} items',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => onSelectPhoto(records.first),
                  icon: const Icon(Icons.ads_click, size: 18),
                  label: const Text('Select'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final record in records)
                  _TimelinePhotoCard(
                    key: Key('timeline-photo-${record.photo.id}'),
                    onTap: () => onSelectPhoto(record),
                    record: record,
                    selected: selected?.photo.id == record.photo.id,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _TimelinePhotoCard extends StatelessWidget {
  const _TimelinePhotoCard({
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
    return SizedBox(
      width: 330,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? Colors.amber.shade600 : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 112,
                child: MediaPreview(record: record, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      record.semantic.caption ?? _basename(record.photo.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TimelineMetricChip(
                          label: selected ? 'Selected' : 'Media',
                          selected: selected,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.photo.path,
                            maxLines: 1,
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
      ),
    );
  }
}

String _formatCoordinate(double? value) {
  if (value == null) {
    return 'unknown';
  }
  return value.toStringAsFixed(5);
}

String _formatTimelineMonth(DateTime value) {
  return '${value.year}年${value.month}月';
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
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 68;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    color: Colors.white70,
                    size: compact ? 24 : 40,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Video',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              );
            },
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
      return _MediaFallbackSurface(
        key: Key('missing-preview-${record.photo.id}'),
        label: record.photo.path,
      );
    }
    return Image.file(
      file,
      key: Key('media-preview-${record.photo.id}'),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          _MediaFallbackSurface(label: record.photo.path),
    );
  }
}

final class _MediaFallbackSurface extends StatelessWidget {
  const _MediaFallbackSurface({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBFAF8), Color(0xFFEFEDE9), Color(0xFFBDB9B0)],
          stops: [0, 0.58, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 8,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
