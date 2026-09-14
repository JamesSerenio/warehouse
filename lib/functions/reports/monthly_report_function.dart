import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class MonthlyReportException implements Exception {
  const MonthlyReportException(this.message);
  final String message;
}

enum ReportItemStatus { active, partial, returned, overdue, noReturnRequired }

class ReportSummary {
  const ReportSummary({
    required this.totalItems,
    required this.toolsBorrowed,
    required this.materialsIssued,
    required this.totalReturned,
    required this.overdueItems,
    required this.activeTransactions,
  });
  final int totalItems, toolsBorrowed, materialsIssued, totalReturned;
  final int overdueItems, activeTransactions;
}

class ReportTransactionEntry {
  const ReportTransactionEntry({
    required this.transactionCode,
    required this.borrowerName,
    required this.quantity,
    required this.returnedQuantity,
    required this.createdAt,
    required this.status,
  });
  final String transactionCode, borrowerName;
  final int quantity, returnedQuantity;
  final DateTime? createdAt;
  final ReportItemStatus status;
}

class MonthlyItemReport {
  const MonthlyItemReport({
    required this.itemId,
    required this.productName,
    required this.itemType,
    required this.unit,
    required this.currentAvailable,
    required this.borrowedOrIssued,
    required this.returned,
    required this.remaining,
    required this.status,
    required this.history,
    this.imagePath,
  });
  final Object itemId;
  final String productName, itemType, unit;
  final int currentAvailable, borrowedOrIssued, returned, remaining;
  final ReportItemStatus status;
  final List<ReportTransactionEntry> history;
  final String? imagePath;
  bool get isMaterial => itemType == 'material';
  String get typeLabel => switch (itemType) {
    'tool' => 'Tool',
    'equipment' => 'Equipment',
    'material' => 'Material / Consumable',
    _ => itemType,
  };
  String? get imageUrl => imagePath == null || imagePath!.trim().isEmpty
      ? null
      : SupabaseService.client.storage
            .from('item-images')
            .getPublicUrl(imagePath!);
}

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.summary,
    required this.items,
  });
  final DateTime month;
  final ReportSummary summary;
  final List<MonthlyItemReport> items;
}

abstract final class MonthlyReportFunction {
  static const transactionQuery =
      'id, transaction_code, borrower_name, status, created_at, '
      'transaction_items(id, item_id, quantity, returned_quantity, item_type, expected_return_at, status, '
      'items(id, product_name, item_type, unit, image_path, available_stock, is_active))';

