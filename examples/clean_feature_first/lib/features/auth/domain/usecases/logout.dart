// ==========================================
// [DEBUG] GENERATION CONTEXT
// ==========================================
// baseDef: {
//   type: "NullaryUsecase"
//   types: [List, length: 1]
//   import: "package:clean_feature_first/core/usecase/usecase.dart"
//   imports: [List, length: 1]
//   ref: "null"
//   component: "null"
//   isWildcard: "false"
// }
// baseClassName: "NullaryUsecase"
// methodReturnType: "FutureEither<void>"
// usecaseGenericType: "void"
// usecaseName: "Logout"
// repoName: "AuthPort"
// repoVar: "_authPort"
// paramsClassName: "_LogoutParams"
// imports: {
//   items: [List, length: 5]
//   length: "5"
//   isEmpty: "false"
//   isNotEmpty: "true"
//   hasMany: "true"
//   isSingle: "false"
// }
// requiredAnnotations: {
//   items: [List, length: 1]
//   length: "1"
//   isEmpty: "false"
//   isNotEmpty: "true"
//   hasMany: "false"
//   isSingle: "true"
// }
// params: {
//   hasMany: "false"
//   isSingle: "false"
//   isEmpty: "true"
//   type: "void"
//   argument: ""
//   data: {
//     items: [List, length: 0]
//     length: "0"
//     isEmpty: "true"
//     isNotEmpty: "false"
//     hasMany: "false"
//     isSingle: "false"
//   }
// }
// classGenerics: "void"
// source: <SourceWrapper>
// ==========================================


import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';


@Injectable()
class LogoutUseCase implements NullaryUsecase<void> {
  final AuthPort _authPort;

  const LogoutUseCase(this._authPort);

  @override
  FutureEither<void> call() {
    return _authPort.logout(



    );
  }
}