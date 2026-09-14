import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_system/functions/returns/partial_return_function.dart';
import 'package:warehouse_system/functions/returns/verify_return_function.dart';
import 'package:warehouse_system/functions/transactions/transaction_details_function.dart';
import 'package:warehouse_system/widgets/modals/return_code_modal.dart';

void main() {
  const item = TransactionLineDetails(
    id: 'line-1',
    itemId: 'item-1',
    productName: 'Hammer',
    itemType: 'tool',
    unit: 'pcs',
    quantity: 5,
    returnedQuantity: 1,
    status: 'partial_return',
  );

  test('return validation accepts partial and rejects over-return', () {
    expect(
      VerifyReturnFunction.validate(
        items: const [item],
        quantities: const {'line-1': 2},
      ),
      isNull,
    );
    expect(
      VerifyReturnFunction.validate(
        items: const [item],
        quantities: const {'line-1': 5},
      ),
      'Only 4 item(s) remain to be returned.',
    );
    expect(
      VerifyReturnFunction.validate(
        items: const [item],
        quantities: const {'line-1': 0},
      ),
      'Select at least one item to return.',
    );
  });

  test('success copy distinguishes partial and completed returns', () {
    expect(PartialReturnFunction.isComplete('completed'), isTrue);
    expect(
      PartialReturnFunction.successMessage('partial_return'),
      contains('Remaining items can be returned later'),
    );
  });

  testWidgets('reusable Return Items code modal opens and closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showReturnCodeModal(context),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Enter the transaction code for the items being returned.'),
      findsOneWidget,
    );
    expect(find.text('CONTINUE TO RETURN'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('CONTINUE TO RETURN'), findsNothing);
  });
}