  static Future<MonthlyReport> load(DateTime selectedMonth) async {
    final start = DateTime(selectedMonth.year, selectedMonth.month);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1);
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.client.from('items').select('id').eq('is_active', true),
        SupabaseService.client
            .from('transactions')
            .select(transactionQuery)
            .gte('created_at', start.toUtc().toIso8601String())
            .lt('created_at', end.toUtc().toIso8601String())
            .order('created_at', ascending: false),
        SupabaseService.client
            .from('return_history')
            .select('quantity_returned, returned_at')
            .gte('returned_at', start.toUtc().toIso8601String())
            .lt('returned_at', end.toUtc().toIso8601String()),
        SupabaseService.client
            .from('transaction_items')
            .select(
              'quantity, returned_quantity, item_type, expected_return_at',
            )
            .inFilter('item_type', const ['tool', 'equipment'])
            .lt('expected_return_at', DateTime.now().toUtc().toIso8601String()),
        SupabaseService.client
            .from('transactions')
            .select('id, status')
            .inFilter('status', const ['active', 'partial_return', 'overdue']),
      ]);
      final builders = <String, _ItemBuilder>{};
      var toolsBorrowed = 0, materialsIssued = 0;
      for (final raw
          in (results[1] as List).whereType<Map<String, dynamic>>()) {
        final code = raw['transaction_code']?.toString() ?? '';
        final borrower = raw['borrower_name']?.toString() ?? '';
        final createdAt = DateTime.tryParse(
          raw['created_at']?.toString() ?? '',
        );
        final lines = raw['transaction_items'] as List<dynamic>? ?? const [];
        for (final line in lines.whereType<Map<String, dynamic>>()) {
          final item = line['items'] as Map<String, dynamic>? ?? const {};
          final itemId = line['item_id'];
          if (itemId == null) continue;
          final type =
              line['item_type']?.toString() ??
              item['item_type']?.toString() ??
              '';
          if (!const ['tool', 'equipment', 'material'].contains(type)) continue;
          final quantity = _integer(line['quantity']);
          final returned = _integer(line['returned_quantity']);
          type == 'material'
              ? materialsIssued += quantity
              : toolsBorrowed += quantity;
          builders
              .putIfAbsent(
                itemId.toString(),
                () => _ItemBuilder(
                  itemId: itemId as Object,
                  productName:
                      item['product_name']?.toString() ?? 'Unknown item',
                  itemType: type,
                  unit: item['unit']?.toString() ?? '',
                  currentAvailable: _integer(item['available_stock']),
                  imagePath: item['image_path']?.toString(),
                ),
              )
              .add(
                quantity: quantity,
                returned: returned,
                due: DateTime.tryParse(
                  line['expected_return_at']?.toString() ?? '',
                ),
                transactionCode: code,
                borrowerName: borrower,
                createdAt: createdAt,
              );
        }
      }
      final totalReturned = (results[2] as List)
          .whereType<Map<String, dynamic>>()
          .fold<int>(0, (sum, row) => sum + _integer(row['quantity_returned']));
      final overdue = (results[3] as List)
          .whereType<Map<String, dynamic>>()
          .where(
            (row) =>
                _integer(row['quantity']) - _integer(row['returned_quantity']) >
                0,
          )
          .length;
      final items = builders.values.map((value) => value.build()).toList()
        ..sort((a, b) => a.productName.compareTo(b.productName));
      return MonthlyReport(
        month: start,
        items: List.unmodifiable(items),
        summary: ReportSummary(
          totalItems: (results[0] as List).length,
          toolsBorrowed: toolsBorrowed,
          materialsIssued: materialsIssued,
          totalReturned: totalReturned,
          overdueItems: overdue,
          activeTransactions: (results[4] as List).length,
        ),
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('REPORT SUPABASE ERROR: ${error.message}');
      debugPrint('REPORT SUPABASE CODE: ${error.code}');
      debugPrint('$stackTrace');
      throw const MonthlyReportException('Unable to load report data.');
    } catch (error, stackTrace) {
      debugPrint('REPORT ERROR: $error');
      debugPrint('$stackTrace');
      throw const MonthlyReportException(
        'Unable to connect. Check your internet connection.',
      );
    }
  }
}

class _ItemBuilder {
  _ItemBuilder({
    required this.itemId,
    required this.productName,
    required this.itemType,
    required this.unit,
    required this.currentAvailable,
    this.imagePath,
  });
  final Object itemId;
  final String productName, itemType, unit;
  final int currentAvailable;
  final String? imagePath;
  int issued = 0, returned = 0;
  bool overdue = false;
  final history = <ReportTransactionEntry>[];

  void add({
    required int quantity,
    required int returned,
    required DateTime? due,
    required String transactionCode,
    required String borrowerName,
    required DateTime? createdAt,
  }) {
    issued += quantity;
    this.returned += returned;
    final remaining = (quantity - returned).clamp(0, quantity);
    final isOverdue =
        itemType != 'material' &&
        remaining > 0 &&
        due != null &&
        due.isBefore(DateTime.now());
    overdue = overdue || isOverdue;
    history.add(
      ReportTransactionEntry(
        transactionCode: transactionCode,
        borrowerName: borrowerName,
        quantity: quantity,
        returnedQuantity: returned,
        createdAt: createdAt,
        status: _lineStatus(itemType, quantity, returned, isOverdue),
      ),
    );
  }

  MonthlyItemReport build() {
    final remaining = itemType == 'material'
        ? 0
        : (issued - returned).clamp(0, issued);
    final status = itemType == 'material'
        ? ReportItemStatus.noReturnRequired
        : overdue
        ? ReportItemStatus.overdue
        : returned == issued
        ? ReportItemStatus.returned
        : returned > 0
        ? ReportItemStatus.partial
        : ReportItemStatus.active;
    return MonthlyItemReport(
      itemId: itemId,
      productName: productName,
      itemType: itemType,
      unit: unit,
      currentAvailable: currentAvailable,
      borrowedOrIssued: issued,
      returned: returned,
      remaining: remaining,
      status: status,
      history: List.unmodifiable(history),
      imagePath: imagePath,
    );
  }
}

ReportItemStatus _lineStatus(
  String type,
  int quantity,
  int returned,
  bool overdue,
) {
  if (type == 'material') return ReportItemStatus.noReturnRequired;
  if (overdue) return ReportItemStatus.overdue;
  if (quantity - returned <= 0) return ReportItemStatus.returned;
  if (returned > 0) return ReportItemStatus.partial;
  return ReportItemStatus.active;
}

int _integer(dynamic value) => value is num ? value.toInt() : 0;
