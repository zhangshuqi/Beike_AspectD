// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A extends B with M {}

class B {
  final Object m = new Object();
}

class M {
  static Object m() => new Object();
}

main() {
  new A();
}
