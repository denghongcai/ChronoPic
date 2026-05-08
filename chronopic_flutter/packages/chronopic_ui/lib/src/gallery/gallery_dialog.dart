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
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Dialog.fullscreen(
        key: const Key('gallery-dialog'),
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              '${_index + 1} / ${widget.photos.length}',
              key: const Key('gallery-counter'),
            ),
            actions: [
              IconButton(
                key: const Key('close-gallery-button'),
                onPressed: () => Navigator.of(context).pop(record),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: MediaPreview(
                          record: record,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      child: IconButton.filledTonal(
                        key: const Key('previous-gallery-button'),
                        onPressed: _index <= 0 ? null : () => _move(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ),
                    Positioned(
                      right: 18,
                      child: IconButton.filledTonal(
                        key: const Key('next-gallery-button'),
                        onPressed: _index >= widget.photos.length - 1
                            ? null
                            : () => _move(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ),
                    Positioned(
                      left: 28,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.semantic.caption ??
                                _basename(record.photo.path),
                            key: Key('gallery-title-${record.photo.id}'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Arrow keys navigate. Escape closes.',
                            key: Key('gallery-keyboard-hint'),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                key: const Key('gallery-filmstrip'),
                height: 96,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final item = widget.photos[index];
                    return InkWell(
                      key: Key('gallery-filmstrip-${item.photo.id}'),
                      onTap: () => setState(() => _index = index),
                      child: Container(
                        width: 92,
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
                        child: MediaPreview(record: item, fit: BoxFit.cover),
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
    return KeyEventResult.ignored;
  }

  void _move(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, widget.photos.length - 1);
    });
  }
}
