// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.obfuscation_prohibitions_annotator;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart' show Target;

import '../metadata/obfuscation_prohibitions.dart';
import 'pragma.dart';

void transformComponent(
    Component component, CoreTypes coreTypes, Target target) {
  final repo = new ObfuscationProhibitionsMetadataRepository();
  component.addMetadataRepository(repo);
  final visitor = ObfuscationProhibitionsVisitor(
      ConstantPragmaAnnotationParser(coreTypes, target));
  visitor.visitComponent(component);
  repo.mapping[component] = visitor.metadata;
}

class ObfuscationProhibitionsVisitor extends RecursiveVisitor {
  final PragmaAnnotationParser parser;
  final metadata = ObfuscationProhibitionsMetadata();

  ObfuscationProhibitionsVisitor(this.parser);

  void _checkAnnotations(
      List<Expression> annotations, String name, TreeNode node) {
    for (final annotation in annotations) {
      final pragma = parser.parsePragma(annotation);
      if (pragma is ParsedEntryPointPragma || pragma is ParsedKeepNamePragma) {
        metadata.protectedNames.add(name);
        if (node is Field) {
          metadata.protectedNames.add(name + "=");
        }
        final parent = node.parent;
        final Library library;
        if (parent is Class) {
          metadata.protectedNames.add(parent.name);
          library = parent.enclosingLibrary;
        } else if (parent is Library) {
          library = parent;
        } else {
          throw "Unexpected parent";
        }
        metadata.protectedNames.add(library.importUri.toString());
        break;
      }
    }
  }

  @override
  visitClass(Class klass) {
    _checkAnnotations(klass.annotations, klass.name, klass);
    klass.visitChildren(this);
  }

  @override
  visitConstructor(Constructor ctor) {
    _checkAnnotations(ctor.annotations, ctor.name.text, ctor);
  }

  @override
  visitProcedure(Procedure proc) {
    _checkAnnotations(proc.annotations, proc.name.text, proc);
  }

  @override
  visitField(Field field) {
    _checkAnnotations(field.annotations, field.name.text, field);
  }
}
