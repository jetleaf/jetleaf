// test/support/test_entities.dart
//
// Entities used by the jetleaf_data test suite. These classes are picked up
// by `jl build --test` and registered in the test AOT registry, which is why
// tests can reflect over them with `Class<T>()`.

import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

@Entity()
@Table(name: 'users')
class TestUser {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.autoIncrement)
  int? id;

  @Column(name: 'email_address', nullable: false, unique: true, length: 320)
  String? email;

  String? firstName;
  String? lastName;

  @Column(name: 'user_age')
  int? age;

  @Column(name: 'is_active')
  bool? active;

  @CreatedDate()
  DateTime? createdAt;

  @LastModifiedDate()
  DateTime? updatedAt;

  @DataVersion()
  int? version;

  TestUser();

  TestUser.withValues({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.age,
    this.active,
    this.createdAt,
    this.updatedAt,
    this.version,
  });
}

@Entity()
@Table(name: 'profiles')
class TestProfile {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.uuid)
  String? id;

  String? bio;
  String? website;

  TestProfile();
}

@Entity()
@Table(name: 'accounts')
class TestAccount {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.uuid)
  String? id;

  String? handle;

  @OneToOne(targetEntity: ClassType<TestProfile>(), cascade: [CascadeType.all])
  TestProfile? profile;

  TestAccount();
}

@Entity()
@Table(name: 'orders')
class TestOrder {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.snowflake)
  int? id;

  int? totalCents;
  String? reference;

  @ManyToOne(joinColumn: 'owner_id')
  TestUser? owner;

  TestOrder();
}

enum TestStatus { active, inactive, banned }

@Entity()
@Table(name: 'products')
@Indexes([
  Index(columnList: 'sku', unique: true),
  Index(name: 'idx_products_name', columnList: 'name'),
])
class TestProduct {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.autoIncrement)
  int? id;

  String? name;
  TestStatus? status;
  String? sku;

  TestProduct();
}

@Entity()
class TestUuidEntity {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.uuid)
  String? id;

  String? label;

  TestUuidEntity();
}

@Entity()
class TestParentRow {
  @Id()
  String? id;

  @DataVersion()
  int? version;

  String? payload;

  TestParentRow();
}
