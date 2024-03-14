import 'package:example/SecondPage.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';

import 'FirstPage.dart';

///路由管理
class RouteHelper {
  ///主模块
  static const String firstPage = 'first';
  static const String secondPage = 'second';
  static const String main = '/main';

  ///路由与页面绑定注册
  static Map<String, WidgetBuilder> routes = {
    firstPage: (context) => FirstPage(),
    main: (context) => MyHomePage(title: "1111"),
    secondPage: (context) => SecondPage(),
  };
}
