import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/application/services/player_resume_orchestrator.dart';

void main() {
  group('PlayerResumeOrchestrator', () {
    test(
      'n\'est validé qu\'après confirmation de position proche de la cible',
      () async {
        final seeks = <Duration>[];
        final telemetry = <String>[];
        final orchestrator = PlayerResumeOrchestrator(
          requestedResume: const Duration(seconds: 30),
          seekTo: (position) async {
            seeks.add(position);
          },
          telemetry: (result, _) => telemetry.add(result),
        );

        await orchestrator.onDuration(const Duration(minutes: 5));

        expect(seeks, <Duration>[const Duration(seconds: 30)]);
        expect(orchestrator.isDone, isFalse);
        expect(telemetry, contains('seek_issued'));

        await orchestrator.onPosition(const Duration(seconds: 3));
        expect(orchestrator.isDone, isFalse);

        await orchestrator.onPosition(const Duration(seconds: 31));
        expect(orchestrator.isDone, isTrue);
        expect(telemetry.last, 'applied_confirmed');
      },
    );

    test('relance un seek si la position retombe au début après reprise', () async {
      final seeks = <Duration>[];
      final telemetry = <String>[];
      final orchestrator = PlayerResumeOrchestrator(
        requestedResume: const Duration(seconds: 45),
        seekTo: (position) async {
          seeks.add(position);
        },
        telemetry: (result, _) => telemetry.add(result),
      );

      await orchestrator.onDuration(const Duration(minutes: 8));
      await orchestrator.onPosition(Duration.zero);
      await orchestrator.onPosition(const Duration(seconds: 45));

      expect(
        seeks,
        <Duration>[
          const Duration(seconds: 45),
          const Duration(seconds: 45),
        ],
      );
      expect(orchestrator.isDone, isTrue);
      expect(telemetry, contains('applied_confirmed'));
    });

    test('ignore la reprise quand aucune position valide n\'est demandée', () async {
      final seeks = <Duration>[];
      final telemetry = <String>[];
      final orchestrator = PlayerResumeOrchestrator(
        requestedResume: Duration.zero,
        seekTo: (position) async {
          seeks.add(position);
        },
        telemetry: (result, _) => telemetry.add(result),
      );

      await orchestrator.onDuration(const Duration(minutes: 2));

      expect(seeks, isEmpty);
      expect(orchestrator.isDone, isTrue);
      expect(telemetry.last, 'skip_no_resume');
    });
  });
}
