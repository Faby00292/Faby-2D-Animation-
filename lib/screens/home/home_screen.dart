import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project.dart';
import '../../services/storage_service.dart';
import '../../state/projects_controller.dart';
import '../../theme/app_theme.dart';
import '../editor/editor_screen.dart';
import '../settings/settings_screen.dart';
import 'new_project_dialog.dart';
import 'project_card.dart';

/// The start page: project library with search + filters, a settings entry and
/// the "+" button that opens the New Project dialog.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final NewProjectSpec? spec = await showDialog<NewProjectSpec>(
      context: context,
      builder: (_) => const NewProjectDialog(),
    );
    if (spec == null || !mounted) return;
    final ProjectsController projects = context.read<ProjectsController>();
    final Project project = await projects.create(
      name: spec.name,
      format: spec.format,
      fps: spec.fps,
    );
    if (!mounted) return;
    await _openProject(project);
  }

  Future<void> _openById(String id) async {
    final StorageService storage = context.read<StorageService>();
    final Project? project = await storage.loadProject(id);
    if (project == null || !mounted) return;
    await _openProject(project);
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(project: project),
      ),
    );
    if (mounted) {
      await context.read<ProjectsController>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProjectsController projects = context.watch<ProjectsController>();
    final List<ProjectSummary> items = projects.visible;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _searchBar(context, projects)),
            SliverToBoxAdapter(child: _filters(context, projects)),
            if (projects.loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final ProjectSummary s = items[index];
                      return ProjectCard(
                        summary: s,
                        onTap: () => _openById(s.id),
                        onToggleFavorite: () =>
                            projects.toggleFavorite(s.id),
                        onDelete: () => _confirmDelete(context, projects, s),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
      child: Row(
        children: <Widget>[
          const Icon(Icons.animation, color: AppTheme.accent, size: 30),
          const SizedBox(width: 10),
          Text(
            'Faby',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            '  2D Animation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accent,
                ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context, ProjectsController projects) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _search,
        onChanged: projects.setQuery,
        decoration: InputDecoration(
          hintText: 'Search projects',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    projects.setQuery('');
                  },
                ),
        ),
      ),
    );
  }

  Widget _filters(BuildContext context, ProjectsController projects) {
    Widget chip(String label, ProjectSort sort, IconData icon) {
      final bool selected = projects.sort == sort;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: selected,
          avatar: Icon(
            icon,
            size: 18,
            color: selected ? Colors.black : null,
          ),
          label: Text(label),
          onSelected: (_) => projects.setSort(sort),
          selectedColor: AppTheme.accent,
          labelStyle: TextStyle(
            color: selected ? Colors.black : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: <Widget>[
          chip('Recent', ProjectSort.updated, Icons.schedule),
          chip('Name', ProjectSort.name, Icons.sort_by_alpha),
          chip('Favorites', ProjectSort.favorites, Icons.star),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.movie_filter_outlined,
            size: 72,
            color: AppTheme.accent.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Tap “New” to start animating.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProjectsController projects,
    ProjectSummary summary,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('“${summary.name}” will be permanently removed.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await projects.delete(summary.id);
    }
  }
}
