import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/storage/history_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransferRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await HistoryRepository.getHistory();
    setState(() {
      _records = list;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await HistoryRepository.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transfer History', style: SoviTypography.headlineLg()),
                  const SizedBox(height: 4),
                  Text(
                    'Log of all past acoustic transfers.',
                    style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
                  ),
                ],
              ),
              if (_records.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: SoviColors.onSurfaceVariant),
                  onPressed: _clearHistory,
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: SoviColors.primary))
          else if (_records.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.history_toggle_off, size: 48, color: SoviColors.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'NO TRANSFER HISTORY',
                    style: SoviTypography.labelMono(color: SoviColors.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All verified acoustic file and text transfer logs will appear here after a real session.',
                    style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _records[index];
                final isSent = item.direction == 'sent';
                final isText = item.type == 'text';
                final isSuccess = item.status == 'success';

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSent
                              ? SoviColors.primary.withOpacity(0.15)
                              : SoviColors.secondaryContainer.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isText
                              ? Icons.message
                              : isSent
                                  ? Icons.upload
                                  : Icons.download,
                          color: isSent ? SoviColors.primary : SoviColors.secondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isText ? (item.textContent ?? 'Text Message') : item.fileName,
                                  style: SoviTypography.bodyMd(color: SoviColors.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.status.toUpperCase(),
                                  style: SoviTypography.labelMonoSm(
                                    color: isSuccess ? SoviColors.secondaryFixed : SoviColors.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isText ? "TEXT" : "${(item.fileSize / 1024).toStringAsFixed(1)} KB"} • ${isSent ? "Sent" : "Received"} • ${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                              style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                            ),
                            if (item.errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.errorMessage!,
                                style: SoviTypography.labelMonoSm(color: SoviColors.error),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
