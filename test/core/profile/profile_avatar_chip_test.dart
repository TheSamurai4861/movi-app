import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/profile/presentation/ui/widgets/profile_avatar_chip.dart';

void main() {
  testWidgets('affiche icone par defaut sans avatarInitial', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatarChip(
            color: Colors.blue,
            label: 'Test',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('T'), findsNothing);
  });

  testWidgets('affiche initiale quand avatarInitial est fourni', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatarChip(
            color: Colors.blue,
            label: 'Marie',
            avatarInitial: 'marie',
            size: 75,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsNothing);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Marie'), findsOneWidget);
  });
}
