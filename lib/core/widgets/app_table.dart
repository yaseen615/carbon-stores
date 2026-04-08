import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pos_colors.dart';

/// Modern borderless table inspired by Apple HIG.
/// Uses spacing-based row separation instead of grid lines.
/// Includes hover effects and sticky header styling.
class AppTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final bool showHeader;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            if (showHeader)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02),
                ),
                child: Row(
                  children: columns.map((col) {
                    return Expanded(
                      flex: col.flex,
                      child: Align(
                        alignment: col.numeric
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Text(
                          col.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: pos.divider,
                  ),
                ),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _AppTableRowWidget(
                    row: row,
                    columns: columns,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTableRowWidget extends StatefulWidget {
  final AppTableRow row;
  final List<AppTableColumn> columns;

  const _AppTableRowWidget({
    required this.row,
    required this.columns,
  });

  @override
  State<_AppTableRowWidget> createState() => _AppTableRowWidgetState();
}

class _AppTableRowWidgetState extends State<_AppTableRowWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.row.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: widget.row.backgroundColor
              ?? (_isHovered ? cs.primary.withValues(alpha: 0.04) : Colors.transparent),
          child: Row(
            children: List.generate(widget.columns.length, (i) {
              final col = widget.columns[i];
              return Expanded(
                flex: col.flex,
                child: Align(
                  alignment: col.numeric
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: widget.row.cells[i],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Column definition for AppTable
class AppTableColumn {
  final String label;
  final int flex;
  final bool numeric;

  const AppTableColumn({
    required this.label,
    this.flex = 1,
    this.numeric = false,
  });
}

/// Row definition for AppTable
class AppTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppTableRow({
    required this.cells,
    this.onTap,
    this.backgroundColor,
  });
}
