import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_storage_service.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _xController = TextEditingController();
  final _whatsappController = TextEditingController();

  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _nameController.text = await SettingsService.getBusinessName() ?? '';
    _logoPath = await SettingsService.getLogoPath();
    final links = await SettingsService.getSocialLinks();

    _facebookController.text = links["facebook"] ?? '';
    _instagramController.text = links["instagram"] ?? '';
    _tiktokController.text = links["tiktok"] ?? '';
    _xController.text = links["x"] ?? '';
    _whatsappController.text = links["whatsapp"] ?? '';

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      final logoPath =
          await ImageStorageService.saveImageToAppStorage(picked.path);
      if (logoPath != null) {
        await SettingsService.saveLogoPath(logoPath);
        setState(() => _logoPath = logoPath);
      }
    }
  }

  Future<void> _saveSettings() async {
    await SettingsService.saveBusinessName(_nameController.text);
    await SettingsService.saveSocialLinks(
      facebook: _facebookController.text,
      instagram: _instagramController.text,
      tiktok: _tiktokController.text,
      x: _xController.text,
      whatsapp: _whatsappController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _xController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del negocio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nombre del negocio
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del negocio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Logo
          Row(
            children: [
              _logoPath != null && File(_logoPath!).existsSync()
                  ? CircleAvatar(
                      backgroundImage: FileImage(File(_logoPath!)),
                      radius: 40,
                    )
                  : const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.store, size: 40),
                    ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image),
                label: const Text("Cambiar logo"),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Redes sociales
          const Text(
            "Redes sociales",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _socialField("Facebook", _facebookController),
          _socialField("Instagram", _instagramController),
          _socialField("TikTok", _tiktokController),
          _socialField("X (Twitter)", _xController),
          _socialField("WhatsApp (número o texto)", _whatsappController),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text("Guardar cambios"),
          ),
        ],
      ),
    );
  }

  Widget _socialField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
