import 'package:equatable/equatable.dart';

/// User model representing a user in the system
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  final String id;
  final String email;
  final String role;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [id, email, role];
}
