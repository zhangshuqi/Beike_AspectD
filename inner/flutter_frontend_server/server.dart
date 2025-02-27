// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide FileSystemEntity;

import 'package:args/args.dart';
import 'package:frontend_server/frontend_server.dart' as frontend
    show
        FrontendCompiler,
        CompilerInterface,
        listenAndCompile,
        argParser,
        usage,
        ProgramTransformer;
import 'package:kernel/ast.dart';
import 'package:path/path.dart' as path;
import 'package:vm/incremental_compiler.dart';
import 'package:vm/target/flutter.dart';

import '../transformer/plugins/aop/aop_transformer_wrapper.dart';

/// Wrapper around [FrontendCompiler] that adds [widgetCreatorTracker] kernel
/// transformation to the compilation.
class _FlutterFrontendCompiler implements frontend.CompilerInterface {

  _FlutterFrontendCompiler(StringSink? output,
      {bool? unsafePackageSerialization,
        bool? useDebuggerModuleNames,
        bool? emitDebugMetadata,
       frontend.ProgramTransformer? transformer,
        this.aopTransform = false})
      : _compiler = frontend.FrontendCompiler(output,
            transformer: transformer,
            unsafePackageSerialization: unsafePackageSerialization);
  final frontend.CompilerInterface _compiler;

  final AopWrapperTransformer aspectdAopTransformer = AopWrapperTransformer();
  final bool aopTransform;

  @override
  Future<bool> compile(String filename, ArgResults options,
      {IncrementalCompiler? generator}) async {
    print('aop: need perform ' + aopTransform.toString());

    if (aopTransform == true &&
        !FlutterTarget.flutterProgramTransformers
            .contains(aspectdAopTransformer)) {
      FlutterTarget.flutterProgramTransformers.add(aspectdAopTransformer);
    }

    return _compiler.compile(filename, options, generator: generator);
  }

  @override
  Future<void> recompileDelta({String? entryPoint}) async {
    final List<FlutterProgramTransformer> transformers =
        FlutterTarget.flutterProgramTransformers;
    transformers.clear();

    return _compiler.recompileDelta(entryPoint: entryPoint);
  }

  @override
  void acceptLastDelta() {
    _compiler.acceptLastDelta();
  }

  @override
  Future<void> rejectLastDelta() async {
    return _compiler.rejectLastDelta();
  }

  @override
  void invalidate(Uri uri) {
    _compiler.invalidate(uri);
  }

  @override
  Future<void> compileExpression(
      String expression,
      List<String> definitions,
      List<String> definitionTypes,
      List<String> typeDefinitions,
      List<String> typeBounds,
      List<String> typeDefaults,
      String libraryUri,
      String? klass,
      String? method,
      bool isStatic) {
    return _compiler.compileExpression(
        expression,
        definitions,
        definitionTypes,
        typeDefinitions,
        typeBounds,
        typeDefaults,
        libraryUri,
        klass,
        method,
        isStatic);
  }

  @override
  Future<void> compileExpressionToJs(
      String libraryUri,
      int line,
      int column,
      Map<String, String> jsModules,
      Map<String, String> jsFrameValues,
      String moduleName,
      String expression) {
    return _compiler.compileExpressionToJs(libraryUri, line, column, jsModules,
        jsFrameValues, moduleName, expression);
  }

  @override
  void reportError(String msg) {
    _compiler.reportError(msg);
  }

  @override
  void resetIncrementalCompiler() {
    _compiler.resetIncrementalCompiler();
  }

  @override
  Future<bool> setNativeAssets(String nativeAssets) {
    return _compiler.setNativeAssets(nativeAssets);
  }
}

