import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ActionTrigger {
  final String? component;
  final String? element;
  final String? errorCode;

  const ActionTrigger({this.component, this.element, this.errorCode});

  factory ActionTrigger.fromMap(Map<String, dynamic> map) => ActionTrigger(
    component: map.tryGetString('component'),
    element: map.tryGetString('element'),
    errorCode: map.tryGetString('error_code'),
  );
}