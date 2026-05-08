part of '../chronopic_home.dart';

final class MemoryListPage extends StatelessWidget {
  const MemoryListPage({
    required this.labels,
    required this.memories,
    required this.memoryNameController,
    required this.onCreateMemory,
    required this.onSelectMemory,
  });

  final UiStrings labels;
  final List<Memory> memories;
  final TextEditingController memoryNameController;
  final VoidCallback onCreateMemory;
  final ValueChanged<String> onSelectMemory;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('memories-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: labels.memories,
          description: 'Create, review, and manage photo memories.',
        ),
        const SizedBox(height: 18),
        _Panel(
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
              FilledButton.icon(
                key: const Key('create-memory-button'),
                onPressed: onCreateMemory,
                icon: const Icon(Icons.add),
                label: Text(labels.createMemory),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (memories.isEmpty)
          _Panel(
            child: Text(
              'No memories yet. Create one, then add selected photos from the detail pane.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.65,
            children: [
              for (final memory in memories)
                Card(
                  child: InkWell(
                    key: Key('memory-card-${memory.id}'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onSelectMemory(memory.id),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_stories,
                            color: Colors.amber.shade700,
                          ),
                          const Spacer(),
                          Text(
                            memory.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            memory.description ?? 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
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
        labels: labels,
        memories: const [],
        memoryNameController: TextEditingController(),
        onCreateMemory: () {},
        onSelectMemory: (_) {},
      );
    }
    return Column(
      key: const Key('memory-detail-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: memory!.name,
          description: 'Edit memory metadata and manage the selected photo.',
          trailing: OutlinedButton.icon(
            onPressed: onBackToMemories,
            icon: const Icon(Icons.arrow_back),
            label: Text(labels.memories),
          ),
        ),
        const SizedBox(height: 18),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('memory-title-field'),
                controller: memoryTitleController,
                decoration: InputDecoration(labelText: labels.memoryName),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('memory-description-field'),
                controller: memoryDescriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
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
                    label: const Text('Save Memory'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('add-to-memory-button'),
                    onPressed: selected == null ? null : onAddSelectedToMemory,
                    icon: const Icon(Icons.playlist_add),
                    label: Text(labels.addToMemory),
                  ),
                  OutlinedButton.icon(
                    key: const Key('set-memory-cover-button'),
                    onPressed: selected == null ? null : onSetCover,
                    icon: const Icon(Icons.wallpaper_outlined),
                    label: const Text('Set Cover'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('remove-from-memory-button'),
                    onPressed: selected == null
                        ? null
                        : onRemoveSelectedFromMemory,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Remove from Memory'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Panel(
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected == null
                      ? 'Select a photo on the home page, then return here to add or remove it.'
                      : 'Selected photo: ${selected!.photo.path}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
