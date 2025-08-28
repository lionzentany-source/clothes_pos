import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:flutter/cupertino.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:clothes_pos/core/printing/system_pdf_printer.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

class PrintingSettingsScreen extends StatefulWidget {
  const PrintingSettingsScreen({super.key});
  @override
  State<PrintingSettingsScreen> createState() => _PrintingSettingsScreenState();
}

class _PrintingSettingsScreenState extends State<PrintingSettingsScreen> {
  final _pageWidthCtrl = TextEditingController();
  final _pageHeightCtrl = TextEditingController();
  final _marginCtrl = TextEditingController();
  final _fontSizeCtrl = TextEditingController();
  final _settings = sl<SettingsRepository>();
  bool _loading = true;
  bool _openDialog = true;
  String? _printerName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      _pageWidthCtrl.text = await _settings.get('print_page_width') ?? '58';
      _pageHeightCtrl.text = await _settings.get('print_page_height') ?? '200';
      _marginCtrl.text = await _settings.get('print_margin') ?? '6';
      _fontSizeCtrl.text = await _settings.get('print_font_size') ?? '10';
      _openDialog = (await _settings.get('print_open_dialog')) != '0';
      _printerName = await _settings.get('print_printer_name');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!mounted) return; // in case save was triggered during a route pop
    if (mounted) setState(() => _loading = true);
    try {
      await _settings.set('print_page_width', _pageWidthCtrl.text.trim());
      await _settings.set('print_page_height', _pageHeightCtrl.text.trim());
      await _settings.set('print_margin', _marginCtrl.text.trim());
      await _settings.set('print_font_size', _fontSizeCtrl.text.trim());
      await _settings.set('print_open_dialog', _openDialog ? '1' : '0');
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (dialogCtx) {
          // Use the dialog's own BuildContext to avoid referencing a possibly unmounted State context.
          final l = AppLocalizations.of(dialogCtx);
          return CupertinoAlertDialog(
            title: Text(l.done),
            content: Text(l.printingSettingsSaved),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(l.ok),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPrinter() async {
    final sp = SystemPdfPrinter();
    final printer = await sp.pickAndSaveDefaultPrinter(context);
    if (!mounted) return;
    setState(() => _printerName = printer?.name);
  }

  Future<void> _clearPrinter() async {
    final sp = SystemPdfPrinter();
    await sp.clearDefaultPrinter();
    if (!mounted) return;
    setState(() => _printerName = null);
  }

  Future<Uint8List> _buildTestPdfBytes() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (c) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('صفحة اختبار الطباعة', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 12),
              pw.Text('إذا ظهرت هذه الصفحة، فالطباعة تعمل.'),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  @override
  void dispose() {
    _pageWidthCtrl.dispose();
    _pageHeightCtrl.dispose();
    _marginCtrl.dispose();
    _fontSizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.printingSettings)),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l.pageSizeMm),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _pageWidthCtrl,
                          placeholder: l.widthPlaceholder58,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _pageHeightCtrl,
                          placeholder: l.heightPlaceholder200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l.marginMm),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _marginCtrl,
                    placeholder: l.marginPlaceholder6,
                  ),
                  const SizedBox(height: 12),
                  Text(l.fontSizePt),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _fontSizeCtrl,
                    placeholder: l.fontSizePlaceholder10,
                  ),
                  const SizedBox(height: 12),
                  // Open dialog switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.openPrintDialog),
                      CupertinoSwitch(
                        value: _openDialog,
                        onChanged: (v) => setState(() => _openDialog = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l.defaultPrinter),
                  const SizedBox(height: 6),
                  Text(
                    _printerName == null || _printerName!.isEmpty
                        ? l.none
                        : _printerName!,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _loading ? null : _pickPrinter,
                          child: Text(l.choosePrinter),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _loading ? null : _clearPrinter,
                          child: Text(l.clearDefault),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            // Generate a small test PDF and print via SystemPdfPrinter
                            final docBytes = await _buildTestPdfBytes();
                            await SystemPdfPrinter().printPdfBytes(docBytes);
                          },
                    child: Text(l.testPrinter),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: _loading ? null : _save,
                    child: Text(l.save),
                  ),
                ],
              ),
      ),
    );
  }
}
