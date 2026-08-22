import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/security/security_service.dart';

class SendFileScreen extends StatefulWidget {
  final Function(File file, String? passphrase, {bool isText, String? textContent}) onStartTransfer;

  const SendFileScreen({super.key, required this.onStartTransfer});

  @override
  State<SendFileScreen> createState() => _SendFileScreenState();
}

class _SendFileScreenState extends State<SendFileScreen> {
  bool _isTextMode = false;

  // File Mode State
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;
  String? _fileHash;
  String? _fileExtension;

  // Text Mode State
  final TextEditingController _textController = TextEditingController();

  bool _obscurePassphrase = true;
  final TextEditingController _passphraseController = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final hash = SecurityService.calculateSha256(bytes);

      setState(() {
        _selectedFile = file;
        _fileName = result.files.single.name;
        _fileSize = result.files.single.size;
        _fileExtension = result.files.single.extension?.toUpperCase() ?? 'FILE';
        _fileHash = hash;
      });
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _fileHash = null;
      _fileExtension = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Transmit Data', style: SoviTypography.headlineLg()),
          const SizedBox(height: 4),
          Text(
            'Select file or enter text message for acoustic transmission.',
            style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // Mode Selector (FILE vs TEXT)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isTextMode = false),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('SEND FILE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isTextMode ? SoviColors.primary : SoviColors.surfaceContainerHighest,
                    foregroundColor: !_isTextMode ? SoviColors.onPrimary : SoviColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isTextMode = true),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('SEND TEXT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTextMode ? SoviColors.primary : SoviColors.surfaceContainerHighest,
                    foregroundColor: _isTextMode ? SoviColors.onPrimary : SoviColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (!_isTextMode) ...[
            // Upload Area / Picker Zone
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xB31C2026),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SoviColors.outline.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: SoviColors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.upload_file, color: SoviColors.primary, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedFile == null ? 'SELECT A FILE' : 'CHANGE FILE',
                      style: SoviTypography.labelMono(color: SoviColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to browse device storage',
                      style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File Preview Card
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
                          color: SoviColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _fileExtension == 'PDF'
                              ? Icons.picture_as_pdf
                              : _fileExtension == 'PNG' || _fileExtension == 'JPG'
                                  ? Icons.image
                                  : Icons.insert_drive_file,
                          color: SoviColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fileName ?? 'No file selected',
                              style: SoviTypography.bodyLg(color: SoviColors.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _fileSize != null
                                  ? '${_fileExtension ?? "FILE"} • ${(_fileSize! / 1024).toStringAsFixed(1)} KB'
                                  : 'Tap Select File above',
                              style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFile != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: SoviColors.onSurfaceVariant),
                          onPressed: _clearFile,
                        ),
                    ],
                  ),
                  if (_fileHash != null) ...[
                    const Divider(height: 20, color: SoviColors.outlineVariant),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: SoviColors.secondaryContainer, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'SHA-256: ${_fileHash!.substring(0, 16)}...',
                            style: SoviTypography.labelMonoSm(color: SoviColors.secondaryContainer),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Text Input Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.message, color: SoviColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TEXT MESSAGE PAYLOAD',
                        style: SoviTypography.labelMonoSm(color: SoviColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    style: SoviTypography.bodyMd(color: SoviColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter text message to transmit (e.g. Hello from SOVI!)...',
                      hintStyle: TextStyle(color: SoviColors.outlineVariant),
                      filled: true,
                      fillColor: SoviColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: SoviColors.outline.withOpacity(0.3)),
                      ),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${utf8.encode(_textController.text).length} bytes (UTF-8)',
                        style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                      ),
                      if (_textController.text.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _textController.clear()),
                          child: Text('CLEAR', style: SoviTypography.labelMonoSm(color: SoviColors.primary)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Security Section
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, color: SoviColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AES-256-GCM ENCRYPTED',
                      style: SoviTypography.labelMonoSm(color: SoviColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Payload is encrypted prior to 2-FSK acoustic modulation.',
                  style: SoviTypography.labelSm(color: SoviColors.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Text(
                  'PASSPHRASE (OPTIONAL)',
                  style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passphraseController,
                  obscureText: _obscurePassphrase,
                  style: SoviTypography.labelMono(color: SoviColors.onSurface),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: SoviColors.outlineVariant),
                    filled: true,
                    fillColor: SoviColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: SoviColors.outline.withOpacity(0.3)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassphrase ? Icons.visibility_off : Icons.visibility,
                        color: SoviColors.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassphrase = !_obscurePassphrase;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Start Acoustic Transfer Primary Button
          ElevatedButton(
            onPressed: () async {
              final pass = _passphraseController.text.trim();

              if (_isTextMode) {
                final text = _textController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a text message to send.')),
                  );
                  return;
                }
                final dir = await getTemporaryDirectory();
                final tempFile = File('${dir.path}${Platform.pathSeparator}sovi_text_${DateTime.now().millisecondsSinceEpoch}.txt');
                await tempFile.writeAsString(text);
                widget.onStartTransfer(tempFile, pass.isEmpty ? null : pass, isText: true, textContent: text);
              } else {
                if (_selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a file to send.')),
                  );
                  return;
                }
                widget.onStartTransfer(_selectedFile!, pass.isEmpty ? null : pass, isText: false);
              }
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
                const Icon(Icons.graphic_eq, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isTextMode ? 'TRANSMIT TEXT ACOUSTICALLY' : 'START ACOUSTIC FILE TRANSFER',
                  style: SoviTypography.labelMono(color: SoviColors.onPrimary).copyWith(
                    fontWeight: FontWeight.w700,
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
