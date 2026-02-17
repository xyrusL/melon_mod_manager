import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_reporter.dart';
import '../../core/providers.dart';
import '../../domain/entities/content_type.dart';
import '../../domain/entities/modrinth_project.dart';
import '../viewmodels/mods_controller.dart';

part 'modrinth_search/bulk_install_progress_dialog.dart';
part 'modrinth_search/cart_confirm_dialog.dart';
part 'modrinth_search/empty_states.dart';
part 'modrinth_search/project_card.dart';
part 'modrinth_search/status_tag.dart';

class ModrinthSearchDialog extends ConsumerStatefulWidget {
  const ModrinthSearchDialog({
    super.key,
    required this.modsPath,
    required this.targetPath,
    required this.contentType,
  });

  final String modsPath;
  final String targetPath;
  final ContentType contentType;

  @override
  ConsumerState<ModrinthSearchDialog> createState() =>
      _ModrinthSearchDialogState();
}

enum _BrowseMode { popular, search }

enum _SortMode { popular, relevance, newest, updated }

enum _StatusFilter { all, installed, update, onDisk }

class _ModrinthSearchDialogState extends ConsumerState<ModrinthSearchDialog> {
  static const List<int> _pageSizeOptions = [10, 20, 30, 50];
  static const String _anyVersionValue = '__any_version__';
  static const Set<String> _supportedLoaders = {
    'fabric',
    'quilt',
    'forge',
    'neoforge',
  };

  final _queryController = TextEditingController();

  var _loader = 'fabric';
  var _loading = false;
  var _statusLoading = false;
  var _hasNextPage = false;
  var _mode = _BrowseMode.popular;
  var _sortMode = _SortMode.popular;
  var _versionLookupToken = 0;
  var _currentPage = 1;
  var _pageSize = 10;
  var _statusFilter = _StatusFilter.all;
  var _versionSelection = _anyVersionValue;
  String? _detectedGameVersion;
  String? _detectedLoader;
  String? _detectedLoaderVersion;
  List<ModrinthProject> _results = const [];
  Map<String, ProjectInstallInfo> _installInfo = const {};
  Map<String, String> _latestVersionByProject = const {};
  Set<String> _selectedProjectIds = <String>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (widget.contentType.supportsLoaderFilter) {
      try {
        final detected = await ref
            .read(minecraftVersionServiceProvider)
            .detectVersionFromModsPath(widget.modsPath);
        if (mounted) {
          setState(() {
            _detectedGameVersion = detected;
            _versionSelection = detected ?? _anyVersionValue;
          });
        }
      } catch (_) {
        // Best effort only.
      }

      try {
        final detected = await ref
            .read(minecraftLoaderServiceProvider)
            .detectLoaderFromModsPath(widget.modsPath);
        if (mounted) {
          setState(() {
            _detectedLoader = detected?.loader;
            _detectedLoaderVersion = detected?.version;
            if (detected != null &&
                (detected.loader == 'fabric' ||
                    detected.loader == 'quilt' ||
                    detected.loader == 'forge' ||
                    detected.loader == 'neoforge')) {
              _loader = detected.loader;
            }
          });
        }
      } catch (_) {
        // Best effort only.
      }
    }

    await _loadPopular();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadPopular() async {
    setState(() {
      _sortMode = _SortMode.popular;
      _queryController.clear();
      _currentPage = 1;
      _latestVersionByProject = const {};
    });
    await _search();
  }

