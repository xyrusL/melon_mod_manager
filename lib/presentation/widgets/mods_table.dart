import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/mod_item.dart';

class ModsTable extends StatefulWidget {
  const ModsTable({
    super.key,
    required this.mods,
    required this.selectedFiles,
    required this.onToggleSelected,
    required this.onToggleSelectAllVisible,
    required this.isScanning,
    required this.processed,
    required this.total,
    this.uiScale = 1.0,
  });

  final List<ModItem> mods;
  final Set<String> selectedFiles;
  final void Function(String fileName, bool selected) onToggleSelected;
  final void Function(bool selected) onToggleSelectAllVisible;
  final bool isScanning;
  final int processed;
  final int total;
  final double uiScale;

  @override
  State<ModsTable> createState() => _ModsTableState();
}

class _ModsTableState extends State<ModsTable> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  double _tableScale() {
    final s = widget.uiScale;
    return (1.0 + (s - 1.0) * 0.45).clamp(1.0, 1.14).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final tableScale = _tableScale();
    if (widget.mods.isEmpty && !widget.isScanning) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all((20 * tableScale).clamp(20, 24).toDouble()),
        child: Text(
          'No mods installed',
          style: TextStyle(
            fontSize: (18 * tableScale).clamp(18, 21).toDouble(),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final dataSource = _ModsDataSource(
      mods: widget.mods,
      selectedFiles: widget.selectedFiles,
      onToggleSelected: widget.onToggleSelected,
      uiScale: tableScale,
    );
    final allSelected = widget.mods.isNotEmpty &&
        widget.selectedFiles.length == widget.mods.length;

    return Column(
      children: [
        if (widget.isScanning)
          Padding(
            padding: EdgeInsets.only(
              bottom: (8 * tableScale).clamp(8, 10).toDouble(),
            ),
            child: LinearProgressIndicator(
              value: widget.total == 0 ? null : widget.processed / widget.total,
              minHeight: 6,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final headingRowHeight =
                  (48 * tableScale).clamp(48, 56).toDouble();
              final dataRowHeight = (46 * tableScale).clamp(44, 54).toDouble();
              const footerHeight = 76.0;
              const headerReserve = 72.0;
              final availableForRows = constraints.maxHeight -
                  headingRowHeight -
                  footerHeight -
                  headerReserve;
              final computedMaxRows = availableForRows <= dataRowHeight
                  ? 1
                  : (availableForRows / dataRowHeight).floor();
              final maxRows = computedMaxRows.clamp(1, 100);
              final allowedRows = <int>{5, 10, 25, 50, 100}
                  .where((value) => value <= maxRows)
                  .toList()
                ..sort();
              if (allowedRows.isEmpty) {
                allowedRows.add(maxRows);
              } else if (!allowedRows.contains(maxRows)) {
                allowedRows.add(maxRows);
              }

              final effectiveRowsPerPage =
                  _rowsPerPage > maxRows ? maxRows : _rowsPerPage;

              return SizedBox(
                width: constraints.maxWidth,
                child: PaginatedDataTable(
                  header: Text(
                    'Mods (${widget.mods.length})',
                    style: TextStyle(
                      fontSize: (18 * tableScale).clamp(18, 22).toDouble(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  columns: [
                    DataColumn(
                      label: Checkbox(
                        value: allSelected,
                        tristate: false,
                        onChanged: (value) =>
                            widget.onToggleSelectAllVisible(value ?? false),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Icon',
                        style: TextStyle(
                          fontSize: (14 * tableScale).clamp(14, 17).toDouble(),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Name',
                        style: TextStyle(
                          fontSize: (14 * tableScale).clamp(14, 17).toDouble(),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Version',
                        style: TextStyle(
                          fontSize: (14 * tableScale).clamp(14, 17).toDouble(),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Provider',
                        style: TextStyle(
                          fontSize: (14 * tableScale).clamp(14, 17).toDouble(),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Last Modified',
                        style: TextStyle(
                          fontSize: (14 * tableScale).clamp(14, 17).toDouble(),
                        ),
                      ),
                    ),
                  ],
                  source: dataSource,
                  headingRowHeight: headingRowHeight,
                  dataRowMinHeight: dataRowHeight,
                  dataRowMaxHeight: dataRowHeight,
                  rowsPerPage: effectiveRowsPerPage,
                  availableRowsPerPage: allowedRows,
                  onRowsPerPageChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _rowsPerPage = value);
                  },
                  showCheckboxColumn: false,
                  columnSpacing: (14 * tableScale).clamp(14, 22).toDouble(),
                  horizontalMargin: (20 * tableScale).clamp(20, 30).toDouble(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModsDataSource extends DataTableSource {
  _ModsDataSource({
    required this.mods,
    required this.selectedFiles,
    required this.onToggleSelected,
    required this.uiScale,
  });

  final List<ModItem> mods;
  final Set<String> selectedFiles;
  final void Function(String fileName, bool selected) onToggleSelected;
  final double uiScale;

  TextStyle get _cellTextStyle => TextStyle(
        fontSize: (13.5 * uiScale).clamp(13.5, 16.5).toDouble(),
      );

  @override
  DataRow? getRow(int index) {
    if (index >= mods.length) {
      return null;
    }

    final mod = mods[index];
    final isSelected = selectedFiles.contains(mod.fileName);

    return DataRow.byIndex(
      index: index,
      selected: isSelected,
      cells: [
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: (value) =>
                onToggleSelected(mod.fileName, value ?? false),
          ),
        ),
        DataCell(_ModIcon(path: mod.iconCachePath, uiScale: uiScale)),
        DataCell(
          Tooltip(
            message: mod.fileName,
            child: Text(
              mod.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _cellTextStyle,
            ),
          ),
        ),
        DataCell(Text(mod.version, style: _cellTextStyle)),
        DataCell(Text(mod.provider.label, style: _cellTextStyle)),
        DataCell(Text(_formatDate(mod.lastModified), style: _cellTextStyle)),
      ],
    );
  }

  static String _formatDate(DateTime dateTime) {
    final date =
        '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => mods.length;

  @override
  int get selectedRowCount => 0;
}

class _ModIcon extends StatelessWidget {
  const _ModIcon({required this.path, required this.uiScale});

  final String? path;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final size = (24 * uiScale).clamp(22, 28).toDouble();
    final fallbackSize = (18 * uiScale).clamp(16, 21).toDouble();
    if (path != null && path!.isNotEmpty) {
      final file = File(path!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.extension_rounded, size: fallbackSize),
        ),
      );
    }
    return Icon(Icons.extension_rounded, size: fallbackSize);
  }
}
