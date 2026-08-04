import 'package:flutter/material.dart';

import '../../models/project_format.dart';
import '../../theme/app_theme.dart';

/// Values collected by [NewProjectDialog].
class NewProjectResult {
  const NewProjectResult({
    required this.name,
    required this.format,
    required this.fps,
  });

  final String name;
  final ProjectFormat format;
  final int fps;
}

/// Dialog for naming a project and choosing its format and frame rate.
class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  ProjectFormat _format = ProjectFormat.youtube1080;
  double _fps = 12;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      NewProjectResult(
        name: _nameController.text,
        format: _format,
        fps: _fps.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Project name',
                hintText: 'My animation',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            const Text('Format', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ProjectFormat>(
              initialValue: _format,
              isExpanded: true,
              items: [
                for (final f in ProjectFormat.values)
                  DropdownMenuItem<ProjectFormat>(
                    value: f,
                    child: Text('${f.label}  ·  ${f.dimensionsLabel}'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _format = value);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Frame rate',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '${_fps.round()} FPS',
                  style: const TextStyle(
                    color: FabyColors.turquoise,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: _fps,
              min: 1,
              max: 24,
              divisions: 23,
              label: '${_fps.round()} FPS',
              onChanged: (value) => setState(() => _fps = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
