import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/strings/app_strings.dart';
import '../../data/reports_api.dart';

class ExportButton extends ConsumerStatefulWidget {
  const ExportButton({super.key});

  @override
  ConsumerState<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<ExportButton> {
  bool _exporting = false;

  Future<void> _pickRangeAndExport() async {
    final now = DateTime.now();
    final defaultFrom = DateTime(now.year, 1, 1);
    final defaultTo = DateTime(now.year, now.month, now.day);

    final range = await showDialog<({DateTime from, DateTime to})>(
      context: context,
      builder: (context) => _ExportRangeDialog(
        initialFrom: defaultFrom,
        initialTo: defaultTo,
      ),
    );

    if (range == null || !mounted) return;
    await _export(range.from, range.to);
  }

  Future<void> _export(DateTime from, DateTime to) async {
    setState(() => _exporting = true);

    try {
      final bytes = await ref.read(reportsApiProvider).exportCsv(from: from, to: to);
      final dir = await getTemporaryDirectory();
      final filename = 'fintrack_${_formatDate(from)}_${_formatDate(to)}.csv';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: AppStrings.exportCsvSubject,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.exportCsvSuccess(file.path))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _exporting ? null : _pickRangeAndExport,
      icon: _exporting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_outlined),
      label: Text(_exporting ? AppStrings.exportCsvProgress : AppStrings.exportCsvButton),
    );
  }
}

class _ExportRangeDialog extends StatefulWidget {
  const _ExportRangeDialog({
    required this.initialFrom,
    required this.initialTo,
  });

  final DateTime initialFrom;
  final DateTime initialTo;

  @override
  State<_ExportRangeDialog> createState() => _ExportRangeDialogState();
}

class _ExportRangeDialogState extends State<_ExportRangeDialog> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.exportCsvTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text(AppStrings.exportCsvFrom),
            subtitle: Text(_formatDate(_from)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickFrom,
          ),
          ListTile(
            title: const Text(AppStrings.exportCsvTo),
            subtitle: Text(_formatDate(_to)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickTo,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancelButton),
        ),
        FilledButton(
          onPressed: _from.isAfter(_to)
              ? null
              : () => Navigator.pop(context, (from: _from, to: _to)),
          child: const Text(AppStrings.exportCsvButton),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
