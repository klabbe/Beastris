import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:share_plus/share_plus.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final List<String> _pages = [];
  bool _busy = false;

  String get _fileName => 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

  // Native scanner handles edge detection, cropping and multi-page capture.
  Future<List<String>> _capturePages() async {
    try {
      final paths = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        scannerSource: ScannerSource.cameraAndGallery,
      );
      return paths ?? [];
    } catch (e) {
      _snack('Kunde inte starta skannern: $e');
      return [];
    }
  }

  Future<void> _scan() async {
    final paths = await _capturePages();
    if (paths.isNotEmpty && mounted) setState(() => _pages.addAll(paths));
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    for (final path in _pages) {
      final image = pw.MemoryImage(await File(path).readAsBytes());
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
    return doc.save();
  }

  Future<void> _run(Future<void> Function() action, String errorMsg) async {
    if (_busy || _pages.isEmpty) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('$errorMsg: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_busy || _pages.isEmpty) return;

    final enteredName = await showDialog<String>(
      context: context,
      builder: (_) => _PdfNameDialog(
        initialName: _fileName.replaceFirst(RegExp(r'\.pdf$'), ''),
      ),
    );
    if (enteredName == null || !mounted) return;

    final safeName = enteredName
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
    if (safeName.isEmpty) return;

    await _run(() async {
      final bytes = await _buildPdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$safeName.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
      );
    }, 'Kunde inte dela PDF');
  }

  Future<void> _download() => _run(() async {
    final uri = await FilePicker.saveFile(
      fileName: _fileName,
      bytes: await _buildPdf(),
      mimeType: 'application/pdf',
      dialogTitle: 'Spara PDF',
    );
    if (uri != null) _snack('PDF sparad');
  }, 'Kunde inte spara PDF');

  void _remove(int index) => setState(() => _pages.removeAt(index));

  void _reorder(int oldIndex, int newIndex) {
    setState(() => _pages.insert(newIndex, _pages.removeAt(oldIndex)));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _discard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Släng skanning?'),
        content: const Text('Alla skannade sidor tas bort.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Släng'),
          ),
        ],
      ),
    );
    if (ok == true) setState(_pages.clear);
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lämna skannern?'),
        content: const Text('Dina skannade sidor går förlorade om du lämnar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stanna'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lämna'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasPages = _pages.isNotEmpty;
    return PopScope(
      canPop: !hasPages,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            hasPages ? 'Dokument (${_pages.length} sidor)' : 'Dokumentskanner',
          ),
          actions: [
            if (hasPages)
              IconButton(
                tooltip: 'Släng alla sidor',
                onPressed: _discard,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: Column(
          children: [
            if (hasPages)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dra för att ordna · tryck på sidan för att granska eller redigera',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Expanded(
              child: hasPages
                  ? _PageGrid(
                      pages: _pages,
                      onReorder: _reorder,
                      onTap: _editPage,
                      onRemove: _remove,
                    )
                  : const _EmptyScanState(),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasPages && !_busy ? _share : null,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded),
                    label: Text(_busy ? 'Skapar PDF…' : 'Dela PDF'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _scan,
                        icon: const Icon(Icons.document_scanner_rounded),
                        label: const Text('Lägg till sidor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: hasPages && !_busy ? _download : null,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Spara PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editPage(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PageEditorScreen(pages: _pages, initialIndex: index),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _PdfNameDialog extends StatefulWidget {
  const _PdfNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_PdfNameDialog> createState() => _PdfNameDialogState();
}

class _PdfNameDialogState extends State<_PdfNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  bool _showNameError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Namn på PDF'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(
        labelText: 'Filnamn',
        suffixText: '.pdf',
        errorText: _showNameError ? 'Ange ett filnamn' : null,
      ),
      textInputAction: TextInputAction.done,
      onChanged: (_) {
        if (_showNameError) setState(() => _showNameError = false);
      },
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Avbryt'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Dela')),
    ],
  );
}

