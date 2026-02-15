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
  });

  final List<ModItem> mods;
  final Set<String> selectedFiles;
  final void Function(String fileName, bool selected) onToggleSelected;
  final void Function(bool selected) onToggleSelectAllVisible;
  final bool isScanning;
  final int processed;
  final int total;

  @override
  State<ModsTable> createState() => _ModsTableState();
}

class _ModsTableState extends State<ModsTable> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
    if (widget.mods.isEmpty && !widget.isScanning) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: const Text(
          'No mods installed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );
    }

    final dataSource = _ModsDataSource(
      mods: widget.mods,
      selectedFiles: widget.selectedFiles,
      onToggleSelected: widget.onToggleSelected,
    );
    final allSelected = widget.mods.isNotEmpty &&
        widget.selectedFiles.length == widget.mods.length;

    return Column(
      children: [
        if (widget.isScanning)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              value: widget.total == 0 ? null : widget.processed / widget.total,
              minHeight: 6,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: PaginatedDataTable(
              header: Text('Mods (${widget.mods.length})'),
              columns: [
                DataColumn(
                  label: Checkbox(
                    value: allSelected,
                    tristate: false,
                    onChanged: (value) =>
                        widget.onToggleSelectAllVisible(value ?? false),
                  ),
                ),
                DataColumn(label: Text('Icon')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Version')),
                DataColumn(label: Text('Provider')),
                DataColumn(label: Text('Last Modified')),
              ],
              source: dataSource,
              rowsPerPage: _rowsPerPage,
              availableRowsPerPage: const [10, 25, 50, 100],
              onRowsPerPageChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _rowsPerPage = value);
              },
              showCheckboxColumn: false,
              columnSpacing: 16,
            ),
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
  });

  final List<ModItem> mods;
  final Set<String> selectedFiles;
  final void Function(String fileName, bool selected) onToggleSelected;

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
        DataCell(_ModIcon(path: mod.iconCachePath)),
        DataCell(
          Tooltip(
            message: mod.fileName,
            child: Text(
              mod.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(mod.version)),
        DataCell(Text(mod.provider.label)),
        DataCell(Text(_formatDate(mod.lastModified))),
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
  const _ModIcon({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path != null && path!.isNotEmpty) {
      final file = File(path!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 26,
          height: 26,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.extension_rounded, size: 20),
        ),
      );
    }
    return const Icon(Icons.extension_rounded, size: 20);
  }
}
