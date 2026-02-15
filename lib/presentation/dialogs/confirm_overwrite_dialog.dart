import 'package:flutter/material.dart';

import '../../data/services/file_install_service.dart';

class ConfirmOverwriteDialog extends StatelessWidget {
  const ConfirmOverwriteDialog({super.key, required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File already exists'),
      content: Text('"$fileName" already exists in the mods folder.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.skip),
          child: const Text('Skip'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.rename),
          child: const Text('Rename'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(ConflictResolution.overwrite),
          child: const Text('Overwrite'),
        ),
      ],
    );
  }
}
