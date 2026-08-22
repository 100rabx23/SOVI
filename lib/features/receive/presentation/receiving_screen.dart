import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/waveform_visualizer.dart';

class ReceivingScreen extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String fileName;
  final int receivedBytes;
  final int totalBytes;
  final int packetsRx;
  final int missingPackets;
  final int bitrateBps;
  final int signalIntegrity;
  final VoidCallback onComplete;

  const ReceivingScreen({
    super.key,
    required this.progress,
    required this.fileName,
    required this.receivedBytes,
    required this.totalBytes,
    required this.packetsRx,
    required this.missingPackets,
    required this.bitrateBps,
    required this.signalIntegrity,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final percentInt = (progress * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Circular Progress Ring
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: SoviColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(SoviColors.primary),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentInt%',
                        style: SoviTypography.displayMetrics(),
                      ),
                      Text(
                        'RECEIVING',
                        style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // File Info Glass Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: SoviColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description, color: SoviColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, style: SoviTypography.bodyLg(color: SoviColors.onSurface)),
                          const SizedBox(height: 2),
                          Text(
                            '${(receivedBytes / 1024).toStringAsFixed(1)} KB / ${(totalBytes / 1024).toStringAsFixed(1)} KB',
                            style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (missingPackets > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SoviColors.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, color: SoviColors.error, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$missingPackets packets retransmitted',
                          style: SoviTypography.labelMonoSm(color: SoviColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Telemetry Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('PACKETS RX', style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('$packetsRx', style: SoviTypography.headlineMd(color: SoviColors.secondary)),
                        const SizedBox(width: 8),
                        if (missingPackets > 0)
                          Text('$missingPackets MIS', style: SoviTypography.labelMonoSm(color: SoviColors.error)),
                      ],
                    ),
                  ],
                ),
              ),
              GlassCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('BITRATE', style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('$bitrateBps bps', style: SoviTypography.headlineMd(color: SoviColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Signal Integrity Bar
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SIGNAL INTEGRITY', style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
                    Text('$signalIntegrity%', style: SoviTypography.labelMonoSm(color: SoviColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: signalIntegrity / 100.0,
                    minHeight: 6,
                    backgroundColor: SoviColors.surfaceBright,
                    valueColor: const AlwaysStoppedAnimation<Color>(SoviColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Process Timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep('Signal', true),
              _buildStep('Session', true),
              _buildStep('Crypt', true),
              _buildStep('Rx', true, isActive: true),
              _buildStep('Build', false),
            ],
          ),
          const SizedBox(height: 20),

          // Bottom Waveform
          const WaveformVisualizer(height: 72, isReceiving: true),
        ],
      ),
    );
  }

  Widget _buildStep(String name, bool isDone, {bool isActive = false}) {
    final color = isActive
        ? SoviColors.primary
        : isDone
            ? SoviColors.secondaryContainer
            : SoviColors.outlineVariant;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? SoviColors.primary : SoviColors.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(
            isDone && !isActive ? Icons.check : Icons.sync,
            size: 12,
            color: isActive ? SoviColors.onPrimary : color,
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: SoviTypography.labelMonoSm(color: color)),
      ],
    );
  }
}
