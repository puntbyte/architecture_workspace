// lib/src/constants/config_keys.dart

abstract class ConfigKeys {
  const ConfigKeys._();

  static const String configFilename = 'architecture.yaml';

  static const root = _RootKeys();
  static const typeDef = _TypeDefinitionKeys();
  static const component = _ComponentKeys();
  static const dependency = _DependencyKeys();
  static const inheritance = _InheritanceKeys();
  static const placeholder = _PlaceholderKeys();
}

class _RootKeys {
  const _RootKeys();

  String get components => 'components';
  String get types => 'types';
  String get dependencies => 'dependencies';
  String get inheritances => 'inheritances';
}

/// There are common keys used redundantly in multiple places.
abstract class _CommonKeys {
  static const name = 'name';
  static const path = 'path';
  static const on = 'on';
  static const required = 'required';
  static const allowed = 'allowed';
  static const forbidden = 'forbidden';

  const _CommonKeys._();
}

class _ComponentKeys {
  const _ComponentKeys();

  String get name => _CommonKeys.name;
  String get path => _CommonKeys.path;
  String get default$ => 'default';
  String get pattern => 'pattern';
  String get antipattern => 'antipattern';
}

class _TypeDefinitionKeys {
  const _TypeDefinitionKeys();
  String get type => 'type';
  String get import => 'import';
}

class _DependencyKeys {
  const _DependencyKeys();

  String get on => _CommonKeys.on;

  String get allowed => _CommonKeys.allowed;
  String get forbidden => _CommonKeys.forbidden;

  // Inside the detail object
  String get component => 'component';
  String get import => 'import';
}

class _InheritanceKeys {
  const _InheritanceKeys();

  String get on => _CommonKeys.on;

  String get required => _CommonKeys.required;
  String get allowed => _CommonKeys.allowed;
  String get forbidden => _CommonKeys.forbidden;

  // Fields inside the TypeReference
  String get type => 'type';
  String get import => 'import';
  String get definition => 'definition';
  String get component => 'component';
}

class _PlaceholderKeys {
  const _PlaceholderKeys();

  String get name => '{{name}}';
  String get affix => '{{affix}}';
}
