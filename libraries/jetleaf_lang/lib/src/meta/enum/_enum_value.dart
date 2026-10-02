part of 'enum_value.dart';

final class _EnumValue extends PermissionManager with EqualsAndHashCode implements EnumValue {
  final EnumDeclaration _parent;
  final EnumFieldDeclaration _field;
  final ProtectionDomain _pd;

  _EnumValue(this._parent, this._field, [ProtectionDomain? pd]) : _pd = pd ?? ProtectionDomain.current();

  @override
  EnumDeclaration getDeclaration() {
    checkAccess('getDeclaration', DomainPermission.READ_FIELDS);

    return _parent;
  }

  @override
  Class<D> getDeclaringClass<D>() {
    checkAccess('getDeclaringClass', DomainPermission.READ_FIELDS);

    return Class<D>.declared(_parent, _pd);
  }

  @override
  Version getVersion() => getDeclaringClass().getVersion();

  @override
  EnumFieldDeclaration getFieldDeclaration() {
    checkAccess('getFieldDeclaration', DomainPermission.READ_FIELDS);

    return _field;
  }

  @override
  String getName() {
    checkAccess('getName', DomainPermission.READ_FIELDS);
    return _field.getName();
  }

  @override
  int getPosition() {
    checkAccess('getPosition', DomainPermission.READ_FIELDS);

    return _field.getPosition();
  }

  @override
  ProtectionDomain getProtectionDomain() => _pd;

  @override
  dynamic getValue() {
    checkAccess('getValue', DomainPermission.READ_FIELDS);
    return _field.getEnumValue();
  }

  @override
  bool isNullable() {
    checkAccess('isNullable', DomainPermission.READ_FIELDS);

    return _field.isNullable();
  }

  @override
  String getSignature() {
    checkAccess('getSignature', DomainPermission.READ_FIELDS);
    final modifiers = <String>[];
    
    if (isNullable()) modifiers.add('static');
    modifiers.add(getPosition().toString());
    
    final modifierStr = modifiers.isEmpty ? '' : '${modifiers.join(' ')} ';
    return '$modifierStr${getClass().getName()} ${getName()}';
  }

  @override
  Author? getAuthor() {
    checkAccess("getAuthor", DomainPermission.READ_TYPE_INFO);

    final field = Field.declared(_field, _parent, _pd);
    return field.getAuthor();
  }

  @override
  List<Object?> equalizedProperties() {
    return [
      _field.getName(),
      getSignature(),
      _field.getIsPublic(),
      _field.getIsSynthetic(),
      _field.getType(),
    ];
  }

  @override
  String toString() => "${_parent.getName()}.${_field.getName()}";
}