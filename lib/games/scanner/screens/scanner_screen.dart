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

  // Native scanner handles edge detection, cropping and multi-page capture.
  Future<void> _scan() async {
    try {
      final paths = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        scannerSource: ScannerSource.cameraAndGallery,
      );
      if (paths != null && mounted) setState(() => _pages.addAll(paths));
    } catch (e) {
      _snack('Kunde inte starta skannern: $e');
    }
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

  void _remove(int index) => setState(() => _pages.removeAt(index));

  void _reorder(int oldIndex, int newIndex) {
    setState(() => _pages.insert(newIndex, _pages.removeAt(oldIndex)));
  }

  // The export screen shares the list, so reordering there carries back here.
  Future<void> _next() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _ExportScreen(pages: _pages)));
    if (mounted) setState(() {});
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
            hasPages ? 'Skanner (${_pages.length} sidor)' : 'Skanner',
          ),
        ),
        body: !hasPages
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Tryck på kameran för att skanna. Dokumentets kanter hittas automatiskt och du kan lägga till flera sidor.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _PageGrid(
                pages: _pages,
                bottomPadding: 100,
                onReorder: _reorder,
                onTap: (i) => _openViewer(context, _pages, i),
                onRemove: _remove,
              ),
        bottomNavigationBar: hasPages
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _discard,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Släng'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _next,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Nästa'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _scan,
          icon: const Icon(Icons.document_scanner_rounded),
          label: Text(hasPages ? 'Lägg till sidor' : 'Skanna'),
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

class _ExportScreen extends StatefulWidget {
  const _ExportScreen({required this.pages});

  final List<String> pages;

  @override
  State<_ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<_ExportScreen> {
  bool _busy = false;

  String get _fileName => 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    for (final path in widget.pages) {
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
    if (_busy) return;
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    return Scaffold(
      appBar: AppBar(title: Text('Klart (${pages.length} sidor)')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Håll in och dra en sida för att byta ordning'),
          ),
          Expanded(
            child: _PageGrid(
              pages: pages,
              onReorder: (o, n) =>
                  setState(() => pages.insert(n, pages.removeAt(o))),
              onTap: (i) => _openViewer(context, pages, i),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Tillbaka'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _download,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Ladda ner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_rounded),
                  label: const Text('Dela'),
                ),
              ),
            ],
          ),
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
    this.bottomPadding = 12,
  });

  final List<String> pages;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onTap;
  final void Function(int index)? onRemove;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ReorderableGridView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
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
