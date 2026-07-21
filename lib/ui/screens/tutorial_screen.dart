import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import 'home_screen.dart';

class TutorialScreen extends StatefulWidget {
  final bool launchedFromSettings;

  const TutorialScreen({
    super.key,
    this.launchedFromSettings = false,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _showAgain = false;

  final _steps = const [
    _TutorialStep(
      icon: Icons.inventory_2,
      title: 'Carga tu inventario',
      text:
          'Agrega productos con precio, costo, stock, categoría y foto. El costo ayuda a calcular utilidad.',
    ),
    _TutorialStep(
      icon: Icons.receipt_long,
      title: 'Vende con ticket',
      text:
          'Selecciona productos, cliente opcional y tipo de pago. La venta descuenta stock automáticamente.',
    ),
    _TutorialStep(
      icon: Icons.attach_money,
      title: 'Controla fiados y abonos',
      text:
          'Marca ventas como pagadas, parciales o pendientes. Después registra abonos desde Historial.',
    ),
    _TutorialStep(
      icon: Icons.notifications_active,
      title: 'Usa recordatorios',
      text:
          'Programa alertas para cobrar, despachar pedidos o dar seguimiento a clientes y tickets.',
    ),
    _TutorialStep(
      icon: Icons.backup,
      title: 'Protege tus datos',
      text:
          'Crea respaldos completos en ZIP. Incluyen base de datos, imágenes y configuración.',
    ),
  ];

  bool get _isLast => _page == _steps.length - 1;

  Future<void> _finish() async {
    await SettingsService.saveTutorialCompleted(!_showAgain);
    if (!mounted) return;
    if (widget.launchedFromSettings) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía rápida'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Saltar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            step.icon,
                            size: 42,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.text,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => Container(
                  width: index == _page ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color:
                        index == _page ? colors.primary : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            if (_isLast)
              SwitchListTile(
                value: _showAgain,
                onChanged: (value) => setState(() => _showAgain = value),
                title: const Text('Mostrar tutorial al iniciar'),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_page > 0)
                    OutlinedButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Atrás'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLast
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            ),
                    child: Text(_isLast ? 'Finalizar' : 'Siguiente'),
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

class _TutorialStep {
  final IconData icon;
  final String title;
  final String text;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.text,
  });
}
