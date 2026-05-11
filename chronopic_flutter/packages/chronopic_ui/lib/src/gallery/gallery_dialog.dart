part of '../chronopic_home.dart';

enum GalleryDialogResultAction { close, detail }

final class GalleryDialogResult {
  const GalleryDialogResult._({required this.action, required this.record});

  const GalleryDialogResult.close(PhotoRecord record)
    : this._(action: GalleryDialogResultAction.close, record: record);

  const GalleryDialogResult.detail(PhotoRecord record)
    : this._(action: GalleryDialogResultAction.detail, record: record);

  final GalleryDialogResultAction action;
  final PhotoRecord record;
}

final class GalleryDialog extends StatefulWidget {
  const GalleryDialog({
    required this.initialPhotoId,
    required this.labels,
    required this.photos,
    super.key,
  });

  final String initialPhotoId;
  final UiStrings labels;
  final List<PhotoRecord> photos;

  @override
  State<GalleryDialog> createState() => _GalleryDialogState();
}

final class _GalleryDialogState extends State<GalleryDialog> {
  late int _index = widget.photos.indexWhere(
    (record) => record.photo.id == widget.initialPhotoId,
  );

  PhotoRecord get _record => widget.photos[_index < 0 ? 0 : _index];

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final mobileLayout = MediaQuery.sizeOf(context).width < 720;
    final captured = record.metadata.datetime == null
        ? _localized(widget.labels, 'Captured: unknown', '拍摄：未知')
        : () {
            final dateTime = DateTime.fromMillisecondsSinceEpoch(
              record.metadata.datetime!,
            ).toLocal();
            return '${_formatDate(dateTime).replaceAll('-', '/')} ${_formatTime(dateTime)}';
          }();

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Dialog.fullscreen(
        key: const Key('gallery-dialog'),
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: mobileLayout
                ? Text(
                    '${_index + 1} / ${widget.photos.length}',
                    key: const Key('gallery-counter'),
                  )
                : Row(
                    children: [
                      Chip(
                        label: Text(
                          _localized(widget.labels, 'Gallery View', '图库视图'),
                        ),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_index + 1} / ${widget.photos.length}',
                        key: const Key('gallery-counter'),
                      ),
                    ],
                  ),
            actions: [
              if (mobileLayout)
                IconButton(
                  key: const Key('open-inspector-button'),
                  tooltip: _localized(widget.labels, 'Detail View', '详情视图'),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(GalleryDialogResult.detail(record)),
                  icon: const Icon(Icons.info_outline),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: FilledButton(
                    key: const Key('open-inspector-button'),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(GalleryDialogResult.detail(record)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.grey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _localized(widget.labels, 'Detail View', '详情视图'),
                    ),
                  ),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: _GalleryPreview(record: record, onMove: _move),
                ),
                const SizedBox(height: 8),
                if (mobileLayout)
                  _GalleryMetadataText(
                    captured: captured,
                    labels: widget.labels,
                    record: record,
                    showKeyboardHint: false,
                  )
                else
                  Row(
                    key: const Key('gallery-metadata-row'),
                    children: [
                      Expanded(
                        child: _GalleryMetadataText(
                          captured: captured,
                          labels: widget.labels,
                          record: record,
                          showKeyboardHint: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(GalleryDialogResult.detail(record)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.grey.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          _localized(widget.labels, 'Open Inspector', '打开检查器'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _GalleryFilmstrip(
                  index: _index,
                  labels: widget.labels,
                  onSelect: (index) => setState(() => _index = index),
                  photos: widget.photos,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(GalleryDialogResult.close(_record));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyD) {
      Navigator.of(context).pop(GalleryDialogResult.detail(_record));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _move(int delta) {
    final nextIndex = (_index + delta).clamp(0, widget.photos.length - 1);
    if (nextIndex == _index) return;
    setState(() => _index = nextIndex);
  }
}

final class _GalleryPreview extends StatelessWidget {
  const _GalleryPreview({required this.onMove, required this.record});

  final ValueChanged<int> onMove;
  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: MediaPreview(record: record, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          child: _GalleryNavButton(
            key: const Key('previous-gallery-button'),
            onPressed: () => onMove(-1),
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        Positioned(
          right: 4,
          child: _GalleryNavButton(
            key: const Key('next-gallery-button'),
            onPressed: () => onMove(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}

final class _GalleryMetadataText extends StatelessWidget {
  const _GalleryMetadataText({
    required this.captured,
    required this.labels,
    required this.record,
    required this.showKeyboardHint,
  });

  final String captured;
  final UiStrings labels;
  final PhotoRecord record;
  final bool showKeyboardHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('gallery-metadata-row'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.semantic.caption ?? _basename(record.photo.path),
          key: Key('gallery-title-${record.photo.id}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          captured,
          key: const Key('gallery-captured-at'),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              key: const Key('gallery-memory-badge'),
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: Colors.white24),
              backgroundColor: Colors.black,
              label: Text(
                _localized(labels, 'NOT IN ANY MEMORY', '未加入任何记忆'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            if (showKeyboardHint)
              Text(
                _localized(
                  labels,
                  'Esc close • Left/Right navigate • D detail',
                  'Esc 关闭 • 左/右导航 • D 详情',
                ),
                key: const Key('gallery-keyboard-hint'),
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ],
    );
  }
}

final class _GalleryFilmstrip extends StatelessWidget {
  const _GalleryFilmstrip({
    required this.index,
    required this.labels,
    required this.onSelect,
    required this.photos,
  });

  final int index;
  final UiStrings labels;
  final ValueChanged<int> onSelect;
  final List<PhotoRecord> photos;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('gallery-filmstrip'),
      height: 146,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  _localized(labels, 'GALLERY STRIP', '图库胶片条'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    _localized(
                      labels,
                      '${photos.length} ITEMS',
                      '${photos.length} 项',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, itemIndex) {
                final item = photos[itemIndex];
                return InkWell(
                  key: Key('gallery-filmstrip-${item.photo.id}'),
                  onTap: () => onSelect(itemIndex),
                  child: Container(
                    width: 82,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: itemIndex == index
                            ? Colors.amber
                            : Colors.white24,
                        width: itemIndex == index ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MediaPreview(record: item, fit: BoxFit.cover),
                  ),
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

final class _GalleryNavButton extends StatelessWidget {
  const _GalleryNavButton({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
        disabledForegroundColor: Colors.white24,
        foregroundColor: enabled ? Colors.white : Colors.white24,
        fixedSize: const Size.square(48),
      ),
    );
  }
}
