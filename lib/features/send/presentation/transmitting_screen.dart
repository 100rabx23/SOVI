import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/waveform_visualizer.dart';
import '../../../services/protocol/sovi_protocol.dart';

class TransmittingScreen extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String fileName;
  final int transferredBytes;
  final int totalBytes;
  final int packetsSent;
  final int totalPackets;
  final int retries;
  final int speedBps;
  final String statusText;
  final bool isTimeout;
  final VoidCallback onCancel;
  final VoidCallback? onRetry;

  const TransmittingScreen({
    super.key,
    required this.progress,
    required this.fileName,
    required this.transferredBytes,
    required this.totalBytes,
    required this.packetsSent,
    required this.totalPackets,
    required this.retries,
    required this.speedBps,
    required this.statusText,
    this.isTimeout = false,
    required this.onCancel,
    this.onRetry,
  });

  @override
  State<TransmittingScreen> createState() => _TransmittingScreenState();
}

class _TransmittingScreenState extends State<TransmittingScreen> {
  late StreamSubscription<SoviLogEntry> _logSub;
  List<SoviLogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _logs = List.from(ProtocolEventLogger.history);
    _logSub = ProtocolEventLogger.stream.listen((entry) {
      if (mounted) {
        setState(() {
          _logs.add(entry);
          if (_logs.length > 50) _logs.removeAt(0);
        });
      }
    });
  }

  @override
  void dispose() {
    _logSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentInt = (widget.progress * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  widget.isTimeout ? 'No Receiver Detected' : 'Acoustic Transmission',
                  style: SoviTypography.headlineLg(
                    color: widget.isTimeout ? SoviColors.error : SoviColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.statusText.toUpperCase(),
                  style: SoviTypography.labelMonoSm(
                    color: widget.isTimeout ? SoviColors.error : SoviColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (widget.isTimeout) ...[
            // Timeout / No Receiver Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: SoviColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'NO ACOUSTIC RECEIVER ACKNOWLEDGED',
                    style: SoviTypography.labelMono(color: SoviColors.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not detect an active SOVI receiver after acoustic HELLO handshake timeout.',
                    style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: SoviColors.outline.withOpacity(0.3)),
                          ),
                          child: Text('CANCEL', style: SoviTypography.labelMono(color: SoviColors.onSurface)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SoviColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('RETRY HANDSHAKE', style: SoviTypography.labelMono(color: SoviColors.onPrimary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Circular Progress Ring
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: widget.progress,
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
                          '${widget.transferredBytes} B',
                          style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // File Info Glass Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                        Text(widget.fileName, style: SoviTypography.bodyLg(color: SoviColors.onSurface)),
                        const SizedBox(height: 2),
                        Text(
                          '${(widget.transferredBytes / 1024).toStringAsFixed(1)} KB / ${(widget.totalBytes / 1024).toStringAsFixed(1)} KB ACKNOWLEDGED',
                          style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Telemetry Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildTelemetryCard('PACKETS TX', '${widget.packetsSent}/${widget.totalPackets}', SoviColors.onSurface),
                _buildTelemetryCard('RETRIES', '${widget.retries}', SoviColors.error),
                _buildTelemetryCard('THROUGHPUT', '${widget.speedBps} bps', SoviColors.primary),
                _buildTelemetryCard('SIGNAL', 'N/A', SoviColors.secondary),
              ],
            ),
            const SizedBox(height: 20),

            // Live Real-Time Protocol Event Log Box
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('REAL-TIME PROTOCOL LOG', style: SoviTypography.labelMonoSm(color: SoviColors.primary)),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: SoviColors.secondaryContainer, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: SoviColors.outlineVariant),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: SoviColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: _logs.isEmpty
                        ? Center(
                            child: Text(
                              'Awaiting protocol events...',
                              style: SoviTypography.labelMonoSm(color: SoviColors.outlineVariant),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final item = _logs[_logs.length - 1 - index];
                              return Text(
                                '${item.formattedTime}  ${item.message}',
                                style: SoviTypography.labelMonoSm(
                                  color: item.isError ? SoviColors.error : SoviColors.onSurface,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Waveform Visualizer
            const WaveformVisualizer(height: 64, isTransmitting: true),
            const SizedBox(height: 20),

            // Cancel Button
            OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: SoviColors.error.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel, color: SoviColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'CANCEL SESSION',
                    style: SoviTypography.labelMono(color: SoviColors.error),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(String label, String value, Color valueColor) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: SoviTypography.headlineMd(color: valueColor)),
        ],
      ),
    );
  }
}