class _PageEditorScreen extends StatefulWidget {
  const _PageEditorScreen({required this.pages, required this.initialIndex});

  final List<String> pages;
  final int initialIndex;

  @override
  State<_PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<_PageEditorScreen> {
  late int _index = widget.initialIndex;
  bool _busy = false;

  Future<void> _crop() async {
    final colorScheme = Theme.of(context).colorScheme;
    final cropped = await ImageCropper().cropImage(
      sourcePath: widget.pages[_index],
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Beskär sida ${_index + 1}',
          toolbarColor: colorScheme.surface,
          toolbarWidgetColor: colorScheme.onSurface,
          activeControlsWidgetColor: colorScheme.primary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Beskär sida ${_index + 1}',
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.square,
          ],
        ),
        WebUiSettings(context: context),
      ],
    );
    if (cropped == null || !mounted) return;
    setState(() => widget.pages[_index] = cropped.path);
  }

  Future<void> _transform(Uint8List Function(Uint8List) transform) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final input = await File(widget.pages[_index]).readAsBytes();
      final outputBytes = await compute(transform, input);
      final dir = await getTemporaryDirectory();
      final output = File(
        '${dir.path}/edited_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await output.writeAsBytes(outputBytes);
      if (mounted) setState(() => widget.pages[_index] = output.path);
    } catch (e) {
      _snack('Kunde inte redigera sidan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enhance() => _transform(_enhanceImageBytes);

  Future<void> _rotate() => _transform(_rotateImageBytes);

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    return Scaffold(
      appBar: AppBar(
        title: Text('Redigera sida ${_index + 1} av ${pages.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Klar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.file(File(pages[_index]), fit: BoxFit.contain),
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _crop,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const SizedBox(
                            height: 56,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.crop_rounded, size: 20),
                                SizedBox(height: 4),
                                Text('Beskär', maxLines: 1, softWrap: false),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _enhance,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const SizedBox(
                            height: 56,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_fix_high_rounded, size: 20),
                                SizedBox(height: 4),
                                Text('Förbättra', maxLines: 1, softWrap: false),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _rotate,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const SizedBox(
                            height: 56,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rotate_right_rounded, size: 20),
                                SizedBox(height: 4),
                                Text('Rotera', maxLines: 1, softWrap: false),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _index > 0
                            ? () => setState(() => _index--)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        label: const Text('Föregående'),
                      ),
                      Text('${_index + 1} / ${pages.length}'),
                      TextButton.icon(
                        onPressed: _index < pages.length - 1
                            ? () => setState(() => _index++)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        label: const Text('Nästa'),
                        iconAlignment: IconAlignment.end,
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
}

Uint8List _enhanceImageBytes(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) throw const FormatException('Ogiltig bildfil');
  final enhanced = img.grayscale(decoded);
  img.normalize(enhanced, min: 0, max: 255);
  return img.encodeJpg(enhanced, quality: 92);
}

Uint8List _rotateImageBytes(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) throw const FormatException('Ogiltig bildfil');
  return img.encodeJpg(img.copyRotate(decoded, angle: 90), quality: 92);
}

class _EmptyScanState extends StatelessWidget {
  const _EmptyScanState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.document_scanner_rounded,
                size: 38,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Börja med att skanna',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Dokumentets kanter hittas automatiskt. Du kan lägga till fler sidor efteråt.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageGrid extends StatelessWidget {
  const _PageGrid({
    required this.pages,
    required this.onReorder,
    required this.onTap,
    this.onRemove,
  });

  final List<String> pages;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onTap;
  final void Function(int index)? onRemove;

  @override
  Widget build(BuildContext context) {
    return ReorderableGridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: pages.length,
      onReorder: onReorder,
      itemBuilder: (_, i) => GestureDetector(
        key: ValueKey(pages[i]),
        onTap: () => onTap(i),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(pages[i]), fit: BoxFit.cover),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${i + 1}'),
              ),
            ),
            if (onRemove != null)
              Positioned(
                right: 2,
                top: 2,
                child: IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onRemove!(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
