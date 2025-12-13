// ==========================================
// [DEBUG] GENERATION CONTEXT
// ==========================================
// baseDef: {
//   type: "UnaryUsecase"
//   types: [List, length: 1]
//   import: "package:clean_feature_first/core/usecase/usecase.dart"
//   imports: [List, length: 1]
//   ref: "null"
//   component: "null"
//   isWildcard: "false"
// }
// baseClassName: "UnaryUsecase"
// methodReturnType: "FutureEither<User>"
// usecaseGenericType: "User"
// usecaseName: "Login"
// repoName: "AuthPort"
// repoVar: "_authPort"
// paramsClassName: "_LoginParams"
// imports: {
//   items: [List, length: 7]
//   length: "7"
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
//   hasMany: "true"
//   isSingle: "false"
//   isEmpty: "false"
//   type: "_LoginParams"
//   argument: "_LoginParams params"
//   data: {
//     items: [List, length: 2]
//     length: "2"
//     isEmpty: "false"
//     isNotEmpty: "true"
//     hasMany: "true"
//     isSingle: "false"
//   }
// }
// classGenerics: "User, _LoginParams"
// source: <SourceWrapper>
// ==========================================


import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:injectable/injectable.dart';

typedef _LoginParams = ({
  String username,
  String password,
});

@Injectable()
class LoginUseCase implements UnaryUsecase<User, _LoginParams> {
  final AuthPort _authPort;

  const LoginUseCase(this._authPort);

  @override
  FutureEither<User> call(_LoginParams params) {
    return _authPort.login(



      params.username,

      params.password,

    );
  }
}