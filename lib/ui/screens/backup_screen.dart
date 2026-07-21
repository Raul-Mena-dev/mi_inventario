import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool isBusy = false;
  String? selectedRestorePath;

  Future<void> _createBackup({bool share = false}) async {
    setState(() => isBusy = true);
    try {
      if (share) {
        await BackupService.shareBackup();
      } else {
        await BackupService.createBackup();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(share
              ? 'Respaldo listo para compartir'
              : 'Respaldo creado correctamente'),
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear el respaldo. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> _selectRestoreFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'db'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => selectedRestorePath = path);
  }

  Future<void> _restoreBackup() async {
    final path = selectedRestorePath;
    if (path == null || path.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un respaldo primero')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
          'Esto reemplazará los datos actuales por el respaldo seleccionado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => isBusy = true);
    try {
      await BackupService.restoreBackup(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respaldo restaurado')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se pudo restaurar. Revisa el archivo seleccionado.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respaldos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: isBusy ? null : () => _createBackup(),
            icon: const Icon(Icons.save_alt),
            label: const Text('Crear respaldo'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: isBusy ? null : () => _createBackup(share: true),
            icon: const Icon(Icons.share),
            label: const Text('Crear y compartir'),
          ),
          const Divider(height: 32),
          Text(
            'Restaurar datos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'El respaldo completo incluye productos, ventas, imágenes y configuración.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isBusy ? null : _selectRestoreFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Seleccionar respaldo'),
          ),
          if (selectedRestorePath != null) ...[
            const SizedBox(height: 8),
            Text(
              selectedRestorePath!.split('/').last,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                isBusy || selectedRestorePath == null ? null : _restoreBackup,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar respaldo'),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
