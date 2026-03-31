import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class MovieDetailCastSection extends ConsumerWidget {
  const MovieDetailCastSection({
    super.key,
    required this.cast,
    this.horizontalPadding = 20,
  });
  final List<MoviPerson> cast;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: MoviPersonCard.listHeight,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: EdgeInsetsDirectional.only(
          start: horizontalPadding,
          end: horizontalPadding,
        ),
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
              navigateToPersonDetail(context, ref, person: personSummary);
            },
          );
        },
      ),
    );
  }
}
