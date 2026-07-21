import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/ad_service.dart';
import '../../services/settings_service.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;

  const SplashScreen({
    super.key,
    required this.next,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? logoPath;

  @override
  void initState() {
    super.initState();
    _loadLogoAndContinue();
  }

  Future<void> _loadLogoAndContinue() async {
    final path = await SettingsService.getLogoPath();
    if (mounted) {
      setState(() => logoPath = path);
    }
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    await AdService.maybeShowAppOpenAd(context);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasBusinessLogo = logoPath != null && File(logoPath!).existsSync();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primaryContainer, colors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasBusinessLogo
                      ? Image.file(File(logoPath!), fit: BoxFit.cover)
                      : Image.asset('mecha.JPG', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Mi Inventario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inventario, ventas y recordatorios',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
