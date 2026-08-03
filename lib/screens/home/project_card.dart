import 'package:flutter/material.dart';

import '../../models/project.dart';
import '../../theme/app_theme.dart';

/// A single project tile on the home grid: a format-aspect preview block with
/// the project name, frame count / fps, and a favourite toggle.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  final ProjectSummary summary;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppTheme.accent.withValues(alpha: 0.18),
                          scheme.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: summary.format.aspectRatio,
                        child: Container(
                          margin: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.movie_creation_outlined,
                            color: AppTheme.accent.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      iconSize: 20,
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        summary.favorite ? Icons.star : Icons.star_border,
                        color: summary.favorite
                            ? AppTheme.accent
                            : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          summary.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.format.label} · ${summary.frameCount} '
                          'frames · ${summary.fps} fps',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
