import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../aop.dart';

typedef ElementContentCallback = String? Function(Widget widget);

@pragma("vm:entry-point")
class HookImpl {
  static final _instance = HookImpl._();

  HookImpl._();

  factory HookImpl.getInstance() => _instance;

  HitTestEntry? hitTestEntry;
  var elementInfoMap = <String, Object>{};
  bool searchStop = false;

  var elementPathList = <Element>[];

  List<String> contentList = [];

  Route? _targetRoute;
  Route? _popRoute;
  Route? _popPreviousRoot;
  Route? _buildPageRoute;
  BuildContext? _buildPageContext;

  void hookHitTest(HitTestEntry entry, PointerEvent event) {
    hitTestEntry = entry;
    CustomLog.d("hookHitTest:::" + hitTestEntry!.target.toString());
  }

  ElementContentCallback? elementContentCallback;

  void addElementContentCallback(ElementContentCallback callback) {
    elementContentCallback = callback;
  }

  Map<String, Object> hookClick(PointCut pointCut) {
    if (hitTestEntry == null) {
      return {};
    }
    dynamic eventName = pointCut.positionalParams![0];

    _resetValues();

    if (eventName == "onTap") {
      initValues();
      _getElementPath();
      _getElementType();
      _getElementContent();
      // _debugPrintClick(elementInfoMap);
      debugPrint("_deviceInfoMap=========${elementInfoMap}");
      debugPrint(
          "router==Info=======_targetRoute==$_targetRoute==_popRoute===$_popRoute====_popPreviousRoot==$_popPreviousRoot===");
    }
    return elementInfoMap;
  }

  void initValues() {
    elementPathList.clear();
    searchStop = false;
    elementInfoMap.clear();
  }

  void _resetValues() {
    initValues();
    contentList.clear();
  }

  void _getElementContent() {
    if (hitTestEntry == null) {
      return;
    }
    Element finalContainerElement = elementPathList[0];
    elementInfoMap["element_content"] =
        getElementContent(finalContainerElement.widget) ?? "unknown";
  }

  String? getElementContent(Widget widget) {
    String? result;
    CustomLog.d("widget===${widget.runtimeType.toString()}");
    if (widget is Text) {
      result = widget.data;
    } else if (widget is Tab) {
      result = widget.text;
    } else if (widget is IconButton) {
      result = widget.tooltip ?? "";
    }
    if (elementContentCallback != null) {
      result = elementContentCallback!(widget);
    }
    return result;
  }

  bool _shouldAddToPath(Element element) {
    Widget widget = element.widget;
    // CustomLog.d("_shouldAddToPath:::"+widget.toStringShort());
    if (widget is _CustomHasCreationLocation) {
      _CustomHasCreationLocation creationLocation =
          widget as _CustomHasCreationLocation;
      if (creationLocation._customLocation != null) {
        // CustomLog.d(creationLocation._customLocation.toString());
        return creationLocation._customLocation.isProjectRoot();
      }
    }
    return false;
  }

  void _getElementPath() {
    if (hitTestEntry == null) {
      return;
    }
    var listResult = <String>[];
    var widgetNames = <String>[];
    var listSlot = <int>[];
    RenderObject renderObject = hitTestEntry?.target as RenderObject;
    DebugCreator? debugCreator = renderObject.debugCreator as DebugCreator;
    Element element = debugCreator.element;
    if (_shouldAddToPath(element)) {
      var widgetName = element.widget.runtimeType.toString();
      int slot = 0;
      if (element.slot != null) {
        if (element.slot is IndexedSlot) {
          slot = (element.slot as IndexedSlot).index;
        }
      }
      widgetNames.add(widgetName);
      listResult.add("$widgetName[$slot]");
      listSlot.add(slot);
      elementPathList.add(element);
    }

    element.visitAncestorElements((element) {
      if (_shouldAddToPath(element)) {
        var widgetName = element.widget.runtimeType.toString();
        int slot = 0;
        if (element.slot != null) {
          if (element.slot is IndexedSlot) {
            slot = (element.slot as IndexedSlot).index;
          }
        }
        widgetNames.add(widgetName);
        listResult.add("$widgetName[$slot]");
        listSlot.add(slot);
        elementPathList.add(element);
      }
      return true;
    });
    String finalResult = "";
    listResult.reversed.forEach((element) {
      finalResult += "/$element";
    });

    if (finalResult.startsWith('/')) {
      finalResult = finalResult.replaceFirst('/', '');
    }
    String listSlotResult = "";
    listSlot.reversed.forEach((element) {
      listSlotResult += element.toString();
    });
    elementInfoMap["element_path"] = finalResult;
    elementInfoMap["element_slot"] = listSlotResult;
    elementInfoMap["widget_name"] = widgetNames;
  }

