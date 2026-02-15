import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_reporter.dart';
import '../../core/providers.dart';
import '../../domain/entities/modrinth_project.dart';
import '../viewmodels/mods_controller.dart';

class ModrinthSearchDialog extends ConsumerStatefulWidget {
  const ModrinthSearchDialog({super.key, required this.modsPath});

  final String modsPath;

  @override
  ConsumerState<ModrinthSearchDialog> createState() =>
      _ModrinthSearchDialogState();
}

enum _BrowseMode { popular, search }

enum _SortMode { popular, relevance, newest, updated }
enum _StatusFilter { all, installed, update, onDisk, notInstalled }

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
      final projects =
          await ref.read(modsControllerProvider.notifier).searchModrinth(
                query,
                loader: _loader,
                gameVersion: _selectedGameVersion,
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
            loader: _loader,
            gameVersion: _selectedGameVersion,
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
            loader: _loader,
            gameVersion: _selectedGameVersion,
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
        _error = '${project.title} is already in your mods folder (untracked). '
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
        projects: selected,
        installInfo: _installInfo,
        loader: _loader,
        gameVersion: _selectedGameVersion,
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
      _StatusFilter.notInstalled => state == ProjectInstallState.notInstalled,
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
        .where((p) => _projectState(p) == ProjectInstallState.installedUntracked)
        .length;
    final notInstalledCount = _results
        .where((p) => _projectState(p) == ProjectInstallState.notInstalled)
        .length;
    final filteredResults = _results
        .where((p) => _matchesStatusFilter(_projectState(p)))
        .toList();

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
                  ? 'Showing $_sortLabel client mods for selected loader and detected game version.'
                  : 'Showing $_sortLabel search results for selected loader and detected game version.',
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
                      hintText: 'Search mods',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _runNewQuery(),
                  ),
                ),
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
                const SizedBox(width: 6),
                _StatusTag(
                  label: 'Not Installed ($notInstalledCount)',
                  color: const Color(0xFF8D98A5),
                  selected: _statusFilter == _StatusFilter.notInstalled,
                  onTap: () => _toggleStatusFilter(_StatusFilter.notInstalled),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed:
                      _selectedProjectIds.isEmpty || _loading || _statusLoading
                          ? null
                          : _confirmAndInstallSelected,
                  icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  label: const Text('Review & Install'),
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
                              final latestVersion = info?.latestVersionNumber ??
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
                                      index == filteredResults.length - 1 ? 8 : 8,
                                ),
                                child: _ProjectCard(
                                  project: item,
                                  info: info,
                                  selected: selected,
                                  versionLine: versionLine,
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

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.info,
    required this.selected,
    required this.versionLine,
    required this.onTapAction,
  });

  final ModrinthProject project;
  final ProjectInstallInfo? info;
  final bool selected;
  final String versionLine;
  final VoidCallback onTapAction;

  @override
  Widget build(BuildContext context) {
    final state = info?.state ?? ProjectInstallState.notInstalled;
    final isInstalled = state == ProjectInstallState.installed;
    final isUntracked = state == ProjectInstallState.installedUntracked;
    final isUpdate = state == ProjectInstallState.updateAvailable;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: project.iconUrl == null
                ? Container(
                    width: 46,
                    height: 46,
                    color: Colors.white.withValues(alpha: 0.08),
                    child: const Icon(Icons.extension_rounded),
                  )
                : Image.network(
                    project.iconUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 46,
                      height: 46,
                      color: Colors.white.withValues(alpha: 0.08),
                      child: const Icon(Icons.extension_rounded),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  project.description.isEmpty
                      ? project.slug
                      : project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.sell_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        versionLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.download_rounded,
                      label: _formatCompact(project.downloads),
                    ),
                    const SizedBox(width: 6),
                    _StatPill(
                      icon: Icons.favorite_border_rounded,
                      label: _formatCompact(project.follows),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isInstalled)
                  _StatusTag(
                    label: 'Installed',
                    color: const Color(0xFF68DA97),
                  ),
                if (isUpdate)
                  _StatusTag(
                    label: 'Update',
                    color: const Color(0xFFFFB55A),
                  ),
                if (isUntracked)
                  _StatusTag(
                    label: 'On Disk',
                    color: const Color(0xFF86C5FF),
                  ),
                if (!isInstalled && !isUpdate && !isUntracked)
                  _StatusTag(
                    label: 'Not Installed',
                    color: const Color(0xFF8D98A5),
                  ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: (isInstalled || isUntracked) ? null : onTapAction,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(150, 42),
                    backgroundColor: isInstalled
                        ? const Color(0xFF68DA97).withValues(alpha: 0.15)
                        : isUntracked
                            ? const Color(0xFF86C5FF).withValues(alpha: 0.15)
                            : isUpdate
                                ? const Color(0xFFFFB55A).withValues(alpha: 0.2)
                                : selected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.25)
                                    : null,
                    foregroundColor: isInstalled
                        ? const Color(0xFF68DA97)
                        : isUntracked
                            ? const Color(0xFF86C5FF)
                            : isUpdate
                                ? const Color(0xFFFFC574)
                                : null,
                  ),
                  child: Text(
                    isInstalled
                        ? 'Installed'
                        : isUntracked
                            ? 'On Disk'
                            : selected
                                ? 'Selected'
                                : isUpdate
                                    ? 'Add Update'
                                    : 'Add',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.color,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: selected ? 0.95 : 0.55),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) {
      return tag;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: tag,
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.76)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReloadPopular});

  final VoidCallback onReloadPopular;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No mods found.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onReloadPopular,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Load popular mods'),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClearFilter});

  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No mods in this status filter.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onClearFilter,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Show all statuses'),
          ),
        ],
      ),
    );
  }
}

