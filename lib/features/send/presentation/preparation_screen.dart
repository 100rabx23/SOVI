import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/acoustic/receiver_discovery_engine.dart';

class PreparationScreen extends StatefulWidget {
  final Function(String selectedDeviceId) onInitiate;
  final VoidCallback onCancel;

  const PreparationScreen({
    super.key,
    required this.onInitiate,
    required this.onCancel,
  });

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  final ReceiverDiscoveryScanner _scanner = ReceiverDiscoveryScanner();
  StreamSubscription? _scannerSub;
  List<DiscoveredReceiver> _discoveredReceivers = [];
  DiscoveredReceiver? _selectedReceiver;

  @override
  void initState() {
    super.initState();
    _startDiscoveryScanner();
  }

  Future<void> _startDiscoveryScanner() async {
    _scannerSub = _scanner.stream.listen((receivers) {
      if (mounted) {
        setState(() {
          _discoveredReceivers = receivers;
          if (_selectedReceiver != null && !receivers.any((r) => r.deviceId == _selectedReceiver!.deviceId)) {
            _selectedReceiver = null;
          }
        });
      }
    });

    await _scanner.startScanning();
  }

  @override
  void dispose() {
    _scannerSub?.cancel();
    _scanner.stopScanning();
    super.dispose();
  }

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
                Text('Nearby Acoustic Receivers', style: SoviTypography.headlineLg()),
                const SizedBox(height: 4),
                Text(
                  'Scanning for active SOVI receivers listening nearby...',
                  style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status & Scanning Radar Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SoviColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SoviColors.outline.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SoviColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _discoveredReceivers.isEmpty
                        ? 'SEARCHING FOR RECEIVERS...'
                        : 'FOUND ${_discoveredReceivers.length} RECEIVER(S)',
                    style: SoviTypography.labelMonoSm(color: SoviColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Discovered Receivers List
          if (_discoveredReceivers.isEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.sensors_off, size: 40, color: SoviColors.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No active receivers detected yet.',
                    style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ensure the receiving phone has SOVI open and tapped START LISTENING.',
                    style: SoviTypography.labelSm(color: SoviColors.outlineVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _discoveredReceivers.length,
              itemBuilder: (context, index) {
                final receiver = _discoveredReceivers[index];
                final isSelected = _selectedReceiver?.deviceId == receiver.deviceId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedReceiver = receiver;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SoviColors.primary.withOpacity(0.15)
                            : SoviColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? SoviColors.primary
                              : SoviColors.outline.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: receiver.status == 'READY'
                                  ? SoviColors.secondaryContainer
                                  : SoviColors.errorContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  receiver.displayName,
                                  style: SoviTypography.bodyLg(color: SoviColors.onSurface).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Device ID: ${receiver.deviceId} • Status: ${receiver.status}',
                                  style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: SoviColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Signal: ${receiver.signalQuality}',
                              style: SoviTypography.labelMonoSm(
                                color: receiver.signalQuality == 'Strong'
                                    ? SoviColors.secondaryContainer
                                    : SoviColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),

          // Receiver Target Confirmation Box
          if (_selectedReceiver != null) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, color: SoviColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'SELECTED TARGET RECEIVER',
                        style: SoviTypography.labelMonoSm(color: SoviColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedReceiver!.displayName,
                    style: SoviTypography.headlineMd(),
                  ),
                  Text(
                    'Device ID: ${_selectedReceiver!.deviceId}',
                    style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm & Send Button
            ElevatedButton(
              onPressed: () {
                widget.onInitiate(_selectedReceiver!.deviceId);
              },
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
                    'CONFIRM & SEND TO ${_selectedReceiver!.displayName.toUpperCase()}',
                    style: SoviTypography.labelMono(color: SoviColors.onPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: SoviColors.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SELECT A RECEIVER ABOVE TO SEND',
                style: SoviTypography.labelMono(color: SoviColors.onSurfaceVariant),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Cancel Button
          OutlinedButton(
            onPressed: widget.onCancel,
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
}
