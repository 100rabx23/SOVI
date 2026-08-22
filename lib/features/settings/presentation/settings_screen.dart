import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _modulation = '2-FSK';
  double _volume = 1.0;
  String _sampleRate = '44.1 kHz';
  int _maxRetries = 5;
  bool _enableAesGcm = true;
  bool _enableDiagnostics = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: SoviTypography.headlineLg()),
          const SizedBox(height: 4),
          Text(
            'Configure acoustic modem and security parameters.',
            style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Modem PHY Settings
          Text(
            'MODEM CONFIGURATION',
            style: SoviTypography.labelMonoSm(color: SoviColors.primary),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Modulation Mode', style: SoviTypography.bodyMd()),
                    DropdownButton<String>(
                      value: _modulation,
                      dropdownColor: SoviColors.surfaceContainerHigh,
                      underline: const SizedBox(),
                      style: SoviTypography.labelMono(
                        color: SoviColors.primary,
                      ),
                      items: ['2-FSK', '4-FSK'].map((m) {
                        return DropdownMenuItem(value: m, child: Text(m));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _modulation = val);
                      },
                    ),
                  ],
                ),
                const Divider(color: SoviColors.outlineVariant),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sample Rate', style: SoviTypography.bodyMd()),
                    DropdownButton<String>(
                      value: _sampleRate,
                      dropdownColor: SoviColors.surfaceContainerHigh,
                      underline: const SizedBox(),
                      style: SoviTypography.labelMono(
                        color: SoviColors.primary,
                      ),
                      items: ['44.1 kHz', '48.0 kHz', '96.0 kHz'].map((sr) {
                        return DropdownMenuItem(value: sr, child: Text(sr));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _sampleRate = val);
                      },
                    ),
                  ],
                ),
                const Divider(color: SoviColors.outlineVariant),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transmission Volume',
                          style: SoviTypography.bodyMd(),
                        ),
                        Text(
                          '${(_volume * 100).toInt()}%',
                          style: SoviTypography.labelMono(
                            color: SoviColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _volume,
                      activeColor: SoviColors.primary,
                      inactiveColor: SoviColors.surfaceBright,
                      onChanged: (val) => setState(() => _volume = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Security Settings
          Text(
            'SECURITY & PROTOCOL',
            style: SoviTypography.labelMonoSm(color: SoviColors.primary),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'AES-256-GCM Encryption',
                    style: SoviTypography.bodyMd(),
                  ),
                  value: _enableAesGcm,
                  activeColor: SoviColors.primary,
                  onChanged: (val) => setState(() => _enableAesGcm = val),
                ),
                const Divider(color: SoviColors.outlineVariant),
                SwitchListTile(
                  title: Text(
                    'Enable Hardware Diagnostics',
                    style: SoviTypography.bodyMd(),
                  ),
                  value: _enableDiagnostics,
                  activeColor: SoviColors.primary,
                  onChanged: (val) => setState(() => _enableDiagnostics = val),
                ),
                const Divider(color: SoviColors.outlineVariant),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max Packet Retries', style: SoviTypography.bodyMd()),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: SoviColors.onSurfaceVariant,
                          ),
                          onPressed: () {
                            if (_maxRetries > 1) setState(() => _maxRetries--);
                          },
                        ),
                        Text(
                          '$_maxRetries',
                          style: SoviTypography.labelMono(
                            color: SoviColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: SoviColors.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _maxRetries++),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hardware Diagnostic Trigger
          OutlinedButton(
            onPressed: _enableDiagnostics
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: SoviColors.surfaceContainerHigh,
                        title: Text(
                          'Audio Hardware Diagnostic',
                          style: SoviTypography.headlineMd(),
                        ),
                        content: Text(
                          'Microphone: 44.1kHz - OK\nSpeaker: 44.1kHz - OK\nNyquist Limit: 22.05kHz - PASS\n18.5kHz / 19.5kHz Support: CONFIRMED',
                          style: SoviTypography.labelMonoSm(
                            color: SoviColors.secondaryContainer,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'CLOSE',
                              style: SoviTypography.labelMono(
                                color: SoviColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
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
                Icon(
                  Icons.build,
                  color: _enableDiagnostics
                      ? SoviColors.primary
                      : SoviColors.outline,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'RUN HARDWARE DIAGNOSTIC',
                  style: SoviTypography.labelMono(
                    color: _enableDiagnostics
                        ? SoviColors.primary
                        : SoviColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