/// Entry point for this module, that creates `_FrontendCompiler` instance and
/// processes user input.
/// `compiler` is an optional parameter so it can be replaced with mocked
/// version for testing.
Future<int> starter(
  List<String> args, {
  frontend.CompilerInterface? compiler,
  Stream<List<int>>? input,
  StringSink? output,
  frontend.ProgramTransformer? transformer,
}) async {
  ArgResults options;

  try {
    final ArgParser parser = frontend.argParser;
    parser.addOption('aop', help: 'aop transform');
    options = parser.parse(args);
  } catch (error) {
    print('ERROR: $error\n');
    print(frontend.usage);
    return 1;
  }

  final Set<String> deleteToStringPackageUris =
      (options['delete-tostring-package-uri'] as List<String>).toSet();

  if (options['train'] as bool) {
    if (!options.rest.isNotEmpty) {
      throw Exception('Must specify input.dart');
    }

    final String input = options.rest[0];
    final String sdkRoot = options['sdk-root'] as String;
    final Directory temp =
        Directory.systemTemp.createTempSync('train_frontend_server');
    try {
      for (int i = 0; i < 3; i++) {
        final String outputTrainingDill = path.join(temp.path, 'app.dill');
        options = frontend.argParser.parse(<String>[
          '--incremental',
          '--sdk-root=$sdkRoot',
          '--output-dill=$outputTrainingDill',
          '--target=flutter',
          '--track-widget-creation',
          '--enable-asserts',
          '--gen-bytecode',
          '--bytecode-options=source-positions,local-var-info,debugger-stops,instance-field-initializers,keep-unreachable-code,avoid-closure-call-instructions',
        ]);
        compiler ??= _FlutterFrontendCompiler(
          output,
          transformer: ToStringTransformer(transformer, deleteToStringPackageUris),
        );

        await compiler.compile(input, options);
        compiler.acceptLastDelta();
        await compiler.recompileDelta();
        compiler.acceptLastDelta();
        compiler.resetIncrementalCompiler();
        await compiler.recompileDelta();
        compiler.acceptLastDelta();
        await compiler.recompileDelta();
        compiler.acceptLastDelta();
      }
      return 0;
    } finally {
      temp.deleteSync(recursive: true);
    }
  }

  compiler ??= _FlutterFrontendCompiler(output,
      transformer: ToStringTransformer(transformer, deleteToStringPackageUris),
      useDebuggerModuleNames: options['debugger-module-names'] as bool,
      emitDebugMetadata: options['experimental-emit-debug-metadata'] as bool,
      unsafePackageSerialization:
          options['unsafe-package-serialization'] as bool,
      aopTransform: options['aop'].toString() == '1' ? true : false);

  if (options.rest.isNotEmpty) {
    return await compiler.compile(options.rest[0], options) ? 0 : 254;
  }

  final Completer<int> completer = Completer<int>();
  frontend.listenAndCompile(compiler, input ?? stdin, options, completer);
  return completer.future;
}

// Transformer/visitor for toString
// If we add any more of these, they really should go into a separate library.

/// A [RecursiveVisitor] that replaces [Object.toString] overrides with
/// `super.toString()`.
class ToStringVisitor extends RecursiveVisitor<void> {
  /// The [packageUris] must not be null.
  ToStringVisitor(this._packageUris) : assert(_packageUris != null);

  /// A set of package URIs to apply this transformer to, e.g. 'dart:ui' and
  /// 'package:flutter/foundation.dart'.
  final Set<String> _packageUris;

  /// Turn 'dart:ui' into 'dart:ui', or
  /// 'package:flutter/src/semantics_event.dart' into 'package:flutter'.
  String _importUriToPackage(Uri importUri) =>
      '${importUri.scheme}:${importUri.pathSegments.first}';

  bool _isInTargetPackage(Procedure node) {
    return _packageUris
        .contains(_importUriToPackage(node.enclosingLibrary.importUri));
  }

  bool _hasKeepAnnotation(Procedure node) {
    for (ConstantExpression expression
        in node.annotations.whereType<ConstantExpression>()) {
      if (expression.constant is! InstanceConstant) {
        continue;
      }
      final InstanceConstant constant = expression.constant as InstanceConstant;
      if (constant.classNode.name == '_KeepToString' &&
          constant.classNode.enclosingLibrary.importUri.toString() ==
              'dart:ui') {
        return true;
      }
    }
    return false;
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.name.text == 'toString' &&
        node.enclosingClass != null &&
        node.enclosingLibrary != null &&
        !node.isStatic &&
        !node.isAbstract &&
        !node.enclosingClass!.isEnum &&
        _isInTargetPackage(node) &&
        !_hasKeepAnnotation(node)) {
      node.function.body?.replaceWith(
        ReturnStatement(
          SuperMethodInvocation(
            node.name,
            Arguments(<Expression>[]),node
          ),
        ),
      );
    }
  }

  @override
  void defaultMember(Member node) {}
}

/// Replaces [Object.toString] overrides with calls to super for the specified
/// [packageUris].
class ToStringTransformer extends frontend.ProgramTransformer {
  /// The [packageUris] parameter must not be null, but may be empty.
  ToStringTransformer(this._child, this._packageUris)
      : assert(_packageUris != null);

  final frontend.ProgramTransformer? _child;

  /// A set of package URIs to apply this transformer to, e.g. 'dart:ui' and
  /// 'package:flutter/foundation.dart'.
  final Set<String> _packageUris;

  @override
  void transform(Component component) {
    assert(_child is! ToStringTransformer);
    if (_packageUris.isNotEmpty) {
      component.visitChildren(ToStringVisitor(_packageUris));
    }
    _child?.transform(component);
  }
}
