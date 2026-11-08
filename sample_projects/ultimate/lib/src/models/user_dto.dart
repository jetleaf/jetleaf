// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Domain Models and DTOs with Validation and Serialization Annotations
// ---------------------------------------------------------------------------

import 'package:jetleaf_core/format.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';
import 'package:jetson/jetson.dart';

class UserDto {
  @NotBlank(message: 'Full name cannot be blank')
  @Size(min: 3, max: 50, message: 'Name must be between 3 and 50 characters')
  @JsonField(name: 'full_name')
  final String fullName;

  @NotNull(message: 'Email must be provided')
  @Email(message: 'Must be a valid email address')
  @JsonField(name: 'email_address')
  final String email;

  @Positive(message: 'Age must be positive')
  @JsonField(name: 'age')
  final int age;

  @DateTimeFormat(pattern: 'yyyy-MM-dd')
  @JsonField(name: 'birth_date')
  final DateTime? birthDate;

  @NumberFormat(style: NumberFormatStyle.currency)
  @JsonField(name: 'credit_balance')
  final double balance;

  @JsonIgnore()
  final String internalToken;

  const UserDto({
    required this.fullName,
    required this.email,
    required this.age,
    this.birthDate,
    this.balance = 0.0,
    this.internalToken = 'secret-token-123',
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email_address': email,
    'age': age,
    'birth_date': birthDate?.toIso8601String(),
    'credit_balance': balance,
  };

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
    email: json['email_address'] as String? ?? json['email'] as String? ?? '',
    age: (json['age'] as num?)?.toInt() ?? 0,
    birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date'] as String) : null,
    balance: (json['credit_balance'] as num?)?.toDouble() ?? 0.0,
    internalToken: json['internalToken'] as String? ?? 'secret-token-123',
  );
}
