import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';

class SuccessScreen extends StatelessWidget {
  final String fileName;
  final int durationSeconds;
  final int throughputBps;
  final int totalPackets;
  final int retries;
  final String? originalHash;
  final String? receivedHash;
  final bool isSender;
  final bool isText;
  final VoidCallback onOpenFile;
  final VoidCallback onDone;

  const SuccessScreen({
    super.key,
    required this.fileName,
    required this.durationSeconds,
    required this.throughputBps,
    required this.totalPackets,
    required this.retries,
    this.originalHash,
    this.receivedHash,
    this.isSender = false,
    this.isText = false,
    required this.onOpenFile,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isHashMatch = originalHash != null && receivedHash != null && originalHash == receivedHash;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Animated Success Ripple & Checkmark Node
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: SoviColors.secondaryContainer.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: SoviColors.secondaryContainer.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: SoviColors.secondaryContainer.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: Icon(
                isSender ? Icons.sensors : Icons.check_circle,
                size: 56,
                color: SoviColors.secondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  isSender
                      ? 'Transmission Sent'
                      : (isText ? 'Message Received' : 'File Received'),
                  style: SoviTypography.headlineLg(),
                ),
                const SizedBox(height: 4),
                Text(
                  isSender
                      ? (isText
                          ? 'Text message payload emitted acoustically.'
                          : 'File payload transmitted acoustically over speaker.')
                      : (isText
                          ? 'Text message decrypted and verified successfully.'
                          : 'File successfully received, decrypted, and saved.'),
                  style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security Verification Lock Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: SoviColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFICATION LOCK',
                      style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const Divider(height: 20, color: SoviColors.outlineVariant),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isHashMatch ? SoviColors.secondaryContainer : SoviColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHashMatch ? Icons.check : Icons.close,
                        size: 12,
                        color: SoviColors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SHA-256 ${isHashMatch ? "MATCH VERIFIED" : "VERIFICATION ERROR"}',
                        style: SoviTypography.labelMono(
                          color: isHashMatch ? SoviColors.onSurface : SoviColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                if (originalHash != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ORIGINAL: ${originalHash!.substring(0, 16)}...',
                    style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                  ),
                ],
                if (receivedHash != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'RECEIVED: ${receivedHash!.substring(0, 16)}...',
                    style: SoviTypography.labelMonoSm(color: SoviColors.secondaryContainer),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: SoviColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: SoviColors.onSecondaryContainer),
                    ),
                    const SizedBox(width: 10),
                    Text('AES-256-GCM Authenticated', style: SoviTypography.labelMono(color: SoviColors.onSurface)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _buildStatCard('DURATION', '${durationSeconds}s'),
              _buildStatCard('THROUGHPUT', '$throughputBps bps'),
              _buildStatCard('PACKETS', '$totalPackets px'),
              _buildStatCard('RETRIES', '$retries err'),
            ],
          ),
          const SizedBox(height: 32),

          // Primary Action Button (Only show OPEN FILE / VIEW MESSAGE if RECEIVER)
          if (!isSender) ...[
            ElevatedButton(
              onPressed: onOpenFile,
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
                  Icon(isText ? Icons.message : Icons.folder_open, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isText ? 'VIEW MESSAGE' : 'OPEN FILE',
                    style: SoviTypography.labelMono(color: SoviColors.onPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            ElevatedButton(
              onPressed: onDone,
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
                  const Icon(Icons.send, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'TRANSMIT ANOTHER',
                    style: SoviTypography.labelMono(color: SoviColors.onPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Done / Back to Home Button
          OutlinedButton(
            onPressed: onDone,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: SoviColors.outline.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSender ? 'BACK TO DASHBOARD' : 'DONE',
              style: SoviTypography.labelMono(color: SoviColors.primary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: SoviTypography.headlineMd()),
        ],
      ),
    );
  }
}
