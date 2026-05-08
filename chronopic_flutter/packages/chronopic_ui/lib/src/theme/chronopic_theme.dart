part of '../chronopic_home.dart';

final class ChronoPicTheme {
  const ChronoPicTheme._();

  static const sidebarWidth = 264.0;
  static const panelRadius = 24.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xffd97706),
      brightness: Brightness.light,
      surface: const Color(0xfffafaf9),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff5f5f4),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

final class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.description,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? description;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

Color _statusColor(String status) {
  if (status.contains('failed') || status.contains('failed:')) {
    return Colors.red.shade700;
  }
  if (status.contains('Saved') ||
      status.contains('Added') ||
      status.contains('Restored') ||
      status.contains('Exported') ||
      status.contains('complete')) {
    return Colors.green.shade700;
  }
  return Colors.blueGrey.shade700;
}
