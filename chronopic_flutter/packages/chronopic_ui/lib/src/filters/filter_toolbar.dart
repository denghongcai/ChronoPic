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
    const denseDecoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    );
    return _Panel(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 128,
            child: TextField(
              key: const Key('tag-filter-field'),
              controller: tagController,
              decoration: denseDecoration.copyWith(labelText: labels.tag),
            ),
          ),
          FilterChip(
            key: const Key('gps-filter-chip'),
            selected: gpsOnly,
            label: Text(labels.gpsOnly),
            onSelected: onGpsOnlyChanged,
          ),
          DropdownButton<AiPipelineStatus?>(
            key: const Key('ai-status-filter-control'),
            value: aiStatus,
            onChanged: onAiStatusChanged,
            items: [
              DropdownMenuItem(value: null, child: Text(labels.aiAny)),
              DropdownMenuItem(
                value: AiPipelineStatus.disabled,
                child: Text(labels.aiDisabled),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.pending,
                child: Text(labels.aiPending),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.processing,
                child: Text(labels.aiProcessing),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.completed,
                child: Text(labels.aiCompleted),
              ),
              DropdownMenuItem(
                value: AiPipelineStatus.failed,
                child: Text(labels.aiFailed),
              ),
            ],
          ),
          SizedBox(
            width: 118,
            child: TextField(
              key: const Key('from-date-filter-field'),
              controller: fromDateController,
              decoration: denseDecoration.copyWith(
                labelText: labels.fromDate,
                hintText: 'YYYY-MM-DD',
              ),
            ),
          ),
          SizedBox(
            width: 118,
            child: TextField(
              key: const Key('to-date-filter-field'),
              controller: toDateController,
              decoration: denseDecoration.copyWith(
                labelText: labels.toDate,
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
            items: [
              DropdownMenuItem(
                value: PhotoSortBy.datetime,
                child: Text(labels.sortDatetime),
              ),
              DropdownMenuItem(
                value: PhotoSortBy.path,
                child: Text(labels.sortPath),
              ),
              DropdownMenuItem(
                value: PhotoSortBy.updatedAt,
                child: Text(labels.sortUpdated),
              ),
            ],
          ),
          DropdownButton<SortDirection>(
            key: const Key('sort-direction-control'),
            value: sortDirection,
            onChanged: (value) {
              if (value != null) onSortDirectionChanged(value);
            },
            items: [
              DropdownMenuItem(
                value: SortDirection.desc,
                child: Text(labels.desc),
              ),
              DropdownMenuItem(
                value: SortDirection.asc,
                child: Text(labels.asc),
              ),
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