  Future<void> _search() async {
    if (_loading) {
      return;
    }

    final query = _queryController.text.trim();
    final isPopularMode = query.isEmpty && _sortMode == _SortMode.popular;

    setState(() {
      _loading = true;
      _error = null;
      _mode = isPopularMode ? _BrowseMode.popular : _BrowseMode.search;
    });

    try {
      final projects = await ref
          .read(modsControllerProvider.notifier)
          .searchModrinth(
            query,
            loader: widget.contentType.supportsLoaderFilter ? _loader : null,
            projectType: widget.contentType.modrinthProjectType,
            gameVersion: widget.contentType.supportsLoaderFilter
                ? _selectedGameVersion
                : null,
            limit: _pageSize,
            offset: (_currentPage - 1) * _pageSize,
            index: _sortIndex,
          );
      await _applyResults(projects);
    } catch (error) {
      setState(() => _error = ErrorReporter().toUserMessage(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String get _sortIndex => switch (_sortMode) {
        _SortMode.popular => 'downloads',
        _SortMode.relevance => 'relevance',
        _SortMode.newest => 'newest',
        _SortMode.updated => 'updated',
      };

  String get _sortLabel => switch (_sortMode) {
        _SortMode.popular => 'Popular',
        _SortMode.relevance => 'Relevance',
        _SortMode.newest => 'Newest',
        _SortMode.updated => 'Last updated',
      };

  Future<void> _applyResults(List<ModrinthProject> projects) async {
    setState(() {
      _results = projects;
      _hasNextPage = projects.length == _pageSize;
      final visible = projects.map((p) => p.id).toSet();
      _selectedProjectIds = _selectedProjectIds.intersection(visible);
    });

    await _loadInstallInfo(projects);
    await _loadLatestVersions(projects);
  }

  Future<void> _loadInstallInfo(List<ModrinthProject> projects) async {
    if (projects.isEmpty) {
      setState(() => _installInfo = const {});
      return;
    }

    setState(() => _statusLoading = true);
    try {
      final info = await ref
          .read(modsControllerProvider.notifier)
          .loadProjectInstallInfo(
            projects: projects,
            loader: widget.contentType.supportsLoaderFilter ? _loader : null,
            gameVersion: widget.contentType.supportsLoaderFilter
                ? _selectedGameVersion
                : null,
          );

      final prunedSelected = _selectedProjectIds.where((id) {
        final state = info[id]?.state;
        return state != ProjectInstallState.installed &&
            state != ProjectInstallState.installedUntracked;
      }).toSet();

      if (mounted) {
        setState(() {
          _installInfo = info;
          _selectedProjectIds = prunedSelected;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = ErrorReporter().toUserMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _statusLoading = false);
      }
    }
  }

  Future<void> _loadLatestVersions(List<ModrinthProject> projects) async {
    final candidates = projects
        .where((project) => !_latestVersionByProject.containsKey(project.id))
        .toList();
    if (candidates.isEmpty) {
      return;
    }

    final token = ++_versionLookupToken;
    final fetched = <String, String>{};
    final repository = ref.read(modrinthRepositoryProvider);

    await Future.wait(
      candidates.map((project) async {
        try {
          final latest = await repository.getLatestVersion(
            project.id,
            loader: widget.contentType.supportsLoaderFilter ? _loader : null,
            gameVersion: widget.contentType.supportsLoaderFilter
                ? _selectedGameVersion
                : null,
          );
          if (latest != null) {
            fetched[project.id] = latest.versionNumber;
          }
        } catch (_) {
          // Keep UI responsive if one project fails.
        }
      }),
    );

    if (!mounted || token != _versionLookupToken || fetched.isEmpty) {
      return;
    }

    setState(() {
      _latestVersionByProject = {
        ..._latestVersionByProject,
        ...fetched,
      };
    });
  }

  Future<void> _runNewQuery() async {
    setState(() {
      _currentPage = 1;
      _latestVersionByProject = const {};
    });
    await _search();
  }

  Future<void> _goToPreviousPage() async {
    if (_loading || _currentPage <= 1) {
      return;
    }
    setState(() {
      _currentPage--;
    });
    await _search();
  }

  Future<void> _goToNextPage() async {
    if (_loading || !_hasNextPage) {
      return;
    }
    setState(() {
      _currentPage++;
    });
    await _search();
  }

  Future<void> _changePageSize(int? value) async {
    if (value == null || value == _pageSize) {
      return;
    }
    setState(() {
      _pageSize = value;
      _currentPage = 1;
    });
    await _runNewQuery();
  }

  void _toggleSelection(ModrinthProject project) {
    final state = _installInfo[project.id]?.state;
    if (state == ProjectInstallState.installed) {
      setState(() {
        _error = '${project.title} is already installed and up to date.';
      });
      return;
    }
    if (state == ProjectInstallState.installedUntracked) {
      setState(() {
        final folderLabel = widget.contentType.label.toLowerCase();
        _error =
            '${project.title} is already in your $folderLabel folder (untracked). '
            'Skipped to avoid duplicate install.';
      });
      return;
    }

    setState(() {
      if (_selectedProjectIds.contains(project.id)) {
        _selectedProjectIds.remove(project.id);
      } else {
        _selectedProjectIds.add(project.id);
      }
    });
  }

  Future<void> _confirmAndInstallSelected() async {
    final selected =
        _results.where((p) => _selectedProjectIds.contains(p.id)).toList();
    if (selected.isEmpty) {
      return;
    }

    if (widget.contentType != ContentType.mod) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _BulkInstallProgressDialog(
          modsPath: widget.modsPath,
          targetPath: widget.targetPath,
          projects: selected,
          installInfo: const {},
          loader: null,
          gameVersion: null,
          contentType: widget.contentType,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedProjectIds = <String>{};
      });
      await _search();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CartConfirmDialog(
        projects: selected,
        installInfo: _installInfo,
        latestVersionByProject: _latestVersionByProject,
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BulkInstallProgressDialog(
        modsPath: widget.modsPath,
        targetPath: widget.targetPath,
        projects: selected,
        installInfo: _installInfo,
        loader: _loader,
        gameVersion: _selectedGameVersion,
        contentType: widget.contentType,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedProjectIds = <String>{};
    });

    if (_mode == _BrowseMode.popular) {
      await _loadPopular();
    } else {
      await _search();
    }
  }

  ProjectInstallState _projectState(ModrinthProject project) {
    return _installInfo[project.id]?.state ?? ProjectInstallState.notInstalled;
  }

  bool _matchesStatusFilter(ProjectInstallState state) {
    return switch (_statusFilter) {
      _StatusFilter.all => true,
      _StatusFilter.installed => state == ProjectInstallState.installed,
      _StatusFilter.update => state == ProjectInstallState.updateAvailable,
      _StatusFilter.onDisk => state == ProjectInstallState.installedUntracked,
    };
  }

  void _toggleStatusFilter(_StatusFilter filter) {
    setState(() {
      _statusFilter = _statusFilter == filter ? _StatusFilter.all : filter;
    });
  }

  String? get _selectedGameVersion =>
      _versionSelection == _anyVersionValue ? null : _versionSelection;

  @override
  Widget build(BuildContext context) {
    final hasDetectedLoader =
        _detectedLoader != null && _supportedLoaders.contains(_detectedLoader);
    final supportsLoader = widget.contentType.supportsLoaderFilter;
    final versionItems = <DropdownMenuItem<String>>[
      if (_detectedGameVersion != null)
        DropdownMenuItem(
          value: _detectedGameVersion!,
          child: Text(_detectedGameVersion!),
        ),
      const DropdownMenuItem(
        value: _anyVersionValue,
        child: Text('Any version'),
      ),
    ];
    final installedCount = _results
        .where((p) => _projectState(p) == ProjectInstallState.installed)
        .length;
    final updateCount = _results
        .where((p) => _projectState(p) == ProjectInstallState.updateAvailable)
        .length;
    final onDiskCount = _results
        .where(
            (p) => _projectState(p) == ProjectInstallState.installedUntracked)
        .length;
    final filteredResults =
        _results.where((p) => _matchesStatusFilter(_projectState(p))).toList();

    return Dialog(
      child: Container(
        width: 980,
        height: 680,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Download from Modrinth',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _mode == _BrowseMode.popular
                  ? 'Showing $_sortLabel ${widget.contentType.label.toLowerCase()} for your selected filters.'
                  : 'Showing $_sortLabel search results for ${widget.contentType.label.toLowerCase()}.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      hintText: 'Search projects',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _runNewQuery(),
                  ),
                ),
                if (supportsLoader) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String>(
                        'loader_${hasDetectedLoader ? 1 : 0}_${_loader}_${_detectedLoaderVersion ?? ''}',
                      ),
                      initialValue: _loader,
                      isExpanded: true,
                      items: hasDetectedLoader
                          ? [
                              DropdownMenuItem(
                                value: _loader,
                                child: Text(_loaderDisplayLabel(_loader)),
                              ),
                            ]
                          : const [
                              DropdownMenuItem(
                                value: 'fabric',
                                child: Text('Fabric'),
                              ),
                              DropdownMenuItem(
                                value: 'quilt',
                                child: Text('Quilt'),
                              ),
                              DropdownMenuItem(
                                value: 'forge',
                                child: Text('Forge'),
                              ),
                              DropdownMenuItem(
                                value: 'neoforge',
                                child: Text('NeoForge'),
                              ),
                            ],
                      onChanged: hasDetectedLoader
                          ? null
                          : (value) async {
                              if (value != null) {
                                setState(() => _loader = value);
                                await _runNewQuery();
                              }
                            },
                      decoration: const InputDecoration(labelText: 'Loader'),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<_SortMode>(
                    initialValue: _sortMode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: _SortMode.popular,
                        child: Text('Popular'),
                      ),
                      DropdownMenuItem(
                        value: _SortMode.relevance,
                        child: Text('Relevance'),
                      ),
                      DropdownMenuItem(
                        value: _SortMode.newest,
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: _SortMode.updated,
                        child: Text('Updated'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      setState(() => _sortMode = value);
                      await _runNewQuery();
                    },
                    decoration: const InputDecoration(labelText: 'Sort'),
                  ),
                ),
                if (supportsLoader) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String>(_versionSelection),
                      initialValue: _versionSelection,
                      isExpanded: true,
                      items: versionItems,
                      onChanged: _loading
                          ? null
                          : (value) async {
                              if (value == null || value == _versionSelection) {
                                return;
                              }
                              setState(() => _versionSelection = value);
                              await _runNewQuery();
                            },
                      decoration: const InputDecoration(
                        labelText: 'Minecraft Version',
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _loading ? null : _runNewQuery,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Selected: ${_selectedProjectIds.length}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(width: 12),
                if (widget.contentType == ContentType.mod) ...[
                  _StatusTag(
                    label: 'Installed ($installedCount)',
                    color: const Color(0xFF68DA97),
                    selected: _statusFilter == _StatusFilter.installed,
                    onTap: () => _toggleStatusFilter(_StatusFilter.installed),
                  ),
                  const SizedBox(width: 6),
                  _StatusTag(
                    label: 'Update ($updateCount)',
                    color: const Color(0xFFFFB55A),
                    selected: _statusFilter == _StatusFilter.update,
                    onTap: () => _toggleStatusFilter(_StatusFilter.update),
                  ),
                  const SizedBox(width: 6),
                  _StatusTag(
                    label: 'On Disk ($onDiskCount)',
                    color: const Color(0xFF86C5FF),
                    selected: _statusFilter == _StatusFilter.onDisk,
                    onTap: () => _toggleStatusFilter(_StatusFilter.onDisk),
                  ),
                ],
                const Spacer(),
                FilledButton.icon(
                  onPressed:
                      _selectedProjectIds.isEmpty || _loading || _statusLoading
                          ? null
                          : _confirmAndInstallSelected,
                  icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  label: Text(
                    widget.contentType == ContentType.mod
                        ? 'Review & Install'
                        : 'Download Selected',
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            if (_statusLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 4),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? _EmptyState(onReloadPopular: _loadPopular)
                        : filteredResults.isEmpty
                            ? _FilteredEmptyState(
                                onClearFilter: () => setState(
                                  () => _statusFilter = _StatusFilter.all,
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredResults.length,
                                itemBuilder: (context, index) {
                                  final item = filteredResults[index];
                                  final info = _installInfo[item.id];
                                  final selected =
                                      _selectedProjectIds.contains(item.id);
                                  final latestVersion =
                                      info?.latestVersionNumber ??
                                          _latestVersionByProject[item.id];
                                  final installedVersion =
                                      info?.installedVersionNumber;

                                  final versionLine = switch (info?.state) {
                                    ProjectInstallState.updateAvailable =>
                                      installedVersion != null &&
                                              latestVersion != null
                                          ? 'Version: $installedVersion -> $latestVersion'
                                          : latestVersion != null
                                              ? 'Latest compatible: $latestVersion'
                                              : 'Update available',
                                    ProjectInstallState.installed =>
                                      installedVersion != null
                                          ? 'Installed version: $installedVersion'
                                          : latestVersion != null
                                              ? 'Installed, latest: $latestVersion'
                                              : 'Installed',
                                    _ => latestVersion != null
                                        ? 'Latest compatible: $latestVersion'
                                        : 'Latest version not available',
                                  };

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          index == filteredResults.length - 1
                                              ? 8
                                              : 8,
                                    ),
                                    child: _ProjectCard(
                                      project: item,
                                      info: info,
                                      selected: selected,
                                      versionLine: versionLine,
                                      onDiskLabel:
                                          widget.contentType == ContentType.mod
                                              ? 'On Disk'
                                              : 'Already Added',
                                      onTapAction: () => _toggleSelection(item),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Per page',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: DropdownButtonFormField<int>(
                    initialValue: _pageSize,
                    isExpanded: true,
                    items: _pageSizeOptions
                        .map(
                          (size) => DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size'),
                          ),
                        )
                        .toList(),
                    onChanged: _loading ? null : _changePageSize,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Page $_currentPage',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Previous page',
                  onPressed: (_loading || _currentPage <= 1)
                      ? null
                      : _goToPreviousPage,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  tooltip: 'Next page',
                  onPressed: (_loading || !_hasNextPage) ? null : _goToNextPage,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _loaderDisplayLabel(String value) {
    final base = switch (value) {
      'quilt' => 'Quilt',
      'forge' => 'Forge',
      'neoforge' => 'NeoForge',
      _ => 'Fabric',
    };
    if (_detectedLoader == value &&
        _detectedLoaderVersion != null &&
        _detectedLoaderVersion!.trim().isNotEmpty) {
      return '$base ${_detectedLoaderVersion!}';
    }
    return base;
  }
}
