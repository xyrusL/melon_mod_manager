import 'package:flutter/material.dart';

import '../../data/services/file_install_service.dart';
import '../widgets/app_modal.dart';

class ConfirmOverwriteDialog extends StatelessWidget {
  const ConfirmOverwriteDialog({super.key, required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: const AppModalTitle('File already exists'),
      subtitle: Text('"$fileName" is already in the target folder.'),
      content: const SizedBox.shrink(),
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