class _CartConfirmDialog extends StatelessWidget {
  const _CartConfirmDialog({
    required this.projects,
    required this.installInfo,
    required this.latestVersionByProject,
  });

  static const int _scrollTriggerCount = 4;
  static const double _rowHeight = 62;
  static const double _listMaxHeight = 280;

  final List<ModrinthProject> projects;
  final Map<String, ProjectInstallInfo> installInfo;
  final Map<String, String> latestVersionByProject;

  @override
  Widget build(BuildContext context) {
    final shouldScroll = projects.length > _scrollTriggerCount;
    final desiredHeight = projects.length * _rowHeight;
    final listHeight = shouldScroll
        ? _listMaxHeight
        : desiredHeight.clamp(0, _listMaxHeight).toDouble();

    return AlertDialog(
      title: const Text('Confirm Installation'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected mods:'),
            const SizedBox(height: 10),
            SizedBox(
              height: listHeight,
              child: Scrollbar(
                thumbVisibility: shouldScroll,
                child: ListView.builder(
                  shrinkWrap: !shouldScroll,
                  physics: shouldScroll
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final info = installInfo[project.id];
                    final state = info?.state;
                    final label = switch (state) {
                      ProjectInstallState.updateAvailable => 'Update',
                      ProjectInstallState.installed => 'Installed',
                      ProjectInstallState.installedUntracked => 'On Disk',
                      _ => 'Install',
                    };
                    final latestVersion = info?.latestVersionNumber ??
                        latestVersionByProject[project.id];
                    final installedVersion = info?.installedVersionNumber;
                    final versionText = switch (state) {
                      ProjectInstallState.updateAvailable =>
                        installedVersion != null && latestVersion != null
                            ? '$installedVersion -> $latestVersion'
                            : latestVersion ?? 'Update available',
                      ProjectInstallState.installed =>
                        installedVersion ?? latestVersion ?? 'Installed',
                      _ => latestVersion ?? 'Latest version: unknown',
                    };

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == projects.length - 1 ? 0 : 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: project.iconUrl == null
                                  ? Container(
                                      width: 34,
                                      height: 34,
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      child: const Icon(
                                        Icons.extension_rounded,
                                        size: 18,
                                      ),
                                    )
                                  : Image.network(
                                      project.iconUrl!,
                                      width: 34,
                                      height: 34,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 34,
                                        height: 34,
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        child: const Icon(
                                          Icons.extension_rounded,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Version: $versionText',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.72),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              label,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Install Now'),
        ),
      ],
    );
  }
}

class _BulkInstallProgressDialog extends ConsumerStatefulWidget {
  const _BulkInstallProgressDialog({
    required this.modsPath,
    required this.projects,
    required this.installInfo,
    required this.loader,
    required this.gameVersion,
  });

  final String modsPath;
  final List<ModrinthProject> projects;
  final Map<String, ProjectInstallInfo> installInfo;
  final String loader;
  final String? gameVersion;

  @override
  ConsumerState<_BulkInstallProgressDialog> createState() =>
      _BulkInstallProgressDialogState();
}

class _BulkInstallProgressDialogState
    extends ConsumerState<_BulkInstallProgressDialog> {
  String _message = 'Preparing installation...';
  final List<String> _logs = [];
  var _done = false;

  int _installed = 0;
  int _updated = 0;
  int _skipped = 0;
  int _failed = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    final total = widget.projects.length;

    for (var i = 0; i < total; i++) {
      final project = widget.projects[i];
      final installState = widget.installInfo[project.id]?.state;
      final step = i + 1;

      if (installState == ProjectInstallState.installed) {
        _skipped++;
        _logs.add('Skipped ${project.title}: already installed.');
        if (mounted) {
          setState(() {
            _message =
                '[$step/$total] Skipped ${project.title} (already installed).';
          });
        }
        continue;
      }
      if (installState == ProjectInstallState.installedUntracked) {
        _skipped++;
        _logs.add(
          'Skipped ${project.title}: already in mods folder (untracked).',
        );
        if (mounted) {
          setState(() {
            _message = '[$step/$total] Skipped ${project.title} (on disk).';
          });
        }
        continue;
      }

      final result =
          await ref.read(modsControllerProvider.notifier).installFromModrinth(
                modsPath: widget.modsPath,
                project: project,
                loader: widget.loader,
                gameVersion: widget.gameVersion,
                onProgress: (progress) async {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _message = '[$step/$total] ${progress.message}';
                  });
                },
              );

      if (!result.installed) {
        _failed++;
        _logs.add('Failed ${project.title}: ${result.message}');
        continue;
      }

      if (installState == ProjectInstallState.updateAvailable) {
        _updated++;
        _logs.add('Updated ${project.title}.');
      } else {
        _installed++;
        _logs.add('Installed ${project.title}.');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _done = true;
      _message = 'Done. Installed $_installed, Updated $_updated, '
          'Skipped $_skipped, Failed $_failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Installing Selected Mods'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_done) const LinearProgressIndicator(),
            if (!_done) const SizedBox(height: 12),
            Text(_message),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${_logs[index]}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _done ? () => Navigator.of(context).pop() : null,
          child: const Text('Close'),
        ),
      ],
    );
  }
}
