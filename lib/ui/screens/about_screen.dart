import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final version = packageInfo == null
        ? 'Cargando...'
        : '${packageInfo!.version} (${packageInfo!.buildNumber})';

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'mecha.JPG',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mi Inventario',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Versión $version',
            textAlign: TextAlign.center,
          ),
          const Divider(height: 32),
          Text(
            'Legales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta app está diseñada para apoyar la gestión local de inventario, ventas, clientes, gastos, respaldos y recordatorios de negocios pequeños.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Los datos se almacenan localmente en el dispositivo del usuario, salvo cuando el usuario decide compartir tickets, catálogos o respaldos mediante herramientas externas.',
          ),
          const SizedBox(height: 12),
          const Text(
            'El usuario es responsable de crear y conservar respaldos de su información. La app no sustituye asesoría contable, fiscal ni legal.',
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2026 Mi Inventario. Todos los derechos reservados.',
          ),
        ],
      ),
    );
  }
}
