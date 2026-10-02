part of 'record_field.dart';

final class _RecordField extends PermissionManager implements RecordField {
  final RecordFieldDeclaration _fieldDeclaration;
  final RecordDeclaration _parent;
  final ProtectionDomain _pd;

  _RecordField(this._fieldDeclaration, this._parent, this._pd);

  @override
  LinkDeclaration getDeclaration() {
    checkAccess("getDeclaration", DomainPermission.READ_TYPE_INFO);
    return _fieldDeclaration.getLinkDeclaration();
  }

  @override
  String getName() {
    checkAccess("getName", DomainPermission.READ_TYPE_INFO);
    return _fieldDeclaration.getName();
  }

  @override
  Version getVersion() => getReturnClass().getVersion();

  @override
  ProtectionDomain getProtectionDomain() => _pd;

  @override
  Class<Object> getReturnClass() {
    checkAccess("getReturnClass", DomainPermission.READ_TYPE_INFO);
    return LangUtils.obtainClassFromLink(_fieldDeclaration.getLinkDeclaration());
  }

  @override
  Type getReturnType() {
    checkAccess("getReturnType", DomainPermission.READ_TYPE_INFO);
    return getReturnClass().getType();
  }

  @override
  bool isPositional() {
    checkAccess("isPositional", DomainPermission.READ_TYPE_INFO);
    return _fieldDeclaration.getIsPositional();
  }

  @override
  int position() {
    checkAccess("position", DomainPermission.READ_TYPE_INFO);
    return _fieldDeclaration.getPosition();
  }
  
  @override
  RecordFieldDeclaration getFieldDeclaration() {
    checkAccess("getFieldDeclaration", DomainPermission.READ_TYPE_INFO);
    return _fieldDeclaration;
  }

  @override
  RecordDeclaration getParent() {
    checkAccess("getParent", DomainPermission.READ_TYPE_INFO);
    return _parent;
  }

  @override
  Author? getAuthor() {
    checkAccess("getAuthor", DomainPermission.READ_TYPE_INFO);
    return null;
  }
}