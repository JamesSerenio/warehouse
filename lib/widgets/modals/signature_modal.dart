import 'package:flutter/material.dart';

import '../../functions/transactions/new_transaction_function.dart';
import 'modal_helper.dart';

Future<void> showSignatureModal(
  BuildContext context, {
  required NewTransactionDraft draft,
}) {
  return showWarehouseModal<void>(
    context: context,
    maxWidth: 720,
    barrierDismissible: false,
    builder: (_) => _SignatureModal(draft: draft),
  );
}

class _SignatureModal extends StatefulWidget {
  const _SignatureModal({required this.draft});

  final NewTransactionDraft draft;

  @override
  State<_SignatureModal> createState() => _SignatureModalState();
}

class _SignatureModalState extends State<_SignatureModal> {
  final List<Offset?> _points = [];
  String? _error;
  bool _isConfirming = false;

  void _addPoint(Offset? point) {
    setState(() {
      _points.add(point);
      _error = null;
    });
  }

  Future<void> _confirm() async {
    if (!_points.any((point) => point != null)) {
      setState(() => _error = 'Borrower signature is required.');
      return;
    }
    setState(() {
      _isConfirming = true;
      _error = null;
    });
    try {
      await NewTransactionFunction.confirmTransaction(
        draft: widget.draft,
        signaturePoints: List.unmodifiable(_points),
      );
    } on TransactionStorageUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to confirm the transaction.');
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ModalHeader(
            onClose: _isConfirming ? null : () => Navigator.pop(context),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoRow(label: 'Borrower', value: widget.draft.borrowerName),
                  const SizedBox(height: 7),
                  _InfoRow(label: 'Contact', value: widget.draft.contactNumber),
                  const SizedBox(height: 20),
                  const Text(
                    'Items Summary',
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.draft.items.map(
                    (entry) => _SummaryItem(entry: entry),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Borrower's Signature",
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) =>
                            _addPoint(details.localPosition),
                        onPanUpdate: (details) =>
                            _addPoint(details.localPosition),
                        onPanEnd: (_) => _addPoint(null),
                        child: CustomPaint(
                          painter: _SignaturePainter(_points),
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: _isConfirming
                            ? null
                            : () => setState(() {
                                _points.clear();
                                _error = null;
                              }),
                        child: const Text('CLEAR'),
                      ),
                      OutlinedButton(
                        onPressed: _isConfirming
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      SizedBox(
                        width: 210,
                        child: FilledButton.icon(
                          onPressed: _isConfirming ? null : _confirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D5BE1),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: _isConfirming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: const Text('CONFIRM TRANSACTION'),
                        ),
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

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    padding: const EdgeInsets.only(left: 22, right: 8),
    color: const Color(0xFF08213B),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Review & Signature',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          color: Colors.white,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 82,
        child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageUrl == null || imageUrl!.isEmpty
            ? const ColoredBox(
                color: Color(0xFFE8F0FF),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF0D5BE1),
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFFE8F0FF),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.entry});
  final TransactionDraftItem entry;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        _ItemThumbnail(imageUrl: entry.item.imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.item.productName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                '${entry.item.typeLabel} • ${entry.quantity} ${entry.item.unit}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF172033)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
