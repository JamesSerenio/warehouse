import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_system/widgets/custom_text_field.dart';

void main() {
  testWidgets('custom text field validates an empty username', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CustomTextField(
              controller: controller,
              label: 'Username',
              icon: Icons.person,
            ),
          ),
        ),
      ),
    );
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Please enter your username.'), findsOneWidget);
  });
}
