import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Diagnostics Header Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.graphic_eq, size: 48, color: SoviColors.secondaryContainer),
                const SizedBox(height: 8),
                Text(
                  'ACOUSTIC DIAGNOSTICS',
                  style: SoviTypography.labelMono(color: SoviColors.onSurface).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: SoviColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SoviColors.outline.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SoviColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LINK ACTIVE - SECURE',
                        style: SoviTypography.labelMonoSm(color: SoviColors.secondaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Spectrum Analysis Box
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIVE SPECTRUM ANALYSIS',
                    style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                  ),
                  Text(
                    '18.5kHz DOMINANT',
                    style: SoviTypography.labelMonoSm(color: SoviColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: SoviColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SoviColors.outline.withOpacity(0.15)),
                ),
                child: Stack(
                  children: [
                    // Grid lines
                    CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: _SpectrumGridPainter(),
                    ),
                    const Positioned(
                      left: 8,
                      bottom: 4,
                      child: Text('0 Hz', style: TextStyle(color: SoviColors.outlineVariant, fontSize: 10)),
                    ),
                    const Positioned(
                      right: 8,
                      bottom: 4,
                      child: Text('22.05 kHz', style: TextStyle(color: SoviColors.outlineVariant, fontSize: 10)),
                    ),
                    const Center(
                      child: Text(
                        '18.5 kHz (CARRIER MARKER)',
                        style: TextStyle(color: SoviColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bento Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              // AUDIO IO
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, size: 14, color: SoviColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('AUDIO IO', style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
                      ],
                    ),
                    const Spacer(),
                    Text('Sample Rate: 44.1 kHz', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                    Text('Detected: 18.5 kHz', style: SoviTypography.labelMonoSm(color: SoviColors.primary)),
                    Text('Input: -24 dB', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                    Text('Output: 85%', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                  ],
                ),
              ),

              // MODEM PHY
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.router, size: 14, color: SoviColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('MODEM PHY', style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
                      ],
                    ),
                    const Spacer(),
                    Text('Modulation: 2-FSK', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                    Text('Symbol Rate: 100 baud', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 12, color: SoviColors.secondaryContainer),
                        const SizedBox(width: 4),
                        Text('SYNC: LOCKED', style: SoviTypography.labelMonoSm(color: SoviColors.secondaryContainer)),
                      ],
                    ),
                  ],
                ),
              ),

              // PROTOCOL
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.swap_horiz, size: 14, color: SoviColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('PROTOCOL', style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
                      ],
                    ),
                    const Spacer(),
                    Text('Packets: 301', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                    Text('CRC Errors: 2', style: SoviTypography.labelMonoSm(color: SoviColors.error)),
                    Text('ACK: 298', style: SoviTypography.labelMonoSm(color: SoviColors.secondaryContainer)),
                    Text('NACK: 3', style: SoviTypography.labelMonoSm(color: SoviColors.error)),
                  ],
                ),
              ),

              // PERFORMANCE
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 14, color: SoviColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('PERFORMANCE', style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
                      ],
                    ),
                    const Spacer(),
                    Text('Goodput: 122 bps', style: SoviTypography.labelMonoSm(color: SoviColors.primary)),
                    Text('BER: 0.0012', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                    Text('PER: 0.01', style: SoviTypography.labelMonoSm(color: SoviColors.onSurface)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Export Diagnostics Button
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagnostics log exported to storage.')),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: SoviColors.outline.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.file_download, color: SoviColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'EXPORT DIAGNOSTICS',
                  style: SoviTypography.labelMono(color: SoviColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectrumGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SoviColors.outlineVariant.withOpacity(0.2)
      ..strokeWidth = 1.0;

    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
