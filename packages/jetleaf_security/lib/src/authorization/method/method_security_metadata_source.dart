import 'package:jetleaf_core/lang.dart';

import '../../annotation/security_annotations.dart';

/// {@template method_security_metadata_source}
/// Discovers the security attributes that apply to a method and its class.
///
/// Implementations turn reflection metadata into the annotation objects that
/// the method security interceptors understand. The default implementation
/// reads Jetleaf security annotations from both the declaring class and the
/// method itself.
///
/// ### Contract
/// - Return every applicable attribute, never `null`; use an empty list when a
///   method has no security metadata.
/// - Order is significant: callers evaluate attributes in the order returned,
///   so each implementation should document its own precedence rules.
/// - Implementations must be side-effect free, because the same method may be
///   inspected on every invocation.
/// - Duplicate attributes are allowed and are checked independently.
///
/// ### Implementer guidance
/// Extract attributes from the reflected [Method] and its declaring class,
/// normalize them into the annotation types understood by the interceptors,
/// and keep the returned list immutable where practical. Filter out any
/// metadata that does not represent an authorization rule.
///
/// ### Example
/// ```dart
/// final class MyMetadataSource implements MethodSecurityMetadataSource {
///   const MyMetadataSource();
///
///   @override
///   List<Object> getAttributes(Method method) {
///     final annotation = method.getDirectAnnotation<PreAuthorize>();
///     return annotation == null ? const [] : [annotation];
///   }
/// }
/// ```
///
/// ### See also
/// - [PrePostAnnotationSecurityMetadataSource]
/// - [Method]
/// {@endtemplate}
abstract interface class MethodSecurityMetadataSource {
  /// {@template method_security_metadata_source_get_attributes}
  /// Returns all security attributes applying to [method], including both
  /// method-level and class-level declarations.
  ///
  /// ### Parameters
  /// - [method]: the reflected method whose metadata is inspected.
  ///
  /// ### Returns
  /// An ordered list of attributes; an empty list when none apply. Implementers
  /// must not return `null`.
  /// {@endtemplate}
  List<Object> getAttributes(Method method);
}

/// {@template pre_post_annotation_security_metadata_source}
/// Reads `PreAuthorize`, `PostAuthorize`, `Secured`, and `RolesAllowed` from
/// both the method and its declaring class via Jetleaf reflection.
///
/// Class-level attributes are collected first and method-level attributes are
/// appended after them, giving method declarations precedence. Only annotations
/// that are actually present are included; missing ones are skipped.
///
/// ### Contract and invariants
/// - The returned list contains only non-`null` annotation instances.
/// - Each supported annotation type is read at most once per declaration.
/// - Reflection reads use the AOT metadata emitted by `jl build`.
///
/// ### Example
/// ```dart
/// const source = PrePostAnnotationSecurityMetadataSource();
/// final attributes = source.getAttributes(method);
/// ```
///
/// ### See also
/// - [MethodSecurityMetadataSource]
/// {@endtemplate}
final class PrePostAnnotationSecurityMetadataSource implements MethodSecurityMetadataSource {
  /// {@macro pre_post_annotation_security_metadata_source}
  const PrePostAnnotationSecurityMetadataSource();

  /// {@template pre_post_annotation_security_metadata_source_get_attributes}
  /// Collects the supported annotations declared on the class and method.
  ///
  /// Class-level attributes are added first in the order `PreAuthorize`,
  /// `PostAuthorize`, `Secured`, `RolesAllowed`; method-level attributes follow
  /// in the same order.
  ///
  /// ### Parameters
  /// - [method]: the reflected method to inspect.
  ///
  /// ### Returns
  /// The ordered attributes applying to [method], possibly empty.
  /// {@endtemplate}
  @override
  List<Object> getAttributes(Method method) {
    final attributes = <Object>[];
    final declaration = method.getDeclaringClass();

    _add(attributes, declaration.getDirectAnnotation<PreAuthorize>());
    _add(attributes, declaration.getDirectAnnotation<PostAuthorize>());
    _add(attributes, declaration.getDirectAnnotation<Secured>());
    _add(attributes, declaration.getDirectAnnotation<RolesAllowed>());

    _add(attributes, method.getDirectAnnotation<PreAuthorize>());
    _add(attributes, method.getDirectAnnotation<PostAuthorize>());
    _add(attributes, method.getDirectAnnotation<Secured>());
    _add(attributes, method.getDirectAnnotation<RolesAllowed>());

    return attributes;
  }

  /// {@template pre_post_annotation_security_metadata_source_add}
  /// Appends [annotation] to [attributes] when it is present.
  ///
  /// ### Parameters
  /// - [attributes]: the accumulating attribute list.
  /// - [annotation]: a discovered annotation, or `null` when absent.
  /// {@endtemplate}
  static void _add(List<Object> attributes, Object? annotation) {
    if (annotation != null) attributes.add(annotation);
  }
}
