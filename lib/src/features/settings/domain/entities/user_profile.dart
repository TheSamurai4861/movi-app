import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.subscriptionPlan,
  });

  final String id;
  final String name;
  final String? email;
  final Uri? avatar;
  final String? subscriptionPlan;

  @override
  List<Object?> get props => [id, name, email, avatar, subscriptionPlan];
}
