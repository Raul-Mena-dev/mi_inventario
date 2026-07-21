import 'package:flutter/material.dart';

import '../../services/ad_service.dart';

class MockAdBanner extends StatefulWidget {
  final String placement;

  const MockAdBanner({
    super.key,
    required this.placement,
  });

  @override
  State<MockAdBanner> createState() => _MockAdBannerState();
}

class _MockAdBannerState extends State<MockAdBanner> {
  bool showAd = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shouldShow =
        await AdService.consumeBannerImpression(widget.placement);
    if (!mounted) return;
    setState(() => showAd = shouldShow);
  }

  @override
  Widget build(BuildContext context) {
    if (!showAd) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign, color: colors.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Anuncio de prueba: aquí aparecerá un banner de AdMob.',
              style: TextStyle(color: colors.onSecondaryContainer),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
