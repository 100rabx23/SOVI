import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';

class PreparationScreen extends StatelessWidget {
  final VoidCallback onInitiate;
  final VoidCallback onCancel;

  const PreparationScreen({
    super.key,
    required this.onInitiate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text('Ready to Transmit', style: SoviTypography.headlineLg()),
                const SizedBox(height: 4),
                Text(
                  'Place devices nearby. Point speaker toward the receiver\'s microphone.',
                  style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Device Alignment Visualization Zone
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: SoviColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SoviColors.outline.withOpacity(0.15)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Receiver phone icon (left)
                Positioned(
                  left: 32,
                  child: Container(
                    width: 56,
                    height: 100,
                    decoration: BoxDecoration(
                      color: SoviColors.surfaceContainerLow.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SoviColors.outline.withOpacity(0.3)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.smartphone, color: SoviColors.onSurfaceVariant),
                        Icon(Icons.circle, color: SoviColors.secondaryContainer, size: 8),
                      ],
                    ),
                  ),
                ),
                // Acoustic wave rings
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 12.0 + (index * 12),
                      height: 12.0 + (index * 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SoviColors.primary.withOpacity(0.6 - (index * 0.12)),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
                // Sender tower icon (right)
                Positioned(
                  right: 32,
                  child: Container(
                    width: 56,
                    height: 100,
                    decoration: BoxDecoration(
                      color: SoviColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SoviColors.primary.withOpacity(0.4)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.cell_tower, color: SoviColors.primary),
                        Icon(Icons.volume_up, color: SoviColors.primary, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildStatCard(Icons.radar, 'DISTANCE', 'Optimal', '<1m', SoviColors.secondaryFixed),
              _buildStatCard(Icons.volume_up, 'AUDIO VOL', 'High', '100%', SoviColors.primary),
              _buildStatCard(Icons.lock, 'ENCRYPTION', 'Active', 'AES-GCM', SoviColors.secondaryFixed),
              _buildStatCard(Icons.timer, 'EST. TIME', '45s', '2.4MB', SoviColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 32),

          // Initiate Button
          ElevatedButton(
            onPressed: onInitiate,
            style: ElevatedButton.styleFrom(
              backgroundColor: SoviColors.primary,
              foregroundColor: SoviColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sensors, size: 20),
                const SizedBox(width: 8),
                Text(
                  'INITIATE TRANSFER',
                  style: SoviTypography.labelMono(color: SoviColors.onPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cancel Button
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: SoviColors.outline.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'CANCEL SESSION',
              style: SoviTypography.labelMono(color: SoviColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, String badge, Color badgeColor) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Text(label, style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: SoviTypography.headlineMd()),
              const SizedBox(width: 6),
              Text(badge, style: SoviTypography.labelMonoSm(color: badgeColor)),
            ],
          ),
        ],
      ),
    );
  }
}
