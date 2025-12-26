import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class MovieDetailCastSection extends StatelessWidget {
  const MovieDetailCastSection({super.key, required this.cast});
  final List<MoviPerson> cast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 286,
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.only(start: 20, end: 12),
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final p = cast[index];
          return MoviPersonCard(
            person: p,
            onTap: (person) {
              final personSummary = PersonSummary(
                id: PersonId(person.id),
                name: person.name,
                role: person.role,
                photo: person.poster,
              );
              context.push(AppRouteNames.person, extra: personSummary);
            },
          );
        },
      ),
    );
  }
}
