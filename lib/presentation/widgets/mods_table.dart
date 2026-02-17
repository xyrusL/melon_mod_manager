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
    this.title = 'Mods',
    this.uiScale = 1.0,
  });

  final List<ModItem> mods;
  final Set<String> selectedFiles;
  final void Function(String fileName, bool selected) onToggleSelected;
  final void Function(bool selected) onToggleSelectAllVisible;
  final bool isScanning;
  final int processed;
  final int total;
  final String title;
  final double uiScale;

  @override
  State<ModsTable> createState() => _ModsTableState();
}

class _ModsTableState extends State<ModsTable> {
  int _rowsPerPage = 10;
  int _pageIndex = 0;

  double _tableScale() {
    final s = widget.uiScale;
    return (0.94 + (s - 1.0) * 0.5).clamp(0.86, 1.12).toDouble();
  }

  @override
  void didUpdateWidget(covariant ModsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final totalPages = _totalPages;
    if (_pageIndex >= totalPages) {
      _pageIndex = totalPages - 1;
    }
    if (_pageIndex < 0) {
      _pageIndex = 0;
    }
  }

  int get _totalPages {
    if (widget.mods.isEmpty) {
      return 1;
    }
    return ((widget.mods.length - 1) ~/ _rowsPerPage) + 1;
  }

  int get _pageStartIndex => _pageIndex * _rowsPerPage;

