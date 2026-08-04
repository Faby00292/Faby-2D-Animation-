import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project.dart';
import '../../state/project_store.dart';
import '../../theme/app_theme.dart';
import '../editor/editor_screen.dart';
import 'new_project_dialog.dart';
import 'project_card.dart';

/// Start page: lists existing projects and offers project creation + settings.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _createProject(BuildContext context) async {
    final store = context.read<ProjectStore>();
    final result = await showDialog<NewProjectResult>(
      context: context,
      builder: (_) => const NewProjectDialog(),
    );
    if (result == null) return;
    final project = store.createProject(
      name: result.name,
      format: result.format,
      fps: result.fps,
    );
    if (!context.mounted) return;
    _openProject(context, project);
  }

  void _openProject(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditorScreen(project: project)),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FabyColors.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectStore>().projects;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faby 2D Animation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _openSettings(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: projects.isEmpty
          ? _EmptyState(onCreate: () => _createProject(context))
          : SafeArea(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () => _openProject(context, project),
                    onDelete: () =>
                        context.read<ProjectStore>().deleteProject(project),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: FabyColors.turquoise.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              size: 44,
              color: FabyColors.turquoise,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No projects yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to start animating.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dark_mode_outlined),
              title: Text('Theme'),
              subtitle: Text('Dark'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.palette_outlined),
              title: Text('Accent color'),
              subtitle: Text('Turquoise'),
              trailing: CircleAvatar(
                radius: 12,
                backgroundColor: FabyColors.turquoise,
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline),
              title: Text('About'),
              subtitle: Text('Faby 2D Animation'),
            ),
          ],
        ),
      ),
    );
  }
}
