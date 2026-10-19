import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  Future<void> _share() => _run(() async {
    final bytes = await _buildPdf();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$_fileName');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
    );
  }, 'Kunde inte dela PDF');

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
                    'Dra för att ordna · tryck på × för att ta bort · tryck på en sida för att förstora',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Expanded(
              child: hasPages
                  ? _PageGrid(
                      pages: _pages,
                      onReorder: _reorder,
                      onTap: (i) => _openViewer(context, _pages, i),
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
}

void _openViewer(BuildContext context, List<String> pages, int index) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _PageViewer(pages: List.of(pages), initialIndex: index),
    ),
  );
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

class _PageViewer extends StatefulWidget {
  const _PageViewer({required this.pages, required this.initialIndex});

  final List<String> pages;
  final int initialIndex;

  @override
  State<_PageViewer> createState() => _PageViewerState();
}

class _PageViewerState extends State<_PageViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sida ${_index + 1} av ${widget.pages.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.pages.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(child: Image.file(File(widget.pages[i]))),
        ),
      ),
    );
  }
}