  void _getElementType() {
    if (elementPathList.isEmpty) {
      elementInfoMap["element_type"] = "unknown";
      return;
    }
    Element element = elementPathList[0];
    elementInfoMap["element_type"] = element.widget.runtimeType.toString();
  }

  void handlePush(Route? route, Route? previousRoute) {
    CustomLog.i("handlePush====route:$route    previousRoute:$previousRoute");
    if (route != null && route is PageRoute) {
      _targetRoute = route;
    }
    if (previousRoute != null && previousRoute is PageRoute) {
      _popRoute = previousRoute;
    }
    if (route != null) {
      LifecycleDetect.getInstance().onResume(route.settings.name, false);
    }
  }

  void handlePop(Route? route, Route? previousRoute) {
    CustomLog.i(
        "handlePop====route:$route  previousRoute:$previousRoute====${route is PageRoute}");
    if (route is PageRoute) {
      _popRoute = route;
      //_popPreviousRoot = previousRoute;
      _targetRoute = previousRoute;
      LifecycleDetect.getInstance().onPause(route.settings.name, false);
    }
  }

  void buildPage(Route<dynamic>? route, Widget? widget, BuildContext context) {
    if (_targetRoute == null || route == null) {
      return;
    }
    _buildPageRoute = route;
    _buildPageContext = context;
    CustomLog.i("buildPage====route:$route  widget:$widget  context:$context");
  }

  void handleDrawFrame() {}

  void _resetField() {
    this._targetRoute = null;
    this._buildPageContext = null;
    contentList.clear();
  }

  void onActivityResumed() {
    if (_buildPageRoute != null) {
      LifecycleDetect.getInstance()
          .onResume(_buildPageRoute?.settings.name, true);
    }
  }

  void onActivityPaused() {
    if (_buildPageRoute != null) {
      LifecycleDetect.getInstance()
          .onPause(_buildPageRoute?.settings.name, true);
    }
  }
}

///Location Part
@pragma("vm:entry-point")
abstract class _CustomHasCreationLocation {
  _CustomLocation get _customLocation;
}

@pragma("vm:entry-point")
class _CustomLocation {
  const _CustomLocation({
    this.file,
    this.rootUrl,
    this.line,
    this.column,
    this.name,
    this.parameterLocations,
  });

  final String? rootUrl;
  final String? file;
  final int? line;
  final int? column;
  final String? name;
  final List<_CustomLocation>? parameterLocations;

  bool isProjectRoot() {
    if (rootUrl == null || file == null) {
      return false;
    }
    return file!.startsWith(rootUrl!);
  }

  @override
  String toString() {
    return '_CustomLocation{rootUrl: $rootUrl, file: $file, line: $line, column: $column, name: $name}';
  }
}

@pragma("vm:entry-point")
class PageEvent {
  String? routeName;
  String? widgetName;
  String? fileName;

  PageEvent({this.routeName, this.widgetName, this.fileName});

  @override
  String toString() {
    return 'PageEvent{routeName: $routeName, widgetName: $widgetName, fileName: $fileName}';
  }
}

class CustomLog {
  static void d(String? str) {
    debugPrint("CustomLog:::::ddddd:::::$str");
  }

  static void i(String? str) {
    debugPrint("CustomLog:::::iiiii:::::$str");
  }

  static void w(String? str) {
    debugPrint("CustomLog:::::wwwww:::::$str");
  }
}
