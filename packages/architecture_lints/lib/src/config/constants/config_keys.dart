// lib/src/constants/config_keys.dart

abstract class ConfigKeys {
  const ConfigKeys._();

  static const String configFilename = 'architecture.yaml';

  static const root = _RootKeys();
  static const component = _ComponentKeys();
  static const dependency = _DependencyKeys();
  static const placeholder = _PlaceholderKeys();
}

class _RootKeys {
  const _RootKeys();

  String get components => 'components';
  String get dependencies => 'dependencies';
}

/// There are common keys used redundantly in multiple places.
abstract class _CommonKeys {
  static const name = 'name';
  static const path = 'path';
  static const on = 'on';

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

class _DependencyKeys {
  const _DependencyKeys();

  String get on => _CommonKeys.on;

  String get allowed => 'allowed';
  String get forbidden => 'forbidden';

  // Inside the detail object
  String get component => 'component';
  String get import => 'import';
}

class _PlaceholderKeys {
  const _PlaceholderKeys();

  String get name => '{{name}}';
  String get affix => '{{affix}}';
}
