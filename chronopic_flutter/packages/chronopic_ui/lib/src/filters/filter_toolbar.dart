part of '../chronopic_home.dart';

final class FilterToolbar extends StatelessWidget {
  const FilterToolbar({
    required this.aiStatus,
    required this.fromDateController,
    required this.gpsOnly,
    required this.labels,
    required this.onAiStatusChanged,
    required this.onApply,
    required this.onClear,
    required this.onGpsOnlyChanged,
    required this.onSortByChanged,
    required this.onSortDirectionChanged,
    required this.sortBy,
    required this.sortDirection,
    required this.tagController,
    required this.toDateController,
  });

  final AiPipelineStatus? aiStatus;
  final TextEditingController fromDateController;
  final bool gpsOnly;
  final UiStrings labels;
  final ValueChanged<AiPipelineStatus?> onAiStatusChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final ValueChanged<bool> onGpsOnlyChanged;
  final ValueChanged<PhotoSortBy> onSortByChanged;
  final ValueChanged<SortDirection> onSortDirectionChanged;
  final PhotoSortBy sortBy;
  final SortDirection sortDirection;
  final TextEditingController tagController;
  final TextEditingController toDateController;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 170,
            child: TextField(
              key: const Key('tag-filter-field'),
              controller: tagController,
              decoration: const InputDecoration(labelText: 'Tag'),
            ),
          ),
          FilterChip(
            key: const Key('gps-filter-chip'),
            selected: gpsOnly,
            label: const Text('GPS only'),
            onSelected: onGpsOnlyChanged,
          ),
          DropdownButton<AiPipelineStatus?>(
            key: const Key('ai-status-filter-control'),
            value: aiStatus,
            onChanged: onAiStatusChanged,
            items: const [
              DropdownMenuItem(value: null, child: Text('AI: any')),
              DropdownMenuItem(
                value: AiPipelineStatus.disabled,
                child: Text('AI: disabled'),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.pending,
                child: Text('AI: pending'),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.processing,
                child: Text('AI: processing'),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.completed,
                child: Text('AI: completed'),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.failed,
                child: Text('AI: failed'),
              ),
            ],
          ),
          SizedBox(
            width: 145,
            child: TextField(
              key: const Key('from-date-filter-field'),
              controller: fromDateController,
              decoration: const InputDecoration(
                labelText: 'From date',
                hintText: 'YYYY-MM-DD',
              ),
            ),
          ),
          SizedBox(
            width: 145,
            child: TextField(
              key: const Key('to-date-filter-field'),
              controller: toDateController,
              decoration: const InputDecoration(
                labelText: 'To date',
                hintText: 'YYYY-MM-DD',
              ),
            ),
          ),
          DropdownButton<PhotoSortBy>(
            key: const Key('sort-by-control'),
            value: sortBy,
            onChanged: (value) {
              if (value != null) onSortByChanged(value);
            },
            items: const [
              DropdownMenuItem(
                value: PhotoSortBy.datetime,
                child: Text('Sort: datetime'),
              ),
              DropdownMenuItem(
                value: PhotoSortBy.path,
                child: Text('Sort: path'),
              ),
              DropdownMenuItem(
                value: PhotoSortBy.updatedAt,
                child: Text('Sort: updated'),
              ),
            ],
          ),
          DropdownButton<SortDirection>(
            key: const Key('sort-direction-control'),
            value: sortDirection,
            onChanged: (value) {
              if (value != null) onSortDirectionChanged(value);
            },
            items: const [
              DropdownMenuItem(value: SortDirection.desc, child: Text('Desc')),
              DropdownMenuItem(value: SortDirection.asc, child: Text('Asc')),
            ],
          ),
          FilledButton(
            key: const Key('apply-filter-button'),
            onPressed: onApply,
            child: Text(labels.applyFilters),
          ),
          OutlinedButton(
            key: const Key('clear-filter-button'),
            onPressed: onClear,
            child: Text(labels.clearFilters),
          ),
        ],
      ),
    );
  }
}
