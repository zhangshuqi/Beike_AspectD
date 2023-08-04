import 'annotation_info.dart';

/// Call grammar is working on those callsites for the annotated method.
@pragma('vm:entry-point')
class Call extends AnnotationInfo {
  /// Call grammar default constructor.
  const factory Call(String importUri, String clsName, String methodName,
      {bool isRegex, bool excludeCoreLib}) = Call._;

  @pragma('vm:entry-point')
  const Call._(String importUri, String clsName, String methodName,
      {bool? isRegex,this.excludeCoreLib})
      : super(
            importUri: importUri,
            clsName: clsName,
            methodName: methodName,
            isRegex: isRegex);

  /// Indicate whether to exclude flutter libs
  final bool ? excludeCoreLib;

}
