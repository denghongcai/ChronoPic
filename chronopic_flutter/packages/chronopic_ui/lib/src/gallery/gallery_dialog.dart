part of '../chronopic_home.dart';

final class GalleryDialog extends StatefulWidget {
  const GalleryDialog({
    required this.initialPhotoId,
    required this.photos,
    super.key,
  });

  final String initialPhotoId;
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
    final captured = record.metadata.datetime == null
        ? 'Captured: unknown'
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
            title: Row(
              children: [
                const Chip(
                  label: Text('Gallery View'),
                  side: BorderSide(color: Colors.white24),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_index + 1} / ${widget.photos.length}',
                  key: const Key('gallery-counter'),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: FilledButton(
                  key: const Key('open-inspector-button'),
                  onPressed: () => Navigator.of(context).pop(record),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Detail View'),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
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
                              child: MediaPreview(
                                record: record,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4,
                        child: _GalleryNavButton(
                          key: const Key('previous-gallery-button'),
                          onPressed: _index <= 0 ? null : () => _move(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        child: _GalleryNavButton(
                          key: const Key('next-gallery-button'),
                          onPressed: _index >= widget.photos.length - 1
                              ? null
                              : () => _move(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  key: const Key('gallery-metadata-row'),
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.semantic.caption ??
                                _basename(record.photo.path),
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
                          const Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                key: Key('gallery-memory-badge'),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(color: Colors.white24),
                                backgroundColor: Colors.black,
                                label: Text(
                                  'NOT IN ANY MEMORY',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              Text(
                                'Esc close • Left/Right navigate • D detail',
                                key: Key('gallery-keyboard-hint'),
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(record),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Open Inspector'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
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
                            const Text(
                              'GALLERY STRIP',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            Chip(label: Text('${widget.photos.length} ITEMS')),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final item = widget.photos[index];
                            return InkWell(
                              key: Key('gallery-filmstrip-${item.photo.id}'),
                              onTap: () => setState(() => _index = index),
                              child: Container(
                                width: 82,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: index == _index
                                        ? Colors.amber
                                        : Colors.white24,
                                    width: index == _index ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: MediaPreview(
                                  record: item,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemCount: widget.photos.length,
                        ),
                      ),
                    ],
                  ),
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
      Navigator.of(context).pop(_record);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyD) {
      Navigator.of(context).pop(_record);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _move(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, widget.photos.length - 1);
    });
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
