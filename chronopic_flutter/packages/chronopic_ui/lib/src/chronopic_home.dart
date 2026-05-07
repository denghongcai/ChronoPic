import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:flutter/material.dart';

final class ChronoPicHome extends StatefulWidget {
  const ChronoPicHome({super.key, this.service});

  final ChronoPicAppService? service;

  @override
  State<ChronoPicHome> createState() => _ChronoPicHomeState();
}

final class _ChronoPicHomeState extends State<ChronoPicHome> {
  late final ChronoPicAppService _service = widget.service ?? ChronoPicAppService(ChronoPicRepository());
  String _query = '';
  bool _favoriteOnly = false;
  PhotoRecord? _selected;

  @override
  Widget build(BuildContext context) {
    final photos = _service.listPhotos(PhotoFilter(query: _query.isEmpty ? null : _query, favorite: _favoriteOnly ? true : null));
    return MaterialApp(
      title: 'ChronoPic Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ChronoPic Flutter'),
          actions: <Widget>[
            TextButton(onPressed: () {}, child: const Text('Export Backup')),
            TextButton(onPressed: () {}, child: const Text('Preview Restore')),
            TextButton(onPressed: () {}, child: const Text('Restore Backup')),
          ],
        ),
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: _favoriteOnly ? 1 : 0,
              onDestinationSelected: (index) => setState(() => _favoriteOnly = index == 1),
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(icon: Icon(Icons.photo_library_outlined), label: Text('All Photos')),
                NavigationRailDestination(icon: Icon(Icons.star_border), label: Text('Favorites')),
                NavigationRailDestination(icon: Icon(Icons.auto_stories_outlined), label: Text('Memories')),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.create_new_folder_outlined), label: const Text('Add Library')),
                        FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.sync), label: const Text('Scan Library')),
                        SizedBox(
                          width: 320,
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Search and filters', border: OutlineInputBorder()),
                            onChanged: (value) => setState(() => _query = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Scan progress: idle'),
                    const SizedBox(height: 16),
                    Expanded(
                      child: photos.isEmpty
                          ? const _EmptyLibrary()
                          : GridView.count(
                              crossAxisCount: 4,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: photos
                                  .map(
                                    (record) => Card(
                                      child: InkWell(
                                        onTap: () => setState(() => _selected = record),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              const Icon(Icons.image_outlined, size: 48),
                                              Text(record.semantic.caption ?? record.photo.path, maxLines: 2, overflow: TextOverflow.ellipsis),
                                              Text(record.photo.favorite ? 'Favorite' : 'Not favorite'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _DetailSurface(record: _selected),
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

final class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.photo_library_outlined, size: 64),
          Text('First run library setup'),
          Text('Add a folder, scan, then browse photos here.'),
        ],
      ),
    );
  }
}

final class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.record});

  final PhotoRecord? record;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Detail view and gallery view'),
            Text(selected == null ? 'No photo selected' : selected.photo.path),
            const Wrap(
              spacing: 8,
              children: <Widget>[
                Chip(label: Text('Edit caption')),
                Chip(label: Text('Edit tags')),
                Chip(label: Text('Datetime correction')),
                Chip(label: Text('Add to Memory')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
