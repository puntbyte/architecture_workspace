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
// usecaseName: "CurrentUser"
// repoName: "AuthPort"
// repoVar: "_authPort"
// paramsClassName: "_CurrentUserParams"
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
//   hasMany: "false"
//   isSingle: "true"
//   isEmpty: "false"
//   type: "IntId"
//   argument: "IntId id"
//   data: {
//     items: [List, length: 1]
//     length: "1"
//     isEmpty: "false"
//     isNotEmpty: "true"
//     hasMany: "false"
//     isSingle: "true"
//   }
// }
// classGenerics: "User, IntId"
// source: <SourceWrapper>
// ==========================================


import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';


@Injectable()
class CurrentUserUseCase implements UnaryUsecase<User, IntId> {
  final AuthPort _authPort;

  const CurrentUserUseCase(this._authPort);

  @override
  FutureEither<User> call(IntId id) {
    return _authPort.currentUser(

      id



    );
  }
}