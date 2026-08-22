import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/waveform_visualizer.dart';

class HomeDashboardScreen extends StatelessWidget {
  final VoidCallback onSendPressed;
  final VoidCallback onReceivePressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onDiagnosticsPressed;

  const HomeDashboardScreen({
    super.key,
    required this.onSendPressed,
    required this.onReceivePressed,
    required this.onHistoryPressed,
    required this.onDiagnosticsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header titles
          Center(
            child: Column(
              children: [
                Text(
                  'Secure Acoustic Transfer',
                  style: SoviTypography.headlineLg(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Transfer files through sound. Securely.',
                  style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'No Wi-Fi. No Bluetooth pairing. No cable.',
                  style: SoviTypography.labelSm(color: SoviColors.primary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hero Waveform Visualizer Node
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: SoviColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SoviColors.outline.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const WaveformVisualizer(height: 140, isTransmitting: true),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: SoviColors.surface.withOpacity(0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: SoviColors.primary.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: SoviColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.graphic_eq,
                      color: SoviColors.primary,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Cards Grid
          Row(
            children: [
              // Send Card
              Expanded(
                child: GlassCard(
                  onTap: onSendPressed,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: SoviColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.upload, color: SoviColors.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SoviColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TX_MODE',
                              style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('SEND FILE', style: SoviTypography.headlineMd()),
                      const SizedBox(height: 4),
                      Text(
                        'Transmit a file to another nearby device.',
                        style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Receive Card
              Expanded(
                child: GlassCard(
                  onTap: onReceivePressed,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: SoviColors.secondaryContainer.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: SoviColors.secondaryContainer),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SoviColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'RX_MODE',
                              style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('RECEIVE FILE', style: SoviTypography.headlineMd()),
                      const SizedBox(height: 4),
                      Text(
                        'Listen for an incoming SOVI transfer.',
                        style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ACTIVITY',
                style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
              ),
              GestureDetector(
                onTap: onHistoryPressed,
                child: Text(
                  'View All',
                  style: SoviTypography.labelSm(color: SoviColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassCard(
            onTap: onHistoryPressed,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SoviColors.tertiaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: SoviColors.tertiaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('research.pdf', style: SoviTypography.bodyMd(color: SoviColors.onSurface)),
                          Text('Success', style: SoviTypography.labelMonoSm(color: SoviColors.secondaryFixed)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PDF • 42 KB • Sent • Today 11:42 AM',
                        style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // System Status Bento
          GestureDetector(
            onTap: onDiagnosticsPressed,
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SoviColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACOUSTIC ENGINE: READY',
                        style: SoviTypography.labelMonoSm(color: SoviColors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(Icons.mic, 'Mic Ready', SoviColors.secondaryContainer),
                      ),
                      Expanded(
                        child: _buildMetricItem(Icons.volume_up, 'Speaker Ready', SoviColors.secondaryContainer),
                      ),
                      Expanded(
                        child: _buildMetricItem(Icons.lock, 'AES Encrypted', SoviColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: SoviColors.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
