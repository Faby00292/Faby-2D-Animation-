import 'package:flutter/material.dart';

import '../../models/format_preset.dart';
import '../../theme/app_theme.dart';

/// Result payload from [NewProjectDialog].
class NewProjectSpec {
  NewProjectSpec(this.name, this.format, this.fps);
  final String name;
  final FormatPreset format;
  final int fps;
}

/// Dialog shown from the home "+" button: name, format preset and FPS (1–24).
class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final TextEditingController _name =
      TextEditingController(text: 'Untitled');
  FormatPreset _format = FormatPreset.youtube1080;
  double _fps = 12;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.add_box_outlined, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Text(
                    'New project',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Name'),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(hintText: 'Project name'),
              ),
              const SizedBox(height: 18),
              const Text('Format'),
              const SizedBox(height: 6),
              DropdownButtonFormField<FormatPreset>(
                value: _format,
                isExpanded: true,
                items: FormatPreset.values
                    .map(
                      (FormatPreset f) => DropdownMenuItem<FormatPreset>(
                        value: f,
                        child: Text('${f.label}  ·  ${f.width}×${f.height}'),
                      ),
                    )
                    .toList(),
                onChanged: (FormatPreset? v) =>
                    setState(() => _format = v ?? _format),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  const Text('Frame rate'),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_fps.round()} FPS',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _fps,
                min: 1,
                max: 24,
                divisions: 23,
                label: '${_fps.round()}',
                onChanged: (double v) => setState(() => _fps = v),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        NewProjectSpec(
                          _name.text.trim().isEmpty
                              ? 'Untitled'
                              : _name.text.trim(),
                          _format,
                          _fps.round(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
