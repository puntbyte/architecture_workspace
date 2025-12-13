
part '${source.name.snakeCase}_model.freezed.dart';
part '${source.name.snakeCase}_model.g.dart';

@freezed
class ${source.name}Model with _$${source.name}Model {
const ${source.name}Model._();

const factory ${source.name}Model({
}) = _${source.name}Model;

factory ${source.name}Model.fromJson(Map<String, dynamic> json) =>
_$${source.name}ModelFromJson(json);

factory ${source.name}Model.fromEntity(source.name entity) {
return ${source.name}Model(
);
}

source.name toEntity() {
return source.name(
);
}
}