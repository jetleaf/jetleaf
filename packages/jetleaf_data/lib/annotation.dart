// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

/// 🏷 **JetLeaf Data Annotations Library**
///
/// Provides declarative annotations for entity mapping, auditing, indexing,
/// relationships, custom queries, and transaction boundaries:
/// - **Entity & Schema**: `@Entity`, `@Table`, `@Column`, `@Transient`
/// - **Primary Keys**: `@Id`, `@GeneratedValue`, `GenerationStrategy`
/// - **Indexes**: `@Index`, `@Indexes`
/// - **Auditing & Locking**: `@CreatedDate`, `@LastModifiedDate`,
///   `@CreatedBy`, `@LastModifiedBy`, `@DataVersion`
/// - **Relationships**: `@OneToOne`, `@OneToMany`, `@ManyToOne`, `@ManyToMany`
/// - **Querying**: `@Query`, `@Modifying`, `@Param`
/// - **Transactions**: `@Transactional`, `Propagation`, `Isolation`
/// - **Repository Stereotype**: `@Repository` (re-exported from `jetleaf_core`)
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/annotation.dart';
///
/// @Entity()
/// @Table(name: 'users')
/// class User {
///   @Id()
///   @GeneratedValue(strategy: GenerationStrategy.uuid)
///   String? id;
///
///   @Column(nullable: false, unique: true)
///   String? email;
///
///   @CreatedDate()
///   DateTime? createdAt;
/// }
/// ```
library;

export 'package:jetleaf_core/core.dart' show Repository;

export 'src/annotation/auditing.dart';
export 'src/annotation/entity.dart';
export 'src/annotation/id.dart';
export 'src/annotation/index.dart';
export 'src/annotation/query.dart';
export 'src/annotation/relationships.dart';
export 'src/annotation/transactional.dart';