  List<ModItem> get _visibleMods {
    if (widget.mods.isEmpty) {
      return const [];
    }
    final start = _pageStartIndex;
    final end = (start + _rowsPerPage).clamp(0, widget.mods.length);
    return widget.mods.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final tableScale = _tableScale();
    const rowTextColor = Color(0xFFF2F8FC);

    if (widget.mods.isEmpty && !widget.isScanning) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all((20 * tableScale).clamp(20, 24).toDouble()),
        child: Text(
          'No ${widget.title.toLowerCase()} installed',
          style: TextStyle(
            fontSize: (17 * tableScale).clamp(15, 20).toDouble(),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final allSelected = widget.mods.isNotEmpty &&
        widget.selectedFiles.length == widget.mods.length;
    final headingTextStyle = TextStyle(
      color: rowTextColor.withValues(alpha: 0.84),
      fontSize: (15 * tableScale).clamp(13, 18).toDouble(),
      fontWeight: FontWeight.w800,
    );

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
        Padding(
          padding: EdgeInsets.fromLTRB(
            (10 * tableScale).clamp(8, 14).toDouble(),
            (4 * tableScale).clamp(2, 8).toDouble(),
            (10 * tableScale).clamp(8, 14).toDouble(),
            (6 * tableScale).clamp(6, 10).toDouble(),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: rowTextColor,
                  fontSize: (22 * tableScale).clamp(18, 26).toDouble(),
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(text: widget.title),
                  TextSpan(
                    text: ' (${widget.mods.length})',
                    style: TextStyle(
                      color: const Color(0xFF80D9FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _TableHeader(
          scale: tableScale,
          allSelected: allSelected,
          onToggleAll: widget.onToggleSelectAllVisible,
          headingTextStyle: headingTextStyle,
        ),
        SizedBox(height: (4 * tableScale).clamp(3, 6).toDouble()),
        Expanded(
          child: ListView.builder(
            itemCount: _visibleMods.length,
            itemBuilder: (context, index) {
              final mod = _visibleMods[index];
              final isSelected = widget.selectedFiles.contains(mod.fileName);
              return _ModRow(
                mod: mod,
                isSelected: isSelected,
                scale: tableScale,
                onChanged: (selected) =>
                    widget.onToggleSelected(mod.fileName, selected),
              );
            },
          ),
        ),
        SizedBox(height: (6 * tableScale).clamp(5, 8).toDouble()),
        _TableFooter(
          scale: tableScale,
          rowsPerPage: _rowsPerPage,
          totalRows: widget.mods.length,
          pageIndex: _pageIndex,
          totalPages: _totalPages,
          onRowsPerPageChanged: (value) {
            setState(() {
              _rowsPerPage = value;
              _pageIndex = 0;
            });
          },
          onPrevPage: _pageIndex > 0
              ? () {
                  setState(() {
                    _pageIndex--;
                  });
                }
              : null,
          onNextPage: _pageIndex < _totalPages - 1
              ? () {
                  setState(() {
                    _pageIndex++;
                  });
                }
              : null,
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.scale,
    required this.allSelected,
    required this.onToggleAll,
    required this.headingTextStyle,
  });

  final double scale;
  final bool allSelected;
  final void Function(bool selected) onToggleAll;
  final TextStyle headingTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (50 * scale).clamp(44, 56).toDouble(),
      padding: EdgeInsets.symmetric(
        horizontal: (12 * scale).clamp(10, 16).toDouble(),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D3345), Color(0xFF203648)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF355A73).withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Checkbox(
              value: allSelected,
              onChanged: (value) => onToggleAll(value ?? false),
            ),
          ),
          SizedBox(width: 10 * scale),
          SizedBox(
            width: (52 * scale).clamp(44, 62).toDouble(),
            child: Text('Icon', style: _headerTextStyle(headingTextStyle)),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            flex: 4,
            child: Text('Name', style: _headerTextStyle(headingTextStyle)),
          ),
          Expanded(
            flex: 3,
            child: Text('Version', style: _headerTextStyle(headingTextStyle)),
          ),
          Expanded(
            flex: 2,
            child: Text('Provider', style: _headerTextStyle(headingTextStyle)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Last Modified',
              style: _headerTextStyle(headingTextStyle),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerTextStyle(TextStyle base) {
    return base.copyWith(
      color: const Color(0xFFDDEAF4),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
  }
}

class _ModRow extends StatelessWidget {
  const _ModRow({
    required this.mod,
    required this.isSelected,
    required this.scale,
    required this.onChanged,
  });

  final ModItem mod;
  final bool isSelected;
  final double scale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final rowTextStyle = TextStyle(
      color: const Color(0xFFF2F8FC),
      fontSize: (12.5 * scale).clamp(11.5, 15.5).toDouble(),
      fontWeight: FontWeight.w500,
    );

    return Container(
      margin: EdgeInsets.only(bottom: (7 * scale).clamp(5, 9).toDouble()),
      padding: EdgeInsets.symmetric(
        horizontal: (10 * scale).clamp(8, 14).toDouble(),
        vertical: (6 * scale).clamp(5, 9).toDouble(),
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0x2348D3FF)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0x8A48D3FF)
              : Colors.white.withValues(alpha: 0.12),
          width: isSelected ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) => onChanged(value ?? false),
            ),
          ),
          SizedBox(width: 10 * scale),
          SizedBox(
            width: (52 * scale).clamp(44, 62).toDouble(),
            child: _ModIcon(path: mod.iconCachePath, uiScale: scale),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            flex: 4,
            child: Tooltip(
              message: mod.fileName,
              child: Text(
                mod.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: rowTextStyle,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              mod.version,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: rowTextStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mod.provider.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: rowTextStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatDate(mod.lastModified),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: rowTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final date =
        '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({
    required this.scale,
    required this.rowsPerPage,
    required this.totalRows,
    required this.pageIndex,
    required this.totalPages,
    required this.onRowsPerPageChanged,
    required this.onPrevPage,
    required this.onNextPage,
  });

  final double scale;
  final int rowsPerPage;
  final int totalRows;
  final int pageIndex;
  final int totalPages;
  final ValueChanged<int> onRowsPerPageChanged;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: const Color(0xFFE7F0F6).withValues(alpha: 0.9),
      fontSize: (12 * scale).clamp(11, 14).toDouble(),
      fontWeight: FontWeight.w500,
    );

    final start = totalRows == 0 ? 0 : (pageIndex * rowsPerPage) + 1;
    final end = totalRows == 0
        ? 0
        : ((pageIndex * rowsPerPage) + rowsPerPage).clamp(0, totalRows);

    return SizedBox(
      height: (44 * scale).clamp(40, 52).toDouble(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Rows per page:', style: textStyle),
          SizedBox(width: (8 * scale).clamp(6, 12).toDouble()),
          DropdownButton<int>(
            value: rowsPerPage,
            dropdownColor: const Color(0xFF112131),
            style: textStyle,
            underline: const SizedBox.shrink(),
            items: const [5, 10, 25, 50, 100]
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onRowsPerPageChanged(value);
              }
            },
          ),
          SizedBox(width: (14 * scale).clamp(10, 18).toDouble()),
          Text('$start-$end of $totalRows', style: textStyle),
          SizedBox(width: (8 * scale).clamp(6, 12).toDouble()),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFFE7F0F6),
            onPressed: onPrevPage,
            tooltip: 'Previous page',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFFE7F0F6),
            onPressed: onNextPage,
            tooltip: 'Next page',
          ),
          SizedBox(width: (2 * scale).clamp(1, 4).toDouble()),
          Text('Page ${pageIndex + 1}/$totalPages', style: textStyle),
        ],
      ),
    );
  }
}

class _ModIcon extends StatelessWidget {
  const _ModIcon({required this.path, required this.uiScale});

  final String? path;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final badgeSize = (28 * uiScale).clamp(22, 32).toDouble();
    final iconSize = (20 * uiScale).clamp(16, 24).toDouble();
    final fallbackSize = (16 * uiScale).clamp(14, 20).toDouble();
    Widget imageChild;
    if (path != null && path!.isNotEmpty) {
      final file = File(path!);
      imageChild = ClipOval(
        child: Image.file(
          file,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.extension_rounded, size: fallbackSize),
        ),
      );
    } else {
      imageChild = Icon(Icons.extension_rounded, size: fallbackSize);
    }
    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x1A0E1E33),
        ),
        child: Center(child: imageChild),
      ),
    );
  }
}
